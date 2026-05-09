---
outline: deep
---

# AppPorts User Guide

This guide systematically introduces AppPorts' features, design principles, and technical implementation. For more technical details, see [DeepWiki](https://deepwiki.com/wzh4869/AppPorts). For improvement suggestions, please submit them to the project [Issues](https://github.com/wzh4869/AppPorts/issues).

## Overview

AppPorts is an application migration and linking tool designed for [macOS](https://www.apple.com/macos/), supporting the migration of large applications to external storage devices while maintaining full system functionality and consistency.

### AppPorts Philosophy

| Principle | Description |
|-----------|-------------|
| **Transparent Experience** | Ensures the user experience and operating system perceive the app as still running from internal storage |
| **Stable Strategy** | Prioritizes proven, more stable migration approaches |
| **Low System Burden** | No daemons, avoids continuous system resource consumption |
| **Broad Internationalization** | Prioritizes covering more languages; translation breadth over precision |
| **Accessibility Friendly** | Comprehensive accessibility support |

## Core Features

- **Badge-free Migration**: One-click migration of large apps to external drives. Locally retains only a lightweight launcher shell; Finder does not display shortcut arrows; Launchpad and macOS app menu work normally.
- **Auto-Update Protection**: Automatically detects apps with auto-update support (Sparkle, Electron, Chrome, etc.), providing a "Locked Migration" option to prevent auto-updaters from deleting or overwriting apps on the external drive.
- **Code Signature Management**: After migration, if a "Damaged" prompt appears, one-click re-signing via right-click menu. Supports backing up and restoring original signatures; auto re-signing after data directory migration.
- **macOS 15.1+ App Store Support**: Supports installing App Store apps directly to external drives with in-place updates on the external drive.
- **One-Click Restore**: Supports migrating apps back to local storage with automatic link removal. Automatic recovery on interrupted migration.
- **Data Directory Management**: Supports migrating app data directories (`~/Library/` subdirectories, `~/.npm`, etc.) to external storage, with tree view grouping, search, and sorting.

## Glossary

### Migration Strategies

#### Deep Contents Wrapper (Contents Directory Migration)

The standard file structure of a macOS application is as follows:

```text
/Applications/Safari.app/
├── Contents/
│   ├── MacOS/
│   ├── Resources/
│   ├── Frameworks/
│   └── Info.plist
└── ...
```

The Deep Contents Wrapper strategy migrates all application content to external storage, creating an empty `.app` directory locally with only a symbolic link pointing to the external `Contents` directory. Since macOS detects a complete `.app` package (rather than a shortcut), Finder does not display arrow markers; icons, Launchpad, and app menus work normally.

::: warning ⚠️ This strategy is deprecated in the current version
The main flaw of Deep Contents Wrapper is that auto-updaters follow symbolic links and directly modify files on external storage, potentially corrupting the application.
:::

#### Stub Portal

The Stub Portal approach creates a minimal `.app` shell locally, containing only these four items:

| Component | Description |
|-----------|-------------|
| `Contents/MacOS/launcher` | Bash launch script that executes `open "/Volumes/External/SomeApp.app"` |
| `Contents/Resources/` | Icon file copied from the external application |
| `Contents/Info.plist` | Simplified from the external app's `Info.plist`, with `CFBundleExecutable` set to `launcher`, `LSUIElement=true` (not shown in Dock), and all update-related config keys removed |
| `Contents/PkgInfo` | Standard 4-byte identifier file |

When the user clicks this shell, macOS executes the `launcher` script, opening the real application on the external drive via the `open` command. No symbolic links are present locally; auto-updaters cannot penetrate through.

##### iOS Stub Portal

The basic principle is the same as the standard Stub Portal, but icon handling differs. iOS app icons are not specified in `Info.plist` but stored as multiple `AppIcon.png` files in the `Wrapper/` or `WrappedBundle/` directories. The process is:

1. Find the highest-resolution `AppIcon.png` file
2. Use `sips` to scale to 256×256 pixels
3. Use `sips` to convert to `.icns` format
4. Generate `Info.plist` from `iTunesMetadata.plist` (iOS apps don't include a standard `Info.plist`)

#### Whole Symlink

Creates the entire `.app` directory as a symbolic link to external storage:

```text
/Applications/SomeApp.app → /Volumes/External/SomeApp.app
```

Only a symbolic link is retained locally with no actual files. macOS can open the app normally, but Finder displays arrow shortcut markers on the icon, and Launchpad occasionally has compatibility issues. Auto-updaters can also operate on external app files through the symbolic link. This is AppPorts' fallback migration strategy.
