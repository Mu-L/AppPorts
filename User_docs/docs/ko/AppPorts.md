---
outline: deep
---

# AppPorts 사용자 가이드

이 가이드는 AppPorts의 기능, 설계 원칙 및 기술 구현을 체계적으로 소개합니다. 더 자세한 기술 정보는 [DeepWiki](https://deepwiki.com/wzh4869/AppPorts)를 참조하세요. 개선 사항은 프로젝트 [Issues](https://github.com/wzh4869/AppPorts/issues)에 제출해 주세요.

## 개요

AppPorts는 [macOS](https://www.apple.com/macos/)를 위해 설계된 애플리케이션 마이그레이션 및 연결 도구로, 대용량 애플리케이션을 외장 저장소로 마이그레이션하면서 전체 시스템 기능과 일관성을 유지합니다.

### AppPorts 철학

| 원칙 | 설명 |
|------|------|
| **투명한 경험** | 사용자 경험과 운영 체제가 앱이 여전히 내부 저장소에서 실행되는 것처럼 인식하도록 보장 |
| **안정적 전략** | 검증된, 더 안정적인 마이그레이션 접근 방식을 우선시 |
| **낮은 시스템 부하** | 데몬 없음, 지속적인 시스템 리소스 소비 방지 |
| **폭넓은 국제화** | 더 많은 언어를 우선적으로 커버; 번역의 정확성보다 폭넓은 범위를 우선 |
| **접근성 친화적** | 포괄적인 접근성 지원 |

## 핵심 기능

- **Badge 없는 마이그레이션**: 대용량 앱을 외장 드라이브로 한 번의 클릭으로 마이그레이션. 로컬에는 가벼운 런처 셸만 유지; Finder에 바로가기 화살표가 표시되지 않음; Launchpad와 macOS 앱 메뉴가 정상적으로 동작.
- **자동 업데이트 보호**: 자동 업데이트를 지원하는 앱(Sparkle, Electron, Chrome 등)을 자동으로 감지하여, "잠금 마이그레이션" 옵션을 제공하여 자동 업데이트 프로그램이 외장 드라이브의 앱을 삭제하거나 덮어쓰는 것을 방지.
- **코드 서명 관리**: 마이그레이션 후 "손상됨" 메시지가 나타나면, 우클릭 메뉴를 통해 한 번의 클릭으로 재서명. 원본 서명의 백업 및 복원 지원; 데이터 디렉토리 마이그레이션 후 자동 재서명.
- **macOS 15.1+ App Store 지원**: App Store 앱을 외장 드라이브에 직접 설치하고 외장 드라이브에서 제자리 업데이트를 지원.
- **한 번의 클릭으로 복원**: 앱을 로컬 저장소로 다시 마이그레이션하고 자동으로 링크를 제거. 마이그레이션 중단 시 자동 복구.
- **데이터 디렉토리 관리**: 앱 데이터 디렉토리(`~/Library/` 하위 디렉토리, `~/.npm` 등)를 외장 저장소로 마이그레이션하며, 트리 뷰 그룹화, 검색, 정렬을 지원.

## 용어집

### 마이그레이션 전략

#### Deep Contents Wrapper (Contents 디렉토리 마이그레이션)

macOS 애플리케이션의 표준 파일 구조는 다음과 같습니다:

```text
/Applications/Safari.app/
├── Contents/
│   ├── MacOS/
│   ├── Resources/
│   ├── Frameworks/
│   └── Info.plist
└── ...
```

Deep Contents Wrapper 전략은 모든 애플리케이션 콘텐츠를 외장 저장소로 마이그레이션하고, 로컬에 빈 `.app` 디렉토리를 생성하여 외부의 `Contents` 디렉토리를 가리키는 심볼릭 링크만 포함합니다. macOS가 완전한 `.app` 패키지(바로가기가 아닌)를 감지하므로, Finder에 화살표 표시가 나타나지 않고; 아이콘, Launchpad, 앱 메뉴가 정상적으로 동작합니다.

::: warning ⚠️ 이 전략은 현재 버전에서 더 이상 사용되지 않습니다
Deep Contents Wrapper의 주요 결함은 자동 업데이트 프로그램이 심볼릭 링크를 따라 외장 저장소의 파일을 직접 수정하여 애플리케이션을 손상시킬 수 있다는 점입니다.
:::

#### Stub Portal

Stub Portal 방식은 로컬에 최소한의 `.app` 셸을 생성하며, 다음 네 가지 항목만 포함합니다:

| 구성 요소 | 설명 |
|-----------|------|
| `Contents/MacOS/launcher` | `open "/Volumes/External/SomeApp.app"`을 실행하는 Bash 런처 스크립트 |
| `Contents/Resources/` | 외부 애플리케이션에서 복사한 아이콘 파일 |
| `Contents/Info.plist` | 외부 앱의 `Info.plist`를 간소화하여, `CFBundleExecutable`을 `launcher`로 설정, `LSUIElement=true`로 설정(Dock에 표시 안 함), 모든 업데이트 관련 설정 키 제거 |
| `Contents/PkgInfo` | 표준 4바이트 식별자 파일 |

사용자가 이 셸을 클릭하면 macOS가 `launcher` 스크립트를 실행하여, `open` 명령을 통해 외장 드라이브의 실제 애플리케이션을 엽니다. 로컬에 심볼릭 링크가 존재하지 않으므로 자동 업데이트 프로그램이 침투할 수 없습니다.

##### iOS Stub Portal

기본 원리는 표준 Stub Portal과 동일하지만, 아이콘 처리 방식이 다릅니다. iOS 앱 아이콘은 `Info.plist`에 지정되지 않고 `Wrapper/` 또는 `WrappedBundle/` 디렉토리에 여러 개의 `AppIcon.png` 파일로 저장됩니다. 프로세스는 다음과 같습니다:

1. 가장 높은 해상도의 `AppIcon.png` 파일을 찾음
2. `sips`를 사용하여 256×256 픽셀로 크기 조정
3. `sips`를 사용하여 `.icns` 형식으로 변환
4. `iTunesMetadata.plist`에서 `Info.plist` 생성 (iOS 앱은 표준 `Info.plist`를 포함하지 않음)

#### Whole Symlink

전체 `.app` 디렉토리를 외장 저장소를 가리키는 심볼릭 링크로 생성합니다:

```text
/Applications/SomeApp.app → /Volumes/External/SomeApp.app
```

로컬에는 심볼릭 링크만 유지되며 실제 파일은 없습니다. macOS는 앱을 정상적으로 열 수 있지만, Finder에 아이콘에 화살표 바로가기 표시가 나타나며, Launchpad에 때때로 호환성 문제가 발생합니다. 자동 업데이트 프로그램도 심볼릭 링크를 통해 외부 앱 파일을 조작할 수 있습니다. 이는 AppPorts의 대체 마이그레이션 전략입니다.
