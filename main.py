import time
import RPi.GPIO as GPIO

from recycle import RecycleDetector, capture, send_result
import ultrasonic
import led
import sort_test2 as sorter
import conveyor
import servo

BIN_MAP = {"pet": 1, "plastic": 2, "glass": 3, "can": 4}
BIN_NAME = {1: "투명 페트병", 2: "일반 플라스틱", 3: "유리", 4: "캔"}
LED_WARMUP = 2


def item_inserted():
    """두 번 연속 감지돼야 투입으로 인정"""
    if not ultrasonic.detect_item():
        return False
    time.sleep(0.1)
    return ultrasonic.detect_item()


def take_photo():
    """LED 켜고 촬영 후 끄기"""
    led.led_on()
    try:
        time.sleep(LED_WARMUP)
        return capture()
    finally:
        led.led_off()


def wait_until_clear():
    while ultrasonic.detect_item():
        time.sleep(0.2)


def run_sort(bin_number):
    try:
        if bin_number:
            print(f"  [{bin_number}번 적재함] 공정 시작")
            sorter.sort(bin_number)
        else:
            print("  [반환] 공정 시작")
            sorter.send_to_return()
        print("  완료")
    except sorter.Stopped:
        conveyor.stop()
        servo.reset_all()
        print("  중단했습니다.")


print("모델 불러오는 중...")
detector = RecycleDetector("recycle.onnx")
print("준비 완료. 투입 대기 중... (종료: Ctrl+C)\n")

try:
    while True:
        # 1. 투입 감지
        if not item_inserted():
            time.sleep(0.1)
            continue
        print("투입 감지!")
        time.sleep(0.5)

        # 2. 촬영 + AI 판별
        frame = take_photo()
        result = detector.inspect(frame)
        decision = result["decision"]
        category = result["category"]
        icon = "🟢" if decision == "통과" else "🔴"
        print(f"  {icon} 판정: {decision} → {result['reason']}")

        # 3. 서버 전송
        send_result(result)

        # 4. 분류
        bin_number = BIN_MAP.get(category) if decision == "통과" else None
        run_sort(bin_number)

        wait_until_clear()
        print("\n투입 대기 중...")

except KeyboardInterrupt:
    print("\n종료")

finally:
    led.all_off()
    conveyor.stop()
    servo.reset_all()
    conveyor.shutdown()
    time.sleep(0.5)
    servo.cleanup()
    GPIO.cleanup()
    print("정리 완료")
