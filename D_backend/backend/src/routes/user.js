// 사용자 정보 엔드포인트

const express = require('express');
const { getUserData, updateUser, loginUser } = require('../services/user');

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

/**
 * POST /api/login
 * 이메일 + 비밀번호 검증
 * body: { email, password }
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: '이메일과 비밀번호를 입력해주세요' });
    }
    const ok = await loginUser(email, password);
    if (!ok) {
      return res.status(401).json({ error: '이메일 또는 비밀번호가 올바르지 않아요' });
    }
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;
