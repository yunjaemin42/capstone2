import io
import random
import numpy as np
import torch
from PIL import Image
from torch.utils.data import Dataset, DataLoader

from cache import build_class_cache, load_cache, load_config
from utils import letterbox, IMAGE_SIZE

TRAIN_RATIO = 0.7
VAL_RATIO = 0.1
NUM_WORKERS = 2

_SPLITS = None

def build_splits():
    global _SPLITS
    if _SPLITS is not None:
        return _SPLITS

    config = load_config()
    splits = {"train": [], "val": [], "test": []}

    for class_name in config["names"].values():
        try:
            cache_data = load_cache(class_name)
        except FileNotFoundError:
            build_class_cache(class_name)
            cache_data = load_cache(class_name)

        samples = list(cache_data["samples"])
        random.Random(config["seed"]).shuffle(samples)

        n_train = int(len(samples) * TRAIN_RATIO)
        n_val = int(len(samples) * VAL_RATIO)

        splits["train"] += samples[:n_train]
        splits["val"] += samples[n_train:n_train + n_val]
        splits["test"] += samples[n_train + n_val:]

    for extra_name in config.get("extra_caches", []):

        samples = list(load_cache(extra_name)["samples"])
        random.Random(config["seed"]).shuffle(samples)

        n_train = int(len(samples) * TRAIN_RATIO)
        n_val = int(len(samples) * VAL_RATIO)

        # 수거함 실제 환경 사진처럼 수가 적은 캐시는 train에서만 여러 번 반복 (val/test는 1번)
        repeat = config.get("repeat", {}).get(extra_name, 1)
        splits["train"] += samples[:n_train] * repeat
        splits["val"] += samples[n_train:n_train + n_val]
        splits["test"] += samples[n_train + n_val:]

    print(
        "데이터 분할:",
        {name: len(items) for name, items in splits.items()}
    )

    _SPLITS = splits
    return _SPLITS


class RecycleDataset(Dataset):

    def __init__(self, samples, train=False):
        self.samples = samples
        self.train = train

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, index):
        sample = self.samples[index]
        height = sample["height"]
        width = sample["width"]

        image = Image.open(io.BytesIO(sample["image_bytes"]))
        image.draft("RGB", (IMAGE_SIZE, IMAGE_SIZE))
        image = np.asarray(image.convert("RGB"))
        canvas, boxes, gain, pad = letterbox(
            image,
            sample["boxes"],
            width,
            height
        )

        if self.train:
            if random.random() < 0.5:
                canvas = canvas[:, ::-1]
                boxes[:, 0] = 1.0 - boxes[:, 0]

            alpha = random.uniform(0.7, 1.3)
            canvas = np.clip(canvas.astype(np.float32) * alpha, 0, 255).astype(np.uint8)

        canvas = np.ascontiguousarray(canvas)

        return {
            "img": torch.from_numpy(canvas).permute(2, 0, 1).contiguous(),
            "cls": torch.tensor(sample["class_ids"], dtype=torch.float32).view(-1, 1),
            "bboxes": torch.from_numpy(boxes),
            "ori_shape": (height, width),
            "ratio_pad": ((gain, gain), pad),
            "im_file": sample["image_name"]
        }

def collate_fn(batch):
    return {
        "img": torch.stack([item["img"] for item in batch]),
        "cls": torch.cat([item["cls"] for item in batch]),
        "bboxes": torch.cat([item["bboxes"] for item in batch]),
        "batch_idx": torch.cat(
            [
                torch.full((len(item["cls"]),), float(i))
                for i, item in enumerate(batch)
            ]
        ),
        "ori_shape": [item["ori_shape"] for item in batch],
        "ratio_pad": [item["ratio_pad"] for item in batch],
        "im_file": [item["im_file"] for item in batch]
    }

def get_split_loader(split, batch_size):
    samples = build_splits()[split]
    train = split == "train"
    return DataLoader(
        RecycleDataset(samples, train=train),
        batch_size=batch_size,
        shuffle=train,
        drop_last=train and len(samples) > batch_size,
        num_workers=NUM_WORKERS,
        collate_fn=collate_fn,
        pin_memory=torch.cuda.is_available()
    )

_TRAIN_EVAL = None
def get_train_eval_loader(batch_size):
    global _TRAIN_EVAL

    if _TRAIN_EVAL is None:
        config = load_config()
        splits = build_splits()
        n = min(len(splits["val"]), len(splits["train"]))
        _TRAIN_EVAL = random.Random(config["seed"]).sample(splits["train"], n)

    return DataLoader(
        RecycleDataset(_TRAIN_EVAL, train=False),
        batch_size=batch_size,
        shuffle=False,
        num_workers=NUM_WORKERS,
        collate_fn=collate_fn,
        pin_memory=torch.cuda.is_available()
    )
