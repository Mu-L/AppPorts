---
outline: deep
---

# Data Migration Operation Guide

This page covers the practical workflow for data directory migration. For technical implementation details, see [Basic Implementation](/en/datamigrae/baseinfo).

## Finding App-Associated Data Directories

1. Switch to the "Data Directories" tab in the main AppPorts window
2. The left panel shows all installed apps
3. Click an app; the right panel displays its associated data directories under `~/Library/`

AppPorts automatically scans the following directories, matching by app Bundle ID or name:

| Scan Path | Matching Method |
|-----------|-----------------|
| `~/Library/Application Support/` | Bundle ID or app name |
| `~/Library/Preferences/` | Bundle ID or app name |
| `~/Library/Containers/` | Bundle ID |
| `~/Library/Group Containers/` | Bundle ID |
| `~/Library/Caches/` | Bundle ID or app name |
| `~/Library/WebKit/` | Bundle ID |
| `~/Library/HTTPStorages/` | Bundle ID |
| `~/Library/Application Scripts/` | Bundle ID |
| `~/Library/Logs/` | App name |
| `~/Library/Saved Application State/` | App name |

## Tool Directories (Dot-Folders)

AppPorts can automatically detect dot-folders created by common development tools in the user's home directory:

1. Switch to the "Tool Directories" sub-tab in the Data Directories tab
2. The page lists all detected tool directories with their sizes
3. Each directory shows a priority badge (recommended/optional) and status

For the full supported list, see [Tool Directory Detection](/en/datamigrae/tools).

## Migration Operations

### Single Directory Migration

1. Find the directory to migrate in the data directory list
2. Click the "Migrate" button on the right
3. AppPorts performs the following steps:
   - Copy the directory to external storage
   - Write managed link metadata
   - Delete the original local directory
   - Create a symbolic link

### Auto Re-signing

When "Auto Re-sign" is enabled in settings, data directory migration automatically triggers signing for the associated app:

1. **Before migration**: Backs up the original signature of the associated app's **real external path** (not the local shell)
2. **After migration**: Executes Ad-hoc re-signing on the **real external app** (silent mode; failures do not show a dialog)

For linked apps, AppPorts automatically resolves the real app path behind the Stub Portal shell or symlink, ensuring signature changes are applied to the actual application package rather than an invalid local shell.

::: tip 💡 No Manual Action Needed
With auto-re-signing enabled, the data directory migration workflow is fully automated. Signature backup and re-signing both target the real app path — no manual intervention required.
:::

### Log Context

Data directory operations (migration, restore, normalization, relinking) automatically include associated app context information in logs:

| Field | Description |
|-------|-------------|
| `app_name` | Associated app name |
| `app_status` | App status (Linked, Local, etc.) |
| `app_is_resigned` | Whether the app has been re-signed |
| `app_bundle_id` | App's Bundle ID (read from real path) |
| `app_real_path` | App's real external path |

These fields help pinpoint issues more precisely when exporting diagnostic packages.

### Batch Migration

1. Check multiple directories in the tool directory list
2. Click the "Batch Migrate" button at the bottom
3. AppPorts executes migration sequentially

::: tip 💡 Priority Recommendations
Data directories are classified into three priority levels:

- **Critical** (`critical`): Must work after migration; affects core application functionality
- **Recommended** (`recommended`): Large space savings; high migration benefit
- **Optional** (`optional`): Small size or rebuildable

It is recommended to prioritize migrating directories marked as "Recommended".
:::

## Restore Operations

1. Find the migrated directory in the data directory list (status: "Linked")
2. Click the "Restore" button on the right
3. AppPorts performs the following steps:
   - Delete the local symbolic link
   - Copy data from external storage back to local
   - Delete the external directory (best effort)

## Handling Abnormal States

### Needs Normalization

The directory is managed by AppPorts, but the external path is not at the canonical location. Click "Normalize"; AppPorts will move the external data to the canonical path and rebuild the symbolic link.

### Needs Relinking

External storage data still exists, but the local symbolic link is lost. Click "Relink"; AppPorts will recreate the symbolic link.

### Existing Soft Link

A user-created symbolic link not created by AppPorts. You can choose "Take Over"; AppPorts will write managed link metadata and manage it going forward.

## Tree View

For data directories containing subdirectories (e.g., multiple app directories under `Application Support`), AppPorts provides a tree grouping view:

- Parent directory shows expand/collapse arrows on the left
- Subdirectories display hierarchical indentation
- Each node independently shows size and status
- Migration/restore operations can be performed on individual subdirectories
