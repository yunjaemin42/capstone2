// 사용자 정보 엔드포인트

const express = require('express');
const { getUserData, updateUser } = require('../services/user');

const router = express.Router();

/**
 * GET /api/user
 * 사용자 정보 + 이번 달 통계 반환
 */
router.get('/user', async (req, res) => {
  try {
    const user = await getUserData();
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

/**
 * PATCH /api/user
 * 사용자 정보 수정 (name, notifReturn, notifWeekly)
 */
router.patch('/user', async (req, res) => {
  try {
    const user = await updateUser(req.body);
    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;
