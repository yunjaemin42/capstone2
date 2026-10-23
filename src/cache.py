import os
import io
import yaml
import torch
from collections import Counter
from PIL import Image, ImageOps
from tqdm.auto import tqdm

CACHE_VERSION = 3

EXPECTED_CLASS = {
    "plastic": {"플라스틱", "페트병"},
    "pet": {"페트병"},
    "glass": {"유리병"},
    "can": {"금속캔"},
    "paper": {"종이"},
    "vinyl": {"비닐"},
}


from utils import (
    IMAGE_SIZE,
    load_json,
    annotation_to_bbox,
    clip_bbox,
    normalize_bbox
)

SRC_PATH = os.path.dirname(
    os.path.abspath(__file__)
)

PROJECT_PATH = os.path.dirname(
    SRC_PATH
)

CONFIG_PATH = os.path.join(
    PROJECT_PATH,
    "config",
    "config_recycle.yaml"
)


def load_config():

    with open(
        CONFIG_PATH,
        "r",
        encoding="utf-8"
    ) as f:

        return yaml.safe_load(f)

# 클래스별 Cache 생성
# 원본 사진(4000~5600px, 장당 약 4MB)을 그대로 캐시에 넣으면
# 6클래스 x 500장 = 약 12GB → Colab RAM 초과로 런타임이 죽는다.
# 학습은 어차피 640px로 줄여서 하므로, 캐시에는 줄인 JPEG만 저장한다.
# (박스는 0~1 정규화 좌표라 이미지 크기를 줄여도 그대로 맞는다)
def shrink_image(image_bytes, max_size=IMAGE_SIZE, quality=90, exif=False):

    image = Image.open(io.BytesIO(image_bytes))

    # Roboflow(Auto-Orient)로 라벨링한 휴대폰 사진은 회전 정보를 적용한 기준으로
    # 박스가 그려져 있으므로, 같은 기준으로 맞춘다
    if exif:
        image = ImageOps.exif_transpose(image)

    original_size = image.size              # 박스 정규화용 원본 크기

    image.draft("RGB", (max_size, max_size))  # JPEG 축소 디코딩 (빠름)
    image = image.convert("RGB")
    image.thumbnail((max_size, max_size))   # 긴 변을 max_size로 (비율 유지)

    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=quality)

    return buffer.getvalue(), original_size, image.size


def build_class_cache(class_name):

    config = load_config()

    data_root = config["data_root"]
    cache_path = config["cache_path"]
    target_count = config["target_count"]

    # YAML에서 클래스 ID 가져오기
    class_id = None

    for key, value in config["names"].items():

        if value == class_name:

            class_id = int(key)
            break

    if class_id is None:

        raise ValueError(
            f"YAML에 없는 클래스입니다: {class_name}"
        )

    image_dir = os.path.join(
        data_root,
        f"s_{class_name}"
    )

    label_dir = os.path.join(
        data_root,
        f"l_{class_name}"
    )

    os.makedirs(
        cache_path,
        exist_ok=True
    )

    # 여기서 자르지 않는다 → 유효한 샘플이 target_count개 모일 때까지 읽음
    image_files = sorted(
        [
            file_name
            for file_name in os.listdir(image_dir)
            if file_name.lower().endswith((".jpg", ".jpeg", ".png"))
        ]
    )

    samples = []
    drop = Counter()          # 버린 이유 집계
    clipped = 0               # 경계를 넘어 잘라낸 박스 수
    json_classes = Counter()  # JSON에 적힌 CLASS 값 분포 (폴더 클래스와 다른 게 섞였는지 확인용)

    progress = tqdm(total=target_count, desc=f"{class_name} 캐싱", unit="장")

    for image_name in image_files:

        if len(samples) >= target_count:
            break

        progress.n = len(samples)
        progress.refresh()

        image_path = os.path.join(
            image_dir,
            image_name
        )

        json_name = (
            os.path.splitext(image_name)[0]
            + ".json"
        )

        json_path = os.path.join(
            label_dir,
            json_name
        )

        if not os.path.exists(json_path):
            drop["json 없음"] += 1
            continue

        try:

            # 이미지 읽기 → 640px로 줄인 JPEG bytes
            with open(
                image_path,
                "rb"
            ) as f:

                raw_bytes = f.read()

            image_bytes, (image_width, image_height), (small_width, small_height) = shrink_image(
                raw_bytes
            )

            # JSON
            annotation_data = load_json(
                json_path
            )

            annotations = annotation_data.get(
                "ANNOTATION_INFO",
                []
            )

            if not annotations:
                drop["ANNOTATION_INFO 비어있음"] += 1
                continue

            boxes = []
            class_ids = []

            for annotation in annotations:

                json_class = str(annotation.get("CLASS"))
                json_classes[json_class] += 1

                expected = EXPECTED_CLASS.get(class_name)

                if expected and json_class not in expected:
                    drop[f"(박스) CLASS 불일치: {json_class}"] += 1
                    continue

                bbox = annotation_to_bbox(
                    annotation
                )

                if bbox is None:
                    drop["(박스) POINTS 없음"] += 1
                    continue

                clipped_bbox = clip_bbox(
                    bbox,
                    image_width,
                    image_height
                )

                if clipped_bbox is None:
                    drop["(박스) 범위 밖 / 너무 작음"] += 1
                    continue

                if clipped_bbox != bbox:
                    clipped += 1

                normalized_bbox = normalize_bbox(
                    clipped_bbox,
                    image_width,
                    image_height
                )

                boxes.append(
                    normalized_bbox
                )

                class_ids.append(
                    class_id
                )

            if len(boxes) == 0:
                drop["유효 박스 0개"] += 1
                continue

            samples.append(
                {
                    "image_name": image_name,
                    "image_bytes": image_bytes,
                    "width": small_width,
                    "height": small_height,
                    "boxes": boxes,
                    "class_ids": class_ids
                }
            )

        except Exception as e:

            drop[f"예외 {type(e).__name__}"] += 1

            print(
                f"처리 실패: {image_name}"
            )

            print(e)

    progress.n = len(samples)
    progress.close()

    cache_data = {

        "version": CACHE_VERSION,

        "class_id": class_id,

        "class_name": class_name,

        "image_count": len(samples),

        "samples": samples
    }

    cache_file = os.path.join(
        cache_path,
        f"{class_name}.pt"
    )
    temp_file = cache_file + ".tmp"

    torch.save(
        cache_data,
        temp_file
    )

    os.replace(
        temp_file,
        cache_file
    )

    print(
        f"✅ {class_name}.pt 저장 완료"
    )

    size_mb = sum(len(sample["image_bytes"]) for sample in samples) / 1024 / 1024

    print(
        f"   데이터 수: {len(samples)} / 목표 {target_count}  (용량 {size_mb:.1f}MB)"
    )

    if clipped:
        print(
            f"   경계 밖이라 잘라낸 박스: {clipped}"
        )

    for reason, count in drop.most_common():
        print(
            f"   - 버림({reason}): {count}"
        )

    print(
        f"   JSON CLASS 분포: {dict(json_classes.most_common())}"
    )

    if len(json_classes) > 1:
        print(
            f"   ℹ️ 여러 CLASS가 섞여 있음 (허용 목록 밖의 CLASS는 제외됨)"
        )

    if len(samples) < target_count:
        print(
            f"   ⚠️ 폴더 전체를 읽었지만 목표 수에 못 미침"
        )

    print(
        f"   위치: {cache_file}"
    )

    return cache_file


# Roboflow COCO JSON → Cache (원본 사진은 드라이브 폴더에서 읽음)
#   name      : 캐시 이름 (예: "vinyl_label" → vinyl_label.pt)
#   image_dir : 원본 사진 폴더 (예: datasets/s_vinyl_label)
#   coco_path : Roboflow에서 받은 _annotations.coco.json

# Roboflow 클래스 이름이 우리 이름과 다를 때 맞춰 주는 표
CLASS_ALIAS = {
    "cap": "can",          # 유리병 철뚜껑은 can으로 학습
}


def build_coco_cache(name, image_dir, coco_path):

    config = load_config()

    # 우리 클래스 이름 → 번호
    our_ids = {
        value: int(key)
        for key, value in config["names"].items()
    }

    for alias, target in CLASS_ALIAS.items():
        if target in our_ids:
            our_ids[alias] = our_ids[target]

    coco = load_json(coco_path)

    # Roboflow 카테고리 번호 → 우리 번호 (이름으로 매칭)
    cat_map = {
        cat["id"]: our_ids[cat["name"]]
        for cat in coco["categories"]
        if cat["name"] in our_ids
    }

    print(f"카테고리 매칭: { {c['name']: cat_map.get(c['id']) for c in coco['categories']} }")
    boxes_by_image = {}
    for ann in coco["annotations"]:
        boxes_by_image.setdefault(ann["image_id"], []).append(ann)
    samples = []
    drop = Counter()
    clipped = 0

    # Roboflow가 파일 이름의 특수문자를 바꿔서 내보내는 경우가 있다
    # (예: 535316@1_...jpg → 535316-1_...jpg). 비교용 이름으로 원본을 찾는다
    def name_key(file_name):
        return file_name.replace("@", "-").lower()

    local_files = {
        name_key(f): f
        for f in os.listdir(image_dir)
    }

    for img in tqdm(coco["images"], desc=f"{name} 캐싱", unit="장"):

        coco_name = img.get("extra", {}).get("name", img["file_name"])
        file_name = (local_files.get(name_key(coco_name))              # 원본 사진 이름 (라즈베리파이에서 찍은 그대로)
                     or local_files.get(name_key(img["file_name"])))   # Roboflow에서 내보낸 사진 이름 (.rf. 붙은 것)

        if file_name is None:
            drop["원본 사진 없음"] += 1
            continue

        image_path = os.path.join(image_dir, file_name)

        try:
            with open(image_path, "rb") as f:
                raw_bytes = f.read()

            image_bytes, (image_width, image_height), (small_width, small_height) = shrink_image(
                raw_bytes,
                exif=True
            )
            if (image_width, image_height) != (img["width"], img["height"]):
                drop["사진 크기 불일치"] += 1
                continue

            boxes = []
            class_ids = []

            for ann in boxes_by_image.get(img["id"], []):

                cls = cat_map.get(ann["category_id"])

                if cls is None:
                    drop["(박스) 알 수 없는 클래스"] += 1
                    continue

                x, y, w, h = map(float, ann["bbox"])
                bbox = [x, y, x + w, y + h]

                clipped_bbox = clip_bbox(bbox, image_width, image_height)

                if clipped_bbox is None:
                    drop["(박스) 범위 밖 / 너무 작음"] += 1
                    continue

                if clipped_bbox != bbox:
                    clipped += 1

                boxes.append(
                    normalize_bbox(clipped_bbox, image_width, image_height)
                )
                class_ids.append(cls)

            if not boxes:
                drop["유효 박스 0개"] += 1
                continue

            samples.append(
                {
                    "image_name": file_name,
                    "image_bytes": image_bytes,
                    "width": small_width,
                    "height": small_height,
                    "boxes": boxes,
                    "class_ids": class_ids
                }
            )

        except Exception as e:

            drop[f"예외 {type(e).__name__}"] += 1
            print(f"처리 실패: {file_name}")
            print(e)

    cache_data = {
        "version": CACHE_VERSION,
        "class_id": None,
        "class_name": name,
        "image_count": len(samples),
        "samples": samples
    }

    os.makedirs(config["cache_path"], exist_ok=True)

    cache_file = os.path.join(config["cache_path"], f"{name}.pt")
    temp_file = cache_file + ".tmp"

    torch.save(cache_data, temp_file)
    os.replace(temp_file, cache_file)

    box_count = Counter(config["names"][c] for s in samples for c in s["class_ids"])
    size_mb = sum(len(s["image_bytes"]) for s in samples) / 1024 / 1024

    print(f"✅ {name}.pt 저장 완료")
    print(f"   데이터 수: {len(samples)} / {len(coco['images'])}  (용량 {size_mb:.1f}MB)")
    print(f"   박스 분포: {dict(box_count)}")

    if clipped: print(f"   경계 밖이라 잘라낸 박스: {clipped}")
    for reason, count in drop.most_common():
        print(f"   - 버림({reason}): {count}")
    print(f"   위치: {cache_file}")
    return cache_file

# Cache 불러오기
def load_cache(class_name):

    config = load_config()

    cache_file = os.path.join(
        config["cache_path"],
        f"{class_name}.pt"
    )

    if not os.path.exists(cache_file):
        raise FileNotFoundError(f"Cache 파일이 없습니다: {cache_file}")
    try:
        cache_data = torch.load(
            cache_file,
            weights_only=False
        )

    except Exception as e:
        print(f"⚠️ {class_name}.pt 파일이 손상되어 삭제 후 다시 만듭니다 ({type(e).__name__})")
        os.remove(cache_file)
        raise FileNotFoundError(cache_file)
    if cache_data.get("version") != CACHE_VERSION:
        print(f"⚠️ {class_name}.pt가 예전 형식이라 삭제 후 다시 만듭니다")
        os.remove(cache_file)
        raise FileNotFoundError(cache_file)

    return cache_data
