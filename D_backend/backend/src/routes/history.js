// 모바일 앱 -> 서버로 이력/통계를 조회하는 엔드포인트들

const express = require('express');
const { listRecords, getStatistics } = require('../services/database');
const { getPresignedUrl } = require('../services/storage');

const router = express.Router();

/**
 * GET /api/history?limit=20
 * 최근 배출/검수 기록 목록
 */
router.get('/history', async (req, res) => {
  try {
    const limit = Number(req.query.limit) || 20;
    const records = await listRecords(limit);

    // S3 private 객체는 pre-signed URL로 교체 (1시간 유효)
    const signedRecords = await Promise.all(
      records.map(async (r) => ({
        ...r,
        imageUrl: r.imageUrl ? await getPresignedUrl(r.imageUrl) : null,
      }))
    );

    res.json({ count: signedRecords.length, records: signedRecords });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

/**
 * GET /api/statistics
 * 전체 배출 건수, 오염 판정 비율, 품목별 건수 등 요약 통계
 */
router.get('/statistics', async (req, res) => {
  try {
    const stats = await getStatistics();
    res.json(stats);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;
