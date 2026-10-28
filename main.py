import time
import RPi.GPIO as GPIO

from recycle import RecycleDetector, capture, send_result
import ultrasonic
import conveyor
import servo
import led

BIN_MAP = {"pet": 1, "plastic": 2, "glass": 3, "can": 4}
WARMUP = 1        # 조명 안정화 대기(초)? 이것도 먼지 모르겟음 ㅠㅡㅠ

print("모델 불러오는 중...")
detector = RecycleDetector("recycle.onnx")
print("준비 완료. 투입 대기 중...")

try:
    while True:
        # 1. 투입 감지
        if not ultrasonic.detect_item():
            time.sleep(0.1)
            continue

        print("투입 감지!")
        # 2. 촬영
        led.led_on()
        try:
            time.sleep(WARMUP)      # 조명 안정화
            frame = capture()
        finally:
            led.led_off()

        # 3. AI 판별
        result = detector.inspect(frame)
        decision = result["decision"]
        category = result["category"]
        reason = result["reason"]
        print(f"판정: {decision} → {reason}")

        # 4. 이송 + 분기
        if decision == "통과":
            bin_number = BIN_MAP[category]
            conveyor.move_to_bin(bin_number)
            servo.sort_to(bin_number)
        else:
            conveyor.move_to_return()

        # 5. 결과 전송
        send_result(result)

        print("대기 중...\n")
        time.sleep(2) #재감지 방지라는디.. 뭔지 이해 잘 안 가요

except KeyboardInterrupt:
    print("\n종료")
finally:
    led.all_off()
    servo.cleanup()
    GPIO.cleanup()