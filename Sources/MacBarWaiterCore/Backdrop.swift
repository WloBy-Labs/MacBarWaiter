import CoreGraphics

/// 菜单栏图标是根据壁纸自适应明暗的，抓下来是带透明通道的白字或黑字。
/// 画在面板上得给个反差够的底色，否则白字配白底就什么都看不见。
public enum Backdrop {
    /// 不透明像素偏亮（白字）就返回 true，该配深色底。
    public static func needsDarkBackdrop(averageLuminance: Double) -> Bool {
        averageLuminance > 0.5
    }

    /// 算一批图里不透明像素的平均亮度。没有不透明像素时返回 nil。
    public static func averageLuminance(of images: [CGImage]) -> Double? {
        var sum = 0.0
        var count = 0
        for img in images {
            guard img.bitsPerPixel == 32,
                  let data = img.dataProvider?.data,
                  let ptr = CFDataGetBytePtr(data) else { continue }
            let bpr = img.bytesPerRow
            // 大图上逐像素算没必要，隔几个采样就够判断明暗
            let xStep = max(1, img.width / 32)
            let yStep = max(1, img.height / 16)
            for y in stride(from: 0, to: img.height, by: yStep) {
                for x in stride(from: 0, to: img.width, by: xStep) {
                    let off = y * bpr + x * 4
                    guard ptr[off + 3] > 8 else { continue }   // 透明像素不算
                    let b = Double(ptr[off]) / 255              // BGRA
                    let g = Double(ptr[off + 1]) / 255
                    let r = Double(ptr[off + 2]) / 255
                    sum += 0.2126 * r + 0.7152 * g + 0.0722 * b
                    count += 1
                }
            }
        }
        return count > 0 ? sum / Double(count) : nil
    }
}
