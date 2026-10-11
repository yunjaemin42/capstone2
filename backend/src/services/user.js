// 사용자 정보 서비스
// USE_LOCAL_MOCK=true  -> 메모리에 저장
// USE_LOCAL_MOCK=false -> AWS DynamoDB에 저장

const { listRecords } = require('./database');

const USE_LOCAL_MOCK = process.env.USE_LOCAL_MOCK !== 'false';

// 기본 사용자 (단일 사용자 시스템)
let localUser = {
  name: '사용자',
  joinedAt: new Date().toISOString(),
  points: 0,
  notifReturn: true,
  notifWeekly: false,
};

// 등급 계산 (누적 배출 횟수 기준 — Flutter 앱 등급표와 동일)
function calcGrade(total) {
  if (total >= 201) return '에코마스터';
  if (total >= 121) return '마스터 등급';
  if (total >= 71)  return '에코 등급';
  if (total >= 31)  return '초록 등급';
  return '새싹 등급';
}

// 이번 달 통과 건수당 10포인트
const POINTS_PER_PASS = 10;

async function getUserData() {
  const now = new Date();
  const allRecords = await listRecords(1000);

  // 이번 달 기록
  const monthRecords = allRecords.filter((r) => {
    const d = new Date(r.date);
    return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth();
  });

  const monthCount = monthRecords.length;
  const monthPassed = monthRecords.filter((r) => !r.contaminated).length;
  const passRate = monthCount > 0 ? Math.round((monthPassed / monthCount) * 100) : 0;
  const monthPoints = monthPassed * POINTS_PER_PASS;

  // 누적 포인트 = 전체 통과 건수 * 10
  const totalPassed = allRecords.filter((r) => !r.contaminated).length;
  const points = USE_LOCAL_MOCK ? totalPassed * POINTS_PER_PASS : localUser.points;

  // 가입 경과 일수
  const joinedAt = new Date(localUser.joinedAt);
  const joinedDays = Math.floor((now - joinedAt) / (1000 * 60 * 60 * 24)) + 1;

  // 지난달과 비교해서 개선 메시지 생성
  const lastMonth = allRecords.filter((r) => {
    const d = new Date(r.date);
    const lm = new Date(now.getFullYear(), now.getMonth() - 1);
    return d.getFullYear() === lm.getFullYear() && d.getMonth() === lm.getMonth();
  });
  let improvementMessage = null;
  if (lastMonth.length > 0 && monthRecords.length > 0) {
    const lastRate = lastMonth.filter((r) => r.contaminated).length / lastMonth.length;
    const currRate = monthRecords.filter((r) => r.contaminated).length / monthRecords.length;
    if (currRate < lastRate) {
      const pct = Math.round((1 - currRate / lastRate) * 100);
      improvementMessage = `반환율이 지난달보다 ${pct}% 줄었어요`;
    }
  }

  return {
    name: localUser.name,
    joinedDays,
    monthCount,
    passRate,
    points,
    monthPoints,
    grade: calcGrade(allRecords.length),
    improvementMessage,
    notifReturn: localUser.notifReturn,
    notifWeekly: localUser.notifWeekly,
  };
}

async function updateUser(fields) {
  const allowed = ['name', 'notifReturn', 'notifWeekly'];
  for (const key of allowed) {
    if (fields[key] !== undefined) localUser[key] = fields[key];
  }
  return getUserData();
}

module.exports = { getUserData, updateUser };
