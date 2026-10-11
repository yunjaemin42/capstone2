// DynamoDB Local에 테이블 생성하는 스크립트
// 사용법: node scripts/create-table.js

require('dotenv').config();
const { DynamoDBClient, CreateTableCommand, ListTablesCommand } = require('@aws-sdk/client-dynamodb');

const client = new DynamoDBClient({
  region: process.env.AWS_REGION || 'ap-northeast-2',
  endpoint: process.env.DYNAMODB_ENDPOINT, // 로컬: http://localhost:8000
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'fakeKey',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'fakeSecret',
  },
});

const TABLE_NAME = process.env.DYNAMODB_TABLE_NAME || 'InspectionLog';

async function createTable() {
  // 이미 있는지 확인
  const { TableNames } = await client.send(new ListTablesCommand({}));
  if (TableNames.includes(TABLE_NAME)) {
    console.log(`테이블 "${TABLE_NAME}" 이미 존재함`);
    return;
  }

  await client.send(
    new CreateTableCommand({
      TableName: TABLE_NAME,
      KeySchema: [{ AttributeName: 'id', KeyType: 'HASH' }],
      AttributeDefinitions: [{ AttributeName: 'id', AttributeType: 'S' }],
      BillingMode: 'PAY_PER_REQUEST',
    })
  );

  console.log(`테이블 "${TABLE_NAME}" 생성 완료`);
}

createTable().catch((err) => {
  console.error('테이블 생성 실패:', err.message);
  process.exit(1);
});
