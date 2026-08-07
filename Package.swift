// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mac_bar_waiter",
    platforms: [
        // SCScreenshotManager 需要 macOS 14
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MacBarWaiterCore",
            targets: ["MacBarWaiterCore"]),
        .executable(
            name: "MacBarWaiter",
            targets: ["MacBarWaiterApp"])
    ],
    targets: [
        .target(
            name: "MacBarWaiterCore",
            path: "Sources/MacBarWaiterCore"),
        .executableTarget(
            name: "MacBarWaiterApp",
            dependencies: ["MacBarWaiterCore"],
            path: "Sources/MacBarWaiterApp"),
        .testTarget(
            name: "MacBarWaiterCoreTests",
            dependencies: ["MacBarWaiterCore"],
            path: "Tests/MacBarWaiterCoreTests")
    ]
)
