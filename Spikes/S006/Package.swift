// swift-tools-version: 6.0
// Throwaway spike for S-006. Do not merge into the app.
import PackageDescription

let package = Package(
    name: "S006",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "S006")
    ],
    swiftLanguageModes: [.v6]
)
