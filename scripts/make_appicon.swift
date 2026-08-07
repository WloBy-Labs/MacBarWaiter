import AppKit

// 生成 1024x1024 的 App 图标底图。由 make_appicon.sh 调用后切成 .iconset 再打成 .icns。
//
// 设计意图：一条菜单栏，右边几个图标挤在一起、左边的淡出（表示被挤掉看不见了），
// 下面一个朝下的箭头表示「点开能看到全部」。

let outPath = CommandLine.arguments[1]
let side: CGFloat = 1024

guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                 pixelsWide: Int(side), pixelsHigh: Int(side),
                                 bitsPerSample: 8, samplesPerPixel: 4,
                                 hasAlpha: true, isPlanar: false,
                                 colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 0) else {
    fatalError("无法创建位图")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// 底：macOS 风格的圆角方形 + 石墨色渐变
let inset = side * 0.085
let bg = NSRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
let bgPath = NSBezierPath(roundedRect: bg, xRadius: side * 0.185, yRadius: side * 0.185)
NSGradient(starting: NSColor(calibratedWhite: 0.26, alpha: 1),
           ending: NSColor(calibratedWhite: 0.11, alpha: 1))?
    .draw(in: bgPath, angle: -90)

// 菜单栏：一条横条，靠上
let barH = side * 0.115
let barRect = NSRect(x: bg.minX + side * 0.075, y: bg.maxY - side * 0.115 - barH,
                     width: bg.width - side * 0.15, height: barH)
NSColor(calibratedWhite: 1, alpha: 0.14).setFill()
NSBezierPath(roundedRect: barRect, xRadius: barH / 2, yRadius: barH / 2).fill()

// 条上的图标：从右往左排，越往左越淡 —— 表示被挤出去的那些
let dot = barH * 0.42
let gap = dot * 0.85
var x = barRect.maxX - gap - dot
for i in 0..<6 {
    // 右边三个实心，往左逐渐淡出
    let alpha: CGFloat = i < 3 ? 0.95 : max(0.12, 0.95 - CGFloat(i - 2) * 0.28)
    NSColor(calibratedWhite: 1, alpha: alpha).setFill()
    let r = NSRect(x: x, y: barRect.midY - dot / 2, width: dot, height: dot)
    NSBezierPath(roundedRect: r, xRadius: dot * 0.28, yRadius: dot * 0.28).fill()
    x -= dot + gap
}

// 朝下的箭头：表示点开能看到全部
let cw = side * 0.30          // 箭头宽
let ch = side * 0.155         // 箭头高
let thick = side * 0.058
let cy = bg.minY + side * 0.20
let chevron = NSBezierPath()
chevron.lineWidth = thick
chevron.lineCapStyle = .round
chevron.lineJoinStyle = .round
chevron.move(to: NSPoint(x: side / 2 - cw / 2, y: cy + ch / 2))
chevron.line(to: NSPoint(x: side / 2, y: cy - ch / 2))
chevron.line(to: NSPoint(x: side / 2 + cw / 2, y: cy + ch / 2))
NSColor.white.setStroke()
chevron.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("PNG 编码失败")
}
try png.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath)")
