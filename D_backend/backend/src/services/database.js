// 검수 기록 저장 담당 서비스
// USE_LOCAL_MOCK=true  -> 메모리 배열에 저장 (서버 재시작하면 사라짐, 개발용)
// USE_LOCAL_MOCK=false -> 실제 AWS DynamoDB에 저장

const USE_LOCAL_MOCK = process.env.USE_LOCAL_MOCK !== 'false';

// 로컬 모드용 인메모리 저장소
const localRecords = [];

let ddbDocClient = null;
function getDdbDocClient() {
  if (!ddbDocClient) {
    const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
    const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');
    const client = new DynamoDBClient({ region: process.env.AWS_REGION });
    ddbDocClient = DynamoDBDocumentClient.from(client);
  }
  return ddbDocClient;
}

/**
 * 검수 기록 한 건 저장
 * @param {object} record - { id, date, itemType, contaminated, reason, imageUrl }
 */
async function saveRecord(record) {
  if (USE_LOCAL_MOCK) {
    localRecords.unshift(record);
    return record;
  }

  const { PutCommand } = require('@aws-sdk/lib-dynamodb');
  await getDdbDocClient().send(
    new PutCommand({
      TableName: process.env.DYNAMODB_TABLE_NAME,
      Item: record,
    })
  );
  return record;
}

/**
 * 최근 기록 목록 조회
 * @param {number} limit
 */
async function listRecords(limit = 50) {
  if (USE_LOCAL_MOCK) {
    return localRecords.slice(0, limit);
  }

  const { ScanCommand } = require('@aws-sdk/lib-dynamodb');
  const result = await getDdbDocClient().send(
    new ScanCommand({
      TableName: process.env.DYNAMODB_TABLE_NAME,
      Limit: limit,
    })
  );
  return result.Items || [];
}

/**
 * 간단 통계 계산 (품목별 건수, 오염 판정 비율)
 */
async function getStatistics() {
  const records = await listRecords(1000);
  const total = records.length;
  const contaminated = records.filter((r) => r.contaminated).length;

  const byItemType = {};
  for (const r of records) {
    byItemType[r.itemType] = (byItemType[r.itemType] || 0) + 1;
  }

  return {
    total,
    contaminated,
    contaminationRate: total ? Number(((contaminated / total) * 100).toFixed(1)) : 0,
    byItemType,
  };
}

module.exports = { saveRecord, listRecords, getStatistics, USE_LOCAL_MOCK };
