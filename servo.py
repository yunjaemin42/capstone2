from adafruit_servokit import ServoKit
import time

CHANNELS = [0, 4, 8, 12]   # 적재함 1~4번 서보가 꽂힌 PCA9685 채널
ANGLE_REST = 180           # 대기 각도
ANGLE_READY = 115          # 밀어내기 전 준비 위치
ANGLE_MID = 150            # 여기까지는 천천히, 이후 빠르게

STEP = 2                   # 한 번에 움직이는 각도
DELAY_READY = 0.02         # 115도로 나갈 때
DELAY_SLOW = 0.03          # 115 → 160 (부드럽게 접근)
DELAY_FAST = 0.02          # 160 → 180 (턱 넘기기)

kit = ServoKit(channels=16)
_current = {}

for ch in CHANNELS:
    kit.servo[ch].set_pulse_width_range(500, 2500)
    kit.servo[ch].angle = ANGLE_REST
    _current[ch] = ANGLE_REST
    time.sleep(0.5)


def _move(ch, target, delay):
    """목표 각도까지 STEP씩 나눠서 이동"""
    angle = _current.get(ch, ANGLE_REST)
    if target == angle:
        return
    direction = 1 if target > angle else -1
    while angle != target:
        angle += direction * STEP
        if (direction == 1 and angle > target) or (direction == -1 and angle < target):
            angle = target
        kit.servo[ch].angle = angle
        time.sleep(delay)
    _current[ch] = target

def ready(bin_number):
    """115도로 나가서 대기"""
    _move(CHANNELS[bin_number - 1], ANGLE_READY, DELAY_READY)


def sweep(bin_number):
    """천천히 접근했다가 마지막에 빠르게 밀어낸다"""
    ch = CHANNELS[bin_number - 1]
    _move(ch, ANGLE_MID, DELAY_SLOW)
    _move(ch, ANGLE_REST, DELAY_FAST)


def reset_all():
    """전부 대기 각도로 곧장 복귀"""
    for ch in CHANNELS:
        _move(ch, ANGLE_REST, DELAY_READY)


def cleanup():
    """서보 힘 빼기"""
    for ch in CHANNELS:
        kit.servo[ch].angle = None


if __name__ == "__main__":
    try:
        for i in range(1, 5):
            print(f"{i}번 준비 위치(115도)")
            ready(i)
            time.sleep(1)
            print(f"{i}번 밀어내기")
            sweep(i)
            time.sleep(1)
        print("테스트 완료")
    finally:
        cleanup()
