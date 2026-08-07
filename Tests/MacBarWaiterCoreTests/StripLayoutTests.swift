import XCTest
@testable import MacBarWaiterCore

final class StripLayoutTests: XCTestCase {
    func testSingleRowWhenWideEnough() {
        XCTAssertEqual(StripLayout.rows(widths: [30, 40, 50], maxWidth: 200, spacing: 8),
                       [[0, 1, 2]])
    }

    /// 30 + 8 + 40 = 78，再加 8 + 50 = 136 > 100，所以第三个换行
    func testWrapsWhenTooWide() {
        XCTAssertEqual(StripLayout.rows(widths: [30, 40, 50], maxWidth: 100, spacing: 8),
                       [[0, 1], [2]])
    }

    /// 单个图标比面板还宽也要独占一行，不能丢掉（「正在播放」歌名就有 319pt）
    func testOversizedItemGetsItsOwnRow() {
        XCTAssertEqual(StripLayout.rows(widths: [400, 30], maxWidth: 100, spacing: 8),
                       [[0], [1]])
        XCTAssertEqual(StripLayout.rows(widths: [400], maxWidth: 100, spacing: 8), [[0]])
    }

    func testNoItemsMeansNoRows() {
        XCTAssertTrue(StripLayout.rows(widths: [], maxWidth: 100, spacing: 8).isEmpty)
    }

    /// 每一项必须出现且只出现一次，顺序不能乱
    func testEveryItemAppearsExactlyOnceInOrder() {
        let widths: [CGFloat] = [34, 124, 31, 32, 34, 44, 319, 33]
        let rows = StripLayout.rows(widths: widths, maxWidth: 300, spacing: 8)
        XCTAssertEqual(rows.flatMap { $0 }, Array(0..<widths.count))
    }

    func testContentSizeSingleRow() {
        let widths: [CGFloat] = [30, 40, 50]
        let rows = StripLayout.rows(widths: widths, maxWidth: 200, spacing: 8)
        let size = StripLayout.contentSize(widths: widths, rows: rows,
                                           rowHeight: 24, spacing: 8, padding: 12)
        XCTAssertEqual(size.width, 160, "30+8+40+8+50 = 136，加左右各 12")
        XCTAssertEqual(size.height, 48, "行高 24 加上下各 12")
    }

    func testContentSizeTwoRowsIncludesRowSpacing() {
        let widths: [CGFloat] = [30, 40, 50]
        let rows = StripLayout.rows(widths: widths, maxWidth: 100, spacing: 8)
        let size = StripLayout.contentSize(widths: widths, rows: rows,
                                           rowHeight: 24, spacing: 8, padding: 12)
        XCTAssertEqual(size.height, 24 * 2 + 8 + 24)
    }

    func testContentSizeEmpty() {
        let size = StripLayout.contentSize(widths: [], rows: [],
                                           rowHeight: 24, spacing: 8, padding: 12)
        XCTAssertEqual(size.width, 24)
        XCTAssertEqual(size.height, 24)
    }
}
