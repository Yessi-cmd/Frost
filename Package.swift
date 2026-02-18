// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Frost",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Frost",
            path: "Frost",
            exclude: ["Resources"]
        )
    ]
)
