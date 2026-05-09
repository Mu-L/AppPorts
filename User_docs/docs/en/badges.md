---
outline: deep
---

# Status Badges

AppPorts displays the current status of apps and data directories using capsule-shaped colored badges. Some badges are clickable for detailed information.

## App Status Badges

### Link Status

| Badge | Icon | Color | Meaning |
|-------|------|-------|---------|
| Linked | `link` | Green | App migrated to external storage with local entry |
| Locked Migration | `lock.fill` | Green | Linked and locked with `uchg`, preventing self-updates from damaging external app |
| Unlocked Migration | `lock.open` | Orange | Linked but not locked; in-app updates may delete external app |
| Partial Link | `link.badge.plus` | Yellow | Partial app components linked (e.g., some `.app` files in a directory) |
| Orphan Link | `link.badge.exclamationmark` | Red | External storage app lost but local entry still exists |
| Unlinked | `externaldrive.badge.xmark` | Orange | App on external storage but not linked back locally |
| External | `externaldrive` | Orange | App on external storage with no local entry |
| Local | `macmini` | Secondary color | Regular local app, not migrated; shown when no other tags present |

### Framework Labels

| Badge | Icon | Color | Meaning | Click Action |
|-------|------|-------|---------|-------------|
| Sparkle | `arrow.triangle.2.circlepath` | Cyan | Uses Sparkle framework for auto-updates | After migrating to external storage, in-app updates may cause external app loss; locked migration recommended |
| Electron | `atom` | Indigo | Based on Electron framework with auto-update support | After migrating to external storage, in-app updates may cause external app loss; locked migration recommended |

### Type Labels

| Badge | Icon | Color | Meaning |
|-------|------|-------|---------|
| Running | `play.fill` | Purple | App currently running |
| System | `lock.fill` | Gray | macOS system application |
| Non-native | `iphone` | Pink | iOS/iPadOS app (running via Apple Silicon) |
| Store | `applelogo` | Blue | Mac App Store application |

### Special Labels

| Badge | Icon | Color | Meaning |
|-------|------|-------|---------|
| Re-signed | `seal.fill` | Cyan | App has been Ad-hoc re-signed (executed when "Damaged" appears after migration) |

::: tip 💡 Special Note on Store Label
When an app meets the following conditions, the "Store" label becomes clickable and displays macOS 15.1+ native installation instructions:
- App is located in the `/Volumes/{drive}/Applications/` directory on external storage
- Natively managed by macOS; App Store can perform incremental updates directly in this directory
:::

## Data Directory Status Badges

| Status | Color | Meaning |
|--------|-------|---------|
| Local | Secondary color | Directory on local storage, not migrated |
| Linked | Green | Migrated to external storage; local is a symbolic link |
| Needs Normalization | Yellow | AppPorts-managed link, but external path not at canonical location; "Normalize" operation recommended |
| Needs Relinking | Orange | External storage data exists but local symbolic link lost; "Relink" operation recommended |
| Existing Soft Link | Blue | User-created symbolic link (not created by AppPorts); option to take over management |

## App Status Combinations

An app may display multiple badges simultaneously:

```text
[Linked] [Sparkle] [Running]
```
Meaning: App migrated to external storage, uses Sparkle auto-update framework, currently running.

```text
[External] [Store] [Non-native]
```
Meaning: iOS app (Mac version) on external storage, installed via App Store.

```text
[Orphan Link]
```
Meaning: External storage app lost or removed, but local entry still retained. Manual unlinking required.
