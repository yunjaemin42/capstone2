from gpiozero import PWMOutputDevice, OutputDevice
import time

PUL_PIN = 20      # PUL+ (물리 38번)
DIR_PIN = 21      # DIR+ (물리 40번)
ENA_PIN = 13      # ENA+ (물리 33번)

FREQ = 650        # 속도(초당 펄스 수). 올리면 빨라짐
DIRECTION = 1     # 1 = 정방향, 0 = 역방향

pul = PWMOutputDevice(PUL_PIN, frequency=FREQ, initial_value=0)
dir_pin = OutputDevice(DIR_PIN)
ena = OutputDevice(ENA_PIN)


def start(direction=DIRECTION):
    """벨트 가동"""
    ena.off()                  # 드라이버 활성화 (active low)
    dir_pin.value = direction
    pul.value = 0.5


def stop():
    """벨트 정지 (드라이버는 켜둬서 위치 유지)"""
    pul.value = 0


def run_for(seconds, direction=DIRECTION):
    """지정 시간만큼 돌리고 멈춤"""
    start(direction)
    time.sleep(seconds)
    stop()


def set_speed(freq):
    """속도 변경"""
    pul.frequency = freq


def shutdown():
    """완전 종료 (모터 힘 빼기)"""
    pul.value = 0
    ena.on()


if __name__ == "__main__":
    try:
        print("5초간 정방향 가동")
        run_for(5)
        print("완료 - 벨트가 움직인 거리를 재서 BIN_TRAVEL 값을 계산하세요")
    finally:
        shutdown()
