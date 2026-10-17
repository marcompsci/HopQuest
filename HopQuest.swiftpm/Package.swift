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
            displayVersion: "2.0",
            bundleVersion: "2",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.purple),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight(.when(deviceFamilies: [.pad])),
                .landscapeLeft(.when(deviceFamilies: [.pad])),
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .localNetwork(purposeString: "HopQuest uses your local network so kids in the same room can see each other's buddies in Hop Village and play Brain Duels.",
                              bonjourServiceTypes: ["_hopq-village._tcp", "_hopq-village._udp"])
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
