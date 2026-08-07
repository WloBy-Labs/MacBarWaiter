import XCTest
@testable import MacBarWaiterCore

/// 用一台 14 寸 MBP（有刘海）上实测到的数据做回归。
///
/// 实测：刘海右侧可用区 850..1512（662pt），主屏共 12 个状态项、合计 919pt，
/// 最左边 6 个被挤进刘海区域完全不渲染。抓图实验确认这 6 个的像素照样拿得到，
/// 所以面板里应该 12 个全在。
final class RealWorldTests: XCTestCase {
    private let xs: [CGFloat] = [595, 629, 756, 787, 819, 853,
                                 897, 1216, 1249, 1287, 1329, 1371]
    private let ws: [CGFloat] = [34, 127, 31, 32, 34, 44,
                                 319, 33, 38, 42, 42, 143]
    private let onScreen = [false, false, false, false, false, false,
                            true, true, true, true, true, true]

    private var all: [StatusItemInfo] {
        (0..<xs.count).map { info(UInt32($0), x: xs[$0], w: ws[$0], onScreen: onScreen[$0]) }
    }

    func testAllTwelveItemsIncludingInvisibleOnes() {
        let picked = ItemPicker.pick(all, menuBarY: 0, excludingX: nil)
        XCTAssertEqual(picked.count, 12, "12 个状态项全部入选，含 6 个看不见的")
        XCTAssertEqual(picked.filter { !$0.onScreen }.count, 6, "其中 6 个标记为当前不可见")
    }

    func testOrderMatchesMenuBar() {
        XCTAssertEqual(ItemPicker.pick(all, menuBarY: 0, excludingX: nil).map(\.frame.minX), xs)
    }

    /// 总宽 919pt 比 662pt 的可用区多出 257pt —— 这就是 6 个图标画不出来的原因
    func testTotalWidthExceedsUsableArea() {
        XCTAssertEqual(ws.reduce(0, +), 919)
        XCTAssertEqual(919 - 662, 257)
    }

    func testPanelWrapsWithoutDroppingAnything() {
        let rows = StripLayout.rows(widths: ws, maxWidth: 500, spacing: 8)
        XCTAssertGreaterThan(rows.count, 1, "919pt 装不进 500pt 宽的面板，必须换行")
        XCTAssertEqual(rows.flatMap { $0 }.count, 12, "换行后一个都没丢")
    }
}
