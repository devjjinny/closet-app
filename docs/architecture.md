# closet_app 아키텍처

## 레이어 구조

```
lib/
├── core/                          # 앱 전체 공유 상수·에러
│   ├── constants/
│   │   ├── enums.dart             # GarmentCategory, StyleTag, Season, Gender 등 열거형
│   │   └── app_constants.dart     # 문자열/숫자 상수
│   └── errors/
│       └── failures.dart          # 도메인 실패 타입
│
├── data/                          # 데이터 레이어
│   ├── models/                    # 불변 데이터 모델 (fromMap/toMap/copyWith)
│   │   ├── garment_model.dart     # GarmentModel, GarmentImage
│   │   ├── outfit_model.dart      # OutfitModel, OutfitCandidate
│   │   ├── user_model.dart        # UserPrefs (gender 포함)
│   │   ├── weather_snapshot.dart  # WeatherSnapshot (온도·강수·바람)
│   │   └── style_preference.dart  # StylePreference (선호 스타일 태그)
│   └── repositories/              # Firebase 읽기/쓰기 추상화
│       ├── garment_repository.dart # Firestore garments 컬렉션 CRUD + Storage
│       └── outfit_repository.dart  # Firestore outfits 컬렉션 CRUD + Storage
│
├── services/                      # 외부 의존 서비스
│   ├── auth/
│   │   └── auth_service.dart      # Firebase Auth (익명 로그인, 성별 저장)
│   ├── image/
│   │   ├── background_removal_service.dart  # ML Kit Selfie Segmentation (온디바이스)
│   │   └── collage_service.dart   # 콜라주 PNG 생성 (image 패키지, isolate)
│   ├── recommendation/
│   │   └── recommendation_engine.dart  # 룰 기반 코디 추천 (점수 계산)
│   ├── storage/
│   │   └── firebase_storage_service.dart  # Firebase Storage 업로드
│   └── weather/
│       └── weather_service.dart   # OpenWeatherMap API (Dio)
│
├── presentation/                  # UI 레이어
│   ├── providers/
│   │   └── providers.dart         # 전체 Riverpod provider 정의
│   ├── screens/
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart  # 성별 선택 (최초 1회)
│   │   ├── today_outfit/
│   │   │   └── today_outfit_screen.dart  # 홈: 날씨 + 스타일 칩 + 코디 추천
│   │   ├── closet/
│   │   │   └── closet_screen.dart  # 내 옷장 그리드
│   │   ├── add_garment/
│   │   │   ├── add_garment_screen.dart  # 옷 등록 (카메라/갤러리 + 배경제거)
│   │   │   └── camera_guide_screen.dart
│   │   ├── history/
│   │   │   └── history_screen.dart  # 코디 기록 (즐겨찾기, 삭제)
│   │   ├── auth/
│   │   │   └── auth_screen.dart   # 계정 전환 (deferred login)
│   │   └── shell_screen.dart      # BottomNavigationBar 쉘
│   ├── widgets/
│   │   ├── async_widgets.dart     # AppLoadingWidget, AppErrorWidget, AsyncValueX
│   │   ├── character_widget.dart  # 성별+날씨별 캐릭터 이미지 (assets/characters/)
│   │   └── collage_preview.dart   # CollagePreviewWidget (좌3칸 + 우2칸 레이아웃)
│   └── theme/
│       └── app_theme.dart         # 앱 테마 (primary: #6C5CE7)
│
├── app_router.dart                # go_router 설정 (온보딩 redirect 포함)
├── firebase_options.dart          # FlutterFire 자동 생성
└── main.dart                      # Firebase 초기화, 익명 자동 로그인
```

## Provider 의존 관계

```
stylePreferenceProvider (NotifierProvider)
    └── SharedPreferences

currentWeatherProvider (FutureProvider)
    └── weatherServiceProvider → OpenWeatherMap API
        └── Geolocator (위치 권한)

garmentsStreamProvider (StreamProvider)
    └── garmentRepositoryProvider
        └── storageServiceProvider (Firebase Storage)
            currentUidProvider → authStateProvider

recommendationsProvider (FutureProvider)
    ├── currentUidProvider
    ├── garmentsStreamProvider
    ├── currentWeatherProvider
    ├── outfitRepositoryProvider
    ├── recommendationEngineProvider
    └── stylePreferenceProvider   ← 스타일 선호 반영

outfitsStreamProvider (StreamProvider)
    └── outfitRepositoryProvider
        └── currentUidProvider
```

## 주요 설계 결정

| 결정 | 이유 |
|------|------|
| 익명 자동 로그인 | 가입 마찰 제거. 이탈률 낮추고, 나중에 계정 연결 유도 |
| ML Kit 온디바이스 배경제거 | 무료, 서버 불필요, 개인정보 보호 |
| 룰 기반 추천 (v1) | 초기 데이터 없이도 동작. v1.1에서 Claude Haiku LLM 추가 예정 |
| 콜라주 PNG 저장 시 생성 | 미리보기는 네트워크 썸네일, 저장 시에만 고화질 PNG 생성 |
| SharedPreferences (스타일·온보딩) | 네트워크 불필요한 로컬 상태. Firestore는 의상·코디 데이터만 |
| go_router redirect | onboarding_complete 플래그로 온보딩 완료 여부 판단 |

## 화면 흐름

```
앱 시작
  └── main.dart: Firebase 초기화 + 익명 자동 로그인
        └── app_router.dart
              ├── onboarding_complete == false → /onboarding (성별 선택)
              └── onboarding_complete == true  → /today (홈)
                    ├── /closet    (내 옷장)
                    │     └── /add-garment
                    ├── /history   (코디 기록)
                    └── /profile   (계정 전환, deferred login)
```

## 테스트 구조

```
test/unit/
├── models/         # 모델 직렬화·비즈니스 로직
├── recommendation/ # 추천 엔진 점수 계산
└── services/       # 서비스 단위 테스트 (collage, weather)
```
