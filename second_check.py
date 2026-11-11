"""
2차 오염 검수 (무게 + UV 형광)

AI 판정에서 "통과"한 품목만 추가로 검사한다.
  1) 무게: 빈 용기 기준 무게보다 많이 무거우면 → 내용물 잔여 → 반환
  2) UV  : UV 조명 아래에서 형광으로 빛나는 영역이 많으면 → 오염 → 반환

센서가 없으면 MOCK = True 로 두고 모의값으로 동작 확인 가능.

사용 (recycle.py 판정 루프 안)
    from second_check import SecondCheck
    checker = SecondCheck()
    result = detector.inspect(frame)
    if result["decision"] == "통과":
        result.update(checker.check(result, read_frame))

측정용 실행 (기준값 만들 때)
    python second_check.py tare      # 빈 저울 영점
    python second_check.py cal 500   # 무게 아는 물건 올리고 환산 계수 계산
    python second_check.py weigh     # 올린 물건 무게 10회 측정
    python second_check.py test      # AI 탐지 + 박스 면적 + 무게 판정 한 번에
    python second_check.py uv        # UV 형광 비율 측정 + 사진 저장
"""

import sys
import time
import statistics

import cv2
import numpy as np

# ============================================================
# 설정
# ============================================================
MOCK = False               # 센서 연결 전: True / 연결 후: False
USE_UV = False             # UV LED 연결 전: False (무게만 검사) / 연결 후: True

HX_DOUT, HX_SCK = 5, 6     # HX711 핀 (BCM) → DT=GPIO5(29번), SCK=GPIO6(31번)
UV_PIN = 22                # UV LED 릴레이 핀 (BCM)
WHITE_LED_PIN = 27         # 기존 흰색 조명 (recycle.py LED_PIN)
RELAY_ON = 0               # 릴레이 켜짐 값 (recycle.py LED_ON_VALUE 와 맞출 것)

SCALE = -100.38         # HX711 원시값 → g 환산 계수 (보정 후 수정)
OFFSET_FILE = "hx_offset.txt"
a
# 품목·체급별 (공병 무게 g, 허용 초과분 g) → 2차검수_기준무게표.xlsx 와 동일, 실측 후 수정
# 판정: 측정 무게 > 공병 무게 + 허용 초과분 → 잔여물 반환 / 종이는 무게 판정 제외
EMPTY_WEIGHT = {
    "pet":     {"S": (18, 8),   "M": (20, 10),  "L": (35, 20)},
    "plastic": {"S": (2, 5),    "M": (30, 20),  "L": (60, 30)},
    "can":     {"S": (9, 6),    "M": (15, 5),   "L": (20, 10)},
    "glass":   {"S": (100, 10), "M": (290, 29), "L": (500, 50)},   # 공병의 +10%
}

# 체급 경계: AI 박스 "짧은 변"(640 축소 이미지 기준 픽셀) → 실제 병을 찍어보고 수정
#   카메라가 위에서 비스듬히 내려다봐서 박스 아래쪽이 화면 끝에 잘림 → 높이·면적은 못 씀
#   짧은 변(= 용기 지름)은 세우든 눕히든 잘리지 않아 크기 구분에 사용
SIZE_LIMIT = {             # (소형 상한, 중형 상한) 픽셀
    "pet":     (110, 160),
    "plastic": (120, 200),
    "can":     (90, 125),
    "glass":   (80, 130),
}


def size_class(item, box):
    """박스의 짧은 변(= 용기 지름)으로 소형(S)/중형(M)/대형(L) 구분
    세워 넣으면 가로가, 눕혀 넣으면 세로가 지름 → 짧은 변을 쓰면 방향과 무관"""
    x1, y1, x2, y2 = box
    width = min(x2 - x1, y2 - y1)
    s, m = SIZE_LIMIT[item]
    return "S" if width < s else "M" if width < m else "L"

# UV 형광 판정
UV_WARMUP = 0.3            # UV 켠 뒤 안정화 대기(초)
UV_HSV_LOW = (35, 80, 150)     # 형광 색 범위 (청록~황록, 밝고 진한 색)
UV_HSV_HIGH = (95, 255, 255)
UV_RATIO_LIMIT = 0.02      # 물체 영역 중 형광 비율이 2% 넘으면 오염

# ============================================================
# GPIO
# ============================================================
# 라즈베리파이 5 는 기존 RPi.GPIO 가 동작하지 않음 → rpi-lgpio 설치 필요
#   sudo apt install python3-rpi-lgpio
# ImportError 뿐 아니라 RuntimeError(핀 접근 실패) 도 잡아서 MOCK 으로 떨어뜨린다
try:
    import RPi.GPIO as GPIO
    GPIO.setwarnings(False)
    GPIO.setmode(GPIO.BCM)
except (ImportError, RuntimeError) as e:
    print(f"[경고] GPIO 사용 불가 → MOCK 모드로 실행합니다: {e}")
    GPIO = None
    MOCK = True


def relay(pin, on):
    if GPIO is None:
        return
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, RELAY_ON if on else 1 - RELAY_ON)


# ============================================================
# 무게 (HX711)
# ============================================================
class Scale:
    def __init__(self):
        self.offset = 0
        if MOCK:
            return
        GPIO.setup(HX_DOUT, GPIO.IN)
        GPIO.setup(HX_SCK, GPIO.OUT, initial=0)
        try:
            self.offset = float(open(OFFSET_FILE).read())
        except FileNotFoundError:
            pass

    def _raw(self):
        """HX711 24비트 값 1회 읽기"""
        t = time.time()
        while GPIO.input(HX_DOUT):              # 준비될 때까지 대기
            if time.time() - t > 0.5:
                raise RuntimeError("HX711 응답 없음 (배선 확인)")
        v = 0
        for _ in range(24):
            GPIO.output(HX_SCK, 1)
            v = (v << 1) | GPIO.input(HX_DOUT)
            GPIO.output(HX_SCK, 0)
        GPIO.output(HX_SCK, 1)                  # 게인 128 설정용 펄스
        GPIO.output(HX_SCK, 0)
        return v - (1 << 24) if v & 0x800000 else v

    def raw(self, n=7):
        """n회 측정 후 중앙값 (튀는 값 제거)"""
        return statistics.median(self._raw() for _ in range(n))

    def tare(self):
        self.offset = self.raw(15)
        open(OFFSET_FILE, "w").write(str(self.offset))

    def grams(self):
        if MOCK:
            return 25.0                         # 모의값: 빈 페트병(20g)보다 약간 무거움
        return (self.raw() - self.offset) / SCALE


# ============================================================
# UV 형광
# ============================================================
def uv_ratio(image, box=None):
    """형광으로 빛나는 픽셀 비율 (box 가 있으면 그 영역만)"""
    if box is not None:
        x1, y1, x2, y2 = map(int, box)
        image = image[y1:y2, x1:x2]
    if image.size == 0:
        return 0.0, None
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(hsv, UV_HSV_LOW, UV_HSV_HIGH)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))   # 점 반사 제거
    return float(mask.mean() / 255), mask


def uv_capture(read_frame):
    """흰 조명 끄고 UV 켜서 한 장 촬영"""
    if MOCK:
        return None
    relay(WHITE_LED_PIN, False)
    relay(UV_PIN, True)
    time.sleep(UV_WARMUP)
    read_frame()                                # 노출 적응용으로 한 장 버림
    frame = read_frame()
    relay(UV_PIN, False)
    relay(WHITE_LED_PIN, True)
    return frame


# ============================================================
# 2차 검수
# ============================================================
class SecondCheck:
    def __init__(self):
        self.scale = Scale()

    def check(self, result, read_frame):
        """AI 통과 품목 검사 → recycle.py result 에 덮어쓸 dict 반환"""
        t0 = time.time()
        item = result.get("category")
        out = {}

        # 1) 무게
        g = self.scale.grams()
        out["weight_g"] = round(g, 1)
        body = next((b for b in result.get("boxes", []) if b["name"] == item), None)
        if item in EMPTY_WEIGHT and body:
            size = size_class(item, body["xyxy"])
            base, tol = EMPTY_WEIGHT[item][size]
            out["size"] = size
            if g > base + tol:
                out.update(decision="반환", reason="내용물을 비우고 헹궈서 버려 주세요",
                           contaminated=True)

        # 2) UV (무게 통과한 경우만)
        if "decision" not in out and USE_UV:
            frame = uv_capture(read_frame)
            if frame is None:
                ratio = 0.0                     # MOCK
            else:
                # 본체 박스 = 분류된 품목의 박스. 좌표는 640 축소 이미지 기준이라 원본 크기로 환산
                body = next((b for b in result.get("boxes", []) if b["name"] == item), None)
                box = None
                if body:
                    k = max(frame.shape[:2]) / 640
                    box = [v * k for v in body["xyxy"]]
                ratio, _ = uv_ratio(frame, box)
            out["uv_ratio"] = round(ratio, 4)
            if ratio > UV_RATIO_LIMIT:
                out.update(decision="반환", reason="용기에 이물질이 묻어 있어요. 헹궈서 버려 주세요",
                           contaminated=True)

        out.setdefault("contaminated", False)
        out["second_ms"] = round((time.time() - t0) * 1000)
        return out


# ============================================================
# 측정용 실행
# ============================================================
if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""

    if cmd == "tare":
        Scale().tare()
        print("영점 저장 완료")

    elif cmd == "cal":                          # python second_check.py cal 77  (올린 물건 무게 g)
        known = float(sys.argv[2])
        s = Scale()
        raw = s.raw(15) - s.offset
        print(f"SCALE = {raw / known:.2f}   ← 파일 위쪽 SCALE 값을 이걸로 바꾸기")

    elif cmd == "weigh":
        s = Scale()
        vals = [s.grams() for _ in range(10)]
        print(f"평균 {statistics.mean(vals):.1f} g  (최소 {min(vals):.1f}, 최대 {max(vals):.1f})")

    elif cmd == "test":                         # AI 탐지 + 박스 면적 + 무게 판정 (Enter 마다 1회, q 종료)
        from recycle import RecycleDetector, open_camera, led
        detector, checker = RecycleDetector(), SecondCheck()
        led(True)
        read_frame, close = open_camera()
        try:
            while input("\n물건 올리고 Enter (q 종료): ").strip() != "q":
                result = detector.inspect(read_frame())
                for b in result["boxes"]:
                    x1, y1, x2, y2 = b["xyxy"]
                    print(f"  {b['name']:<8} {b['conf']:.2f}  박스 {x2 - x1:.0f}x{y2 - y1:.0f} = {(x2 - x1) * (y2 - y1):.0f}px²")
                if result["decision"] == "통과":
                    result.update(checker.check(result, read_frame))
                print(f"→ {result['decision']} / {result['reason']}  "
                      f"[체급 {result.get('size', '-')}, 무게 {result.get('weight_g', '-')} g]")
        finally:
            close()
            led(False)

    elif cmd == "uv":
        from recycle import open_camera
        read_frame, close = open_camera()
        try:
            frame = uv_capture(read_frame) if not MOCK else read_frame()
            ratio, mask = uv_ratio(frame)
            name = time.strftime("uv_%H%M%S")
            cv2.imwrite(name + ".jpg", frame)
            if mask is not None:
                cv2.imwrite(name + "_mask.png", mask)
            print(f"형광 비율 {ratio * 100:.2f}%  → {'오염' if ratio > UV_RATIO_LIMIT else '깨끗'}  ({name}.jpg)")
        finally:
            close()

    else:
        print(__doc__)
