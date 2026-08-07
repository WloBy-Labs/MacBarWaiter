# Changelog

本项目的所有值得注意的改动都记录在此文件。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [1.1.0] - 2026-08-07

换了新图标，和 WloBy 其他 App 统一版式。App 功能没有改动。

### Changed

- **新 App 图标**：青绿底 + 菜单栏条（右侧图标实心、往左淡出）+ 朝下箭头，
  下方 `WLOBY MB` 字标。底色特意跟 PrWaiter 的靛蓝、KeyboardWaiter 的石墨区分开
- 图标改成**逐尺寸渲染**成 iconset，不再是「画一张 1024 PNG 再 `sips` 缩」。
  因为字标只在 128px 以上出现，小尺寸要用不同画面，缩放做不到这件事。
  细元素（条高、圆点、箭头线宽）给了最小像素下限，避免在小尺寸退化到亚像素消失

### Fixed

- `actions/upload-artifact` 从 v5 升到 v6。1.0.1 里把它升到 v5 并没有消掉 Node 20 弃用
  告警 —— v5 只是「preliminary support for Node.js 24」，默认仍跑在 Node 20 上，
  真正切换默认运行时的是 v6。没选 v7 是因为 v7 还引入了 ESM 重写和 `archive: false`
  直传特性，改动面更大，而这里只是上传一个 DMG

## [1.0.1] - 2026-08-07

只有 CI 的维护性改动，App 功能与 1.0.0 完全一致。

### Changed

- `actions/checkout` 与 `actions/upload-artifact` 升到 v5。GitHub 已弃用 Node.js 20，
  v4 会被强制跑在 Node 24 上并打一条告警

## [1.0.0] - 2026-08-07

第一个正式分发的版本。功能与 0.1.0 一致，区别在签名。

### Changed

- **Release 包改用稳定的自签身份签名**（`MacBarWaiter CI Signing`，仓库 Secrets 里的
  `MACOS_CERT_P12`）。0.1.0 是 ad-hoc 签名，每次构建签名都变，TCC 会当成另一个 App，
  于是每次更新都要重新授予屏幕录制权限。换成固定身份后不再需要
- 证书本身要长期保留：换一张新证书等于换身份，用户又得重新授权一次

> 从 0.1.0 升上来需要再授权一次屏幕录制（最后一次）—— 签名身份变了。

## [0.1.0] - 2026-08-07

第一版：一个下拉面板，把菜单栏上所有状态项（含被挤掉看不见的）原样列出来。

### Added

- **下拉面板**：菜单栏放一个下拉按钮，点开列出全部状态项。用 ScreenCaptureKit
  按窗口 ID 逐个抓图，**离屏的也抓得到**
- 当前不可见的图标底下画一道横线标出来，一眼看出自己漏掉了哪些
- 内容超过面板宽度自动换行；单个超宽项（如 319pt 的「正在播放」歌名）独占一行而不是被丢弃
- **底色自适应**：菜单栏图标随壁纸呈白字或黑字，按抓到的不透明像素平均亮度选深色或浅色底，
  保证看得清
- 缺屏幕录制权限时给出明确提示和一键跳转设置，而不是弹个空面板。
  权限判断不做前置拦截，直接尝试抓图、失败了再归因 —— 否则权限刚授予、进程还没重启时
  会误报成没权限
- 多屏：按 `SCWindow.frame.minY` 分组，只列出下拉按钮所在那块屏的菜单栏
- 专门的 App 图标：石墨底上一条菜单栏（右侧图标实心、往左淡出）加一个朝下的箭头

### 工程

- 采用与 KeyboardWaiter 一致的骨架：SwiftPM 清单（Core 库 + App 可执行 + XCTest 目标）、
  `Resources/Info.plist`、`scripts/` 下的构建与打包脚本、`release_notes/`
- 以拖拽安装的 DMG 分发，附 Applications 快捷方式
- GitHub Actions 在推 `v*` tag 时构建 .app、打 DMG、发 Release
- **渐进式签名**：默认 ad-hoc，配置了证书就用稳定身份，提供 Apple 凭据则额外公证。
  用稳定身份签名可以在更新之间保住「屏幕录制」权限 —— 实测 ad-hoc 签名下每次重新打包
  权限都会失效，因为签名变了，TCC 会当成另一个 App。先跑一次
  `scripts/bootstrap_local_signing.sh` 即可避免
- 构建与打包只需要 Command Line Tools；**只有 `swift test` 需要 Xcode**，
  因为 macOS 上 XCTest 与 swift-testing 的模块都只随 Xcode.app 分发

### 设计决策：为什么不是「把真图标滑出来」

一开始走的是另一条路 —— 插一个可变宽度的空白状态项，撑宽它把左边的图标顶出可用区，
缩窄再让它们滑回来（Hidden Bar / Dozer 的路子）。那条路**不需要任何权限**，
`NSStatusItem.length` 改位移实测是精确 1:1 的，机制本身成立。

放弃它是因为一个无法回避的天花板：**可见集永远只能是一个后缀，不能平移。**
系统右边界锚定、从右往左排，而别的 App 的图标顺序改不了，我们唯一的手段是插入空隙，
而空隙只能把东西往左推。所以「藏掉最右边那个、左边补进来」做不到 ——
那个图标要消失就得被推出可用区左边界，而它左边所有图标都得先出去，等于藏掉全部。

抓像素的代价是必须要屏幕录制权限，换来的是能真正看到全部。

### 踩过的坑

- `CGWindowListCreateImage` 在 macOS 26 SDK 里已是 **unavailable**（不只是 deprecated），
  只能用 ScreenCaptureKit
- ScreenCaptureKit 抓图前必须已初始化 `NSApplication`，否则崩在 `CGS_REQUIRE_INIT` 断言上
- 取窗口清单必须 `onScreenWindowsOnly: false`，否则查不到离屏的那些 —— 而那正是要找的
- `SCWindow.owningApplication` 对所有状态项一律返回「控制中心」（现代 macOS 由它统一托管
  合成），认不出真正的归属 App；`SCWindow.title` 只能给出一部分
- `NSStatusItem Preferred Position` 数值**越小越靠右**，0 是最右；而且必须在创建
  `NSStatusItem` **之前**写入。写成属性初始化器就来不及 —— 属性初始化器在 `init()` 体之前
  执行完，那时偏好还没写下，图标会落到最左边（可用区之外），连下拉按钮自己都看不见
- 状态项窗口的 `NSWindow.windowNumber` 是 2^33 量级的值，跟 `kCGWindowNumber` 不是一回事
- `CGPreflightScreenCaptureAccess()` 不能当前置拦截用，只能用于失败后的归因

[Unreleased]: https://github.com/WloBy-Labs/MacBarWaiter/compare/v1.1.0...HEAD
