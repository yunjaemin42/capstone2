import RPi.GPIO as GPIO

LED_PIN = 17      # 릴레이 1 - 일반 조명
UV_PIN = 27       # 릴레이 2 - UV (최종 발표 때 사용)

ON = 1            # 릴레이가 반대로 동작하면 0으로
OFF = 1 - ON

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED_PIN, GPIO.OUT)
GPIO.setup(UV_PIN, GPIO.OUT)
GPIO.output(LED_PIN, OFF)
GPIO.output(UV_PIN, OFF)


def led_on():
    GPIO.output(LED_PIN, ON)


def led_off():
    GPIO.output(LED_PIN, OFF)


def uv_on():
    GPIO.output(UV_PIN, ON)


def uv_off():
    GPIO.output(UV_PIN, OFF)


def all_off():
    GPIO.output(LED_PIN, OFF)
    GPIO.output(UV_PIN, OFF)
