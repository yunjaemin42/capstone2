from gpiozero import PWMOutputDevice, OutputDevice
import time

IN1 = 16      # 방향 1 (물리 36)
IN2 = 19      # 방향 2 (물리 35)
ENA = 26      # 속도 PWM (물리 37)

SPEED = 0.8       # 미는 속도 0.0~1.0 (튕기면 낮추기)
PUSH_TIME = 1.5   # 미는 시간(초) - 실측해서 조정
PULL_TIME = 1.5   # 복귀 시간(초)

in1 = OutputDevice(IN1)
in2 = OutputDevice(IN2)
ena = PWMOutputDevice(ENA, initial_value=0)


def push(speed=SPEED, t=PUSH_TIME):
    """막대 전진 (쓰레기 밀기)"""
    in1.on()
    in2.off()
    ena.value = speed
    time.sleep(t)
    _stop()


def pull(speed=SPEED, t=PULL_TIME):
    """막대 복귀"""
    in1.off()
    in2.on()
    ena.value = speed
    time.sleep(t)
    _stop()


def _stop():
    """정지 (막대는 그 자리에 잠김)"""
    ena.value = 0
    in1.off()
    in2.off()


def push_and_pull(hold=0.5):
    """밀고 → 잠깐 유지 → 복귀 (한 사이클)"""
    push()
    time.sleep(hold)
    pull()


if __name__ == "__main__":
    try:
        print("전진 (밀기)")
        push()
        time.sleep(1)
        print("복귀")
        pull()
        print("완료")
    finally:
        _stop()
