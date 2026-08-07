import CoreGraphics

public enum StripLayout {
    /// 把图标按原始顺序横向排进面板，排不下就换行。
    /// 返回每一行包含的下标。单个图标比面板还宽时（比如 319pt 的「正在播放」歌名）
    /// 让它独占一行，而不是把它丢掉。
    public static func rows(widths: [CGFloat], maxWidth: CGFloat, spacing: CGFloat) -> [[Int]] {
        var out: [[Int]] = []
        var line: [Int] = []
        var used: CGFloat = 0

        for (i, w) in widths.enumerated() {
            let need = line.isEmpty ? w : used + spacing + w
            if !line.isEmpty && need > maxWidth {
                out.append(line)
                line = [i]
                used = w
            } else {
                line.append(i)
                used = need
            }
        }
        if !line.isEmpty { out.append(line) }
        return out
    }

    /// 面板的内容尺寸。
    public static func contentSize(widths: [CGFloat], rows: [[Int]],
                                   rowHeight: CGFloat, spacing: CGFloat,
                                   padding: CGFloat) -> CGSize {
        let w = rows.map { row in
            row.reduce(0) { $0 + widths[$1] } + CGFloat(max(row.count - 1, 0)) * spacing
        }.max() ?? 0
        let h = CGFloat(rows.count) * rowHeight + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: w + padding * 2, height: h + padding * 2)
    }
}
