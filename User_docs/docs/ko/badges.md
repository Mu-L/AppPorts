---
outline: deep
---

# 상태 배지

AppPorts는 캡슐 형태의 컬러 배지를 사용하여 앱과 데이터 디렉토리의 현재 상태를 표시합니다. 일부 배지를 클릭하면 상세 정보를 확인할 수 있습니다.

## 앱 상태 배지

### 링크 상태

| 배지 | 아이콘 | 색상 | 의미 |
|------|--------|------|------|
| Linked | `link` | 녹색 | 앱이 외장 저장소로 마이그레이션되었으며 로컬 엔트리가 있음 |
| Locked Migration | `lock.fill` | 녹색 | 링크됨 및 `uchg`로 잠금, 자체 업데이트가 외부 앱을 손상시키는 것을 방지 |
| Unlocked Migration | `lock.open` | 주황색 | 링크되었으나 잠기지 않음; 앱 내부 업데이트가 외부 앱을 삭제할 수 있음 |
| Partial Link | `link.badge.plus` | 노란색 | 일부 앱 구성 요소만 링크됨 (예: 디렉토리 내 일부 `.app` 파일) |
| Orphan Link | `link.badge.exclamationmark` | 빨간색 | 외장 저장소 앱이 손실되었지만 로컬 엔트리가 여전히 존재 |
| Unlinked | `externaldrive.badge.xmark` | 주황색 | 외장 저장소에 앱이 있지만 로컬에 링크되지 않음 |
| External | `externaldrive` | 주황색 | 외장 저장소에 앱이 있고 로컬 엔트리가 없음 |
| Local | `macmini` | 보조 색상 | 일반 로컬 앱, 마이그레이션되지 않음; 다른 태그가 없을 때 표시 |

### 프레임워크 라벨

| 배지 | 아이콘 | 색상 | 의미 | 클릭 동작 |
|------|--------|------|------|----------|
| Sparkle | `arrow.triangle.2.circlepath` | 청록색 | 자동 업데이트를 위해 Sparkle 프레임워크 사용 | 외장 저장소로 마이그레이션 후 앱 내부 업데이트가 외부 앱 손실을 유발할 수 있으므로 잠금 마이그레이션 권장 |
| Electron | `atom` | 남보라색 | 자동 업데이트를 지원하는 Electron 프레임워크 기반 | 외장 저장소로 마이그레이션 후 앱 내부 업데이트가 외부 앱 손실을 유발할 수 있으므로 잠금 마이그레이션 권장 |

### 유형 라벨

| 배지 | 아이콘 | 색상 | 의미 |
|------|--------|------|------|
| Running | `play.fill` | 보라색 | 현재 실행 중인 앱 |
| System | `lock.fill` | 회색 | macOS 시스템 애플리케이션 |
| Non-native | `iphone` | 분홍색 | iOS/iPadOS 앱 (Apple Silicon을 통해 실행) |
| Store | `applelogo` | 파란색 | Mac App Store 애플리케이션 |

### 특수 라벨

| 배지 | 아이콘 | 색상 | 의미 |
|------|--------|------|------|
| Re-signed | `seal.fill` | 청록색 | 앱이 Ad-hoc 재서명됨 (마이그레이션 후 "손상됨"이 나타날 때 실행) |

::: tip 💡 Store 라벨에 대한 특별 참고
앱이 다음 조건을 충족하면 "Store" 라벨이 클릭 가능해지며 macOS 15.1+ 네이티브 설치 안내가 표시됩니다:
- 앱이 외장 저장소의 `/Volumes/{drive}/Applications/` 디렉토리에 위치
- macOS에 의해 네이티브하게 관리됨; App Store가 이 디렉토리에서 직접 증분 업데이트를 수행할 수 있음
:::

## 데이터 디렉토리 상태 배지

| 상태 | 색상 | 의미 |
|------|------|------|
| Local | 보조 색상 | 로컬 저장소의 디렉토리, 마이그레이션되지 않음 |
| Linked | 녹색 | 외장 저장소로 마이그레이션됨; 로컬은 심볼릭 링크 |
| Needs Normalization | 노란색 | AppPorts가 관리하는 링크이지만 외부 경로가 표준 위치에 있지 않음; "정규화" 작업 권장 |
| Needs Relinking | 주황색 | 외장 저장소 데이터가 존재하지만 로컬 심볼릭 링크가 손실됨; "재링크" 작업 권장 |
| Existing Soft Link | 파란색 | 사용자가 생성한 심볼릭 링크 (AppPorts가 생성하지 않음); 관리 전환 옵션 제공 |

## 앱 상태 조합

앱은 여러 배지를 동시에 표시할 수 있습니다:

```text
[Linked] [Sparkle] [Running]
```
의미: 앱이 외장 저장소로 마이그레이션되었으며, Sparkle 자동 업데이트 프레임워크를 사용하고, 현재 실행 중.

```text
[External] [Store] [Non-native]
```
의미: 외장 저장소에 있는 iOS 앱(Mac 버전), App Store를 통해 설치됨.

```text
[Orphan Link]
```
의미: 외장 저장소 앱이 손실되거나 제거되었지만 로컬 엔트리가 여전히 유지됨. 수동으로 링크 해제가 필요합니다.
