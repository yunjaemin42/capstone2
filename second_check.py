"""
2차 오염 검수 (무게)

AI 판정에서 "통과"한 품목만 추가로 검사한다.
  무게: 품목·체급별 반환 기준 무게를 넘으면 → 내용물 잔여 → 반환
  (용기 표면 오염은 AI의 stain 클래스가 1차 판정에서 걸러낸다)

센서가 없으면 MOCK = True 로 두고 모의값으로 동작 확인 가능.

사용 (main.py)
    from second_check import SecondCheck
    checker = SecondCheck()
    result = detector.inspect(frame)
    if result["decision"] == "통과":
        result.update(checker.check(result))

측정용 실행 (기준값 만들 때)
    python second_check.py tare      # 빈 저울 영점
    python second_check.py cal 500   # 무게 아는 물건 올리고 환산 계수 계산
    python second_check.py weigh     # 올린 물건 무게 10회 측정
    python second_check.py test      # AI 탐지 + 박스 크기 + 무게 판정 한 번에
"""

import os
import sys
import time
import statistics

# ============================================================
# 설정
# ============================================================
MOCK = False               # 센서 연결 전: True / 연결 후: False

HX_DOUT, HX_SCK = 5, 6     # HX711 핀 (BCM) → DT=GPIO5(29번), SCK=GPIO6(31번)

SCALE = -100.38            # HX711 원시값 → g 환산 계수 (보정 후 수정)
OFFSET_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hx_offset.txt")   # 어느 폴더에서 실행해도 같은 파일

# 무게 센서 기준표: 품목 → 체급 → (기준 무게 g, 반환 판정 기준 g)
# 판정: 측정 무게 > 반환 판정 기준 → 내용물 잔여 → 반환
WEIGHT_TABLE = {
    "pet":     {"S": (16, 26),   "M": (20, 30),   "L": (35, 45)},
    "plastic": {"S": (2, 12),    "M": (30, 40),   "L": (60, 70)},
    "can":     {"S": (9, 19),    "M": (15, 25),   "L": (20, 30)},
    "glass":   {"S": (100, 110), "M": (290, 300), "L": (500, 510)},
}

# 체급 경계: AI 박스 "짧은 변"(640 축소 이미지 기준 픽셀) → (소형 상한, 중형 상한)
#   카메라가 위에서 비스듬히 내려다봐서 박스 아래쪽이 화면 끝에 잘림 → 높이·면적은 못 씀
#   짧은 변(= 용기 지름)은 세우든 눕히든 잘리지 않아 크기 구분에 사용
SIZE_LIMIT = {
    "pet":     (110, 160),
    "plastic": (120, 200),
    "can":     (90, 125),
    "glass":   (80, 130),
}

SIZE_NAME = {"S": "소형", "M": "중형", "L": "대형"}


def size_class(item, box):
    """박스의 짧은 변(= 용기 지름)으로 소형(S)/중형(M)/대형(L) 구분
    세워 넣으면 가로가, 눕혀 넣으면 세로가 지름 → 짧은 변을 쓰면 방향과 무관"""
    x1, y1, x2, y2 = box
    width = min(x2 - x1, y2 - y1)
    s, m = SIZE_LIMIT[item]
    return "S" if width < s else "M" if width < m else "L"


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
            print(f"[경고] {OFFSET_FILE} 없음 → 'python second_check.py tare' 로 영점을 먼저 잡아 주세요")

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
            return 25.0                         # 모의값: 500ml 페트(20g)보다 약간 무거움, 기준(30g) 이내
        return (self.raw() - self.offset) / SCALE


# ============================================================
# 2차 검수
# ============================================================
class SecondCheck:
    def __init__(self):
        self.scale = Scale()

    def check(self, result):
        """AI 통과 품목 무게 검사 → result 에 덮어쓸 dict 반환
        반환 판정이면 decision/reason/category 를 덮어쓴다"""
        t0 = time.time()
        item = result.get("category")
        out = {}

        try:
            g = self.scale.grams()
        except RuntimeError as e:
            # 저울이 고장 나도 수거함은 멈추지 않게: 무게 검사만 건너뜀
            print(f"   ⚖️ 무게 측정 실패 → 검사 생략: {e}")
            return out

        out["weight_g"] = round(g, 1)
        body = next((b for b in result.get("boxes", []) if b["name"] == item), None)
        if item in WEIGHT_TABLE and body:
            size = size_class(item, body["xyxy"])
            base, limit = WEIGHT_TABLE[item][size]
            out["size"] = size
            out["weight_limit_g"] = limit
            if g > limit:
                # category 는 서버에 품목 이름으로 보내야 해서 남겨 두고, 분류는 main.py 에서 decision 으로 막는다
                out.update(decision="반환", reason="내용물을 비우고 헹궈서 버려 주세요")

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

    elif cmd == "test":                         # AI 탐지 + 박스 크기 + 무게 판정 (Enter 마다 1회, q 종료)
        from recycle import RecycleDetector, open_camera, led
        detector, checker = RecycleDetector(), SecondCheck()
        led(True)
        read_frame, close = open_camera()
        try:
            while input("\n물건 올리고 Enter (q 종료): ").strip() != "q":
                result = detector.inspect(read_frame())
                for b in result["boxes"]:
                    x1, y1, x2, y2 = b["xyxy"]
                    print(f"  {b['name']:<8} {b['conf']:.2f}  박스 {x2 - x1:.0f}x{y2 - y1:.0f}  "
                          f"짧은 변 {min(x2 - x1, y2 - y1):.0f}px")
                if result["decision"] == "통과":
                    result.update(checker.check(result))
                print(f"→ {result['decision']} / {result['reason']}  "
                      f"[체급 {SIZE_NAME.get(result.get('size'), '-')}, "
                      f"무게 {result.get('weight_g', '-')} g / 기준 {result.get('weight_limit_g', '-')} g]")
        finally:
            close()
            led(False)

    else:
        print(__doc__)
