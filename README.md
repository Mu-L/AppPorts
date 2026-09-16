<div align="center">

# 📦 AppPorts

**External drives save the world!**

An application migration and linking tool designed specifically for macOS.
Easily migrate large applications to external storage while maintaining seamless system functionality.

[简体中文](README_CN.md)｜[Official Website](https://appports.shimoko.com/)｜[Documentation](https://docs-appports.shimoko.com/)｜[DeepWiki](https://deepwiki.com/wzh4869/AppPorts)

<a href="https://github.com/wzh4869/AppPorts/releases"><img src="https://img.shields.io/github/v/release/wzh4869/AppPorts?style=flat-square&label=release&color=blue" alt="Release"></a>
<a href="https://github.com/wzh4869/AppPorts/stargazers"><img src="https://img.shields.io/github/stars/wzh4869/AppPorts?style=flat-square&color=yellow" alt="Stars"></a>
<a href="https://github.com/wzh4869/AppPorts/network/members"><img src="https://img.shields.io/github/forks/wzh4869/AppPorts?style=flat-square" alt="Forks"></a>
<a href="https://github.com/wzh4869/AppPorts/issues"><img src="https://img.shields.io/github/issues/wzh4869/AppPorts?style=flat-square" alt="Issues"></a>
<a href="https://github.com/wzh4869/AppPorts/blob/main/LICENSE"><img src="https://img.shields.io/github/license/wzh4869/AppPorts?style=flat-square" alt="License"></a>
<img src="https://img.shields.io/badge/platform-macOS-black?style=flat-square&logo=apple&logoColor=white" alt="Platform">
<img src="https://img.shields.io/badge/Swift-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift">
<a href="https://linux.do"><img src="https://img.shields.io/badge/linux.do-%E7%A4%BE%E5%8C%BA-1f7aec?style=flat-square&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMjAgMTIwIj48Y2xpcFBhdGggaWQ9ImEiPjxjaXJjbGUgY3g9IjYwIiBjeT0iNjAiIHI9IjQ3Ii8%2BPC9jbGlwUGF0aD48cGF0aCBmaWxsPSIjZmZmZmZmIiBjbGlwLXBhdGg9InVybCgjYSkiIGQ9Ik0xMCAxMGgxMDB2MzBIMTB6TTEwIDgwaDEwMHYzMEgxMHoiLz48L3N2Zz4%3D&logoColor=white" alt="linux.do"></a>
<a href="https://docs-appports.shimoko.com/sponsor.html"><img src="https://img.shields.io/badge/%E8%B5%9E%E8%B5%8F-Sponsor-ff69b4?style=flat-square&labelColor=ff69b4&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI%2BPHBhdGggZmlsbD0iI2ZmZmZmZiIgZD0iTTEyIDIxLjM1bC0xLjQ1LTEuMzJDNS40IDE1LjM2IDIgMTIuMjggMiA4LjUgMiA1LjQyIDQuNDIgMyA3LjUgM2MxLjc0IDAgMy40MS44MSA0LjUgMi4wOUMxMy4wOSAzLjgxIDE0Ljc2IDMgMTYuNSAzIDE5LjU4IDMgMjIgNS40MiAyMiA4LjVjMCAzLjc4LTMuNCA2Ljg2LTguNTUgMTEuNTRMMTIgMjEuMzV6Ii8%2BPC9zdmc%2B&logoColor=white" alt="赞赏 · Sponsor"></a>

<div style="display:flex; justify-content:center; align-items:center; gap:10px; flex-wrap:nowrap;">
  <a href="https://www.producthunt.com/products/appports/launches/appports?embed=true&utm_source=badge-featured&utm_medium=badge&utm_campaign=badge-appports" target="_blank" rel="noopener noreferrer">
    <img alt="AppPorts - An application migration designed specifically for macOS. | Product Hunt"
         width="250" height="54"
         src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=1078207&theme=light&t=1772851420450">
  </a>

  <a href="https://hellogithub.com/repository/wzh4869/AppPorts" target="_blank">
    <img src="https://abroad.hellogithub.com/v1/widgets/recommend.svg?rid=9bc7259839c740faa2246ee5f10bc786&claim_uid=SjNchy8nMfGgUlx&theme=neutral"
         alt="Featured｜HelloGitHub"
         width="250" height="54">
  </a>
</div>

</div>

---

## ✨ Introduction

Mac's built-in storage space is extremely precious. **AppPorts** allows you to move applications from your `/Applications` directory to an external drive (SSD, SD Card, or NAS) with a single click, while keeping a tiny **launcher stub** in the original location.

To macOS, the app still "exists" locally, allowing you to launch it as usual, but the actual storage is on the external drive. The local stub is so small it's negligible — and Finder shows **no shortcut arrow**.

### ⚠️ "AppPorts" is damaged and can't be opened
If you encounter this error (and macOS suggests moving it to the Trash) when opening the app, it is because the application is not signed with an Apple Developer ID.
(Note: The command below assumes you have moved AppPorts to the **/Applications** folder)
To fix this, please run the following command in Terminal to remove the quarantine attribute:
```bash
xattr -rd com.apple.quarantine /Applications/AppPorts.app
```

## 📸 Screenshots

| Welcome Screen | Main Interface |
|:---:|:---:|
| ![Welcome](https://pic.cdn.shimoko.com/appports/huanying.png) | ![Main](https://pic.cdn.shimoko.com/appports/zhuyemian.png) |

| Dark Mode | Language Switching |
|:---:|:---:|
| ![Dark](https://pic.cdn.shimoko.com/appports/shensemoshi.png) | ![Lang](https://pic.cdn.shimoko.com/appports/yuyan.png) |

## 🚀 Key Features

* **📦 Arrow-Free Migration**: One-click migration of multi-gigabyte applications to external storage. A tiny launcher stub stays locally — Finder shows no shortcut arrow, Launchpad and macOS App Menu work perfectly.
* **🛡️ Auto-Update Protection**: Automatically detects self-updating apps (Sparkle, Electron, Chrome, etc.) and offers a **locked migration** option. Locked apps on the external drive are protected from being deleted or overwritten by auto-updaters.
* **✍️ Code Signature Management**: Re-sign migrated apps that show "damaged" warnings, or restore their original signatures. Supports automatic re-signing after data directory migration.
* **🔴 Orphaned Link Detection**: If the external drive is disconnected or an app is deleted, the app list shows a red "Orphaned Link" badge so you can clean up the broken link.
* **🍎 macOS 15.1+ App Store Support**: On macOS 15.1+, App Store apps can be installed directly to the external drive, and App Store can update them in-place without migrating back.
* **↩️ Restore Anytime**: One-click restore moves the app back to local storage and removes the link automatically. Interrupted migrations are automatically recovered.
* **📊 Data Directory Management**: Migrate app data folders (`~/Library/` subfolders, dot-folders like `~/.npm`) to external storage. Tree view with grouped cards, search, and sorting.
* **🎨 Modern UI**: Native SwiftUI, full Dark Mode support, 20+ languages.
* **♿️ Accessibility**: VoiceOver-friendly with clear semantic labels and a Braille language option.
* **🌍 Global Ready**: 20+ languages including English, Chinese, Japanese, Korean, German, French, Spanish, Italian, Portuguese, Russian, Arabic, Hindi, Vietnamese, Thai, Turkish, Dutch, Polish, Indonesian, Esperanto, Braille, and 👽 Martian.

## 🏆 Why AppPorts?

AppPorts uses a unique **Stub Portal** technology — a tiny launcher shell that opens the real app on the external drive. This gives you the best of both worlds: the app looks and behaves as if it's still installed locally, but the storage is on the external drive.

| Feature | AppPorts (Stub Portal) | Traditional Symlink |
| :--- | :--- | :--- |
| **Finder Icon** | ✅ Native (No Arrow) | ❌ Arrow Overlay |
| **Launchpad** | ✅ Perfect | ⚠️ Unreliable |
| **App Menu (macOS 26)** | ✅ Perfect | ❌ Unsupported |
| **Auto-Update Protection** | ✅ Lock Mode | ❌ None |
| **Signature Management** | ✅ Built-in | ❌ None |
| **Orphaned Link Detection** | ✅ Automatic | ❌ None |

## 🧭 Migration Strategy

AppPorts picks the best migration strategy based on the app's type and behavior:

| App Type | Strategy | Default | Notes |
| :--- | :--- | :--- | :--- |
| **Native Mac apps** | Stub Portal | ✅ Enabled | Tiny launcher shell locally, no arrow icon |
| **Self-updating apps** (Sparkle, Electron, etc.) | Stub Portal + Lock | ✅ Enabled | External app is locked (uchg) to prevent auto-updater damage |
| **iPhone/iPad apps** | iOS Stub Portal | ✅ Enabled | Icon extracted from iOS app bundle |
| **Mac App Store apps** | Native on macOS 15.1+ | ✅ Auto on 15.1+ | App Store can update directly on external drive |
| **App suites** (Office, Adobe, etc.) | Folder symlink | ✅ Enabled | Entire folder migrated as a unit |
| **System apps** | Blocked | ❌ | Protected from migration |
| **Running apps** | Blocked | ❌ | Quit the app first |
| **Already linked apps** | Blocked | ❌ | Prevents double-linking |

## 🛠️ Installation

### System Requirements
* macOS 12.0 (Monterey) or newer.

### Download and Installation
Please visit the [official website](https://appports.shimoko.com/) or the [Releases](https://github.com/wzh4869/AppPorts/releases) page to download the latest `AppPorts.dmg`.

### ⚠️ Permissions
AppPorts requires **Full Disk Access** to read and modify `/Applications`.

1. Open **System Settings** → **Privacy & Security**.
2. Select **Full Disk Access**.
3. Click the `+` button, add **AppPorts**, and turn on the toggle.
4. Relaunch AppPorts.

*(The app includes an in-app guide that can open Settings directly)*

## 🧑‍💻 Development

```bash
git clone https://github.com/wzh4869/AppPorts.git
```
Open the project with **Xcode** and build.

## 🤝 Contributing

We welcome Issues and Pull Requests!
If you find translation errors or have suggestions for new features, please let us know.

## AppPorts Heroes 💗
<a href="https://github.com/wzh4869/AppPorts/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=wzh4869/AppPorts" />
</a>

## 💗 Sponsor

AppPorts is completely free, open source and free of ads. It is maintained by a single developer in his spare time and generates no revenue. If it has freed up tens of gigabytes on your disk, you are welcome to scan the QR code and buy the author a coffee — **any amount is welcome, and even the smallest one means a lot**.

<img src="https://pic.cdn.shimoko.com/thanks.png" alt="Sponsor QR code" width="220" />

- When sponsoring, please leave your **nickname** and a **link** (GitHub profile, blog, social account, etc.) in the message. They will be shown on the **About AppPorts** page in the app and on the [sponsor page](https://docs-appports.shimoko.com/sponsor.html) of the documentation site.
- There is **no minimum amount** — give whatever feels right. Sponsors are ordered by amount (highest first) and, for equal amounts, by sponsorship date (earliest first); the amount is only shown on the [sponsor page](https://docs-appports.shimoko.com/sponsor.html).

Thanks to the following sponsors (this list is kept in sync with `sponsors.json` in the repository root):

- **师杀** · [space.bilibili.com/396481888](https://space.bilibili.com/396481888)

## Advanced Storage Management

* [LazyMount-Mac](https://github.com/yuanweize/LazyMount-Mac): Easily expand Mac storage space — Automatically mount SMB shares and cloud storage at startup, no manual operation required.

  > The perfect companion for AppPorts. LazyMount connects the storage, AppPorts handles the applications.
  > * 🎮 Game Libraries — Store Steam/Epic games on a NAS, play them like local installs
  > * 💾 Time Machine Backups — Back up to a remote server automatically
  > * 🎬 Media Libraries — Access your movie/music collection stored on a home server
  > * 📁 Project Archives — Keep large files on cheaper storage, access them on-demand
  > * ☁️ Cloud Storage — Mount Google Drive, Dropbox, or any rclone-supported service as a local folder

## Star History

[![Star History Chart](https://star-history.dera.page/svg?repos=wzh4869/AppPorts&type=date&legend=top-left)](https://star-history.dera.page/#wzh4869/AppPorts&type=date&legend=top-left)

## 📄 License

This project is open-source under the [Apache License 2.0](LICENSE).

See the [Privacy Policy](PRIVACY.md).

<br>
<div align="center">

[Personal Website](https://www.shimoko.com) • [GitHub](https://github.com/wzh4869/AppPorts)

</div>
