// swift-tools-version: 5.9

// HopQuest — opens in Xcode 15+ or Swift Playgrounds on iPad/Mac.
// Double-click HopQuest.swiftpm, pick an iPhone simulator, press Run.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "HopQuest",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "HopQuest",
            targets: ["AppModule"],
            bundleIdentifier: "com.phoronomics.hopquest",
            teamIdentifier: "X6LZQ3FS36",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.purple),
            supportedDeviceFamilies: [
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            exclude: ["README.md", "GAME_DESIGN.md", "ArtSource"]
        )
    ]
)
