# 수동으로 해야 할 작업들

> 코드로 처리할 수 없는 작업들. 확인하면 체크 해주세요.

---

## Firebase Console 설정

### 익명 인증 활성화
- [ ] [Firebase Console](https://console.firebase.google.com) → 프로젝트 `closet-app-mvp`
- [x] Authentication → Sign-in method → Anonymous → 사용 설정

### Firestore 규칙 배포
- [x] `firebase deploy --only firestore:rules` 실행
- [x] Firestore → Rules 탭에서 반영 확인

### Firebase Storage 규칙 배포
- [x] `firebase deploy --only storage` 실행

---

## API 키 설정

### OpenWeatherMap API 키
- [x] OpenWeatherMap API 키 앱에 등록 완료

---

## iOS 설정

### 위치 권한 문구 확인
- [x] `ios/Runner/Info.plist` → `NSLocationWhenInUseUsageDescription` 문구 자연스러운지 확인
- [x] 현재 값: `"현재 위치의 날씨를 가져옵니다"`

### 카메라/갤러리 권한 문구 확인
- [x] `NSCameraUsageDescription` — `"옷 사진 촬영에 카메라를 사용합니다"` 확인 완료
- [x] `NSPhotoLibraryUsageDescription` — `"앨범에서 옷 사진을 선택합니다"` 확인 완료

---

## 향후 확인 필요

### #04 캐릭터 이미지 교체 (현재 컬러 플레이스홀더 → 실제 일러스트)
- [ ] 캐릭터 일러스트 8개 제작 (PNG, 200×260px 이상, 배경 투명)
  - `assets/characters/male_sunny.png`
  - `assets/characters/male_cloudy.png`
  - `assets/characters/male_rainy.png`
  - `assets/characters/male_cold.png`
  - `assets/characters/female_sunny.png`
  - `assets/characters/female_cloudy.png`
  - `assets/characters/female_rainy.png`
  - `assets/characters/female_cold.png`
- [ ] 파일 교체 후 `flutter pub get` 및 앱 재빌드

### App Store Connect (출시 준비 - #13 때)
- [ ] 앱 등록
- [ ] 개인정보 처리방침 URL 준비
- [ ] 스크린샷 준비 (6.7인치, 6.1인치)
