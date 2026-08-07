import AppKit

// 程序化绘制 App 图标：青绿底 + 一条菜单栏（右侧图标实心、往左逐渐淡出，
// 表示被系统挤掉看不见了）+ 朝下的箭头，下方是 WLOBY MB 字标。
// 与 WloBy 其他 App 同一套版式（见 PrWaiter/make-icon.swift），只有底色和图形不同 ——
// PrWaiter 是靛蓝、KeyboardWaiter 是石墨，这里用青绿区分开。
//
// 关键点：小尺寸不画字标。macOS 图标常以 16/32px 出现，八个字符横排在那个尺寸下
// 只会糊成一团。.icns 允许每个尺寸用不同画面，所以大尺寸给完整设计，
// 小尺寸只留图形 —— 这也是为什么要逐尺寸渲染而不是画一张大图再缩。
//
// 图形本身在所有尺寸都完整画（和 PrWaiter 一致），不按尺寸丢元素；
// 靠给细元素（条高、圆点、箭头线宽）设最小像素下限来保证它们不会退化到亚像素消失。
//
// 用法：swiftc -O make_appicon.swift -o make_appicon && ./make_appicon <out.iconset>

let wordmarkMinSize: CGFloat = 128

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let bgTop = color(0x1E6E68)          // 青绿，跟 PrWaiter 的靛蓝、KeyboardWaiter 的石墨区分开
let bgBottom = color(0x0A2B2A)
let glyph = color(0xFFFFFF, 0.95)
let textMain = color(0xFFFFFF)
let textAccent = color(0x5EE0C8)     // 亮薄荷，和底色同一色系但明度拉开

func render(size px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    // 画布是 bottom-left 原点，统一用「从顶部量」的坐标再翻过去
    func fromTop(_ y: CGFloat) -> CGFloat { s - y }

    // 圆角方块底：macOS 图标本体不铺满画布，四周留白
    let inset = s * 0.085
    let side = s - inset * 2
    let plate = NSRect(x: inset, y: inset, width: side, height: side)
    let radius = side * 0.2235

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: plate, xRadius: radius, yRadius: radius).addClip()
    NSGradient(starting: bgTop, ending: bgBottom)!.draw(in: plate, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    let showWordmark = s >= wordmarkMinSize

    // 细元素在小尺寸会退化到亚像素直接消失，一律给下限
    let barH = max(side * 0.155, 3)
    let dot = max(barH * 0.44, 2)
    let thick = max(side * 0.062, 1.5)
    let cw = side * 0.30
    let ch = side * 0.135
    let stackGap = side * 0.075

    // 有字标时整组图形上移让出下方文字位；没字标就整块居中
    let blockH = barH + stackGap + ch
    let blockTop = showWordmark ? side * 0.175 : (side - blockH) / 2

    let barRect = NSRect(x: plate.minX + side * 0.10,
                         y: fromTop(inset + blockTop + barH),
                         width: side * 0.80, height: barH)
    color(0xFFFFFF, 0.16).setFill()
    NSBezierPath(roundedRect: barRect, xRadius: barH / 2, yRadius: barH / 2).fill()

    // 条上的图标：从右往左排，越往左越淡 —— 表示被挤出去的那些
    let dotGap = dot * 0.8
    var x = barRect.maxX - dotGap - dot
    for i in 0..<5 {
        let alpha: CGFloat = i < 2 ? 0.95 : max(0.14, 0.95 - CGFloat(i - 1) * 0.27)
        color(0xFFFFFF, alpha).setFill()
        let r = NSRect(x: x, y: barRect.midY - dot / 2, width: dot, height: dot)
        NSBezierPath(roundedRect: r, xRadius: dot * 0.3, yRadius: dot * 0.3).fill()
        x -= dot + dotGap
    }

    // 朝下的箭头：表示点开能看到全部
    let cy = fromTop(inset + blockTop + barH + stackGap + ch / 2)

    let chevron = NSBezierPath()
    chevron.lineWidth = thick
    chevron.lineCapStyle = .round
    chevron.lineJoinStyle = .round
    chevron.move(to: NSPoint(x: plate.midX - cw / 2, y: cy + ch / 2))
    chevron.line(to: NSPoint(x: plate.midX, y: cy - ch / 2))
    chevron.line(to: NSPoint(x: plate.midX + cw / 2, y: cy + ch / 2))
    glyph.setStroke()
    chevron.stroke()

    if showWordmark {
        let fontSize = side * 0.145
        let font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .kern: fontSize * 0.02]
        let text = NSMutableAttributedString(string: "WLOBY", attributes: attrs)
        text.addAttribute(.foregroundColor, value: textMain,
                          range: NSRange(location: 0, length: 5))
        let suffix = NSMutableAttributedString(string: "MB", attributes: attrs)
        suffix.addAttribute(.foregroundColor, value: textAccent,
                            range: NSRange(location: 0, length: 2))
        // 两段之间留一点气口，颜色差别才不显得是一个词
        text.append(NSAttributedString(string: " ", attributes: [.font: font]))
        text.append(suffix)

        // 全是大写字母，用 capHeight 而不是行高来定位 —— 行高含上下留白，
        // 按它居中会让字看起来偏低、和图形之间空出一块
        let tw = text.size().width
        let baseline = fromTop(inset + side * 0.757 + font.capHeight / 2)
        text.draw(at: NSPoint(x: inset + (side - tw) / 2, y: baseline + font.descender))
    }

    return rep.representation(using: .png, properties: [:])!
}

// MARK: 输出 iconset

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

// 同一像素尺寸可能对应两个文件名（如 32 既是 16@2x 也是 32x32）
let entries: [(px: Int, names: [String])] = [
    (16, ["icon_16x16.png"]),
    (32, ["icon_16x16@2x.png", "icon_32x32.png"]),
    (64, ["icon_32x32@2x.png"]),
    (128, ["icon_128x128.png"]),
    (256, ["icon_128x128@2x.png", "icon_256x256.png"]),
    (512, ["icon_256x256@2x.png", "icon_512x512.png"]),
    (1024, ["icon_512x512@2x.png"]),
]

for e in entries {
    let data = render(size: e.px)
    for name in e.names {
        try! data.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
    }
    let note = CGFloat(e.px) >= wordmarkMinSize ? "" : "（无字标）"
    print("  \(e.px)x\(e.px)\(note) → \(e.names.joined(separator: ", "))")
}
print("iconset 已生成：\(out)")
