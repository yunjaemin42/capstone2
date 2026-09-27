// 라즈베리파이(엣지 디바이스) -> 서버로 검수 결과를 보내는 엔드포인트들

const express = require('express');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');

const { uploadImage } = require('../services/storage');
const { saveRecord } = require('../services/database');
const { sendPushNotification } = require('../services/push');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

/**
 * POST /api/inspection-result
 * 라즈베리파이가 검수 결과(정상/불량)를 보고하는 엔드포인트.
 * 결함(불량)인 경우 이미지도 함께 첨부해서 보낸다 (multipart/form-data).
 *
 * body(form fields):
 *   itemType: string      예) "plastic_pet", "can", "glass"
 *   contaminated: "true" | "false"
 *   reason: string        예) "라벨 미제거", "뚜껑 미분리" (정상이면 빈 문자열)
 * file:
 *   image: 결함 캡처 이미지 (contaminated=true일 때만 첨부)
 */
router.post('/inspection-result', upload.single('image'), async (req, res) => {
  try {
    const { itemType, contaminated, reason } = req.body;

    if (!itemType || contaminated === undefined) {
      return res.status(400).json({ error: 'itemType, contaminated는 필수입니다.' });
    }

    const isContaminated = contaminated === 'true' || contaminated === true;
    const id = uuidv4();
    const date = new Date().toISOString();

    let imageUrl = null;
    if (isContaminated && req.file) {
      const fileName = `${date.slice(0, 10)}-${id}.jpg`;
      imageUrl = await uploadImage(req.file.buffer, fileName, req.file.mimetype);
    }

    const record = {
      id,
      date,
      itemType,
      contaminated: isContaminated,
      reason: reason || null,
      imageUrl,
    };

    await saveRecord(record);

    // 불량 판정이면 앱에 즉시 푸시 알림
    if (isContaminated) {
      await sendPushNotification({
        title: '분리배출 반려 안내',
        body: reason ? `사유: ${reason}` : '오염 또는 오분류가 감지되었습니다.',
        data: { recordId: id, imageUrl },
      });
    }

    res.status(201).json({ success: true, record });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;
