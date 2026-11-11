import RPi.GPIO as GPIO
import time

TRIG = 23
ECHO = 24
THRESHOLD_CM = 23   # 이 거리보다 가까우면 "감지"

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(TRIG, GPIO.OUT)
GPIO.setup(ECHO, GPIO.IN)
GPIO.output(TRIG, False)
time.sleep(2)


def get_distance():
    GPIO.output(TRIG, True)
    time.sleep(0.00001)
    GPIO.output(TRIG, False)

    timeout = time.time() + 0.03
    start = time.time()
    while GPIO.input(ECHO) == 0:
        start = time.time()
        if start > timeout:
            return -1

    timeout = time.time() + 0.03
    end = time.time()
    while GPIO.input(ECHO) == 1:
        end = time.time()
        if end > timeout:
            return -1

    return round((end - start) * 34300 / 2, 1)


def detect_item():
    """투입구에 물체가 있으면 True"""
    dist = get_distance()
    return 0 < dist < THRESHOLD_CM


if __name__ == "__main__":
    try:
        print(f"감지 기준: {THRESHOLD_CM}cm 이내 투입 감지. Ctrl+C로 종료\n")
        while True:
            dist = get_distance()
            if dist < 0:
                print("측정 실패 (타임아웃)")
            elif dist < THRESHOLD_CM:
                print(f"★ 투입 감지! {dist}cm")
            else:
                print(f"  대기 중... {dist}cm")
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\n종료")
    finally:
        GPIO.cleanup()
