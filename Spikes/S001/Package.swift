// swift-tools-version: 6.0
// Throwaway spike for S-001. Do not merge into the app.
import PackageDescription

let package = Package(
    name: "S001",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "S001")
    ],
    swiftLanguageModes: [.v6]
)
