// swift-tools-version: 6.0
// Throwaway spike for S-002. Do not merge into the app.
import PackageDescription

let package = Package(
    name: "S002",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "S002")
    ],
    swiftLanguageModes: [.v6]
)
