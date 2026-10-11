# 뚝딱뚝딱 재활용 앱 (Flutter UI)

Figma "뚝딱뚝딱 재활용 앱 UI" 화면 5개를 Flutter로 옮긴 코드예요. 지금은 예시 데이터로 동작합니다.

## 실행 방법

```bash
# 1. 새 프로젝트 만들기
flutter create recycle_app
cd recycle_app

# 2. 글꼴 패키지 추가 (Noto Sans KR)
flutter pub add google_fonts

# 3. 이 압축 파일의 lib 폴더로 프로젝트의 lib 폴더를 통째로 덮어쓰기

# 4. 실행
flutter run
```

`test/widget_test.dart`에서 오류가 나면 그 파일은 지워도 괜찮아요 (기본 카운터 앱용 테스트라서).

## 폴더 구조

```
lib/
├── main.dart              하단 탭 (홈 · 이력 · 통계 · 마이)
├── theme.dart             색상, 글꼴
├── data/mock_data.dart    예시 데이터 (나중에 API로 교체)
├── widgets/common.dart    카드, 배지, 목록 한 줄 등 공통 부품
└── screens/
    ├── home_screen.dart     01 홈
    ├── history_screen.dart  02 검수 이력 (필터 동작)
    ├── detail_screen.dart   03 결함 상세 (목록 누르면 열림)
    ├── stats_screen.dart    04 통계 (주간/월간 전환)
    └── my_screen.dart       05 마이 (알림 토글 동작)
```

## 다음 단계

- `data/mock_data.dart`의 `mockInspections`를 `GET /api/history` 응답으로 교체 (`http` 패키지)
- 결함 이미지는 `Inspection.imageUrl`에 S3 URL을 넣으면 상세 화면에 바로 표시됨
- FCM: `firebase_messaging` 추가 후 알림을 누르면 `DetailScreen`으로 이동하게 연결
- `relativeTime()`의 기준 시각은 시연용으로 고정돼 있으니 `DateTime.now()`로 바꾸기
