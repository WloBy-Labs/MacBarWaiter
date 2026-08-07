import XCTest
@testable import MacBarWaiterCore

final class ItemPickerTests: XCTestCase {
    private let all = [
        info(3, x: 300),
        info(1, x: 100),
        info(7, x: 200, y: -1152),        // 另一块屏的菜单栏
        info(9, x: 400, w: 0, h: 0),      // 尺寸异常
        info(5, x: 500),                   // 假设这是自己
    ]

    func testPicksOnlyRequestedMenuBarSortedByX() {
        XCTAssertEqual(ItemPicker.pick(all, menuBarY: 0, excludingX: nil).map(\.windowID),
                       [1, 3, 5])
    }

    func testExcludesOtherDisplaysAndZeroSizedItems() {
        let picked = ItemPicker.pick(all, menuBarY: 0, excludingX: nil)
        XCTAssertFalse(picked.contains { $0.windowID == 7 }, "别的屏幕上的项要排除")
        XCTAssertFalse(picked.contains { $0.windowID == 9 }, "零尺寸的项要排除")
    }

    func testExcludesOwnIconByX() {
        XCTAssertEqual(ItemPicker.pick(all, menuBarY: 0, excludingX: 500).map(\.windowID), [1, 3])
    }

    /// 排除是按坐标近似匹配的，差 1pt 也算同一个
    func testExclusionToleratesOnePointOfError() {
        XCTAssertEqual(ItemPicker.pick(all, menuBarY: 0, excludingX: 501).map(\.windowID), [1, 3])
    }

    func testPicksFromSecondaryDisplay() {
        XCTAssertEqual(ItemPicker.pick(all, menuBarY: -1152, excludingX: nil).map(\.windowID), [7])
    }

    func testEmptyInput() {
        XCTAssertTrue(ItemPicker.pick([], menuBarY: 0, excludingX: nil).isEmpty)
    }

    /// CG 原点在主屏左上、y 向下；AppKit 原点在主屏左下、y 向上
    func testMenuBarCoordinateConversion() {
        XCTAssertEqual(ItemPicker.menuBarCGY(screenMaxY: 982, mainMaxY: 982), 0,
                       "主屏菜单栏对应 CG y = 0")
        XCTAssertEqual(ItemPicker.menuBarCGY(screenMaxY: 2134, mainMaxY: 982), -1152,
                       "上方外接屏对应负的 CG y")
        XCTAssertEqual(ItemPicker.menuBarCGY(screenMaxY: 0, mainMaxY: 982), 982,
                       "下方外接屏对应正的 CG y")
    }
}
