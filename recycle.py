"""
라즈베리파이용 재활용품 판정 코드

필요한 파일 (같은 폴더에 두기)
    recycle_detector.py   ← 이 파일
    recycle.onnx          ← 변환한 모델

설치 (라즈베리파이 터미널)
    python3 -m venv --system-site-packages venv
    source venv/bin/activate
    pip install ultralytics onnxruntime

실행
    python recycle_detector.py test.jpg     # 사진 파일로 테스트
    python recycle_detector.py              # 카메라로 1장 찍어서 판정
    python recycle_detector.py --live       # 실시간 탐지 (모니터 없으면 브라우저 :8000으로 보기)
    python recycle_detector.py --collect glass_cap   # 학습용 원본 사진 모으기 (captures/glass_cap/)

다른 코드(하드웨어 제어, 서버 전송)에서 쓸 때
    from recycle_detector import RecycleDetector
    detector = RecycleDetector("recycle.onnx")
    result = detector.inspect(frame)        # frame: OpenCV BGR 이미지
    result["decision"]                      # "통과" 또는 "반환"
    result["category"]                      # 통과 시 분류 칸 (pet, plastic, glass, can)
"""

import os
import sys
import time

# 실행할 때 쏟아지는 로그 숨기기
os.environ.setdefault("LIBCAMERA_LOG_LEVELS", "*:ERROR")   # 카메라(libcamera) INFO/WARN 로그
try:
    import onnxruntime
    onnxruntime.set_default_logger_severity(3)               # ONNX Runtime GPU 탐색 경고 (3 = 에러만)
except ImportError:
    pass

import cv2
from ultralytics import YOLO


# ============================================================
# 설정
# ============================================================

MODEL_PATH = "recycle.onnx"
IMAGE_SIZE = 640          # 학습·변환할 때와 같은 크기
SHOW_CONF = 0.2          # 모델에서 받아올 최소 확신도 (판정은 아래 기준으로 다시 거름)
JUDGE_CONF = 0.3          # 본체 판정에 쓸 최소 확신도

# 부착물(홀더·라벨·뚜껑)은 본체 박스 안에 있을 때만, 더 낮은 확신도로도 인정
ATTACH_CLASSES = {"paper", "vinyl", "can"}
ATTACH_CONF = 0.1

# 부착물 안내 문구 (본체, 부착물) → 안내
ATTACH_MSG = {
    ("pet", "vinyl"): "페트병 라벨을 제거해 주세요",
    ("plastic", "paper"): "컵 홀더를 빼 주세요",
    ("glass", "can"): "유리병 뚜껑을 분리해 주세요",
}

# 단독으로 들어오면 반환할 품목 (이 수거함이 받지 않는 재질)
NOT_ACCEPTED = {"paper", "vinyl"}

# 조명 LED (릴레이2)
LED_PIN = 27
LED_ON_VALUE = 1          # 릴레이가 반대로 동작하면 0으로
LED_WARMUP = 2            # LED 켜고 밝기가 안정될 때까지 대기(초)

# 카메라 밝기 보정 (0 = 자동 그대로, 음수 = 어둡게). LED에 뚜껑이 하얗게 날아가면 낮추기
EXPOSURE_EV = 0

# ============================================================
# 전처리: Colab 학습 때와 똑같이 맞춘다
#   학습 (cache.py shrink_image → dataloader → utils.letterbox)
#     1) 긴 변 640으로 축소 (PIL thumbnail)
#     2) JPEG 품질 90으로 저장 (캐시에 이 상태로 들어가 있음)
#     3) 640x640 레터박스, 회색(114) 패딩
#   여기서는 1, 2를 똑같이 하고, 3은 model.predict가 같은 방식(114 패딩)으로 해 준다
#   (CLAHE 같은 밝기 보정은 학습 때 안 했으므로 넣지 않는다)
# ============================================================

def preprocess(frame):
    import io
    import numpy as np
    from PIL import Image

    image = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    image.thumbnail((IMAGE_SIZE, IMAGE_SIZE))          # 1) 긴 변 640 (비율 유지)

    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=90)      # 2) JPEG 90
    image = Image.open(buffer).convert("RGB")

    return cv2.cvtColor(np.asarray(image), cv2.COLOR_RGB2BGR)


# ============================================================
# LED
# ============================================================

def led(on):
    """조명 LED 켜기/끄기 (GPIO 없는 PC에서는 그냥 넘어감)"""
    try:
        import RPi.GPIO as GPIO
    except ImportError:
        return

    if on:
        GPIO.setwarnings(False)
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(LED_PIN, GPIO.OUT)
        GPIO.output(LED_PIN, LED_ON_VALUE)
        time.sleep(LED_WARMUP)
    else:
        GPIO.output(LED_PIN, 1 - LED_ON_VALUE)
        GPIO.cleanup()


# ============================================================
# 판정 로직
# ============================================================

def inside(inner, outer, ratio=0.8):
    """inner 박스 면적의 80% 이상이 outer 박스 안에 있으면 True"""
    x1, y1 = max(inner[0], outer[0]), max(inner[1], outer[1])
    x2, y2 = min(inner[2], outer[2]), min(inner[3], outer[3])
    overlap = max(0, x2 - x1) * max(0, y2 - y1)
    area = (inner[2] - inner[0]) * (inner[3] - inner[1])
    return area > 0 and overlap / area >= ratio


def judge(boxes):
    """
    boxes: [{"name": 클래스, "conf": 확신도, "xyxy": [x1, y1, x2, y2]}, ...]
    반환: (판정, 이유, 분류 칸)
    """
    # 본체 후보: 기준 이상
    strong = [b for b in boxes if b["conf"] >= JUDGE_CONF]
    # 부착물 후보: 확신도가 낮아도 본체 박스 안에 들어 있으면 인정
    weak = [
        b for b in boxes
        if ATTACH_CONF <= b["conf"] < JUDGE_CONF
        and b["name"] in ATTACH_CLASSES
        and any(inside(b["xyxy"], s["xyxy"]) and s["name"] != b["name"] for s in strong)
    ]
    boxes = strong + weak

    if not boxes:
        return "반환", "물체를 인식하지 못했어요", None

    # 다른 박스 안에 들어 있는 박스 = 부착물
    attached = set()
    messages = []
    for i, part in enumerate(boxes):
        for j, body in enumerate(boxes):
            if i != j and inside(part["xyxy"], body["xyxy"]):
                attached.add(i)
                if part["name"] == body["name"]:
                    continue        # 같은 물체를 겹쳐 잡은 중복 박스 → 무시
                key = (body["name"], part["name"])
                messages.append(ATTACH_MSG.get(key, f"{body['name']}에 붙은 {part['name']}를 분리해 주세요"))

    # 같은 클래스 박스가 여러 개면 한 물체로 본다 (확신도 낮을 때 생기는 중복)
    bodies = list(dict.fromkeys(b["name"] for k, b in enumerate(boxes) if k not in attached))

    if len(bodies) >= 2:
        return "반환", "하나씩 넣어 주세요", None

    if messages:
        return "반환", " / ".join(dict.fromkeys(messages)), None

    if bodies[0] in NOT_ACCEPTED:
        return "반환", "이 수거함에 넣을 수 없는 품목이에요", None

    return "통과", bodies[0], bodies[0]


# ============================================================
# 박스 그리기
#   본체 라벨은 박스 위, 부착물(다른 박스 안에 든 박스) 라벨은 박스 아래에 표시
#   → 뚜껑·홀더 라벨이 본체 라벨과 겹쳐서 가려지지 않게
# ============================================================

FONT_PATH = "/usr/share/fonts/truetype/nanum/NanumSquareRoundB.ttf"   # 카톡처럼 부드러운 글씨
FONT_SIZE = 18
_font = None


def draw_boxes(image, boxes):
    import numpy as np
    from PIL import Image, ImageDraw, ImageFont
    from ultralytics.utils.plotting import colors

    global _font
    if _font is None:
        try:
            _font = ImageFont.truetype(FONT_PATH, FONT_SIZE)
        except OSError:
            _font = ImageFont.load_default()

    class_ids = {"plastic": 0, "pet": 1, "glass": 2, "can": 3, "paper": 4, "vinyl": 5}
    shown = [b for b in boxes if b["conf"] >= ATTACH_CONF]

    pil = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(pil)
    W, H = pil.size
    pad = 4

    # 박스 먼저 다 그리고, 라벨은 나중에 (라벨이 다른 박스 선에 가려지지 않게)
    labels = []
    for b in shown:
        x1, y1, x2, y2 = map(int, b["xyxy"])
        r, g, bl = colors(class_ids.get(b["name"], 0), False)   # RGB
        draw.rectangle((x1, y1, x2, y2), outline=(r, g, bl), width=3)

        text = f"{b['name']} {b['conf']:.2f}"
        l, t, rr, bb = draw.textbbox((0, 0), text, font=_font)
        tw, th = rr - l, bb - t
        lw, lh = tw + pad * 2, th + pad * 2

        is_part = any(o is not b and inside(b["xyxy"], o["xyxy"]) for o in shown)
        if is_part:
            ly = min(y2, H - lh)                  # 부착물: 박스 아래
        else:
            ly = max(y1 - lh, 0)                  # 본체: 박스 위
        lx = min(max(x1, 0), W - lw)
        labels.append((lx, ly, lw, lh, l, t, text, (r, g, bl)))

    for lx, ly, lw, lh, l, t, text, color in labels:
        draw.rounded_rectangle((lx, ly, lx + lw, ly + lh), radius=5, fill=color)
        text_color = (0, 0, 0) if sum(color) > 450 else (255, 255, 255)   # 밝은 배경엔 검은 글씨
        draw.text((lx + pad - l, ly + pad - t), text, font=_font, fill=text_color)

    return cv2.cvtColor(np.asarray(pil), cv2.COLOR_RGB2BGR)


# ============================================================
# 모델 래퍼
# ============================================================

class RecycleDetector:

    def __init__(self, model_path=MODEL_PATH):
        self.model = YOLO(model_path, task="detect")

        # 첫 실행은 준비 시간 때문에 느려서, 미리 한 번 돌려 둔다
        dummy = None
        if dummy is None:
            import numpy as np
            dummy = np.zeros((IMAGE_SIZE, IMAGE_SIZE, 3), dtype="uint8")
        self.model.predict(dummy, imgsz=IMAGE_SIZE, verbose=False)

    def inspect(self, frame):
        """frame: OpenCV BGR 이미지 → 판정 결과 dict"""
        start = time.perf_counter()

        frame = preprocess(frame)
        t_pre = time.perf_counter() - start         # 우리 전처리 (640 축소 + JPEG)

        result = self.model.predict(
            frame,
            imgsz=IMAGE_SIZE,
            conf=SHOW_CONF,
            agnostic_nms=False,   # 부착물 박스가 지워지지 않게
            verbose=False,
        )[0]

        # 클래스마다 확신도가 가장 높은 박스 1개만 남긴다 (한 번에 물건 1개 넣는 구조)
        # → 유리병이 glass 박스 여러 개로 쪼개져 잡히는 것 방지
        best = {}
        for i, b in enumerate(result.boxes):
            c = int(b.cls)
            if c not in best or float(b.conf) > float(result.boxes[best[c]].conf):
                best[c] = i
        result = result[sorted(best.values())]

        boxes = [
            {
                "name": result.names[int(b.cls)],
                "conf": float(b.conf),
                "xyxy": [float(v) for v in b.xyxy[0].tolist()],
            }
            for b in result.boxes
        ]

        decision, reason, category = judge(boxes)
        elapsed = time.perf_counter() - start       # 전처리 ~ 판정까지 전체

        sp = result.speed                            # Ultralytics 단계별 시간 (ms)
        timing = {
            "total": elapsed * 1000,
            "preprocess": t_pre * 1000 + sp["preprocess"],
            "inference": sp["inference"],
            "postprocess": sp["postprocess"],
        }

        return {
            "decision": decision,        # "통과" / "반환"
            "reason": reason,            # 사용자 안내 문구
            "category": category,        # 통과 시 분류 칸
            "boxes": boxes,              # 앱에 결함 위치 표시용
            "elapsed": elapsed,          # 초
            "timing": timing,            # 단계별 시간 (ms)
            "plot": draw_boxes(result.orig_img, boxes),   # 박스 그린 이미지 (BGR)
        }


def timing_text(t):
    """⏱️ 탐지 시간: 173.7 ms  (전처리 5.7 / 추론 142.5 / 후처리 24.1 ms)"""
    return (f"⏱️ 탐지 시간: {t['total']:.1f} ms  "
            f"(전처리 {t['preprocess']:.1f} / 추론 {t['inference']:.1f} / 후처리 {t['postprocess']:.1f} ms)")


def timing_summary(times):
    """여러 장 측정 결과 요약"""
    if not times:
        return
    print(f"\n===== 탐지 시간 요약 ({len(times)}장, 라즈베리파이 CPU) =====")
    print(f"   평균 {sum(times) / len(times):.1f} ms / 최소 {min(times):.1f} ms / 최대 {max(times):.1f} ms")
    print(f"   → 초당 약 {1000 / (sum(times) / len(times)):.0f}장 처리 가능")


# ============================================================
# 백엔드 전송 (AWS)
#   DB 컬럼: id, date, imageUrl (서버가 채움) / itemType, contaminated, reason (여기서 보냄)
#   사진은 multipart로 같이 보내면 EC2가 S3에 올리고 imageUrl을 채운다 (라즈베리파이에 AWS 키 불필요)
# ============================================================

SERVER_URL = "http://32.236.105.231:3000/api/inspection-result"
SEND_TIMEOUT = 10         # 사진 업로드 포함. 서버가 느려도 수거함이 멈추지 않게
IMAGE_FIELD = "image"     # 서버(multer)가 받는 사진 필드 이름


def to_payload(result):
    """판정 결과 → 서버로 보낼 JSON. 아무것도 인식 못 했으면 None (보내지 않음)"""
    item = result["category"]
    if item is None:
        # 반환일 때도 어떤 물건이었는지 남기기: 확신도 가장 높은 본체
        strong = [b for b in result["boxes"] if b["conf"] >= JUDGE_CONF]
        if not strong:
            return None
        item = max(strong, key=lambda b: b["conf"])["name"]

    return {
        "itemType": item,                                  # pet, plastic, glass, can, paper, vinyl
        "contaminated": result["decision"] == "반환",
        "reason": result["reason"],
    }


def send_result(result):
    """판정 결과 + 박스 그린 사진을 백엔드에 POST (multipart). 성공하면 True (실패해도 예외 없이 False)"""
    import requests

    payload = to_payload(result)
    if payload is None:
        print("   📡 전송 생략 (인식된 물체 없음)")
        return False

    # multipart 폼 값은 문자열이라 bool은 "true"/"false"로
    data = {**payload, "contaminated": "true" if payload["contaminated"] else "false"}
    ok, jpg = cv2.imencode(".jpg", result["plot"], [cv2.IMWRITE_JPEG_QUALITY, 85])
    files = {IMAGE_FIELD: ("result.jpg", jpg.tobytes(), "image/jpeg")} if ok else None

    try:
        response = requests.post(SERVER_URL, data=data, files=files, timeout=SEND_TIMEOUT)
    except requests.RequestException as e:
        print(f"   📡 서버 연결 실패: {e}")
        return False

    if response.ok:
        print(f"   📡 전송 성공 ({response.status_code}): {response.text[:200]}")
        return True
    print(f"   📡 전송 실패 ({response.status_code}): {response.text[:200]}")
    return False


# ============================================================
# 카메라
# ============================================================

def capture():
    """라즈베리파이 카메라로 1장 촬영 (실패 시 USB 웹캠)"""
    try:
        from picamera2 import Picamera2

        cam = Picamera2()
        cam.configure(cam.create_video_configuration(main={"size": (1280, 720), "format": "RGB888"}))
        cam.set_controls({"ExposureValue": EXPOSURE_EV})
        cam.start()
        time.sleep(1)                     # 노출이 안정될 때까지 대기
        frame = cam.capture_array()       # RGB888 설정 시 OpenCV와 같은 BGR 순서
        cam.stop()
        cam.close()
        return frame

    except ImportError:
        cap = cv2.VideoCapture(0)
        ok, frame = cap.read()
        cap.release()
        if not ok:
            raise RuntimeError("카메라에서 사진을 가져오지 못했어요")
        return frame


# ============================================================
# 실시간 화면 (카메라 미리보기 + 박스 표시)
#   스페이스: 지금 화면으로 판정   q: 종료
# ============================================================

def open_camera():
    """카메라를 열고 프레임을 읽는 함수를 돌려준다"""
    try:
        from picamera2 import Picamera2

        cam = Picamera2()
        cam.configure(cam.create_video_configuration(main={"size": (1280, 720), "format": "RGB888"}))
        cam.set_controls({"ExposureValue": EXPOSURE_EV})
        cam.start()
        time.sleep(1)
        return cam.capture_array, lambda: (cam.stop(), cam.close())

    except ImportError:
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            raise RuntimeError("카메라를 열 수 없어요")
        return (lambda: cap.read()[1]), cap.release


WEB_PORT = 8000
_latest_jpg = None   # 웹으로 보낼 최신 화면


def start_web_server():
    """브라우저에서 http://<라즈베리파이IP>:8000 으로 실시간 화면 보기 (MJPEG)"""
    import threading
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-Type", "multipart/x-mixed-replace; boundary=frame")
            self.end_headers()
            try:
                while True:
                    if _latest_jpg is not None:
                        self.wfile.write(b"--frame\r\nContent-Type: image/jpeg\r\n\r\n" + _latest_jpg + b"\r\n")
                    time.sleep(0.1)
            except (BrokenPipeError, ConnectionResetError):
                pass   # 브라우저 닫힘

        def log_message(self, *args):
            pass       # 접속 로그 숨김

    server = ThreadingHTTPServer(("0.0.0.0", WEB_PORT), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()


def live_headless(detector):
    """모니터 없이(SSH) 실행할 때: 브라우저로 화면 전송 + 1초마다 판정 출력. Ctrl+C로 종료"""
    global _latest_jpg

    read_frame, close = open_camera()
    start_web_server()
    print(f"브라우저에서 http://<라즈베리파이IP>:{WEB_PORT} 접속하면 화면이 보여요 (Ctrl+C: 종료)")

    last_print = 0
    times = []
    try:
        while True:
            frame = read_frame()
            if frame is None:
                continue

            result = detector.inspect(frame)
            times.append(result["timing"]["total"])
            _latest_jpg = cv2.imencode(".jpg", result["plot"])[1].tobytes()

            if time.time() - last_print >= 1:
                last_print = time.time()
                names = ", ".join(f"{b['name']} {b['conf'] * 100:.0f}%" for b in result["boxes"]) or "-"
                icon = "🟢" if result["decision"] == "통과" else "🔴"
                print(f"{icon} {result['decision']} → {result['reason']}  [{names}]")
                print(f"   {timing_text(result['timing'])}")

    except KeyboardInterrupt:
        pass
    finally:
        close()
        timing_summary(times)


def collect(name, interval=2.0):
    """학습용 원본 사진 모으기: LED 켠 상태로 interval초마다 captures/<name>/ 에 저장. 브라우저로 미리보기. Ctrl+C로 종료"""
    global _latest_jpg

    save_dir = os.path.join("captures", name)
    os.makedirs(save_dir, exist_ok=True)

    read_frame, close = open_camera()
    start_web_server()
    print(f"📸 {save_dir}/ 에 {interval:.0f}초마다 저장 (미리보기: http://<라즈베리파이IP>:{WEB_PORT}, Ctrl+C: 종료)")
    print("   찍힐 때마다 물건 위치·방향을 조금씩 바꿔 주세요")

    count = len(os.listdir(save_dir))
    last_save = 0
    try:
        while True:
            frame = read_frame()
            if frame is None:
                continue

            _latest_jpg = cv2.imencode(".jpg", frame)[1].tobytes()   # 박스 없는 원본 미리보기

            if time.time() - last_save >= interval:
                last_save = time.time()
                path = os.path.join(save_dir, f"{name}_{time.strftime('%Y%m%d_%H%M%S')}.jpg")
                cv2.imwrite(path, frame, [cv2.IMWRITE_JPEG_QUALITY, 95])
                count += 1
                print(f"   저장 {count}장: {path}")

    except KeyboardInterrupt:
        pass
    finally:
        close()


def live(detector):
    # 모니터가 없으면(SSH 접속) 창을 못 띄우므로 터미널 모드로
    if not os.environ.get("DISPLAY") and not os.environ.get("WAYLAND_DISPLAY"):
        return live_headless(detector)

    read_frame, close = open_camera()
    window = "Recycle Detector (space: 판정 / q: 종료)"
    message = ""

    try:
        while True:
            frame = read_frame()
            if frame is None:
                continue

            result = detector.inspect(frame)
            view = result["plot"].copy()

            fps = 1 / max(result["elapsed"], 1e-6)
            cv2.putText(view, f"{fps:.1f} FPS", (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

            cv2.imshow(window, view)
            key = cv2.waitKey(1) & 0xFF

            if key == ord("q"):
                break

            if key == ord(" "):
                icon = "🟢" if result["decision"] == "통과" else "🔴"
                print(f"{icon} 판정: {result['decision']} → {result['reason']}")
                print(f"   {timing_text(result['timing'])}")
                cv2.imwrite("result.jpg", result["plot"])
                send_result(result)

    finally:
        close()
        cv2.destroyAllWindows()


# ============================================================
# 실행
# ============================================================

if __name__ == "__main__":

    print("모델 불러오는 중...")
    detector = RecycleDetector()

    if "--collect" in sys.argv:
        # 예: python recycle.py --collect glass_cap
        i = sys.argv.index("--collect")
        name = sys.argv[i + 1] if i + 1 < len(sys.argv) else "unknown"
        led(True)
        try:
            collect(name)
        finally:
            led(False)
        sys.exit()

    if "--live" in sys.argv:
        led(True)
        try:
            live(detector)
        finally:
            led(False)
        sys.exit()

    if len(sys.argv) > 1:
        frame = cv2.imread(sys.argv[1])
        if frame is None:
            sys.exit(f"사진을 열 수 없어요: {sys.argv[1]}")
    else:
        print("LED 켜고 카메라 촬영 중...")
        led(True)
        try:
            frame = capture()
        finally:
            led(False)

    result = detector.inspect(frame)

    print("\n탐지된 박스")
    for b in sorted(result["boxes"], key=lambda b: -b["conf"]):
        mark = "✅" if b["conf"] >= JUDGE_CONF else "·"
        print(f"  {mark} {b['name']}  {b['conf'] * 100:.1f}%")

    icon = "🟢" if result["decision"] == "통과" else "🔴"
    print(f"\n{icon} 판정: {result['decision']} → {result['reason']}")
    print(timing_text(result["timing"]))

    cv2.imwrite("result.jpg", result["plot"])
    print("박스 그린 사진 저장: result.jpg")

    if "--no-send" not in sys.argv:
        send_result(result)