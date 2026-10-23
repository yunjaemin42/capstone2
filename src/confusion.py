import os
import numpy as np
import torch
import seaborn as sns
import matplotlib.pyplot as plt
from tqdm.auto import tqdm
from sklearn.metrics import (
    confusion_matrix,
    classification_report
)


def setup_font():
    import matplotlib.font_manager as fm

    font_path = "/usr/share/fonts/truetype/nanum/NanumGothic.ttf"

    if os.path.exists(font_path):
        fm.fontManager.addfont(font_path)
        plt.rc("font", family="NanumGothic")
        plt.rcParams["axes.unicode_minus"] = False


class RecycleConfusion:

    def __init__(
        self,
        model,
        config,
        device="cpu",
        iou_threshold=0.5,
        conf_threshold=0.25
    ):
        self.model = model
        self.config = config
        self.device = device
        self.iou_threshold = iou_threshold
        self.conf_threshold = conf_threshold

        # YAML names 사용 + 마지막에 background (못 찾음 / 잘못 찾음)
        self.class_names = list(config["names"].values())
        self.background = len(self.class_names)

        setup_font()

    def calculate_iou(self, box1, box2):
        x1 = max(box1[0], box2[0])
        y1 = max(box1[1], box2[1])
        x2 = min(box1[2], box2[2])
        y2 = min(box1[3], box2[3])

        intersection = max(0, x2 - x1) * max(0, y2 - y1)
        area1 = max(0, box1[2] - box1[0]) * max(0, box1[3] - box1[1])
        area2 = max(0, box2[2] - box2[0]) * max(0, box2[3] - box2[1])
        union = area1 + area2 - intersection

        if union <= 0:
            return 0.0

        return intersection / union

    # normalized xywh -> xyxy (이미지 크기는 모델에 들어간 텐서 기준)
    def xywh_to_xyxy(self, boxes, width, height):
        result = []

        for box in boxes:
            x_center = box[0] * width
            y_center = box[1] * height
            box_width = box[2] * width
            box_height = box[3] * height

            result.append(
                [
                    x_center - box_width / 2,
                    y_center - box_height / 2,
                    x_center + box_width / 2,
                    y_center + box_height / 2
                ]
            )

        return result

    def run_analysis(self, test_loader):
        self.model.eval()

        all_labels = []
        all_preds = []

        print("\n🧪 YOLO 모델 검증 시작")
        print(f"📌 대상: {len(test_loader.dataset)}개")

        with torch.no_grad():
            for batch in tqdm(test_loader, desc="분석 중"):

                # dataloader가 이미 640 LetterBox 처리한 이미지 (uint8)
                images = batch["img"].float() / 255.0
                height, width = images.shape[2], images.shape[3]

                results = self.model(
                    images,
                    conf=self.conf_threshold,
                    device=self.device,
                    # 수거함에는 한 번에 물체 1개 → 같은 위치에 다른 클래스 박스가
                    # 겹쳐 나오지 않도록 클래스 구분 없이 중복 제거
                    agnostic_nms=True,
                    verbose=False
                )

                for image_index, result in enumerate(results):

                    # 예측 (confidence 높은 순)
                    pred_boxes = result.boxes.xyxy.cpu().numpy()
                    pred_classes = result.boxes.cls.cpu().numpy().astype(int)
                    pred_conf = result.boxes.conf.cpu().numpy()
                    order = np.argsort(-pred_conf)

                    # 정답
                    mask = batch["batch_idx"] == image_index
                    gt_classes = batch["cls"][mask].view(-1).numpy().astype(int)
                    gt_boxes = self.xywh_to_xyxy(
                        batch["bboxes"][mask].numpy(),
                        width,
                        height
                    )

                    matched_gt = set()

                    for pred_index in order:
                        pred_box = pred_boxes[pred_index]
                        pred_class = int(pred_classes[pred_index])

                        best_iou = 0.0
                        best_gt_index = None

                        for gt_index, gt_box in enumerate(gt_boxes):
                            if gt_index in matched_gt:
                                continue

                            iou = self.calculate_iou(pred_box, gt_box)

                            if iou > best_iou:
                                best_iou = iou
                                best_gt_index = gt_index

                        if (
                            best_gt_index is not None
                            and best_iou >= self.iou_threshold
                        ):
                            # 정답과 매칭: 클래스가 맞았는지 틀렸는지 기록
                            matched_gt.add(best_gt_index)
                            all_labels.append(int(gt_classes[best_gt_index]))
                            all_preds.append(pred_class)
                        else:
                            # 정답 없는 곳을 예측 (False Positive)
                            all_labels.append(self.background)
                            all_preds.append(pred_class)

                    # 못 찾은 정답 (False Negative)
                    for gt_index, gt_class in enumerate(gt_classes):
                        if gt_index not in matched_gt:
                            all_labels.append(int(gt_class))
                            all_preds.append(self.background)

        if len(all_labels) == 0:
            print("\n⚠️ 분석할 데이터가 없습니다.")
            return None

        labels = np.array(all_labels)
        preds = np.array(all_preds)
        bg = self.background

        # 정답 물체와 매칭된 예측만 → 품목 분류를 얼마나 맞혔나
        matched = (labels != bg) & (preds != bg)
        acc = float((labels[matched] == preds[matched]).mean()) if matched.any() else 0.0

        # 정답 물체 중 찾아낸 비율 (놓친 물체가 많으면 낮아짐)
        n_gt = int((labels != bg).sum())
        recall = matched.sum() / n_gt if n_gt else 0.0

        # 정답이 없는 곳에 그린 박스 수
        fp = int(((labels == bg) & (preds != bg)).sum())

        print(f"\n📌 분류 정확도 (찾아낸 물체 기준): {acc:.4f}")
        print(f"📌 검출률 (Recall): {recall:.4f}  ({int(matched.sum())}/{n_gt})")
        print(f"📌 오탐 개수 (False Positive): {fp}")

        print("\n📋 Classification Report")
        print(
            classification_report(
                all_labels,
                all_preds,
                labels=list(range(len(self.class_names))),
                target_names=self.class_names,
                zero_division=0
            )
        )

        final_path = os.path.join(
            self.config.get("output_path", "./outputs"),
            "confusion"
        )
        os.makedirs(final_path, exist_ok=True)

        self.draw_matrix(all_labels, all_preds, acc, final_path)

        return acc

    def draw_matrix(self, labels, preds, acc, final_path):
        names = self.class_names + ["background"]

        cm = confusion_matrix(
            labels,
            preds,
            labels=list(range(len(names))),
            normalize="true"
        )

        plt.figure(figsize=(12, 10))

        sns.heatmap(
            cm,
            annot=True,
            fmt=".2f",
            cmap="Blues",
            xticklabels=names,
            yticklabels=names
        )

        plt.title(f"Confusion Matrix (Classification Acc: {acc * 100:.2f}%)", fontsize=15)
        plt.xlabel("Predicted", fontsize=12)
        plt.ylabel("Actual", fontsize=12)
        plt.tight_layout()

        save_path = os.path.join(final_path, "confusion_matrix.png")

        plt.savefig(save_path, dpi=300, bbox_inches="tight")
        plt.show()

        print("\n✨ 저장 완료")
        print(save_path)
