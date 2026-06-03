# 출시 준비 체크리스트 (iOS v1.0)

> 목표: 2026년 5월 말 App Store 출시

---

## 1. 기능 완성도

| # | 기능 | 상태 |
|---|------|------|
| #01 | 날씨 API (OpenWeatherMap) | ✅ |
| #02 | 온도 기반 추천 룰 | ✅ |
| #03 | 홈 화면 (날씨 + 스타일 칩 + 코디) | ✅ |
| #05 | 이미지 업로드 (카메라/갤러리 + 배경제거) | ✅ |
| #07 | 옷 데이터 모델 + Firestore 저장 | ✅ |
| #08 | 콜라주 미리보기 (좌3 + 우2 레이아웃) | ✅ |
| #09 | 코디 저장 / 기록 화면 | ✅ |
| #10 | 스타일 선호 저장 | ✅ |
| #12 | 에러 / 로딩 공통 처리 | ✅ |
| #14 | 로컬 저장소 연결 (SQLite/기기 파일 저장) | ✅ |
| #04 | 캐릭터 (Rive) | ⬜ v1.1 |

---

## 2. 저장소 / 권한 설정

- [x] SQLite 로컬 DB 동작 확인
- [x] 기기 파일 저장 동작 확인
- [ ] iOS 권한 문구 최종 확인

---

## 3. API 키 / 환경변수

- [x] OpenWeatherMap API 키 발급 → 실행 시 `--dart-define`으로 전달
  ```
  flutter run --dart-define=OPENWEATHER_API_KEY=<키>
  ```
- [ ] App Store 빌드 시 `--dart-define=OPENWEATHER_API_KEY=<키>` 포함 여부 확인

---

## 4. iOS 앱 설정

- [ ] `ios/Runner/Info.plist` 권한 문구 최종 확인
  - `NSLocationWhenInUseUsageDescription`
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
- [ ] Bundle ID: `com.yourname.closetapp` → 실제 Bundle ID로 변경
- [x] 앱 아이콘 1024×1024 PNG 준비 → `flutter_launcher_icons` 적용
- [ ] 스플래시 화면 설정 (`flutter_native_splash`)
- [ ] 최소 iOS 버전 15.5 (현재 설정 확인)
- [ ] Release 빌드 성공 여부 확인: `flutter build ipa`

---

## 5. App Store Connect

- [ ] 앱 등록 (Bundle ID, 앱 이름, 카테고리: Lifestyle)
- [ ] 앱 설명 (한국어) — 80자 이내 부제목 포함
- [ ] 키워드 (100자 이내): 날씨코디,옷추천,코디앱,옷장관리,패션
- [ ] 스크린샷 준비
  - 6.9인치 (iPhone 16 Pro Max)
  - 6.1인치 (iPhone 16)
  - iPad (선택)
- [ ] 개인정보 처리방침 URL (필수) — 후보: `https://devjjinny.github.io/closet-app/privacy/`
- [ ] 연령 등급: 4+ 설정
- [ ] 가격: 무료

---

## 6. 개인정보 처리방침 필수 항목

앱이 수집하는 데이터:
- 위치 정보 (날씨 조회용, 저장 안 함)
- 사진 (옷 등록/코디 기록용, 기기 내 저장)
- 옷장/코디 기록 (SQLite 로컬 DB에 저장)

---

## 7. 성능 / 안정성 체크

- [ ] 옷 0개 상태에서 앱 시작 → 빈 상태 UI 확인
- [ ] 네트워크 없을 때 → 에러 UI + 재시도 버튼 확인
- [ ] 위치 권한 거부 → 서울 기본값으로 동작 확인
- [ ] 이미지 업로드 실패 → SnackBar 에러 메시지 확인
- [ ] 큰 이미지(12MP) 등록 시 메모리 이슈 없는지 확인
- [ ] 다크모드 UI 깨짐 없는지 확인

---

## 8. TestFlight 배포 (출시 2주 전)

- [ ] TestFlight 내부 테스터 초대 (본인 + 지인 5명)
- [ ] 크래시 없이 핵심 플로우 동작 확인
  1. 앱 첫 실행 → 성별 선택 → 홈
  2. 옷 등록 (카메라) → 내 옷장 그리드 확인
  3. 코디 추천 → 저장 → 기록 화면 확인
  4. 스타일 칩 탭 → 추천 갱신 확인
- [ ] 피드백 반영 후 최종 빌드 제출

---

## 9. 심사 제출

- [ ] 심사 메모 작성 (테스트 계정 불필요 — 익명 로그인 자동)
- [ ] 심사 예상 기간: 1-3 영업일
- [ ] 심사 통과 후 즉시 출시 vs 날짜 예약 결정
