// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PTerminal",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "PTerminal",
            dependencies: ["SwiftTerm"],
            path: "Sources",
            resources: [.copy("zsh-autosuggestions.zsh")],
            linkerSettings: [.linkedLibrary("sqlite3")]
        )
    ]
)
