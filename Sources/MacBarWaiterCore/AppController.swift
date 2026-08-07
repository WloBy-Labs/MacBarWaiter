import AppKit

/// 菜单栏上的下拉按钮 + 面板。
public final class AppController: NSObject, NSApplicationDelegate {
    // item 不能写成属性初始化器：属性初始化器在 init() 体之前就执行完了，
    // 那时 seedPosition() 还没写下位置偏好，状态项会落到最左边 —— 而菜单栏本来就是满的，
    // 最左边已经在可用区之外，结果连这个下拉按钮自己都画不出来，整个 App 没有入口。
    private var item: NSStatusItem!
    private let popover = NSPopover()
    private let strip = StripView()
    private var busy = false

    private static let autosaveName = "MacBarWaiter"

    /// 首次运行时把本项摆到第三方图标区最右端。
    ///
    /// 实测 `NSStatusItem Preferred Position` 数值**越小越靠右**，0 是最右
    /// （0 / 1 / 50 都落在最右侧，1000 就被挤到左边去了）。
    /// 之后用户 ⌘ 拖动过的位置由系统存回这个键，所以只在缺失时写。
    private static func seedPosition() {
        let key = "NSStatusItem Preferred Position \(autosaveName)"
        let d = UserDefaults.standard
        if d.object(forKey: key) == nil { d.set(0, forKey: key) }
    }

    public override init() {
        Self.seedPosition()
        super.init()

        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = Self.autosaveName
        item.button?.image = NSImage(systemSymbolName: "chevron.down.circle",
                                     accessibilityDescription: "MacBarWaiter")
        item.button?.target = self
        item.button?.action = #selector(buttonClicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        popover.behavior = .transient
        let vc = NSViewController()
        vc.view = strip
        popover.contentViewController = vc
    }

    // MARK: 点击

    @objc private func buttonClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
            return
        }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        openPanel()
    }

    /// 不管权限状态如何都先试着抓 —— 抓不到才报权限问题。
    /// 早先是先查 `CGPreflightScreenCaptureAccess()` 再决定要不要抓，
    /// 结果权限刚授予、进程还没重启时它返回 false，面板就一直显示「需要权限」，
    /// 哪怕实际已经抓得到图。
    private func openPanel() {
        guard let button = item.button else { return }

        strip.items = []
        strip.message = "正在读取菜单栏…"
        resize()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        refresh()
    }

    private func refresh() {
        guard !busy else { return }
        busy = true

        // 本项所在那块屏的菜单栏在 CG 坐标里的 y
        let ourFrame = item.button?.window?.frame
        let mainMaxY = NSScreen.screens.first { $0.frame.origin == .zero }?.frame.maxY
            ?? NSScreen.main?.frame.maxY ?? 0
        let screen = ourFrame.flatMap { f in NSScreen.screens.first { $0.frame.intersects(f) } }
            ?? NSScreen.main
        let menuBarY = ItemPicker.menuBarCGY(screenMaxY: screen?.frame.maxY ?? 0,
                                             mainMaxY: mainMaxY)

        Task { [weak self] in
            let result = await Capturer.snapshot(menuBarY: menuBarY, excludingX: ourFrame?.minX)
            guard let self else { return }
            await self.apply(result)
        }
    }

    /// 抓图结果回到主线程更新面板。单独抽成 @MainActor 方法，
    /// 免得在并发闭包里引用 self（Swift 6 下那是错误，不只是警告）。
    @MainActor
    private func apply(_ result: Result<[CapturedItem], CaptureError>) {
        busy = false
        switch result {
        case .success(let caught) where caught.isEmpty:
            strip.message = "没读到任何状态项。"
        case .success(let caught):
            strip.message = nil
            if let lum = Backdrop.averageLuminance(of: caught.map(\.image)) {
                strip.dark = Backdrop.needsDarkBackdrop(averageLuminance: lum)
            }
            strip.items = caught
        case .failure(.noPermission):
            strip.message = "需要「屏幕录制」权限才能读到菜单栏图标。\n"
                + "右键本图标可打开系统设置授权，\n授权后重启 MacBarWaiter 即可。"
            Capturer.requestPermission()
        case .failure(.failed(let why)):
            strip.message = "读取失败：\(why)"
        }
        resize()
    }

    private func resize() {
        let maxWidth = (item.button?.window?.screen ?? NSScreen.main)?.frame.width ?? 1440
        let size = strip.fittingSize(maxWidth: min(maxWidth - 80, 900))
        strip.frame = NSRect(origin: .zero, size: size)
        popover.contentSize = size
    }

    // MARK: 右键菜单

    private func showMenu() {
        let version = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let menu = NSMenu()
        menu.addItem(withTitle: "MacBarWaiter \(version)", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        let p = menu.addItem(withTitle: "打开屏幕录制权限设置",
                             action: #selector(openSettings), keyEquivalent: "")
        p.target = self
        menu.addItem(withTitle: "退出 MacBarWaiter",
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc private func openSettings() {
        let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}
