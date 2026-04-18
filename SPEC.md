# closet_app SPEC

> 날씨에 맞는 내 옷장 기반 코디 추천 앱
> 목표 배포: 2026년 5월 말 (iOS App Store)

---

## 1. 개요

### 앱 한 줄 정의
"오늘, 내일 날씨에 맞게 내 옷장에서 코디를 골라주는 앱"

### 대상 사용자
- 20-30대, 매일 아침 옷 선택에 시간을 쓰는 사람
- 옷은 많은데 뭘 입을지 모르는 사람
- 날씨를 고려해서 코디하고 싶은 사람

### 핵심 가치 제안
1. **날씨 연동**: 오늘/내일 날씨를 자동 감지해 온도·날씨 유형에 맞는 코디 추천
2. **내 옷장**: 촬영 가이드 → 배경 제거 → 카테고리별 옷 등록
3. **콜라주 추천**: 상의+하의+신발+악세사리를 한 이미지로 조합해 제안
4. **기본 캐릭터**: 옷이 없는 신규 유저도 바로 추천 경험 (성별 기반 샘플)
5. **즐겨찾기 코디**: 자주 입는 조합 저장 → 맞는 날씨에 재추천

---

## 2. 기능 범위

### MVP (v1.0 — 5월 말 배포)

#### 2.1 온보딩
- **자동 익명 로그인**: 앱 시작 시 `main.dart`에서 `signInAnonymously()` 자동 호출
- **성별 선택 화면** (`/onboarding`): 최초 1회만, SharedPreferences `onboarding_complete` 키로 완료 여부 관리
  - 성별은 Firestore `users/{uid}/prefs.gender`에 저장
- 위치 권한 요청 (날씨 자동 감지) — 홈 진입 시
- **계정 업그레이드 (Post-MVP)**: 옷 저장 / 즐겨찾기 시 "계정 연결하면 데이터가 보존돼요" 바텀시트
  - 로그인 방법: Google Sign-In
  - 익명 uid → 구글 계정 uid 마이그레이션

#### 2.2 홈 화면
- 현재 위치 날씨 표시 (온도, 날씨 상태, 아이콘)
- 오늘 / 내일 탭 전환
- 코디 추천 카드 1개 표시
  - 옷장이 비어 있으면: 성별 기반 샘플 캐릭터 이미지
  - 옷장에 옷이 있으면: 내 옷으로 콜라주 생성
- "이 코디 저장" / "다른 추천 보기" 버튼

#### 2.3 캐릭터 시스템
- 날씨 조건별 캐릭터 이미지 (남/여 각각): sunny / cloudy / rainy / cold — 4종 × 2 = 8개
  - `assets/characters/{gender}_{condition}.png` 형태로 번들 (앱 내 로컬 이미지)
- 이미지 없을 때 자동 폴백: 아이콘 플레이스홀더 표시
- v1.1: 더 많은 날씨 구간 추가 (snowy, hot 등)

#### 2.4 내 옷장 (Closet)
- 옷 등록 플로우:
  1. 카메라 가이드 화면 (배경, 각도 안내)
  2. 촬영 또는 갤러리 선택
  3. 자동 배경 제거 (ML Kit Selfie Segmentation → on-device)
  4. 크롭/확인
  5. 카테고리 선택 (상의 / 하의 / 신발 / 악세사리)
  6. 색상, 이름 입력 (선택)
  7. Firebase Storage 업로드 + Firestore 저장
- 옷장 목록: 카테고리별 필터, 그리드 뷰
- 옷 삭제 가능

#### 2.5 코디 추천 (Recommendation Engine)
- **Phase 1 (MVP)**: 규칙 기반 추천
  - 온도 구간 × 날씨 유형 → 카테고리별 옷 필터링
  - 상의/하의/신발/악세사리 각 1개 무작위 조합
- **Phase 2 (v1.1)**: LLM 보조 추천
  - Claude Haiku 4.5 API 사용 (최저 비용)
  - 사용자 옷 목록 + 날씨 컨텍스트 → 추천 근거 포함
  - 호출은 캐시: 같은 날씨+옷장이면 재호출 안 함

#### 2.6 콜라주 생성
- 추천된 상의/하의/신발/악세사리 배경 제거 이미지를 조합
- 고정 레이아웃: 왼쪽 3칸(상의/하의/신발) + 오른쪽 2칸(외투/악세사리)
  ```
  ┌────────┬────────┐
  │  상의  │  외투  │
  ├────────┤        │
  │  하의  ├────────┤
  ├────────│악세사리│
  │  신발  │        │
  └────────┴────────┘
  ```
  - category 매핑: 왼쪽 → top/bottom/shoes, 오른쪽 → outer/accessory(bag 포함)
  - outer/accessory 없을 경우 해당 칸 빈 상태 or 숨김 처리
- on-device 생성 (collage_service.dart 활용)
- 결과 이미지를 로컬 갤러리에 저장 가능

#### 2.7 코디 저장 (Outfit)
- "오늘 이 코디 입었어요" → 날짜/날씨 스냅샷과 함께 저장
- 즐겨찾기 표시 (하트)
- 코디 기록 화면 (날짜별 리스트)

#### 2.8 추천 결과 수정 (낮은 우선순위, MVP 포함)
- 추천 코디에서 아이템 하나씩 교체 가능
- 교체한 조합을 저장 가능

### Post-launch (v1.1+)
- 즐겨찾기 코디 → 맞는 날씨 예보 시 푸시 알림
- LLM 추천 고도화 (착용 이력 학습)
- Android 지원
- 스타일 선호 태그 (미니멀, 캐주얼, 포멀 등)
- 소셜 공유

---

## 3. 기술 스택

| 영역 | 선택 | 이유 |
|------|------|------|
| Framework | Flutter 3.x | iOS/Android 크로스플랫폼, 기존 코드베이스 |
| State | Riverpod + riverpod_generator | 기존 선택, 코드 생성으로 보일러플레이트 최소화 |
| Navigation | go_router | 기존 선택 |
| Backend | Firebase (Auth, Firestore, Storage) | 서버리스, 비용 효율적 |
| 날씨 API | OpenWeatherMap (무료 티어) | 기존 구현 |
| 배경 제거 | ML Kit Selfie Segmentation | 온디바이스, 무료 |
| 캐릭터 이미지 | 로컬 번들 PNG (assets/characters/) | 서버 불필요, 오프라인 동작 |
| LLM (v1.1) | Claude Haiku 4.5 | 최저 비용 ($0.80/MTok input) |
| 이미지 캐시 | cached_network_image | 기존 |
| 코드 생성 | freezed + json_serializable | 기존 |

---

## 4. 데이터 모델

### GarmentModel (기존 확장)
```
id, userId, name, category (top/bottom/outer/dress/shoes/bag/accessory),
imageUrl (배경제거), thumbnailUrl, color, createdAt
```

### OutfitModel (기존 확장)
```
id, userId, garmentIds[], collageImageUrl,
wornAt, weatherSnapshot (temp, condition), isFavorite, note
```

---

## 5. 프로젝트 구조

```
lib/
├── core/
│   ├── constants/       # 온도 구간, 날씨 유형 상수
│   ├── errors/
│   └── utils/
├── data/
│   ├── models/          # GarmentModel, OutfitModel, WeatherSnapshot
│   ├── repositories/    # Firestore CRUD
│   └── (remote_config 미사용)
├── services/
│   ├── weather/         # OpenWeatherMap
│   ├── image/           # 배경제거, 콜라주
│   ├── recommendation/  # 규칙 기반 엔진
│   └── auth/
├── presentation/
│   ├── screens/
│   │   ├── home/        # 홈 (날씨 + 추천)
│   │   ├── closet/      # 옷장
│   │   ├── add_garment/ # 옷 등록
│   │   ├── outfit/      # 코디 저장/기록
│   │   ├── history/
│   │   └── auth/
│   ├── providers/
│   ├── widgets/
│   └── theme/
├── app_router.dart
└── main.dart
```

---

## 6. 코드 스타일

- **언어**: Dart, Flutter conventions 준수
- **모델**: freezed + json_serializable (불변 모델)
- **Provider**: `@riverpod` 어노테이션 사용, `_ref` 패턴
- **에러 처리**: `Either<Failure, T>` 패턴 (core/errors/failures.dart)
- **주석**: 비자명한 비즈니스 로직에만 한글 주석 허용
- **파일명**: snake_case, 기능명_타입.dart (예: `garment_repository.dart`)
- **임포트**: dart → flutter → 서드파티 → 내부 순

---

## 7. 테스트 전략

| 레이어 | 전략 |
|--------|------|
| 추천 엔진 | Unit test — 온도 구간별 추천 결과 검증 |
| Repository | Mock Firestore로 CRUD 검증 |
| 날씨 서비스 | Mock HTTP로 파싱 검증 |
| UI | Widget test (홈, 옷장 화면 핵심 상태) |
| E2E | 수동 (기기 테스트) — 배경 제거, 콜라주 생성 |

---

## 8. 경계 (Boundaries)

### Always (항상 할 것)
- 옷장이 비어있는 신규 유저에게 샘플 캐릭터 제공
- 날씨 API 실패 시 마지막 캐시된 날씨로 폴백
- 이미지 업로드 전 배경 제거 on-device 처리 (서버 비용 0)
- Firebase Security Rules로 userId 기반 데이터 격리

### Ask First (먼저 물어볼 것)
- LLM API 호출 비용이 예상보다 높을 때 호출 전략 변경
- 새 Firebase 인덱스 추가 (Firestore 비용 영향)
- 캐릭터 이미지 세트 확장 (디자인 결정)

### Never (하지 말 것)
- 유저 이미지를 학습 데이터로 외부 전송
- 로그인 강제 없이 익명 auth 없이 앱 시작 불가 처리 (Anonymous Auth는 항상 사용)
- 배경 제거에 외부 유료 API 사용 (ML Kit 온디바이스 고수)
- Android 지원을 위한 iOS 코드 타협 (출시 전)

---

## 9. MVP 태스크 우선순위 (5월 말 기준)

| 순서 | 태스크 | 현황 |
|------|--------|------|
| 1 | #14 Firebase 연결 완료 | ✅ 완료 |
| 2 | #05 이미지 업로드 (옷 등록 플로우) | 예정 |
| 3 | #08 콜라주 화면 | 예정 |
| 4 | #04 캐릭터 이미지 (로컬 PNG 번들) | ✅ 완료 |
| 5 | #09 코디 저장/불러오기 | 예정 |
| 6 | #11 전체 앱 구조 통합 | 예정 |
| 7 | #12 에러/로딩 처리 | 예정 |
| 8 | #10 스타일 선호 저장 | 예정 |
| 9 | #13 출시 준비 (App Store) | 예정 |

---

## 10. 비용 예측 (월간)

| 항목 | 예상 비용 |
|------|----------|
| Firebase Spark (무료 티어) | $0 (초기) |
| OpenWeatherMap Free | $0 |
| ML Kit (온디바이스) | $0 |
| Claude Haiku (v1.1, 1000 DAU) | ~$5-20/월 |
| **합계** | **$0 (MVP), ~$20 (v1.1)** |
