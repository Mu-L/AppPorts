# AppPorts 隐私政策 | Privacy Policy

[简体中文](#appports-隐私政策) | [English](#appports-privacy-policy)

---

# AppPorts 隐私政策

**更新日期：** 2026 年 9 月 17 日
**生效日期：** 2026 年 9 月 17 日
**适用版本：** AppPorts 1.8.1 及后续版本

AppPorts（以下称“本软件”）是一款运行于 macOS 平台的应用程序迁移工具。本隐私政策（以下称“本政策”）阐释我们如何收集、使用、共享与保护您的个人信息，以及您就此享有的权利。

本政策适用于本软件，以及我们的官方网站（appports.shimoko.com）与用户文档站（docs-appports.shimoko.com）。除本政策外，我们在需要读取您信息的各项功能中，还会以相应的页面提示向您说明该功能的信息处理规则。

请您在使用本软件或访问前述站点前，仔细阅读并充分理解本政策全部内容。您开始使用本软件或访问前述站点，即表示您已阅读、理解并同意本政策。本政策不适用于第三方如何定义或使用您的个人信息，我们建议您在与其互动之前先行阅读其隐私政策。

## 第一条  定义

本政策中下列用语的含义为：

- **个人信息**：指以电子或者其他方式记录的与已识别或者可识别的自然人有关的各种信息，既包括可直接识别您身份的信息（如姓名），也包括不能直接识别、但可通过合理推断间接识别您身份的信息（如设备序列号），不包括匿名化处理后的信息。
- **汇总数据**：指经统计处理后无法识别特定自然人的数据。就本政策而言，汇总数据不属于个人信息。
- **个人信息处理**：指个人信息的收集、存储、使用、加工、传输、提供、公开、删除等行为。
- **您**：指本软件的最终用户以及前述站点的访问者。
- **我们**：指本软件的开发者与运营者。

## 第二条  适用范围

本政策适用于您通过本软件、官方网站与用户文档站与我们发生的各项互动。官方网站与用户文档站均为静态站点，不设用户账号体系，亦不提供用户生成内容功能。

本政策不适用于前述站点所链接的第三方服务，该等第三方服务由其各自的隐私政策约束。

## 第三条  我们的承诺

我们坚信并尊重基本隐私权，并认为这些权利不应因您所在的国家或地区而有所不同。

基于上述理念，我们不设计任何以牺牲隐私为代价的功能：本软件的核心功能完全在您的设备本地完成，我们不设账号体系，不采集使用行为，不进行个性化推荐。若某项功能的实现确需读取您的信息，我们会在本政策或该功能的页面中明确告知其范围与目的。

## 第四条  我们收集与使用的个人信息

我们不收集、不使用、不对外提供您的任何个人信息，亦不在服务器端保留任何与您相关的数据。具体而言：

- 本软件不设账号体系，不提供注册、登录功能，不收集手机号码、电子邮箱、姓名等身份信息；
- 本软件不集成任何统计分析、行为追踪、A/B 测试或崩溃收集类软件开发工具包；
- 本软件不集成任何广告或消息推送类软件开发工具包，不进行个性化广告投放；
- 本软件不生成、不读取任何设备标识符（如 IDFA、IDFV、硬件序列号、硬件 UUID）；
- 本软件不申请、不获取通讯录、日历、提醒事项、照片、麦克风、摄像头、定位、蓝牙、健康等任何系统权限；
- 本软件不访问系统钥匙串；
- 本软件不为统计分析或广告目的设置、读取 Cookie。

## 第五条  本软件在本机读取的信息

为实现“将应用程序及其数据迁移至外部存储介质”这一核心功能，本软件需在您的设备本地读取下列信息。上述读取行为均在本机完成，不构成向任何第三方提供个人信息：

- 应用程序目录（如 `/Applications`）中的应用程序包、图标及其代码签名信息；
- `~/Library` 目录下与应用程序相关的数据目录，用于识别可迁移的数据并计算其占用空间；
- 您自行添加的自定义扫描路径；
- 您指定的外部存储介质路径，用作迁移目标位置及链接状态校验；
- 当前正在运行的应用程序列表，用于在迁移前确认目标应用程序未处于运行状态，以避免数据损坏；
- 设备基本运行信息，包括 macOS 版本、处理器核心数、物理内存容量以及外部存储介质读写速度，仅用于生成本地日志与迁移性能报告。

## 第六条  网络访问与信息接收方

本软件仅在下列情形下发起网络请求，且请求内容不包含您的任何个人信息，亦不包含账号标识、设备标识、文件路径及文件名称：

- **版本检查**：本软件在启动时进行一次静默版本检查，或依您的操作发起检查，请求地址为 `appports.shimoko.com/latest.json`；同时查询 GitHub 平台上的版本信息（`api.github.com`），在该接口不可用时回退至 `github.com` 提供的 `releases.atom` 地址。
- **信息展示**：在您打开“关于 AppPorts”窗口时，本软件请求 GitHub 平台的贡献者名单，以及用户文档站的赞助者名单（`docs-appports.shimoko.com/sponsors.json`）。

上述请求仅携带固定的 User-Agent 标识（`AppPorts` 或 `AppPorts-UpdateChecker`）。基于 HTTP 协议的固有属性，接收方服务器可获取您的 IP 地址与请求时间。前述接收方为 GitHub 平台及本项目用户文档站的服务器，其个人信息处理行为分别适用其各自的隐私政策。

下列行为不由本软件自行实施，而是交由您的默认浏览器完成：下载新版本；打开官方网站、用户文档、代码仓库及赞助页等外部链接。

## 第七条  信息的本地存储

本软件在您的设备本地存储下列文件与配置，相关内容不涉及个人信息的对外提供：

- `~/Library/Application Support/AppPorts/AppPorts_Log.txt`：操作日志与诊断信息；
- `~/Library/Application Support/AppPorts/contributors-cache.json`：贡献者名单缓存，用于减少重复的网络请求；
- `~/Library/Application Support/AppPorts/sponsors-cache.json`：赞助者名单缓存，用于离线状态下展示；
- `~/Library/Preferences` 目录下的偏好设置文件：界面语言、外部存储路径、自定义扫描路径及各项功能开关。

您可以随时删除上述文件及本软件，以清除全部本地数据。

## 第八条  诊断包

“导出诊断包”功能仅在您主动点击后执行，并且：

- 导出文件的保存位置由您在系统保存面板中自行选择；
- 导出前，本软件会将日志中的用户名替换为 `~`，将 `/Users/<用户名>` 替换为 `/Users/<redacted-user>`，并对您的外部存储介质名称作脱敏处理；
- 本软件不会自动上传该文件，亦不会将其提供给任何第三方。是否将其提供给我们，完全由您自行决定。

## 第九条  系统权限

为实现上述功能，本软件可能涉及下列系统权限：

- **完全磁盘访问权限**：用于读写 `/Applications` 及 `~/Library` 下的相关目录。该权限需由您在“系统设置 - 隐私与安全性”中手动开启，本软件无法自行申请，亦无法绕过该权限限制。
- **自动化权限（Apple 事件）**：在迁移 App Store 应用程序时，本软件通过 Finder 完成移动或删除操作。macOS 将就此向您征求同意，您有权拒绝，并可随时在“系统设置 - 隐私与安全性 - 自动化”中关闭该权限。
- **管理员权限**：仅在您对归属 root 用户安装的应用程序执行重新签名或修复所有权时触发。您输入的管理员密码由 macOS 系统对话框直接提交至操作系统，本软件不读取、不记录、不存储该密码。

本软件未申请通讯录、日历、照片、麦克风、摄像头、定位、蓝牙等任何权限，亦不访问系统钥匙串。

本软件未启用 App Sandbox（因需跨磁盘读写应用程序与数据目录），但已启用 Hardened Runtime。发行版本未经 Apple 公证，首次运行时您可能需要在“系统设置 - 隐私与安全性”中手动允许。

## 第十条  Cookie 与同类技术

我们的官方网站（appports.shimoko.com）与用户文档站（docs-appports.shimoko.com）均为静态站点，不使用 Cookie 进行统计分析，不包含第三方广告或社交插件，也不设置跨站跟踪像素。

两个站点均使用开源统计工具 Umami 统计页面访问量，以便了解各页面的使用情况并改进内容，其处理规则如下：

- 不使用 Cookie，不采集可识别您个人身份的信息，不进行跨站追踪；
- 不存储您的原始 IP 地址，该地址仅在请求发生时用于判断粗略地区并对访问去重；
- 仅记录页面访问量、来源站点、浏览器与操作系统类型、粗略地区等汇总数据；
- 您可以随时通过浏览器的内容拦截扩展或网络过滤器屏蔽该脚本，此举不影响页面的正常访问与阅读。

若您所在国家或地区的法律将 IP 地址或类似标识视为个人信息，我们将以同等标准对待此类标识。

站点托管服务商可能基于运维与安全防护的需要保留常规访问日志。

## 第十一条  赞助者信息的公开

当您通过赞助二维码支持本项目，并按提示在留言中填写昵称与链接时，该等信息（昵称、链接、金额、时间）将公开显示于用户文档站的赞助页及本软件“关于 AppPorts”窗口的赞助者区块。

上述情形是本项目中唯一涉及个人信息公开的场景，且以您的自愿提供为前提。若您不希望昵称或链接被公开，可在赞助时不作填写，或依第十八条载明的方式要求更正、删除。

## 第十二条  第三方平台

在下列情形中，相关信息的处理由第三方平台独立进行，适用其各自的隐私政策，我们不对第三方的信息处理行为负责：

- 您通过 GitHub 平台提交 Issue 或 Pull Request 时，相关信息由 GitHub 处理；
- 您通过 Bilibili、微信、支付宝等平台进行赞助时，支付相关信息由该等平台处理，我们不接触您的支付账号信息；
- 您通过本软件或前述站点打开第三方链接时，该第三方站点可能自行收集您的信息。

## 第十三条  个人信息的跨境传输

本软件不在服务器端收集或存储您的个人信息，因此不涉及由我们发起的个人信息出境活动。

当您通过 GitHub、Bilibili 等平台与我们互动时，相关信息可能由该等平台传输至其所在国家或地区的服务器，该等传输与处理由其依其隐私政策独立完成。

## 第十四条  未成年人保护

本软件不面向未成年人设计，不会主动收集未成年人的个人信息。若您是未成年人，请在监护人的陪同下阅读本政策，并在取得监护人同意后使用本软件。

## 第十五条  信息安全

鉴于本软件不在服务器端收集或存储您的个人信息，不存在因服务器数据泄露而导致您的个人信息外泄的风险。本软件在本机读取与写入的文件，其安全性依赖于您的设备与操作系统自身的安全防护措施，我们建议您妥善保管设备并保持系统更新。

## 第十六条  您的隐私权

我们尊重您获知、访问、更正、传输、限制处理与删除个人信息的能力。由于我们不收集、不存储您的个人信息，我们不掌握可供查询、更正或删除的个人信息；但我们保障您就本政策与我们沟通的权利，并承诺不因您行使上述权利而对您作任何区别对待。

若我们在任何情形下需以您的同意作为个人信息处理的合法性基础，您有权随时撤回该同意，且撤回同意不影响撤回前基于您的同意已进行的处理活动的效力。

您可以通过下列方式行使您的权利：

- 删除本软件，以及 `~/Library/Application Support/AppPorts/` 目录下的缓存与日志文件，即可清除全部本地数据；
- 就已公开的赞助者信息，随时依第十八条载明的方式要求更正或删除；
- 若您认为我们的个人信息处理行为损害了您的合法权益，您有权向有关监管部门投诉、举报。

## 第十七条  政策更新

我们可能适时修订本政策。修订后，本页面顶部的“更新日期”与“生效日期”将同步更新。涉及您权利实质变更的重大修订，我们将在版本更新日志及 GitHub Release 说明中予以提示。

本政策以简体中文版本为准，其他语言译本仅供参考。

## 第十八条  联系方式

有关本政策或个人信息保护的任何疑问、意见或投诉，可通过下列方式与我们联系：

**电子邮箱：a@shimoko.com**

我们将在收到您的请求后十五个工作日内予以答复。

---

# AppPorts Privacy Policy

**Last updated:** September 17, 2026
**Effective date:** September 17, 2026
**Applies to:** AppPorts 1.8.1 and later

AppPorts (the "Software") is an application migration tool for macOS. This Privacy Policy (the "Policy") explains how we collect, use, share, and protect your personal information, and the rights you have in that regard.

This Policy applies to the Software and to our official website (appports.shimoko.com) and documentation site (docs-appports.shimoko.com). In addition to this Policy, for each feature that needs to read your information we also explain that feature's information-handling rules in the relevant interface.

Please read this Policy in full and make sure you understand it before using the Software or visiting those sites. By using the Software or visiting those sites, you confirm that you have read, understood, and accepted this Policy. This Policy does not govern how third parties define or use your personal information; we recommend reading their privacy policies before interacting with them.

## 1. Definitions

For the purposes of this Policy:

- **"Personal information"** means any information relating to an identified or identifiable natural person that is recorded electronically or otherwise. It includes information that identifies you directly, such as your name, and information that does not identify you directly but can reasonably be inferred to do so, such as a device serial number. It excludes anonymised information.
- **"Aggregate data"** means data that, after statistical processing, cannot identify a specific natural person. For the purposes of this Policy, aggregate data is not personal information.
- **"Processing"** means any operation performed on personal information, including collection, storage, use, adaptation, transmission, provision, disclosure, and deletion.
- **"You"** means the end user of the Software and a visitor to the sites described above.
- **"We"** means the developer and operator of the Software.

## 2. Scope

This Policy applies to your interactions with us through the Software, the official website, and the documentation site. Both sites are static and have no user accounts and no user-generated content features.

This Policy does not apply to third-party services linked from those sites; such services are governed by their own privacy policies.

## 3. Our Commitment

We believe in and respect fundamental privacy rights, and we believe those rights should not depend on the country or region in which you live.

Consistent with that principle, we do not build features at the expense of your privacy. The Software's core functions run entirely on your device: there is no account system, no usage tracking, and no personalised recommendations. Where a feature genuinely needs to read your information, we state its scope and purpose in this Policy or in the relevant interface.

## 4. Personal Information We Collect and Use

We do not collect, use, or disclose any of your personal information, and we retain no data about you on any server. Specifically:

- The Software has no account system, offers no registration or sign-in, and collects no identifiers such as phone numbers, email addresses, or names;
- The Software includes no analytics, behavioural tracking, A/B testing, or crash-reporting SDK;
- The Software includes no advertising or push-notification SDK and serves no personalised advertising;
- The Software neither generates nor reads any device identifier (such as IDFA, IDFV, hardware serial number, or hardware UUID);
- The Software requests no access to contacts, calendars, reminders, photos, microphone, camera, location, Bluetooth, or health data;
- The Software does not access the system keychain;
- The Software sets and reads no cookies for analytics or advertising purposes.

## 5. Information Read Locally

To provide its core function — migrating applications and their data to external storage — the Software reads the following information on your device. All of this reading takes place locally and does not constitute disclosure to any third party:

- Application bundles, icons, and code-signing information in application directories such as `/Applications`;
- Application-related data directories under `~/Library`, used to identify migratable data and measure its size;
- Custom scan paths that you add yourself;
- The external storage path you select, used as the migration target and to verify link status;
- The list of currently running applications, used to confirm that a target application is not running before migration so that data is not corrupted;
- Basic device information, including the macOS version, processor core count, physical memory, and external drive read/write speed, used only to produce local logs and migration performance reports.

## 6. Network Access and Recipients

The Software makes network requests only in the following cases, and those requests contain none of your personal information, nor any account identifier, device identifier, file path, or file name:

- **Version checks**: the Software performs one silent version check at launch, or when you initiate a check. It requests `appports.shimoko.com/latest.json` and also queries version information on GitHub (`api.github.com`), falling back to the `releases.atom` feed if that interface is unavailable.
- **Displayed information**: when you open the "About AppPorts" window, the Software requests the list of contributors from GitHub and the list of sponsors from the documentation site (`docs-appports.shimoko.com/sponsors.json`).

These requests carry only a fixed User-Agent string (`AppPorts` or `AppPorts-UpdateChecker`). As an inherent property of HTTP, the receiving server can obtain your IP address and the time of the request. Those recipients are the servers of GitHub and of this project's documentation site, and each handles personal information under its own privacy policy.

The following are not performed by the Software itself but handed to your default browser: downloading a new version; opening external links such as the official website, documentation, code repository, and sponsor page.

## 7. Local Storage

The Software stores the following files and settings locally on your device. None of this involves disclosing personal information to any third party:

- `~/Library/Application Support/AppPorts/AppPorts_Log.txt`: operation logs and diagnostic information;
- `~/Library/Application Support/AppPorts/contributors-cache.json`: a cached contributor list, used to reduce repeated network requests;
- `~/Library/Application Support/AppPorts/sponsors-cache.json`: a cached sponsor list, used so it can be shown offline;
- Preference files under `~/Library/Preferences`: interface language, external storage path, custom scan paths, and feature toggles.

You may delete these files and the Software itself at any time to erase all local data.

## 8. Diagnostic Package

The "export diagnostic package" function runs only when you click it, and:

- you choose the destination file location in the system save panel;
- before export, the Software replaces usernames in the logs with `~`, replaces `/Users/<username>` with `/Users/<redacted-user>`, and redacts the names of your external storage volumes;
- the Software never uploads that file automatically and never provides it to any third party. Whether to share it with us is entirely your decision.

## 9. System Permissions

To provide the functions described above, the Software may involve the following system permissions:

- **Full Disk Access**: used to read and write `/Applications` and the relevant directories under `~/Library`. You enable it yourself in System Settings → Privacy & Security. The Software cannot request this permission on its own and cannot work around that restriction.
- **Automation (Apple Events)**: when migrating App Store applications, the Software uses Finder to perform the move or deletion. macOS asks for your consent; you may decline, and you may turn the permission off at any time in System Settings → Privacy & Security → Automation.
- **Administrator privileges**: triggered only when you re-sign or repair the ownership of an application installed under the root user. The administrator password you enter is submitted by the macOS system dialog directly to the operating system; the Software does not read, record, or store it.

The Software requests no access to contacts, calendars, photos, microphone, camera, location, or Bluetooth, and does not access the system keychain.

The Software does not run in the App Sandbox (it requires cross-volume access to application and data directories) but does enable the Hardened Runtime. Release builds are not notarised by Apple, so the first launch may require your approval in System Settings → Privacy & Security.

## 10. Cookies and Similar Technologies

Our official website (appports.shimoko.com) and documentation site (docs-appports.shimoko.com) are static sites. They use no cookies for analytics, contain no third-party advertising or social plugins, and set no cross-site tracking pixels.

Both sites use the open source analytics tool Umami to count page views so that we can understand how each page is used and improve it. Its handling rules are as follows:

- no cookies, no personally identifiable information, and no cross-site tracking;
- your raw IP address is not stored — it is used only at the time of the request to determine an approximate region and to de-duplicate visits;
- only aggregate data is recorded, such as page views, referring site, browser and operating system type, and approximate region;
- you can block the script at any time with a content blocker or network filter, which does not affect your ability to visit or read the pages.

If the law of your country or region treats IP addresses or similar identifiers as personal information, we treat such identifiers to the same standard.

The hosting provider may retain standard access logs for operations and security purposes.

## 11. Publication of Sponsor Information

If you support the project through the sponsor QR code and, as prompted, leave a nickname and a link in the payment note, that information (nickname, link, amount, date) will be published on the sponsor page of the documentation site and in the sponsor section of the "About AppPorts" window.

This is the only case in this project in which personal information is made public, and it depends on your voluntary provision. If you would rather not have your nickname or link published, simply leave it out when sponsoring, or request correction or removal in the manner set out in clause 18.

## 12. Third-Party Platforms

In the following cases, the relevant information is handled independently by third-party platforms under their own privacy policies, and we are not responsible for their information-handling practices:

- when you file an issue or pull request on GitHub, the relevant information is handled by GitHub;
- when you sponsor the project through platforms such as Bilibili, WeChat, or Alipay, payment information is handled by those platforms, and we never have access to your payment account details;
- when you open a third-party link from the Software or from those sites, that third party may collect information about you on its own.

## 13. Cross-Border Transfers

The Software collects and stores no personal information on any server, so no transfer of personal information abroad is initiated by us.

When you interact with us through platforms such as GitHub or Bilibili, the relevant information may be transferred to servers in the country or region where those platforms operate. Such transfers and processing are carried out independently by those platforms under their own privacy policies.

## 14. Minors

The Software is not designed for minors and does not actively collect their personal information. If you are a minor, please read this Policy with your guardian and use the Software only with your guardian's consent.

## 15. Information Security

Because the Software collects and stores no personal information on any server, there is no risk of your personal information being exposed through a server-side data breach. The security of the files the Software reads and writes on your device depends on the safeguards of your device and operating system themselves; we recommend that you keep your device secure and your system up to date.

## 16. Your Privacy Rights

We respect your ability to know about, access, correct, transfer, restrict the processing of, and delete your personal information. Because we do not collect or store your personal information, we hold no personal information that could be accessed, corrected, or deleted; we do, however, guarantee your right to communicate with us about this Policy, and we undertake not to treat you differently for exercising those rights.

If we ever rely on your consent as the legal basis for processing personal information, you may withdraw that consent at any time, without affecting the lawfulness of processing carried out on the basis of your consent before its withdrawal.

You may exercise your rights as follows:

- delete the Software, together with the caches and logs under `~/Library/Application Support/AppPorts/`, to erase all local data;
- request correction or removal of published sponsor information at any time, in the manner set out in clause 18;
- if you believe our handling of personal information has harmed your lawful rights and interests, you have the right to complain to the relevant supervisory authority.

## 17. Changes to This Policy

We may revise this Policy from time to time. When we do, the "Last updated" and "Effective date" at the top of this page will be revised accordingly. For material revisions that substantially change your rights, we will give notice in the changelog and the GitHub release notes.

The Simplified Chinese version of this Policy prevails; translations are provided for reference only.

## 18. Contact

For any question, comment, or complaint about this Policy or about the protection of personal information, you may contact us as follows:

**Email: a@shimoko.com**

We will respond to your request within fifteen business days of receipt.
