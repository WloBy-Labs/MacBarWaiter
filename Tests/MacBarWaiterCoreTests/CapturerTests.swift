import XCTest
@testable import MacBarWaiterCore

/// 失败归因的测试。抓图本身要看屏幕才知道对不对，但「一次失败该不该算成没权限」
/// 是纯逻辑，值得钉住 —— 之前用 CGPreflightScreenCaptureAccess() 做前置拦截时，
/// 权限刚授予、进程还没重启的那段时间里面板会一直显示「需要权限」。
final class CapturerTests: XCTestCase {
    private let scDomain = "com.apple.ScreenCaptureKit.SCStreamErrorDomain"

    func testUserDeclinedIsPermissionError() {
        let e = Capturer.classify(errorDomain: scDomain, errorCode: -3801,
                                  preflightGranted: true)
        guard case .noPermission = e else {
            return XCTFail("userDeclined 应归为没权限，实际 \(e)")
        }
    }

    /// 错误码没对上，但系统说没授权 —— 也当没权限处理
    func testUnknownErrorWithoutPreflightIsPermissionError() {
        let e = Capturer.classify(errorDomain: "SomeOtherDomain", errorCode: 42,
                                  preflightGranted: false)
        guard case .noPermission = e else {
            return XCTFail("未授权时任何失败都该归为没权限，实际 \(e)")
        }
    }

    /// 有授权、错误码也不是 userDeclined —— 那就是别的问题，不要误报成权限问题
    func testUnrelatedErrorWithPreflightIsNotPermissionError() {
        let e = Capturer.classify(errorDomain: "SomeOtherDomain", errorCode: 42,
                                  preflightGranted: true)
        guard case .failed(let why) = e else {
            return XCTFail("已授权时不该归为没权限，实际 \(e)")
        }
        XCTAssertTrue(why.contains("42"), "归因信息里要带上原始错误码，便于排查")
    }

    /// 域名对但错误码是别的 SCStream 错误 —— 已授权的话不算权限问题
    func testOtherScStreamErrorWithPreflightIsNotPermissionError() {
        let e = Capturer.classify(errorDomain: scDomain, errorCode: -3802,
                                  preflightGranted: true)
        guard case .failed = e else {
            return XCTFail("-3802 不是 userDeclined，实际 \(e)")
        }
    }
}
