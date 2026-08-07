import CoreGraphics

// 菜单栏的状态项由系统从右往左排布，排不下的不会折叠、不会换行，直接不渲染 ——
// 它们依然占着坐标和宽度，只是画不出来。有刘海的机器尤其明显：刘海把菜单栏切成两块，
// 状态项只能用刘海右边那一段，于是排不下的图标就永远看不见了。
//
// MacBarWaiter 不去动那些真图标，而是把它们的像素抓下来画在自己的下拉面板里。

/// 一个状态项的元信息。从 SCWindow 提取成纯数据，方便离开 ScreenCaptureKit 单独测试。
public struct StatusItemInfo: Equatable, Sendable {
    public var windowID: UInt32
    /// CG 坐标（原点在主屏左上、y 向下）
    public var frame: CGRect
    /// 当前是否真的画在屏幕上。false 就是被挤掉、看不见的那些
    public var onScreen: Bool
    /// SCWindow.title，形如 "WiFi" / "Clock" / "Amphetamine" / "Item-0"
    public var title: String

    public init(windowID: UInt32, frame: CGRect, onScreen: Bool, title: String) {
        self.windowID = windowID
        self.frame = frame
        self.onScreen = onScreen
        self.title = title
    }
}

public enum ItemPicker {
    /// 状态项窗口所在的层级
    public static let statusItemLayer = 25

    /// 从窗口清单里挑出某一条菜单栏上的状态项。
    ///
    /// - Parameters:
    ///   - menuBarY: 该屏菜单栏在 CG 坐标里的 y（主屏为 0，上方的屏为负）
    ///   - excludingX: 要排除的 x（自己那个图标），避免面板里出现自己
    ///
    /// 结果按 x 升序，也就是菜单栏上从左到右的实际顺序。
    public static func pick(_ all: [StatusItemInfo], menuBarY: CGFloat,
                            excludingX: CGFloat?) -> [StatusItemInfo] {
        all.filter { item in
            guard abs(item.frame.minY - menuBarY) < 1 else { return false }
            guard item.frame.width > 1, item.frame.height > 1 else { return false }
            if let ex = excludingX, abs(item.frame.minX - ex) < 2 { return false }
            return true
        }
        .sorted { $0.frame.minX < $1.frame.minX }
    }

    /// CG 坐标（原点在主屏左上、y 向下）与 AppKit 坐标（原点在主屏左下、y 向上）互换。
    /// 用来把「本项所在的那块屏」对应到它菜单栏的 CG y。
    public static func menuBarCGY(screenMaxY: CGFloat, mainMaxY: CGFloat) -> CGFloat {
        mainMaxY - screenMaxY
    }
}
