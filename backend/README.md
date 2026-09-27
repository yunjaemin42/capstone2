# 재활용 검수 시스템 - 백엔드

AI 기반 스마트 재활용 검수 및 자동 분리배출 시스템의 백엔드 서버입니다.
계획서 기준 4개 API를 구현했습니다.

## 폴더 구조

```
backend/
├── package.json
├── .env.example        # 복사해서 .env로 만들고 값 채우기
├── uploads/             # 로컬 목 모드에서 이미지가 저장되는 곳 (자동 생성됨)
└── src/
    ├── index.js         # 서버 진입점
    ├── routes/
    │   ├── inspection.js  # POST /api/inspection-result
    │   └── history.js     # GET /api/history, GET /api/statistics
    └── services/
        ├── storage.js     # 이미지 저장 (로컬 or S3)
        ├── database.js    # 기록 저장/조회 (메모리 or DynamoDB)
        └── push.js        # FCM 푸시 알림 (목 or 실제)
```

## 1단계: 로컬에서 먼저 실행해보기 (AWS 계정 필요 없음)

```bash
cd backend
npm install
cp .env.example .env      # USE_LOCAL_MOCK=true 로 되어 있으면 그대로 둠
npm run dev
```

서버가 `http://localhost:3000` 에서 실행됩니다.

## 2단계: API 테스트 (라즈베리파이/앱 없이 curl로 확인)

**정상 배출 기록 남기기:**
```bash
curl -X POST http://localhost:3000/api/inspection-result \
  -F "itemType=plastic_pet" \
  -F "contaminated=false"
```

**불량(오염) 배출 + 이미지 첨부:**
```bash
curl -X POST http://localhost:3000/api/inspection-result \
  -F "itemType=plastic_pet" \
  -F "contaminated=true" \
  -F "reason=라벨 미제거" \
  -F "image=@/path/to/test-image.jpg"
```

**이력 조회:**
```bash
curl http://localhost:3000/api/history
```

**통계 조회:**
```bash
curl http://localhost:3000/api/statistics
```

## 3단계: AWS로 전환하기 (계정 준비되면)

1. AWS 콘솔에서 S3 버킷 생성 (`.env`의 `S3_BUCKET_NAME`과 이름 맞추기)
2. DynamoDB 테이블 생성 — 파티션 키: `id` (문자열), 테이블 이름은 `.env`의 `DYNAMODB_TABLE_NAME`과 맞추기
3. IAM 사용자 만들어서 S3/DynamoDB 접근 권한 있는 액세스 키 발급 → `.env`에 `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` 입력
4. `.env`에서 `USE_LOCAL_MOCK=false` 로 변경
5. 서버 재시작 후 다시 테스트 — 코드 수정 없이 그대로 S3/DynamoDB로 저장되는지 확인

## 4단계: EC2에 배포하기

1. EC2 인스턴스 생성 (t3.micro, Ubuntu), Elastic IP 연결
2. EC2에 Node.js 설치, 이 `backend/` 폴더를 GitHub로 올린 뒤 EC2에서 `git clone`
3. `.env` 파일을 EC2에서 직접 생성 (AWS 자격증명 포함이므로 GitHub에 올리지 말 것!)
4. `npm install && npm install -g pm2`
5. `pm2 start src/index.js --name recycling-backend` — 터미널 닫아도 서버가 계속 돌아감
6. 라즈베리파이/앱에서 `http://<Elastic IP>:3000/api/...` 로 호출

## 다음에 추가하면 좋은 것들
- `.env`에 없는 필드 검증(validation) 강화
- FCM 실제 연동 (`src/services/push.js`)
- 라즈베리파이 인증(간단한 API 키 헤더 검사 등) — 아무나 서버를 호출하지 못하도록
