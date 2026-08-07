import XCTest
@testable import MacBarWaiterCore

func info(_ id: UInt32, x: CGFloat, y: CGFloat = 0, w: CGFloat = 30,
          h: CGFloat = 24, onScreen: Bool = true, title: String = "") -> StatusItemInfo {
    StatusItemInfo(windowID: id, frame: CGRect(x: x, y: y, width: w, height: h),
                   onScreen: onScreen, title: title)
}
