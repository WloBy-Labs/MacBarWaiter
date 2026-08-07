# MacBarWaiter

> 菜单栏图标放不下，被系统悄悄丢掉了 —— 怎么才能看到全部？

MacBarWaiter 在菜单栏放一个下拉按钮，点开就把**所有**状态项（包括被挤掉、完全画不出来的那些）
原样列出来。当前不可见的那几个底下会画一道横线标出来。

## 为什么需要它

macOS 的状态项是从右往左排的，排不下的不会折叠、不会换行，**直接不渲染** ——
它们依然占着坐标和宽度，只是画不出来，而且丢哪些不由你定。

有刘海的机器尤其明显。以一台 14 寸 MBP 实测：

```
刘海左侧可用区   x    0..665    宽 665   ← 归 App 菜单，状态项不往这儿放
刘海占据         x  665..850    宽 185   ← 放不了任何东西
刘海右侧可用区   x  850..1512   宽 662   ← 所有状态项只有这 662pt
```

而机器上 12 个状态项一共需要 919pt，超出 257pt。于是最左边 6 个图标有坐标、占宽度、
但永远画不出来 —— 看上去像是「菜单栏中间空了一块」，其实那块被隐形图标占满了。

## 原理

不去动那些真图标，而是把它们的**像素抓下来**画在自己的面板里：

```
[ 菜单栏 ] ⌄ ← 点它
           ┌────────────────────────────┐
           │ ⌨9.8k🖱1.4k  Ⓐ  🖥  ✳  ▶  │  ← 全部状态项，含看不见的
           │ ──────────  ──  ──  ──     │  ← 横线标出当前不可见的
           └────────────────────────────┘
```

关键在于 **ScreenCaptureKit 能按窗口 ID 抓离屏窗口**。实测那 6 个完全不渲染的状态项，
像素全都拿得到（非空像素 12~21%，是真内容不是空白）。

这条路不碰排布，所以刘海、可用区宽度、图标顺序、多屏布局统统不用管。

| 能力 | 用什么 |
| --- | --- |
| 找出全部状态项（含离屏） | `SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)`，筛 `windowLayer == 25` |
| 抓单个图标的像素 | `SCScreenshotManager.captureImage` + `SCContentFilter(desktopIndependentWindow:)` |
| 判断哪些当前不可见 | `SCWindow.isOnScreen` |
| 对应到某一块屏的菜单栏 | 按 `SCWindow.frame.minY` 分组 |

## 下载与安装

[Releases](https://github.com/WloBy-Labs/MacBarWaiter/releases) 里有拖拽安装的 DMG。
打开后把 MacBarWaiter 拖进 Applications 即可。

> Release 包用固定的自签身份签名（`MacBarWaiter CI Signing`），所以**更新之间不需要
> 重新授予屏幕录制权限**。但证书未经 Apple 公证，首次打开 Gatekeeper 仍会警告，
> 需要在「系统设置 → 隐私与安全性」里点一次「仍要打开」。
>
> 例外：0.1.0 那一版是 ad-hoc 签名的，从它升到 1.0.0 需要再授权一次。

自己构建的话，依赖只有 macOS 14+ 与 Command Line Tools（提供 `swiftc`）：

```bash
scripts/bootstrap_local_signing.sh   # 一次性：建立稳定签名身份，保住权限
scripts/package_app.sh               # 产出 dist/MacBarWaiter.app
open dist/MacBarWaiter.app
```

想常驻的话，把 `dist/MacBarWaiter.app` 拖进 `/Applications`。
也可以 `scripts/make_dmg.sh` 打个 DMG。

### 建立稳定的本地签名身份（自己构建时强烈建议先做）

**不做的话，每次重新构建后「屏幕录制」权限都要重新授予一遍。** 因为默认走 ad-hoc 签名，
代码签名每次都变，TCC 会把它当成另一个 App。

```bash
scripts/bootstrap_local_signing.sh
```

一次性操作，会要你输密码（它往登录钥匙串里装一张自签的代码签名证书并设为受信任）。
之后 `package_app.sh` 会自动用这个身份签名，权限就能跨重建保住。

### 授权屏幕录制（必须）

抓图需要**屏幕录制**权限，这是 ScreenCaptureKit 的硬要求，绕不过去。

首次点开面板会提示授权。在「系统设置 → 隐私与安全性 → 录屏与系统录音」里打开
MacBarWaiter，**然后重启 App**（这个权限要重启进程才生效）。

```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
```

## 使用

| 操作 | 效果 |
| --- | --- |
| **左键点击**下拉按钮 | 打开面板，列出全部状态项；再点一次关闭 |
| **右键点击** | 菜单：打开权限设置、退出 |

每次打开面板都会重新抓一遍，所以看到的是当时的实际内容（歌名、计数之类会跟着变）。

## 已知限制

**只能看，不能点。** 面板里的图标是抓下来的图，点不了。真图标在屏幕外，要转发点击得靠
「临时把它挪进可视区再点」这种把戏，第一版不做。

**认不出归属 App。** 现代 macOS 上状态项统一由 Control Center 进程托管，
`SCWindow.owningApplication` 对所有状态项一律返回「控制中心」。`SCWindow.title`
能给出一部分（`WiFi` / `Clock` / `Amphetamine` / `NowPlaying`），其余是 `Item-0`，
所以面板里只画图标本身，标不出名字。

**需要屏幕录制权限。** 见上。

**下拉按钮自己也要占一格。** 菜单栏本来就满，所以首次运行会把它摆到第三方图标区最右端
（那里在可用区内）。如果你 ⌘ 拖动把它挪到左边，它自己也会变成看不见的 —— 那就没入口了。

## 开发

```
Package.swift                        SwiftPM 清单（Core 库 + App 可执行 + XCTest 目标）
Sources/MacBarWaiterCore/            全部逻辑
  StatusItemInfo.swift               数据模型 + 状态项筛选 + 坐标换算
  StripLayout.swift                  面板换行与尺寸
  Backdrop.swift                     底色明暗判断
  Capturer.swift                     ScreenCaptureKit 抓图
  StripView.swift                    面板绘制
  AppController.swift                状态项 + popover
Sources/MacBarWaiterApp/main.swift   入口
Tests/MacBarWaiterCoreTests/         纯逻辑测试（XCTest，需要 Xcode，见下）
Resources/Info.plist                 版本号在打包时由 plutil 注入
Resources/AppIcon.icns               由 scripts/make_appicon.sh 生成，已提交
scripts/                             构建、打包、DMG、签名、图标
release_notes/vX.Y.Z.md              发版说明，CI 会取来当 release notes
VERSION                              版本号唯一来源
```

| 脚本 | 作用 |
| --- | --- |
| `scripts/build_binary.sh` | 一条 `swiftc` 把 Core + App 编成二进制（`BUILD_CONFIG=release` 出优化版） |
| `scripts/package_app.sh` | 构建、组装 `dist/MacBarWaiter.app`、注入版本号、签名 |
| `scripts/make_dmg.sh` | 打成带 Applications 快捷方式的 DMG |
| `scripts/bootstrap_local_signing.sh` | 建立稳定的本地签名身份（保住隐私权限） |
| `scripts/make_signing_cert.sh` | 生成给 GitHub Actions 用的 p12，打印成 Secrets 要填的值 |
| `scripts/make_appicon.sh` | 从 `make_appicon.swift` 重新生成 `AppIcon.icns`（只在改图标设计时跑） |

改完代码：

```bash
swift test && scripts/package_app.sh && open dist/MacBarWaiter.app
```

> `package_app.sh` 会先 `rm -rf dist/MacBarWaiter.app`，正在运行的实例会被一起干掉。
> 重新构建后记得再 `open` 一次。

### 测试需要 Xcode

测试用 XCTest（`swift test`），而**在 macOS 上 XCTest 和 swift-testing 的模块都装在
Xcode.app 里，Command Line Tools 不带**。只装了 CLT 的机器上 `import XCTest` 会报
`no such module`（CLT 里只有 swift-testing 的宏插件
`usr/lib/swift/host/plugins/testing`，没有 `Testing` 模块本身）。

所以跑测试前需要：

```bash
sudo xcodebuild -license accept
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

不想改全局工具链的话，可以只对单次命令生效：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

注意 `scripts/build_binary.sh` 和打包链路**只需要 CLT**，跟 Xcode 无关 ——
只有测试依赖 Xcode。

### 排查

- 面板显示「需要屏幕录制权限」→ 授权后**重启 App**（这个权限要重启进程才生效）
- 面板是空的但没有提示 → `SCShareableContent` 返回了空，检查 `windowLayer == 25` 的筛选
- 面板显示「读取失败：<域> <码>」→ 不是权限问题，错误码见 `SCStreamError`
- 抓图崩在 `CGS_REQUIRE_INIT` → 调用前没初始化 `NSApplication`（写命令行验证脚本时容易撞到）

### 踩过的坑

写在这里免得再踩一遍：

- `CGWindowListCreateImage` 在 macOS 26 SDK 里已是 **unavailable**（不只是 deprecated），
  只能用 ScreenCaptureKit
- ScreenCaptureKit 抓图前必须已初始化 `NSApplication`，否则崩在 `CGS_REQUIRE_INIT` 断言上
- 取窗口清单必须 `onScreenWindowsOnly: false`，否则查不到离屏的那些 —— 而那正是要找的
- `NSStatusItem Preferred Position` 数值**越小越靠右**，0 是最右；而且必须在创建
  `NSStatusItem` **之前**写入。写成属性初始化器就来不及 —— 属性初始化器在 `init()` 体之前
  执行完，那时偏好还没写下，图标会落到最左边（可用区之外），连下拉按钮自己都看不见
- 状态项窗口的 `NSWindow.windowNumber` 是 2^33 量级的值，跟 `kCGWindowNumber` 不是一回事
- ad-hoc 签名会让隐私权限在每次重新构建后失效（实测过：重新 `package_app.sh` 之后面板
  直接变成「需要权限」），务必先跑 `scripts/bootstrap_local_signing.sh`。
  换成稳定身份后同样实测过：重新打包，权限保住了
- **不要用 `CGPreflightScreenCaptureAccess()` 做前置拦截**。权限刚授予、进程还没重启时
  它返回 false，会导致明明抓得到图却只显示「需要权限」。正确做法是直接尝试抓图，
  失败了再用它辅助归因（见 `Capturer.classify`）

### 手动验证

筛选和布局有测试覆盖，但「抓出来的图对不对、面板长得对不对」只有看屏幕才知道，
改完这几件事要手动过一遍：

1. 下拉按钮出现在第三方图标区最右端，并且**看得见**
2. 点开后面板里的图标数量与菜单栏实际状态项总数一致（含看不见的）
3. 面板里图标的左右顺序与菜单栏上的实际顺序一致
4. 当前不可见的那几个底下有横线
5. 图标在面板上看得清（底色明暗要跟图标反差够）
6. 没授权时给出提示而不是空面板；授权并重启后能正常显示
7. 内容宽度超过面板时换行，且一个都没丢（比如「正在播放」歌名那种 319pt 的宽项）

### 协作约定

**分支**：全小写的类型前缀 + 简短描述，例如 `bugfix/notch-range`、`feature/click-through`。

**PR 标题**：以方括号类型前缀开头，类型用驼峰写法：

| 前缀 | 用途 |
| --- | --- |
| `[Feature]` | 新功能 |
| `[BugFix]` | 修复缺陷 |
| `[Enhancement]` | 已有功能的改进、体验优化 |
| `[Refactor]` | 重构，不改变外部行为 |
| `[Misc]` | 杂项：文档、CI、依赖、构建脚本等 |

改动合入后，同步在 `CHANGELOG.md` 的 `[Unreleased]` 小节补一条。

## 版本与发版

版本号唯一来源是 `VERSION`，`package_app.sh` 注入 Info.plist。

`.github/workflows/release.yml` 在推 `v*` tag 时构建 .app、打 DMG、发 GitHub Release，
release notes 取自 `release_notes/v<版本>.md`。签名是渐进式的：

| 配置了什么 Secret | 结果 |
| --- | --- |
| 无 | ad-hoc 签名（能用，但 Gatekeeper 会警告，且更新后要重新授权） |
| `MACOS_CERT_P12` + `MACOS_CERT_PASSWORD` | 用该身份签名，权限可跨更新保留 ← **本仓库当前如此** |
| 再加 `APPLE_ID` + `APPLE_TEAM_ID` + `APPLE_APP_PASSWORD` | 额外公证并 staple |

签名证书由 `scripts/make_signing_cert.sh` 生成，本仓库那张存在
`~/Library/Application Support/MacBarWaiter/signing/ci/`（与 KeyboardWaiter 同一约定）。
**这张 p12 要长期保留** —— 换证书等于换身份，用户得重新授权一次。

发版步骤：

1. 更新 `VERSION`
2. 在 `CHANGELOG.md` 顶部新增对应版本小节，把 `[Unreleased]` 里累积的条目挪过去
3. 新建 `release_notes/v<版本>.md`
4. 提交并推送，然后 `git tag -a v<版本> && git push origin v<版本>`

## License

[MIT](LICENSE) © WloBy Labs
