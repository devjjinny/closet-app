# closet_app 백로그

## 진행 중

## 예정

### Phase D — Claude 디자인/스펙 변경 반영
- [x] 🟢 #D01 디자인 토큰/라벤더 테마 적용
- [x] 🟢 #D02 하단 탭 `홈 / 옷장 / + / 기록` 구조 반영
- [x] 🟢 #D03 홈 화면 HomeB 콜라주 중심 개편
- [x] 🟢 #D04 옷장 화면 ClosetA/D 기반 개편
- [x] 🟢 #D05 옷 등록 AddA/B 기반 개편
- [x] 🟢 #D06 카메라 가이드 AddA viewfinder 스타일 적용
- [x] 🟢 #D07 컷아웃 보정 AddC 스타일 적용
- [x] 🟢 #D08 기록 화면 HistB 룩북 그리드 적용
- [x] 🟢 #D09 기록 필터 실제 동작 연결
- [x] 🟢 #D10 기록 월간 캘린더 뷰 추가 (HistA)
- [x] 🟢 #D11 기록 리포트/인사이트 뷰 추가 (HistD)
- [x] 🟢 #D12 추천 코디 “이대로 입었어요” 저장 플로우 추가 (SaveC)
- [x] 🟢 #D13 오늘 입은 옷 옷장 멀티 셀렉트 저장 추가 (SaveB)
- [x] 🟢 #D14 OOTD 사진 핀 태그 저장 플로우 추가 (SaveA)
- [x] 🟢 #D15 여러 벌 한번에 등록 추가 (AddD)
- [x] 🟢 #D16 옷장 검색 실제 동작 연결
- [x] 🟢 #D17 옷장 컬러 톤/워드로브 분석 추가 (ClosetB)
- [x] 🟢 #D18 옷장 착용 빈도/마지막 착용일 리스트 추가 (ClosetC)
- [x] 🟢 #D19 `나` 탭/설정 화면 추가 여부 결정 및 구현

### Phase 1 — 기술 선결 조건 (5/5-11)
- [ ] 🟠 #M02 API 키 --dart-define 이전 (현재 하드코딩)
- [ ] 🟡 #M03 unawaited_futures 경고 수정 (6건)

### Phase 2 — 캐릭터·에셋 (5/12-18)
- [ ] 🟠 #M04 앱 아이콘 신규 디자인 + flutter_launcher_icons 통합 [외부 작업 필요]
- [ ] 🟠 #M05b 캐릭터 이미지 18개 디자인 [외부 작업]
- [ ] 🟡 #M05c assets 교체 (18개 PNG → assets/characters/)
- [ ] 🟠 #M07 개인정보 처리방침 작성 + GitHub Pages 호스팅

### Phase 3 — App Store Connect & TestFlight (5/19-25)
- [ ] 🟠 #M08 Apple Developer Bundle ID 등록 [수동]
- [ ] 🟠 #M09 App Store Connect 앱 등록
- [ ] 🟡 #M10 스크린샷 촬영 (6.9인치, 6.1인치)
- [ ] 🟠 #M11 TestFlight 내부 테스터 배포

### Phase 4 — 심사 제출 (5/26-31)
- [ ] 🟠 #M12 TestFlight 피드백 반영 + 최종 빌드
- [ ] 🟠 #M13 App Store 심사 제출
- [ ] 🟡 #M14 출시 결정 (즉시 / 날짜 예약)

## 완료
- [x] #M06 스플래시 화면 구성 (flutter_native_splash)
- [x] #M05a character_widget.dart 코드 변경 (temperatureBand 8단계)
- [x] #M01 iOS 배포 타겟 통일 (pbxproj 13.0 → 15.5)
- [x] #15 온도 추천 테스트 (temperatureBand 8단계 / 아우터 기준 12°C unit test)
- [x] #16 warmth 등록 UI (옷 등록 시 warmth 1-5 탭 선택 + 온도/아이템 설명)
- [x] #01 날씨 API
- [x] #02 온도 구간 추천
- [x] #07 옷 데이터 모델
- [x] #14 Firebase 연결 설정
- [x] #05 이미지 업로드
- [x] #08 콜라주 화면
- [x] #09 코디 저장 / 불러오기
- [x] #12 에러 / 로딩 처리
- [x] #03 홈 화면 (TodayOutfitScreen으로 구현됨)
- [x] #06 배경 제거 서버 (ML Kit 온디바이스로 대체)
- [x] #10 스타일 선호 저장
- [x] #11 전체 앱 구조
- [x] #13 출시 준비
- [x] #04 캐릭터 이미지 (로컬 PNG, 플레이스홀더 포함 — 일러스트는 TODO_manual.md 참고)
