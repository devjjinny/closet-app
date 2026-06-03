# closet_app 출시 태스크 (v1.0)

> 목표: 2026년 5월 말 App Store 출시

---

## 2026-06-01 개선점 메모

### 출시 전 최우선
- [ ] 개인정보 처리방침 작성 및 GitHub Pages URL 확보
  - App Store Connect 등록/심사에 필수
  - 위치정보는 날씨 조회용, 사진/옷장/코디 기록은 로컬 저장 중심으로 명시
  - OpenWeatherMap에는 위도/경도만 전달된다는 점 명시
  - 후보 URL: `https://devjjinny.github.io/closet-app/privacy/`
- [ ] Bundle ID / App Store Connect 등록 상태 최종 확인
  - 현재 앱 빌드 ID: `com.closetapp.closetApp`
  - App Store Connect 앱 이름, SKU, 카테고리, 개인정보 URL 입력 필요
- [ ] TestFlight용 실제 API 키 빌드 플로우 확정
  - 개발/실기기: `.env` + `tool/run.sh`
  - 배포/ipa: `--dart-define=OPENWEATHER_API_KEY=<키>` 포함

### 앱 품질 개선
- [ ] 캐릭터 에셋 실기기 홈 화면에서 전 band 확인
  - `female_band1~8`, `male_band1~8`, `female_rainy`, `male_rainy`
  - 투명 배경이 UI 카드에서 어색하지 않은지 확인
  - 여성/남성 비율과 코디 톤이 일관적인지 확인
- [ ] 날씨 API 실패/권한 거부 UX 확인
  - 위치 권한 거부 시 안내 문구
  - API 실패 시 fallback 날씨가 너무 조용히 보이지 않는지 확인
- [ ] 온보딩/설정에서 성별 선택 UX 확인
  - 선택값에 따라 캐릭터가 바로 바뀌는지
  - 기본값 여성 처리로 사용자 혼란 없는지
- [ ] 앱 아이콘 실기기 홈 화면 가독성 확인
  - 작은 크기에서 옷걸이+옷 실루엣이 읽히는지
  - 배경색이 iOS 다크/라이트 홈 화면에서 묻히지 않는지

### 개발 정리
- [ ] `flutter analyze` 기존 61개 경고 정리 여부 결정
  - 릴리즈 차단은 아니지만 미사용 위젯/필드 정리는 권장
  - 특히 `_LegacyOutfitHistoryCard`, `_WeatherBar`, `_buildShootingTip` 확인
- [ ] Android `GeneratedPluginRegistrant.java` 자동 변경 원인 확인
  - iOS 빌드 후 `flutter_native_splash` 등록 줄이 빠지는 현상 반복
  - 커밋 전 항상 diff 확인 필요
- [ ] 출시용 스크린샷 준비 전 샘플 데이터 세팅
  - 홈: 날씨+캐릭터+추천 코디가 풍성하게 보이도록
  - 옷장: 카테고리별 옷 여러 개
  - 기록: 룩북/캘린더/리포트 화면이 비어 보이지 않게

---

## Phase 1 — 기술적 선결 조건 (5월 5-11일)

### Task 01: iOS 배포 타겟 통일
**설명:** `ios/Runner.xcodeproj/project.pbxproj`의 `IPHONEOS_DEPLOYMENT_TARGET` 값을 13.0에서 15.5로 변경한다. Podfile은 이미 15.5지만 pbxproj와 불일치하면 ML Kit 런타임 오류 가능성 있다.

**수락 기준:**
- [ ] `grep IPHONEOS_DEPLOYMENT_TARGET ios/Runner.xcodeproj/project.pbxproj` → 모두 15.5
- [ ] `flutter build ios --simulator` 성공

**검증:** `grep IPHONEOS_DEPLOYMENT_TARGET ios/Runner.xcodeproj/project.pbxproj`
**의존성:** 없음 / **범위:** XS (1 파일)

---

### Task 02: API 키 --dart-define으로 이전
**설명:** `lib/presentation/providers/providers.dart` 하드코딩된 `f3af7a73...` 키를 제거하고 `String.fromEnvironment('OPENWEATHER_API_KEY')`로 교체. `tool/run.sh`에 실행 스크립트 작성, `.gitignore`에 추가.

**수락 기준:**
- [ ] `grep -r "f3af7a73" lib/` → 결과 없음
- [ ] `tool/run.sh` 파일 존재
- [ ] 키 없이 실행 시 fallback (서울 기본 날씨) 동작

**검증:** `grep -r "f3af7a73" lib/`
**의존성:** 없음 / **범위:** S (2 파일)

---

### Task 03: unawaited_futures 경고 수정
**설명:** `garment_repository.dart`와 `outfit_repository.dart`의 `_emitAll()` 호출 6건에 `unawaited()` 처리 또는 적절한 await 추가.

**수락 기준:**
- [ ] `flutter analyze 2>&1 | grep unawaited` → 출력 없음
- [ ] `flutter test` — 61개 통과

**검증:** `flutter analyze && flutter test`
**의존성:** 없음 / **범위:** XS (2 파일)

---

### Checkpoint 1
- [ ] `flutter analyze` — unawaited_futures 0건
- [ ] `flutter test` — 61개 통과
- [ ] `flutter build ipa --dart-define=OPENWEATHER_API_KEY=<키>` 성공

---

## Phase 2 — 캐릭터·에셋 (5월 12-18일)

### Task 04: 앱 아이콘 신규 디자인 + 통합
**설명:** 현재 10KB 플레이스홀더를 실제 디자인으로 교체. `flutter_launcher_icons` 패키지로 모든 크기 자동 생성.

**수락 기준:**
- [ ] 1024×1024 PNG, 알파 채널 없음
- [ ] `dart run flutter_launcher_icons` 성공
- [ ] 시뮬레이터 홈 화면에서 아이콘 확인

**외부 작업:** 아이콘 PNG 디자인 (코드 외)
**의존성:** 없음 / **범위:** S

---

### Task 05a: character_widget.dart 코드 변경
**설명:** `_weatherCondition()` 메서드를 temperatureBand 기반으로 변경. rainy/snowy는 별도 조건으로 유지, 나머지는 `band${w.temperatureBand}` 반환.

```dart
// 변경 전
String _weatherCondition(WeatherSnapshot w) {
  if (w.isRainy || w.isSnowy) return 'rainy';
  if (w.feelsLike < 10) return 'cold';
  if (w.condition == 'Clouds') return 'cloudy';
  return 'sunny';
}

// 변경 후
String _weatherCondition(WeatherSnapshot w) {
  if (w.isRainy || w.isSnowy) return 'rainy';
  return 'band${w.temperatureBand}';
}
```

에셋 경로: `assets/characters/${gender.name}_${condition}.png`
→ 예: `female_band3.png`, `male_rainy.png`

**수락 기준:**
- [ ] 코드 변경 완료
- [ ] `flutter test` 통과 (기존 테스트 무영향 확인)
- [ ] 이미지 없을 때 _Placeholder fallback 정상 동작

**검증:** 시뮬레이터에서 feelsLike 값 조작 후 올바른 에셋 경로 로그 확인
**의존성:** 없음 / **범위:** XS (1 파일)

---

### Task 05b: 캐릭터 이미지 18개 디자인 (외부 작업)
**설명:** 각 temperatureBand별 착장을 반영한 캐릭터 PNG 18개를 디자인한다.

**파일 목록 (18개):**
```
female_rainy.png   ← 우산 + 레인 재킷
female_band1.png   ← 28°C~  민소매/크롭탑, 반바지
female_band2.png   ← 23~27°C 반팔 티셔츠, 면바지
female_band3.png   ← 20~22°C 얇은 가디건/긴팔, 청바지
female_band4.png   ← 17~19°C 맨투맨/얇은 니트
female_band5.png   ← 12~16°C 자켓/야상
female_band6.png   ← 9~11°C  트렌치코트/울코트
female_band7.png   ← 5~8°C   히트텍+두꺼운 니트, 레깅스
female_band8.png   ← ~4°C    패딩/두꺼운 코트, 목도리
(male 동일 9개)
```

**이미지 스펙:**
- 최소 200×320px, 투명 배경 PNG
- 스타일: 단순하고 명확한 일러스트 (세밀화 불필요)

**수락 기준:**
- [ ] 18개 파일 모두 존재
- [ ] 각 파일 투명 배경 PNG

**의존성:** Task 05a (파일명 확정 후 디자인) / **범위:** 외부 작업

---

### Task 05c: 캐릭터 이미지 assets 교체
**설명:** 05b 완료 후 기존 4조건 이미지를 새 18개 이미지로 교체.

**수락 기준:**
- [ ] `assets/characters/` 에 18개 파일 존재
- [ ] 기존 `female_sunny.png` 등 4조건 파일 삭제 또는 보관
- [ ] 시뮬레이터에서 각 band별 이미지 정상 표시 확인

**의존성:** Task 05a, 05b / **범위:** XS

---

### Task 06: 스플래시 화면 구성
**설명:** `flutter_native_splash` 패키지 추가 후 앱 테마 색상(#6C5CE7) 배경으로 스플래시 설정.

**수락 기준:**
- [ ] 앱 시작 시 흰 화면 깜빡임 없음
- [ ] 다크모드에서도 정상 표시

**검증:** 시뮬레이터 앱 종료 후 재시작
**의존성:** 없음 / **범위:** S

---

### Task 07: 개인정보 처리방침 작성 + GitHub Pages 호스팅

**설명:**
1. 처리방침 HTML/Markdown 작성 (수집 항목: 위치, 사진, 로컬 기기 저장)
2. GitHub Pages 배포 → URL 확보
   - 새 repo `closet-app-privacy` 생성 → `docs/index.html` 작성 → Pages 활성화
   - URL: `https://[username].github.io/closet-app-privacy`

**필수 포함 내용:**
- 앱 이름, 운영자 정보
- 수집 데이터: 위치정보(날씨 조회용, 서버 미저장), 사진(기기 내 저장), SQLite 로컬 데이터
- 데이터를 외부 서버로 전송하지 않음 명시 (OpenWeatherMap에는 위치만 전달)
- 문의 이메일

**수락 기준:**
- [ ] 한국어 처리방침 문서 완성
- [ ] GitHub Pages URL 접근 가능

**의존성:** 없음 / **범위:** S (외부 작업 포함)

---

### Checkpoint 2
- [ ] 시뮬레이터에서 각 band 캐릭터 이미지 정상 표시
- [ ] 앱 아이콘 홈 화면 정상 (플레이스홀더 아님)
- [ ] 스플래시 정상 표시
- [ ] 개인정보 처리방침 URL 접근 가능

---

## Phase 3 — App Store Connect & TestFlight (5월 19-25일)

### Task 08: Apple Developer Bundle ID 등록 (수동)
**설명:** [developer.apple.com](https://developer.apple.com) → Certificates, Identifiers & Profiles → Identifiers → + → App ID → `com.closetapp.closetApp` 등록.

**수락 기준:**
- [ ] Apple Developer 콘솔에서 `com.closetapp.closetApp` Identifier 등록 확인

**의존성:** Apple Developer 계정 / **범위:** 수동 작업

---

### Task 09: App Store Connect 앱 등록
**설명:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → + → New App.

**입력값:**
- 이름: 오늘 뭐 입지?
- Bundle ID: com.closetapp.closetApp
- SKU: closetapp-v1
- 카테고리: 라이프스타일
- 부제목: 날씨에 맞는 내 옷장 코디 추천 (27자)
- 키워드: 날씨코디,옷추천,코디앱,옷장관리,패션,스타일,날씨
- 개인정보 처리방침 URL: Task 07에서 확보한 GitHub Pages URL
- 연령 등급: 4+, 가격: 무료

**수락 기준:**
- [ ] App Store Connect에 앱 등록 완료
- [ ] 개인정보 처리방침 URL 입력 완료

**의존성:** Task 07, 08 / **범위:** 수동 작업

---

### Task 10: 스크린샷 촬영
**설명:** Xcode 시뮬레이터에서 핵심 화면 캡처.

**필요 크기:**
- 6.9인치: iPhone 16 Pro Max 시뮬레이터 (1320×2868)
- 6.1인치: iPhone 16 시뮬레이터 (1179×2556)

**촬영 화면 (최소 3장):**
1. 홈 화면 (날씨 + 캐릭터 + 코디 카드)
2. 내 옷장 화면 (그리드)
3. 기록 화면

**수락 기준:**
- [ ] 6.9인치 최소 3장
- [ ] 6.1인치 최소 3장
- [ ] App Store Connect에 업로드 완료

**의존성:** Task 09 / **범위:** 수동 작업

---

### Task 11: TestFlight 내부 테스터 배포
**설명:** `flutter build ipa` → Xcode Organizer → TestFlight 업로드.

```bash
flutter build ipa \
  --dart-define=OPENWEATHER_API_KEY=<키> \
  --release
```

**수락 기준:**
- [ ] IPA 빌드 성공
- [ ] TestFlight에 빌드 업로드 완료
- [ ] 테스터 기기에서 설치 및 실행 성공
- [ ] Checkpoint 3 수동 검증 통과

**의존성:** Task 01, 02, 04, 05, 06 / **범위:** M

---

### Checkpoint 3 — 핵심 플로우 수동 검증
- [ ] 앱 첫 실행 → 성별 선택 → 홈 정상 진입
- [ ] 날씨 표시 및 코디 추천 표시
- [ ] 옷 등록 (카메라) → 배경 제거 → 옷장 그리드 확인
- [ ] 코디 저장 → 기록 화면 표시
- [ ] 스타일 칩 탭 → 추천 갱신
- [ ] 네트워크 없을 때 에러 UI + 재시도 버튼
- [ ] 위치 권한 거부 → 서울 기본값으로 날씨 표시
- [ ] 다크모드 UI 깨짐 없음
- [ ] 큰 이미지(12MP) 등록 시 메모리 이슈 없음

---

## Phase 4 — 심사 제출 (5월 26-31일)

### Task 12: TestFlight 피드백 반영 및 최종 빌드
**설명:** TestFlight 피드백 기반 크리티컬 버그 수정 후 최종 빌드.

**수락 기준:**
- [ ] 크리티컬 버그 0건
- [ ] 버전: 1.0.0+1

**의존성:** Task 11 / **범위:** 피드백 내용에 따라 다름

---

### Task 13: App Store 심사 제출
**설명:** App Store Connect에서 최종 빌드를 선택해 심사 제출. 심사 메모 작성.

**심사 메모 (영문):**
> This app uses anonymous sign-in automatically. No test account is required. The app works with location permission (weather) and camera/photo library (clothing registration). All data is stored locally on the device.

**수락 기준:**
- [ ] 심사 제출 완료 (상태: "Waiting for Review")

**의존성:** Task 09, 10, 12 / **범위:** XS

---

### Task 14: 출시 결정
**수락 기준:**
- [ ] 심사 통과 확인
- [ ] 출시 방식 결정 (즉시 / 날짜 예약) 및 실행

**의존성:** Task 13 / **범위:** XS

---

## 수동 작업 요약 (개발자 직접 필요)

| # | 작업 | 시점 |
|---|------|------|
| 아이콘 디자인 | 1024×1024 PNG 제작 | Phase 2 시작 전 |
| 캐릭터 이미지 | 18개 PNG 디자인 | Phase 2 중 병행 |
| GitHub Pages | closet-app-privacy 레포 생성 + 배포 | Task 07 |
| Apple Developer | Bundle ID 등록 | Task 08 |
| App Store Connect | 앱 등록 | Task 09 |
| Xcode Organizer | TestFlight 업로드 | Task 11 |
| 심사 제출 | App Store Connect에서 제출 버튼 | Task 13 |
