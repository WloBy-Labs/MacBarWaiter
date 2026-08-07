import AppKit

/// 把抓来的图标按原顺序画成一条（或几行）。当前被挤掉、看不见的那些底下画一道横线标出来。
public final class StripView: NSView {
    public var items: [CapturedItem] = [] { didSet { needsDisplay = true } }
    public var dark = true
    public var message: String?

    static let rowHeight: CGFloat = 24
    static let spacing: CGFloat = 8
    static let padding: CGFloat = 12
    /// 标出「当前不可见」的那道横线
    static let markerHeight: CGFloat = 2
    static let markerGap: CGFloat = 3

    public override var isFlipped: Bool { false }

    /// 按当前内容算出面板该多大。
    public func fittingSize(maxWidth: CGFloat) -> CGSize {
        if message != nil || items.isEmpty { return CGSize(width: 280, height: 84) }
        let widths = items.map { $0.info.frame.width }
        let rows = StripLayout.rows(widths: widths,
                                    maxWidth: maxWidth - Self.padding * 2,
                                    spacing: Self.spacing)
        return StripLayout.contentSize(
            widths: widths, rows: rows,
            // 每行底下要留出画横线的空间
            rowHeight: Self.rowHeight + Self.markerGap + Self.markerHeight,
            spacing: Self.spacing, padding: Self.padding)
    }

    public override func draw(_ dirtyRect: NSRect) {
        (dark ? NSColor(white: 0.14, alpha: 1) : NSColor(white: 0.96, alpha: 1)).setFill()
        bounds.fill()

        let fg = dark ? NSColor.white : NSColor.black

        if let message {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: fg.withAlphaComponent(0.85),
            ]
            (message as NSString).draw(in: bounds.insetBy(dx: Self.padding, dy: Self.padding),
                                       withAttributes: attrs)
            return
        }

        let widths = items.map { $0.info.frame.width }
        let rows = StripLayout.rows(widths: widths,
                                    maxWidth: bounds.width - Self.padding * 2,
                                    spacing: Self.spacing)
        let lineHeight = Self.rowHeight + Self.markerGap + Self.markerHeight

        var top = bounds.maxY - Self.padding
        for row in rows {
            var x = Self.padding
            for i in row {
                let it = items[i]
                let iconRect = NSRect(x: x, y: top - Self.rowHeight,
                                      width: widths[i], height: Self.rowHeight)
                NSGraphicsContext.current?.cgContext.draw(it.image, in: iconRect)

                // 当前被挤掉看不见的，底下画一道线标出来
                if !it.info.onScreen {
                    fg.withAlphaComponent(0.7).setFill()
                    NSRect(x: x, y: iconRect.minY - Self.markerGap - Self.markerHeight,
                           width: widths[i], height: Self.markerHeight).fill()
                }
                x += widths[i] + Self.spacing
            }
            top -= lineHeight + Self.spacing
        }
    }
}
