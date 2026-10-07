// swift-tools-version: 6.0
// Throwaway spike for S-004. Do not merge into the app.
import PackageDescription

let package = Package(
    name: "S004",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "S004")
    ],
    swiftLanguageModes: [.v6]
)
