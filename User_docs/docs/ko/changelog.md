---
outline: deep
---

# 변경 이력

## v1.5.5

현재 버전.

## v1.5.0

- macOS 15.1+ App Store 앱 외장 설치 지원 추가
- 자동 재서명 기능 추가 (데이터 디렉토리 마이그레이션 후 자동 실행)
- `LocalizationAuditTests` 현지화 감사 테스트 추가
- Stub Portal Info.plist 생성 로직 개선
- 마이그레이션 후 일부 앱의 Launchpad 아이콘 손실 문제 수정

## v1.4.0

- 데이터 디렉토리 트리 뷰 추가
- 도구 디렉토리 감지 추가 (30개 이상의 개발 도구)
- 진단 패키지 내보내기 기능 추가
- 자체 업데이트 감지 개선 (Chrome, Edge 및 기타 커스텀 업데이터)
- 마이그레이션 중단 후 자동 복구 메커니즘 수정

## v1.3.0

- 데이터 디렉토리 마이그레이션 기능 추가
- 코드 서명 관리 추가 (원본 서명 백업/복원)
- Sparkle 및 Electron 앱 자동 감지 추가
- 잠금 마이그레이션 보호 개선 (`chflags uchg`)
- Finder의 배지 표시 문제 수정

## v1.2.0

- Stub Portal 마이그레이션 전략 추가 (Deep Contents Wrapper 대체)
- iOS 앱 마이그레이션 지원 추가 (Mac 버전 iOS 앱)
- 일괄 마이그레이션 성능 개선
- 복원 후 일부 앱이 실행되지 않는 문제 수정

## v1.1.0

- 다국어 지원 추가 (20개 이상의 언어)
- 앱 스위트 디렉토리 마이그레이션 추가 (예: Microsoft Office)
- 외장 저장소 오프라인 감지 개선
- Deep Contents Wrapper 전략의 심볼릭 링크 침투 문제 수정

## v1.0.0

- 첫 공식 릴리스
- 앱을 외장 저장소로 마이그레이션 지원 (Deep Contents Wrapper / Whole App Symlink)
- 앱 복원 및 링크 관리 지원
- FolderMonitor 실시간 파일 시스템 모니터링 지원
