"""
AI 판별 결과를 백엔드 서버로 전송하는 모듈

사용법 (라즈베리파이):
    from send_result import send_result
    send_result(result, frame)

    result: RecycleDetector.inspect() 반환값
    frame:  촬영 원본 이미지 (OpenCV BGR)
"""

import cv2
import requests

# EC2 배포 전: 로컬 PC IP  /  배포 후: Elastic IP 로 교체
BACKEND_URL = "http://32.236.105.231:3000/api/inspection-result"
TIMEOUT = 10  # 초


def send_result(result: dict, frame=None) -> dict:
    """
    AI 판별 결과를 백엔드로 전송한다.

    반환 예시 (서버 응답):
        {"success": true, "record": {"id": "...", "date": "...", ...}}
    """
    decision    = result["decision"]          # "통과" | "반환"
    reason      = result["reason"]            # 안내 문구
    category    = result.get("category")      # 통과 시 분류 칸 (pet/plastic/glass/can)
    is_rejected = (decision == "반환")

    # itemType: 통과이면 AI가 분류한 칸, 반환이면 박스에서 읽거나 "unknown"
    if category:
        item_type = category
    elif result.get("boxes"):
        item_type = result["boxes"][0]["name"]
    else:
        item_type = "unknown"

    data = {
        "itemType":     item_type,
        "contaminated": "true" if is_rejected else "false",
        "reason":       reason if is_rejected else "",
    }

    # 반환 판정이면 박스 그린 이미지도 첨부
    files = None
    if is_rejected:
        image = result.get("plot") if result.get("plot") is not None else frame
        if image is not None:
            ok, buf = cv2.imencode(".jpg", image, [cv2.IMWRITE_JPEG_QUALITY, 85])
            if ok:
                files = {"image": ("capture.jpg", buf.tobytes(), "image/jpeg")}

    try:
        resp = requests.post(BACKEND_URL, data=data, files=files, timeout=TIMEOUT)
        resp.raise_for_status()
        return resp.json()
    except requests.exceptions.ConnectionError:
        print(f"[send_result] 서버에 연결할 수 없습니다: {BACKEND_URL}")
        return {"success": False, "error": "connection_error"}
    except requests.exceptions.Timeout:
        print("[send_result] 서버 응답 시간 초과")
        return {"success": False, "error": "timeout"}
    except Exception as e:
        print(f"[send_result] 전송 실패: {e}")
        return {"success": False, "error": str(e)}
