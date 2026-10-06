// swift-tools-version: 6.0
// Throwaway spike for S-003. Do not merge into the app.
import PackageDescription

let package = Package(
    name: "S003",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "S003")
    ],
    swiftLanguageModes: [.v6]
)
