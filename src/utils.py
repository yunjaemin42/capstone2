import json
import cv2
import numpy as np

IMAGE_SIZE = 640
PAD_VALUE = 114

def load_json(json_path):
    with open(
        json_path,
        "r",
        encoding="utf-8"
    ) as f:
        return json.load(f)

#폴리곤 -> 바운딩 박스
def annotation_to_bbox(annotation):
    points = annotation.get("POINTS", [])

    if not points:
        return None

    shape = str(annotation.get("SHAPE_TYPE", "")).upper()

    # BOX: [[x, y, w, h]]
    if shape == "BOX":
        x, y, w, h = map(float, points[0])
        return [x, y, x + w, y + h]
    # POLYGON 등
    return polygon_to_bbox(points)

def polygon_to_bbox(points):
    if not points:
        return None

    xs = [float(point[0]) for point in points]
    ys = [float(point[1]) for point in points]

    return [
        min(xs),
        min(ys),
        max(xs),
        max(ys)
    ]


# 이미지 밖으로 살짝 나간 박스를 잘라냄
def clip_bbox(
    bbox,
    image_width,
    image_height,
    min_size=2
):

    if bbox is None:
        return None

    x_min, y_min, x_max, y_max = bbox

    x_min = max(0.0, x_min)
    y_min = max(0.0, y_min)
    x_max = min(float(image_width), x_max)
    y_max = min(float(image_height), y_max)

    if x_max - x_min < min_size: return None
    if y_max - y_min < min_size: return None
    return [x_min, y_min, x_max, y_max]

def normalize_bbox(
    bbox,
    image_width,
    image_height
):

    x_min, y_min, x_max, y_max = bbox
    x_center = ((x_min + x_max) / 2) / image_width
    y_center = ((y_min + y_max) / 2) / image_height
    width = (x_max - x_min) / image_width
    height = (y_max - y_min) / image_height

    return [ x_center, y_center, width, height]


# 비율 유지 + 회색 패딩
def letterbox(
    image,
    boxes,
    width,
    height,
    image_size=IMAGE_SIZE,
    pad_value=PAD_VALUE
):

    gain = min(
        image_size / height,
        image_size / width
    )

    new_w = int(round(width * gain))
    new_h = int(round(height * gain))

    image = cv2.resize(
        image,
        (new_w, new_h),
        interpolation=cv2.INTER_LINEAR
    )

    pad_left = (image_size - new_w) // 2
    pad_top = (image_size - new_h) // 2

    canvas = np.full(
        (image_size, image_size, 3),
        pad_value,
        dtype=np.uint8
    )

    canvas[
        pad_top:pad_top + new_h,
        pad_left:pad_left + new_w
    ] = image

    boxes = np.array(
        boxes,
        dtype=np.float32
    ).reshape(-1, 4)

    boxes[:, 0] = (boxes[:, 0] * new_w + pad_left) / image_size
    boxes[:, 1] = (boxes[:, 1] * new_h + pad_top) / image_size
    boxes[:, 2] = boxes[:, 2] * new_w / image_size
    boxes[:, 3] = boxes[:, 3] * new_h / image_size

    return canvas, boxes, gain, (pad_left, pad_top)
