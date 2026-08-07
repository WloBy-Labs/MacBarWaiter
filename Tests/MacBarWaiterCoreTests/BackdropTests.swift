import XCTest
@testable import MacBarWaiterCore

final class BackdropTests: XCTestCase {
    /// 菜单栏图标随壁纸自适应明暗，白字要配深底，黑字要配浅底
    func testPicksContrastingBackdrop() {
        XCTAssertTrue(Backdrop.needsDarkBackdrop(averageLuminance: 0.9), "白色图标配深色底")
        XCTAssertFalse(Backdrop.needsDarkBackdrop(averageLuminance: 0.1), "黑色图标配浅色底")
        XCTAssertFalse(Backdrop.needsDarkBackdrop(averageLuminance: 0.5), "正中间时不用深色底")
    }

    func testNoImagesMeansNoLuminance() {
        XCTAssertNil(Backdrop.averageLuminance(of: []))
    }

    /// 全透明的图算不出亮度 —— 不透明像素一个都没有
    func testFullyTransparentImageYieldsNil() {
        let w = 8, h = 8
        var pixels = [UInt8](repeating: 0, count: w * h * 4)   // alpha 全 0
        let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8,
                            bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                | CGBitmapInfo.byteOrder32Little.rawValue)!
        XCTAssertNil(Backdrop.averageLuminance(of: [ctx.makeImage()!]))
    }
}
