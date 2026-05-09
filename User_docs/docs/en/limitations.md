---
outline: deep
---

# Compatibility & Limitations

## System Requirements

| Requirement | Description |
|-------------|-------------|
| Minimum OS Version | macOS 12.0 (Monterey) |
| Architecture | Intel x86_64 / Apple Silicon (arm64) |
| Permissions | Full Disk Access |
| External Storage | At least one external storage device required |

## Feature Compatibility

### By macOS Version

| Feature | macOS 12.0 - 15.0 | macOS 15.1+ |
|---------|:---:|:---:|
| App Migration (Stub Portal) | ✓ | ✓ |
| Data Directory Migration | ✓ | ✓ |
| Code Signature Management | ✓ | ✓ |
| App Store App Migration to External Drive | ✗ | ✓ |
| App Store App In-Place Update on External Drive | ✗ | ✓ |
| iOS App Migration | ✓ | ✓ |

::: warning ⚠️ App Store Apps on macOS Versions Below 15.1
macOS versions before 15.1 (Sequoia) do not support App Store app installation to external drives. You need to manually enable "App Store App Migration" in AppPorts settings, and app updates require manual re-migration to overwrite.
:::

### By App Type

| App Type | Migration | Restore | Auto-Update | Notes |
|----------|:---:|:---:|:---:|-------|
| Native macOS app | ✓ | ✓ | ✓ | Best compatibility |
| Sparkle app | ✓ | ✓ | Requires lock | Lock prevents in-app updates; must restore to update |
| Electron app | ✓ | ✓ | Requires lock | Same as Sparkle |
| Chrome / Edge (custom updater) | ✓ | ✓ | ✓ | Updater installs to local; does not damage external copy |
| App Store app (macOS 15.1+) | ✓ | ✓ | ✓ | Native external installation; App Store can update directly |
| App Store app (macOS <15.1) | ✓ | ✓ | Manual | Updates require re-migration |
| iOS app (Mac version) | ✓ | ✓ | ✓ | Uses iOS Stub Portal |
| System apps | ✗ | — | — | SIP protection; cannot be migrated |

### By Data Directory Type

| Data Directory Type | Migration | Risk |
|--------------------|:---:|------|
| `~/Library/Application Support/` | ✓ | Medium — may use file locks or SQLite WAL logs |
| `~/Library/Preferences/` | ✓ | Low-Medium — `cfprefsd` caching may cause stale reads |
| `~/Library/Containers/` | ✓ | Medium — shared by apps under the same Team |
| `~/Library/Group Containers/` | ✓ | Medium — shared data may interfere with other apps |
| `~/Library/Caches/` | ✓ | Low — caches are rebuildable |
| `~/Library/Logs/` | ✓ | Low — log files only |
| `~/Library/WebKit/` | ✓ | Medium — WebKit local storage |
| `~/Library/HTTPStorages/` | ✓ | Low — network session storage |
| `~/Library/Application Scripts/` | ✓ | Low — extension scripts |
| `~/Library/Saved Application State/` | ✓ | Low — window state restoration |
| `~/.npm`, `~/.m2` etc. dot-folder | ✓ | Low — development tool caches |

## Non-migratable Content

### SIP Protected

| Path | Reason |
|------|--------|
| macOS system apps (Safari, Finder, etc.) | System Integrity Protection |
| `~/Library/Containers/` top-level directory | macOS system protection |

### Contains Path References

| Path | Reason |
|------|--------|
| `~/.local` | Contains executable path references; command-line tools may fail after migration |
| `~/.config` | Contains absolute path configurations; tool configurations may fail after migration |

## External Storage Requirements

| Requirement | Description |
|-------------|-------------|
| File System | APFS, HFS+, exFAT supported |
| Minimum Space | Depends on migrated app sizes |
| Interface | USB, Thunderbolt, NVMe all supported |
| Stay Connected | External storage must remain connected after migration; otherwise apps cannot launch |

::: tip 💡 File System Recommendations
- **APFS**: Recommended; supports clones, snapshots, best performance
- **HFS+**: Good compatibility; suitable for older Macs
- **exFAT**: Cross-platform compatible; does not support hard links and clones
:::
