import time
import RPi.GPIO as GPIO

from recycle import RecycleDetector, capture, LED_WARMUP
from send_result import send_result
from second_check import SecondCheck, SIZE_NAME
import ultrasonic
import led
import sort_test2 as sorter
import conveyor
import servo

BIN_MAP = {"pet": 1, "plastic": 2, "glass": 3, "can": 4}


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
detector = RecycleDetector()
checker = SecondCheck()
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
        icon = "🟢" if result["decision"] == "통과" else "🔴"
        print(f"  {icon} AI 판정: {result['decision']} → {result['reason']}")

        # 3. 무게 측정 (AI 통과 품목만, 액추에이터로 밀기 전에)
        if result["decision"] == "통과":
            result.update(checker.check(result))
            if "weight_g" in result:
                size = SIZE_NAME.get(result.get("size"), "-")
                limit = result.get("weight_limit_g", "-")
                icon = "🟢" if result["decision"] == "통과" else "🔴"
                print(f"  {icon} 무게: {result['weight_g']}g ({size}, 기준 {limit}g) → {result['decision']}")

        decision = result["decision"]
        print(f"  ▶ 최종: {decision} → {result['reason']}")

        # 4. 서버 전송
        response = send_result(result, frame)
        if response.get("success") is False:
            print("  📡 전송 실패 (분류는 계속 진행)")
        else:
            print("  📡 전송 완료")

        # 5. 분류
        bin_number = BIN_MAP.get(result["category"]) if decision == "통과" else None
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