---
outline: deep
---

# Troubleshooting

## Migration Interruption

### Symptoms

Migration interrupted due to external storage disconnection, system crash, or app force quit.

### Resolution

AppPorts has a built-in auto-recovery mechanism. After restarting AppPorts:

1. Detects residual migration data (external copy exists but local symbolic link not created)
2. Checks `.appports-link-metadata.plist` in the external directory
3. If `schemaVersion`, `managedBy`, `sourcePath`, `destinationPath`, and `dataDirType` fully match, continues recovery or relinking
4. If metadata does not match, stops automatic handling and preserves existing data for user confirmation

::: tip 💡 No Manual Intervention Needed
AppPorts' auto-recovery mechanism handles interrupted migrations on the next launch. If auto-recovery fails, you may see "Needs Normalization" or "Needs Relinking" status in the data directory list — simply execute the corresponding operation manually.
:::

## External Storage Offline

### Symptoms

After external storage is unplugged or disconnected, migrated apps cannot launch and data directories display red error status.

### Resolution

1. Reconnect external storage
2. AppPorts' `FolderMonitor` automatically detects storage volume mounting and triggers re-scan
3. Apps and data directories resume normal use

::: warning ⚠️ Note
While external storage is offline, local entries (Stub Portal) calling `open` will fail; apps cannot launch but will not crash. Data directory symbolic links point to invalid paths; associated apps may not be able to read data.
:::

## Signature Restore Failure

### Symptoms

Attempting to restore original signature fails, or the app still shows "Damaged" after restore.

### Possible Causes & Resolution

| Cause | Resolution |
|-------|-----------|
| Backup file does not exist | Cannot restore original signature; execute Ad-hoc re-signing as alternative |
| Original developer certificate not in local Keychain | AppPorts automatically falls back to Ad-hoc signing; app can launch but Keychain access may be abnormal |
| Mac App Store app (SIP protection) | Cannot re-sign; SIP prevents any modification to system app signatures |
| App directory is root-owned | AppPorts attempts to change ownership via admin privileges; authorize in the popup |
| Contents symbolic link target lost | Cannot sign; must restore external data or restore app first |

For detailed mechanisms, see [Re-signing & Crash Prevention](/en/datamigrae/resign).

## App Store Apps Cannot Migrate to External Drive

### macOS Versions Below 15.1

macOS versions before 15.1 do not support App Store app installation to external drives. You need to:

1. Enable "App Store App Migration" in AppPorts settings
2. After migration, app updates require manual re-migration to overwrite

### macOS 15.1 and Above

If the App Store cannot update apps on external drives:

1. Open App Store settings
2. Enable "Download and install large apps to an external drive"
3. Select the same external storage as the AppPorts external storage library

## App Cannot Launch After Migration

### Troubleshooting Steps

1. **Check external storage connection**: Confirm external storage is connected and accessible
2. **Check app status badges**:
   - "Orphan Link" → External app lost; manual unlinking required
   - "Damaged" → Execute re-signing
3. **Check lock status**: If app is locked (uchg), self-updater may not be able to run
4. **Check logs**: Menu bar → Logs → View in Finder; search for relevant error messages
5. **Move back to local**: In External Apps library, select "Move Back to Local" to confirm if it's an external storage issue

## Destination Already Exists

### Symptoms

AppPorts reports that the target path already exists and cannot be overwritten during app or data migration.

### Resolution

- **App migration**: AppPorts only replaces a target when it is the old copy for a "Pending Move Out" app, or an AppPorts-managed old portal/remnant. Inspect the external target in Finder before deleting or renaming it manually.
- **Data directory migration**: AppPorts requires matching metadata and no longer takes over a real directory based on similar size. Confirm the directory contents manually before retrying.
- **Moving back to local**: AppPorts will not overwrite a same-name real local app or unrelated symlink. Confirm the local item first.

## Data Directory Display Issues

### Symptoms

Data directory list shows incomplete or incorrect status.

### Resolution

1. AppPorts uses `FolderMonitor` to monitor file system changes; it usually refreshes automatically
2. When switching apps quickly, stale scan results should not overwrite the currently selected app; wait for the current scan to finish if the list is temporarily empty
3. If not auto-refreshed, click the refresh button in the top toolbar or switch tabs and back
4. If the issue persists, check scan error messages in the logs
