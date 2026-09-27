require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');

const inspectionRoutes = require('./routes/inspection');
const historyRoutes = require('./routes/history');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// 로컬 목(mock) 모드에서 저장된 이미지를 브라우저/앱에서 바로 볼 수 있게 정적 제공
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// 헬스체크 - 라즈베리파이/앱이 서버가 살아있는지 확인할 때 사용
app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

app.use('/api', inspectionRoutes);
app.use('/api', historyRoutes);

app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

app.listen(PORT, () => {
  console.log(`서버 실행 중: http://localhost:${PORT}`);
  console.log(`USE_LOCAL_MOCK=${process.env.USE_LOCAL_MOCK}`);
});
