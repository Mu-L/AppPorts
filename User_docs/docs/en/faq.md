---
outline: deep
---

# FAQ

## Installation & Authorization

### What permissions does AppPorts need?

AppPorts needs **Full Disk Access** permission to read and modify the `/Applications` directory. On first launch, it will guide you through authorization. You can also manually add it in System Settings → Privacy & Security → Full Disk Access.

### Which macOS versions are supported?

Minimum support is macOS 12.0 (Monterey). macOS 15.1 (Sequoia) and later additionally support App Store app installation to external drives with in-place updates.

## App Migration

### What if the app won't open after migration?

1. Confirm external storage is connected and accessible
2. Check app status badge: If "Orphan Link," the external app is lost; manual unlinking required
3. If a "Damaged" prompt appears, right-click the app and select "Re-sign"
4. If still unresolved, select "Move Back to Local" in the External Apps library

### What if I see a "Damaged" prompt?

macOS's code signing mechanism detected a change in the app package structure. Resolution:

1. Right-click the app in AppPorts
2. Select "Re-sign"
3. AppPorts will automatically back up the original signature and execute Ad-hoc re-signing

For detailed mechanisms, see [Re-signing & Crash Prevention](/en/datamigrae/resign).

### Will the app crash if external storage is unplugged?

The local entry (Stub Portal) will attempt to call `open` to launch the external app. If external storage is not connected, the app cannot launch but will not crash. Normal use resumes after reconnecting external storage.

### Can apps be updated after migration?

Depends on app type:

| App Type | Can Auto-Update | Notes |
|----------|:---:|-------|
| Native apps (no self-update) | ✓ | Normal updates |
| Chrome, Edge (custom updater) | ✓ | Updates install to local; AppPorts detects version difference and tags "Pending Migration" |
| Sparkle / Electron apps | ✗ | Lock prevents in-app updates; must restore to local via AppPorts before updating |
| App Store apps (macOS 15.1+) | ✓ | App Store can update in-place on external drive |
| App Store apps (macOS <15.1) | ✗ | Manual re-migration required |

### How to migrate App Store apps to external drive?

**macOS 15.1+**: In App Store settings, enable "Download and install large apps to an external drive," selecting the same external storage as AppPorts.

**macOS <15.1**: In AppPorts settings, enable "App Store App Migration." After manual migration, app updates require re-migration.

### Migration is slow/stuck. What to do?

- At 100% migration progress, there may be a 1-2 second pause while creating local entries
- Large apps (e.g., Xcode, Adobe) take longer to migrate — this is normal
- If stuck for a long time, check external storage connection stability
- USB 2.0 is slow; recommended to use USB 3.0 or above, or Thunderbolt

## Data Directory Migration

### Will data be lost after data directory migration?

No. AppPorts uses the symbolic link strategy: data is completely copied to external storage first; only after confirming successful copy is the original local directory deleted. Any failed step triggers automatic rollback.

### When might data directory migration cause app issues?

- Apps using file locks or SQLite WAL logs
- Extended attributes may be lost across symbolic links
- Group Containers directories shared by multiple apps under the same Team

### How to restore migrated data directories?

In AppPorts' data directory management interface, select the migrated directory and click "Restore." AppPorts will delete the symbolic link and copy data from external storage back to local.

## Other

### Does AppPorts collect my data?

No. AppPorts runs completely offline and does not collect or upload any user data. Log files are stored locally in `~/Library/Application Support/AppPorts/`.

### How to report issues?

Please submit on the project [Issues](https://github.com/wzh4869/AppPorts/issues) page. It is recommended to include a diagnostic package (Menu bar → Logs → Export Diagnostic Package) to expedite issue resolution.
