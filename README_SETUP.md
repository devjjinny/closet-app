# 옷장 앱 (Closet App) - 셋업 가이드

## 사전 요구사항
- Flutter SDK 3.24.x
- Firebase CLI (`npm install -g firebase-tools`)
- Xcode (iOS) / Android Studio (Android)

## 1. Firebase 프로젝트 설정

```bash
# Firebase 로그인
firebase login

# 프로젝트에서 Firebase 초기화
cd closet_app
firebase init
# Firestore, Storage, Auth 선택

# FlutterFire CLI 설치 및 설정
dart pub global activate flutterfire_cli
flutterfire configure
```

## 2. OpenWeather API Key 설정

1. https://openweathermap.org/api 에서 API key 발급
2. 실행 시 환경변수로 전달:

```bash
OPENWEATHER_API_KEY=your_api_key_here tool/run.sh
```

직접 Flutter 명령을 실행할 때는 아래처럼 전달합니다.

```bash
flutter run --dart-define=OPENWEATHER_API_KEY=your_api_key_here
flutter build ipa --release --dart-define=OPENWEATHER_API_KEY=your_api_key_here
```

## 3. 의존성 설치 및 빌드

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 4. 보안 규칙 배포

```bash
firebase deploy --only firestore:rules,storage
```

## 5. 실행

```bash
# iOS
OPENWEATHER_API_KEY=your_api_key_here tool/run.sh -d ios

# Android
OPENWEATHER_API_KEY=your_api_key_here tool/run.sh -d android
```

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── app_router.dart              # go_router 설정
├── core/
│   ├── constants/               # 상수, 열거형
│   └── errors/                  # Failure 타입
├── data/
│   ├── models/                  # Firestore 모델
│   └── repositories/            # 데이터 접근 계층
├── services/
│   ├── auth/                    # Firebase Auth
│   ├── weather/                 # OpenWeather API + 캐싱
│   ├── image/                   # 배경제거, 콜라주, 썸네일
│   ├── recommendation/          # 룰 기반 추천 엔진
│   └── storage/                 # Firebase Storage
└── presentation/
    ├── providers/               # Riverpod providers
    ├── screens/                 # UI 화면
    ├── widgets/                 # 공통 위젯
    └── theme/                   # 앱 테마
```
