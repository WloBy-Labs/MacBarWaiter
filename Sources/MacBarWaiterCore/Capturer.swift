import AppKit
import ScreenCaptureKit

public struct CapturedItem {
    public var info: StatusItemInfo
    public var image: CGImage
}

public enum CaptureError: Error {
    case noPermission
    case failed(String)
}

public enum Capturer {
    /// SCShareableContent 没有屏幕录制权限时抛的错误码（SCStreamError.userDeclined）
    static let userDeclinedCode = -3801

    /// 把一次失败归因成「没权限」还是「别的问题」。
    ///
    /// 抽成纯函数是为了能测。注意这只用于**失败之后**的归因，不做前置拦截 ——
    /// 见 `snapshot` 的说明。
    public static func classify(errorDomain: String, errorCode: Int,
                                preflightGranted: Bool) -> CaptureError {
        if errorDomain.contains("SCStream") && errorCode == userDeclinedCode {
            return .noPermission
        }
        // 错误码没对上，但系统说没授权，那也当没权限处理
        if !preflightGranted { return .noPermission }
        return .failed("\(errorDomain) \(errorCode)")
    }

    /// 系统认为有没有屏幕录制权限。
    ///
    /// **只用于提示措辞和失败归因，不用来拦截抓图。** 权限刚授予、进程还没重启时它会
    /// 返回 false，拿它做前置判断会导致明明抓得到图却只显示「需要权限」。
    public static var preflightGranted: Bool { CGPreflightScreenCaptureAccess() }

    public static func requestPermission() { _ = CGRequestScreenCaptureAccess() }

    /// 抓下某一条菜单栏上的全部状态项。
    ///
    /// 不做权限前置判断，直接尝试、失败了再归因 —— 这样只要实际抓得到就能显示，
    /// 不受 `CGPreflightScreenCaptureAccess()` 准不准的影响。
    ///
    /// 注意：调用前必须已经初始化 `NSApplication`，否则 ScreenCaptureKit 会崩在
    /// `CGS_REQUIRE_INIT` 断言上（写命令行验证脚本时尤其容易撞到）。
    public static func snapshot(menuBarY: CGFloat, excludingX: CGFloat?) async
        -> Result<[CapturedItem], CaptureError> {
        let windows: [SCWindow]
        do {
            // onScreenWindowsOnly 必须为 false —— 被挤掉的图标不算「在屏幕上」，
            // 传 true 就查不到它们，而那正是要找的
            windows = try await SCShareableContent
                .excludingDesktopWindows(false, onScreenWindowsOnly: false).windows
        } catch {
            let ns = error as NSError
            return .failure(classify(errorDomain: ns.domain, errorCode: ns.code,
                                     preflightGranted: preflightGranted))
        }

        let pairs = windows.compactMap { w -> (StatusItemInfo, SCWindow)? in
            guard w.windowLayer == ItemPicker.statusItemLayer else { return nil }
            return (StatusItemInfo(windowID: w.windowID, frame: w.frame,
                                   onScreen: w.isOnScreen, title: w.title ?? ""), w)
        }

        let wanted = ItemPicker.pick(pairs.map(\.0), menuBarY: menuBarY, excludingX: excludingX)
        let byID = Dictionary(pairs.map { ($0.0.windowID, $0.1) }, uniquingKeysWith: { a, _ in a })

        var out: [CapturedItem] = []
        for info in wanted {
            guard let w = byID[info.windowID] else { continue }
            let cfg = SCStreamConfiguration()
            cfg.width = Int(info.frame.width * 2)      // 抓 2x，Retina 上才清楚
            cfg.height = Int(info.frame.height * 2)
            cfg.showsCursor = false
            cfg.ignoreShadowsSingleWindow = true
            do {
                let img = try await SCScreenshotManager.captureImage(
                    contentFilter: SCContentFilter(desktopIndependentWindow: w),
                    configuration: cfg)
                out.append(CapturedItem(info: info, image: img))
            } catch {
                continue   // 个别项抓不到就跳过，不影响其余的
            }
        }
        return .success(out)
    }
}
