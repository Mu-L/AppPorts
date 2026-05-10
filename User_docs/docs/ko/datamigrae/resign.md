---
outline: deep
---

# 재서명 및 충돌 방지

![](https://pic.cdn.shimoko.com/appports/%E6%88%AA%E5%B1%8F2026-05-08%2008.38.37.png)

## 데이터 마이그레이션 후 앱이 충돌하는 이유

macOS의 코드 서명 메커니즘(`codesign`)은 애플리케이션 패키지의 무결성을 검증하며, 파일 경로 구조를 포함합니다. AppPorts가 앱의 데이터 디렉토리를 외장 저장소로 마이그레이션하고 심볼릭 링크로 대체하면 서명 봉인이 깨져 다음 문제가 발생합니다:

- **Gatekeeper 차단**: `codesign --verify --deep --strict`가 서명 실패를 감지; 시스템에 "손상됨" 또는 "확인되지 않은 개발자" 대화 상자가 표시되어 앱 실행이 차단
- **Keychain 접근 장애**: Keychain 접근 그룹에 의존하는 앱이 서명 ID 변경으로 인해 저장된 자격 증명을 읽을 수 없음
- **Entitlements 실패**: 일부 앱 entitlements는 서명 ID에 바인딩됨; 서명 변경 후 entitlements 불일치 발생

### 고위험 앱 유형

| 앱 유형 | 위험 수준 | 이유 |
|---------|----------|------|
| Sparkle 자체 업데이트 앱 | **높음** | 업데이터가 앱을 삭제하거나 대체하여 심볼릭 링크를 손상시킬 수 있음 |
| Electron 자체 업데이트 앱 | **높음** | `electron-updater`도 외장 저장소의 앱을 방해할 수 있음 |
| Keychain 의존 앱 | **높음** | Ad-hoc 서명이 서명 ID를 변경; Keychain 접근 그룹이 실패 |
| Mac App Store 앱 | **높음** | SIP 보호; 재서명 불가 |
| 네이티브 자체 업데이트 앱 (Chrome, Edge) | 중간 | 자체 업데이트가 외부 복사본을 대체하여 로컬 엔트리를 무효화할 수 있음 |
| iOS 앱 (Mac 버전) | 낮음 | Stub Portal 또는 whole symlink 사용; 서명 문제가 적음 |

### 고위험 데이터 디렉토리 유형

| 데이터 유형 | 위험 수준 | 이유 |
|------------|----------|------|
| `~/Library/Application Support/` | 중간 | 앱이 파일 잠금, SQLite WAL 로그 또는 확장 속성을 사용할 수 있음; 심볼릭 링크를 통해 비정상적으로 동작할 수 있음 |
| `~/Library/Group Containers/` | 중간 | 동일 Team 하위의 여러 앱이 공유; 심볼릭 링크가 다른 앱을 방해할 수 있음 |
| `~/Library/Preferences/` | 낮음~중간 | `cfprefsd`가 plist 파일을 캐싱; 심볼릭 링크가 오래된 데이터를 읽을 수 있음 |
| `~/Library/Caches/` | 낮음 | 캐시는 재구성 가능; 대부분의 앱이 캐시 부재를 우아하게 처리 |

## 재서명 메커니즘

### Ad-hoc 서명

AppPorts는 마이그레이션 후 앱 서명을 수정하기 위해 **Ad-hoc 서명**(인증서 없는 로컬 서명)을 사용합니다. 실행 명령:

```bash
codesign --force --deep --sign - <앱 경로>
```

여기서 `-`는 Ad-hoc 서명(개발자 인증서 없이)을 나타냅니다.

### 서명 흐름

```mermaid
flowchart TD
    A[재서명 시작] --> B[원본 서명 ID 백업]
    B --> C{앱이 잠겨 있나?}
    C -->|예| D[uchg 플래그를 일시적으로 해제]
    C -->|아니오| E{앱이 쓰기 가능한가?}
    D --> E
    E =>|쓰기 불가 & root 소유| F[관리자 권한으로 소유권 변경 시도]
    E =>|쓰기 가능| G[확장 속성 정리]
    F --> G
    F -->|실패 & MAS 앱| H[서명 건너뜀 - SIP 보호]
    G --> I[번들 루트 디렉토리 잔여 파일 정리]
    I --> J{Contents가 심볼릭 링크인가?}
    J =>|예| K[실제 디렉토리 복사본으로 일시 교체]
    J =>|아니오| L[딥 서명 실행]
    K --> L
    L =>|실패| M[얕은 서명으로 대체]
    L =>|성공| N{Contents가 일시 교체되었나?}
    M --> N
    N =>|예| O[심볼릭 링크 복원]
    N =>|아니오| P[uchg 플래그 재잠금]
    O --> P
    P => Q[서명 완료]
```

### 핵심 단계

1. **원본 서명 ID 백업**: 서명 전 앱의 현재 서명 ID를 읽고(`codesign -dvv`로 `Authority=` 라인 파싱), `~/Library/Application Support/AppPorts/signature-backups/<BundleID>.plist`에 저장

2. **확장 속성 정리**: `xattr -cr`를 실행하여 리소스 포크, Finder 정보 등을 제거하고 서명 시 "detritus not allowed" 오류 방지

3. **번들 루트 디렉토리 정리**: `.DS_Store`, `__MACOSX`, `.git`, `.svn` 등의 잔여 파일 제거

4. **심볼릭 링크 Contents 처리**: `Contents/`가 심볼릭 링크인 경우(Deep Contents Wrapper 전략), 실제 디렉토리 복사본으로 일시 교체한 후 서명이 완료되면 심볼릭 링크 복원

5. **딥 서명 → 얕은 서명 대체**: `--deep` 서명(모든 중첩 구성 요소 포함)을 우선 시도; 권한 또는 리소스 포크 문제로 실패하면 `--deep` 없이 얕은 서명으로 대체

6. **재시도 메커니즘**: `codesign`가 "internal error"를 생성하거나 SIGKILL로 종료되면 최대 2회 재시도

## 서명 백업 및 복원

### 연결된 앱 경로 해결

연결된 앱 (상태: 'Linked')의 경우, 서명 작업은 로컬 Stub Portal 셸이나 심볼릭 링크가 아닌 **외부 실제 앱 경로**를 자동으로 해결합니다. 해결 방법:

| 마이그레이션 방식 | 해결 방법 |
|-----------------|----------|
| Whole App Symlink | 심볼릭 링크 대상을 해결하여 외부 실제 `.app` 경로 반환 |
| Stub Portal | `Contents/MacOS/launcher` 스크립트에서 `REAL_APP='...'` 경로 추출 |

즉, 백업, 복원, 재서명 작업은 항상 실제 애플리케이션 패키지를 대상으로 하여 서명 변경이 확실히 적용됩니다.

### 백업

백업 파일은 `~/Library/Application Support/AppPorts/signature-backups/` 디렉토리에 **실제 앱의** `BundleID.plist`로 저장됩니다:

| 필드 | 설명 |
|------|------|
| `bundleIdentifier` | 앱의 Bundle ID |
| `signingIdentity` | 원본 서명 ID (예: `Developer ID Application: ...` 또는 `ad-hoc`) |
| `originalPath` | 원본 앱 경로 |
| `backupDate` | 백업 타임스탬프 |

백업은 다음 시점에 트리거됩니다:

- 데이터 디렉토리 마이그레이션 전 (자동 재서명이 활성화된 경우) — 실제 앱 경로를 사용하여 백업
- 모든 서명 작업 전 (멱등성; 기존 백업을 덮어쓰지 않음)
- 수동 '서명 백업' 액션

### 복원

서명 복원 시 AppPorts는 백업된 서명 ID에 따라 다른 전략을 실행합니다:

| 백업된 서명 ID | 복원 동작 |
|----------------|----------|
| `ad-hoc` 또는 비어 있음 | `codesign --remove-signature`을 실행하여 서명 제거; 백업 삭제 |
| 유효한 개발자 인증서 ID | Keychain에 인증서가 존재하는지 확인. 존재하면 원본 ID로 재서명 |
| 유효한 개발자 인증서 ID이지만 이 머신에 인증서 없음 | **Ad-hoc 서명으로 대체**; 원본 서명을 완전히 복원할 수 없음 |

### 복원 실패 시나리오

다음 시나리오는 서명 복원 실패 또는 불완전함을 유발합니다:

| 시나리오 | 결과 |
|----------|------|
| 백업 plist 파일이 존재하지 않음 | `noBackupFound` 오류 발생; 복원 불가 |
| 원본 개발자 인증서가 로컬 Keychain에 없음 | Ad-hoc 서명으로 대체. 앱 실행 가능하지만 Keychain 접근 그룹 및 일부 entitlements가 실패할 수 있음 |
| Mac App Store 앱 (SIP 보호) | 자동으로 건너뜀. SIP가 시스템 앱 서명의 모든 수정을 방지 |
| 앱 디렉토리가 쓰기 불가 & root 소유 | 관리자 권한으로 소유권 변경 시도. 사용자가 인증 프롬프트를 취소하면 실패 |
| Contents 심볼릭 링크 대상을 찾을 수 없음 | 일시 교체 단계에서 `copyItem` 실패; 서명 실행 불가 |
| 사용자가 관리자 인증을 취소함 | `codesignFailed("User cancelled authorization")` 오류 발생 |
| 딥 서명과 얕은 서명 모두 실패 | 오류가 상위로 전파; 서명 작업 실패 |

::: warning ⚠️ 개발자 인증서 분실에 관하여
가장 일반적인 실제 복원 실패 시나리오는: 원본 앱이 서드파티 개발자(예: `Developer ID Application: Google LLC`)에 의해 서명되었지만, 현재 머신의 Keychain에 해당 개인 키가 없는 경우입니다. 이 경우 복원 작업은 Ad-hoc 서명만 생성할 수 있으며; **원본 서명 ID를 완전히 복원할 수 없습니다**. 특정 서명 ID에 의존하는 Keychain 접근 그룹 또는 기업 구성 프로파일을 사용하는 앱은 기능 이상이 발생할 수 있습니다.
:::
