import sys
import time
from select import select

import conveyor
import servo
import actuator

BIN_TRAVEL = {1: 1, 2: 5, 3: 10, 4: 15}
RETURN_TRAVEL = 20
READY_SETTLE = 0.3
AFTER_PUSH = 6


class Stopped(Exception):
    pass


def wait(seconds):
    """seconds 동안 대기. 그 사이 엔터를 누르면 Stopped (비상 정지)"""
    if not sys.stdin.isatty():
        # 터미널 없이 실행(백그라운드·자동 실행)하면 stdin 이 항상 '읽을 수 있음'으로 떠서
        # 매번 정지돼 버림 → 이때는 그냥 기다리기만 한다
        time.sleep(seconds)
        return
    if select([sys.stdin], [], [], seconds)[0]:
        sys.stdin.readline()
        raise Stopped


def feed():
    """액추에이터로 투입구 쓰레기를 벨트에 올림 (모든 경우 공통)"""
    print("  액추에이터로 벨트에 올리기")
    actuator.push_and_pull()


def sort(bin_number):
    # 1번은 서보가 가까워서, 액추에이터로 밀기 전에 서보 먼저 열어둠
    if bin_number == 1:
        print(f"  {bin_number}번 서보 미리 준비 위치로")
        servo.ready(bin_number)
        wait(READY_SETTLE)
        feed()
    else:
        # 2·3·4는 거리가 멀어서 액추에이터로 먼저 올리고, 벨트 가는 동안 서보 준비
        feed()
        print(f"  {bin_number}번 서보 준비 위치로")
        servo.ready(bin_number)
        wait(READY_SETTLE)

    print("  벨트 가동")
    conveyor.start()
    wait(BIN_TRAVEL[bin_number])     # 쓰레기가 서보 앞까지 이동

    print("  밀어내기")
    servo.sweep(bin_number)
    wait(AFTER_PUSH)
    conveyor.stop()


def send_to_return():
    feed()                          # 반환도 액추에이터로 올림
    print("  반환구로 이송")
    servo.reset_all()
    conveyor.start()
    wait(RETURN_TRAVEL)
    conveyor.stop()


if __name__ == "__main__":
    print("적재함 번호를 입력하세요.")
    print("  1~4 : 해당 적재함으로 분류")
    print("  r   : 반환구로 이송")
    print("  q   : 종료")
    print("동작 중에 엔터를 누르면 즉시 정지합니다.\n")

    try:
        while True:
            try:
                cmd = input("번호> ").strip().lower()
            except EOFError:
                break
            if cmd == "":
                continue
            if cmd in ("q", "quit", "exit"):
                break
            try:
                if cmd == "r":
                    print("[반환]")
                    send_to_return()
                elif cmd in ("1", "2", "3", "4"):
                    b = int(cmd)
                    print(f"[{b}번 적재함]")
                    sort(b)
                else:
                    print("1~4, r, q 중에서 입력하세요.\n")
                    continue
                print("완료\n")
            except Stopped:
                conveyor.stop()
                servo.reset_all()
                print("중단했습니다.\n")

    except KeyboardInterrupt:
        print("\n중단합니다.")
    finally:
        conveyor.stop()
        servo.reset_all()
        conveyor.shutdown()
        time.sleep(0.5)
        servo.cleanup()
        print("정리 완료")
