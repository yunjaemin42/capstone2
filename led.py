import RPi.GPIO as GPIO

LED_PIN = 17      # 릴레이 1 - 일반 조명

ON = 1            # 릴레이가 반대로 동작하면 0으로
OFF = 1 - ON

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED_PIN, GPIO.OUT)
GPIO.output(LED_PIN, OFF)


def led_on():
    GPIO.output(LED_PIN, ON)


def led_off():
    GPIO.output(LED_PIN, OFF)


def all_off():
    GPIO.output(LED_PIN, OFF)
