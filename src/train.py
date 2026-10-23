import os
import sys
import yaml
import torch
from ultralytics import YOLO
from ultralytics.models.yolo.detect import DetectionTrainer
SRC_PATH = os.path.dirname(os.path.abspath(__file__))
if SRC_PATH not in sys.path:
    sys.path.append(SRC_PATH)
from utils import IMAGE_SIZE
from dataloader import get_split_loader, get_train_eval_loader
from confusion import RecycleConfusion

DOWNLOAD_DIR = "/tmp/ultralytics"
MODEL_NAME = "recycle.pt"

def get_model_path(config):
    return os.path.join(
        config["output_path"],
        "recycle_yolo",
        "weights",
        MODEL_NAME
    )

def load_config(config_path):
    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

class RecycleTrainer(DetectionTrainer):
    def get_dataloader(self, dataset_path, batch_size=16, rank=0, mode="train"):
        return get_split_loader("train" if mode == "train" else "val", batch_size)

    def get_dataset(self):
        config = load_config(self.args.data)
        names = {int(k): v for k, v in config["names"].items()}

        return {
            "train": "cache",      # 사용되지 않는 자리 표시 값
            "val": "cache",        # 실제 데이터는 get_dataloader가 공급
            "nc": len(names),
            "names": names,
            "channels": 3
        }

    def set_class_weights(self):
        return
    def _close_dataloader_mosaic(self):
        return
    def plot_training_labels(self):
        return
    def plot_training_samples(self, batch, ni):
        return
    def final_eval(self):
        return

    def train_map50(self):
        if not hasattr(self, "_train_eval_loader"):
            self._train_eval_loader = get_train_eval_loader(self.batch_size)

        val_loader = self.validator.dataloader
        self.validator.dataloader = self._train_eval_loader

        try:
            metrics = self.validator(trainer=self)
        finally:
            self.validator.dataloader = val_loader

        return float(metrics.get("metrics/mAP50(B)", 0))

    #   cls_loss: 품목 분류 오차 (수거함 판정에 가장 중요)
    #   mAP50   : 탐지 성능 (train: 학습 데이터 450장, val: 검증 데이터)
    #   mAP50-95: 박스 위치 정확도 (참고용)
    def save_metrics(self, metrics):
        csv_path = self.save_dir / "results.csv"

        if self.epoch == 0 or not csv_path.exists():
            csv_path.write_text(
                "epoch,train_cls_loss,val_cls_loss,train_mAP50,val_mAP50,val_mAP50-95\n"
            )

        row = [
            str(self.epoch + 1),
            f"{float(metrics.get('train/cls_loss', 0)):.4f}",
            f"{float(metrics.get('val/cls_loss', 0)):.4f}",
            f"{self.train_map50():.4f}",
            f"{float(metrics.get('metrics/mAP50(B)', 0)):.4f}",
            f"{float(metrics.get('metrics/mAP50-95(B)', 0)):.4f}",
        ]

        with open(csv_path, "a") as f:
            f.write(",".join(row) + "\n")

def train_model(config, config_path):
    output_path = config["output_path"]
    os.makedirs(output_path, exist_ok=True)

    os.makedirs(DOWNLOAD_DIR, exist_ok=True)

    if torch.cuda.is_available():
        device = 0
        print("GPU 사용:", torch.cuda.get_device_name(0))
    else:
        device = "cpu"
        print("GPU를 사용할 수 없어 CPU로 학습합니다.")

    original_cwd = os.getcwd()
    os.chdir(DOWNLOAD_DIR)

    try:
        model = YOLO("yolo11n.pt")

        results = model.train(
            data=config_path,
            trainer=RecycleTrainer,
            epochs=config["epochs"],
            batch=config["batch_size"],
            lr0=config["learning_rate"],
            patience=config["patience"],
            seed=config["seed"],
            imgsz=IMAGE_SIZE,
            device=device,
            project=output_path,
            name="recycle_yolo",
            exist_ok=True,
            optimizer="AdamW",
            mosaic=0.0,
            mixup=0.0,
            copy_paste=0.0,
            close_mosaic=0,
            plots=False
        )
    finally:
        os.chdir(original_cwd)

    save_final_model(config)

    return results

def save_final_model(config):
    weights_dir = os.path.dirname(get_model_path(config))
    best_path = os.path.join(weights_dir, "best.pt")
    last_path = os.path.join(weights_dir, "last.pt")
    model_path = get_model_path(config)

    if not os.path.exists(best_path):
        print("⚠️ best.pt가 없어 recycle.pt를 만들지 못했습니다.")
        return

    os.replace(best_path, model_path)

    if os.path.exists(last_path):
        os.remove(last_path)

    print("✅ 최종 모델 저장:", model_path)

    args_path = os.path.join(os.path.dirname(weights_dir), "args.yaml")
    if os.path.exists(args_path):
        os.remove(args_path)

# results.csv로 학습 곡선 그래프 생성 (Loss / 성능)
def plot_results(config):
    import pandas as pd
    import matplotlib.pyplot as plt

    run_dir = os.path.join(config["output_path"], "recycle_yolo")
    csv_path = os.path.join(run_dir, "results.csv")

    if not os.path.exists(csv_path):
        print("⚠️ results.csv가 없어 그래프를 만들지 못했습니다.")
        return

    df = pd.read_csv(csv_path)

    epoch = df["epoch"]

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4.5))

    # 왼쪽: 분류 손실 (줄어들수록 품목을 잘 구분함, Validation이 다시 오르면 과적합)
    ax1.plot(epoch, df["train_cls_loss"], label="Train")
    ax1.plot(epoch, df["val_cls_loss"], label="Validation")
    ax1.set_title("Classification Loss")
    ax1.set_xlabel("Epoch")
    ax1.set_ylabel("Loss")
    ax1.legend()

    # 오른쪽: mAP50 (탐지 성능)
    ax2.plot(epoch, df["train_mAP50"], label="Train")
    ax2.plot(epoch, df["val_mAP50"], label="Validation")
    ax2.set_title("mAP50")
    ax2.set_xlabel("Epoch")
    ax2.set_ylabel("mAP50")
    ax2.legend(loc="lower right")

    best = df["val_mAP50"].idxmax()
    ax2.scatter(epoch[best], df["val_mAP50"][best], color="red", zorder=5)
    ax2.annotate(f"best val {df['val_mAP50'][best]:.3f} (epoch {int(epoch[best])})",
                 (epoch[best], df["val_mAP50"][best]),
                 textcoords="offset points", xytext=(-140, -25))

    plt.tight_layout()

    save_path = os.path.join(run_dir, "results.png")
    plt.savefig(save_path, dpi=200, bbox_inches="tight")
    plt.show()

    print("✅ 학습 곡선 저장:", save_path)


# Confusion Matrix 생성
def run_confusion(config):
    model_path = get_model_path(config)

    device = 0 if torch.cuda.is_available() else "cpu"
    test_loader = get_split_loader("test", config["batch_size"])

    return RecycleConfusion(
        YOLO(model_path),
        config,
        device=device
    ).run_analysis(test_loader)


def run_process(config_path):
    print("=" * 60)
    print("재활용품 YOLO 학습 시작")
    print("=" * 60)

    config = load_config(config_path)
    print("클래스:", config["names"])
    print("Epoch:", config["epochs"])
    print("Batch Size:", config["batch_size"])
    print("Learning Rate:", config["learning_rate"])
    print("Patience:", config["patience"])
    print("Output:", config["output_path"])

    results = train_model(config, config_path)

    print("=" * 60)
    print("학습 완료")
    print("모델 위치:", get_model_path(config))
    print("=" * 60)

    plot_results(config)
    run_confusion(config)

    return results
