// swift-tools-version: 6.0
// Throwaway spike for S-005. Do not merge into the app.
import PackageDescription

let package = Package(
    name: "S005",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "S005")
    ],
    swiftLanguageModes: [.v6]
)
