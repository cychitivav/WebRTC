// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "WebRTC",
    platforms: [.iOS(.v10), .macOS(.v10_11)],
    products: [
        .library(
            name: "WebRTC",
            targets: ["WebRTC"]),
    ],
    dependencies: [ ],
    targets: [
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/stasel/WebRTC/releases/download/137.0.0/WebRTC-M137.xcframework.zip",
            checksum: "9b45c5c5ecae392403758bb7262f408aa3cff705d41e862dd766856b610c3edd"
        ),
    ]
)
