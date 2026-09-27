// 이미지 저장 담당 서비스
// USE_LOCAL_MOCK=true  -> 로컬 uploads/ 폴더에 저장 (AWS 계정 없이 개발 가능)
// USE_LOCAL_MOCK=false -> 실제 AWS S3에 업로드

const fs = require('fs');
const path = require('path');

const USE_LOCAL_MOCK = process.env.USE_LOCAL_MOCK !== 'false';

const LOCAL_UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads');
if (USE_LOCAL_MOCK && !fs.existsSync(LOCAL_UPLOAD_DIR)) {
  fs.mkdirSync(LOCAL_UPLOAD_DIR, { recursive: true });
}

let s3Client = null;
function getS3Client() {
  if (!s3Client) {
    const { S3Client } = require('@aws-sdk/client-s3');
    s3Client = new S3Client({ region: process.env.AWS_REGION });
  }
  return s3Client;
}

/**
 * 이미지 파일(버퍼)을 저장하고 접근 가능한 URL(또는 경로)을 반환한다.
 * @param {Buffer} fileBuffer
 * @param {string} fileName - 예: 2026-09-27-item001.jpg
 * @param {string} mimeType
 * @returns {Promise<string>} 저장된 위치의 URL
 */
async function uploadImage(fileBuffer, fileName, mimeType) {
  if (USE_LOCAL_MOCK) {
    const filePath = path.join(LOCAL_UPLOAD_DIR, fileName);
    fs.writeFileSync(filePath, fileBuffer);
    return `/uploads/${fileName}`; // 로컬 정적 경로
  }

  const { PutObjectCommand } = require('@aws-sdk/client-s3');
  const bucket = process.env.S3_BUCKET_NAME;
  const key = `inspection-images/${fileName}`;

  await getS3Client().send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: fileBuffer,
      ContentType: mimeType,
    })
  );

  return `https://${bucket}.s3.${process.env.AWS_REGION}.amazonaws.com/${key}`;
}

module.exports = { uploadImage, USE_LOCAL_MOCK };
