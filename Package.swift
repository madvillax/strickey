// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Strickey",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Strickey", targets: ["Strickey"])],
    targets: [
        .target(name: "StrickeyCore", resources: [.copy("Resources/CherryMX")]),
        .executableTarget(name: "Strickey", dependencies: ["StrickeyCore"]),
        .testTarget(name: "StrickeyCoreTests", dependencies: ["StrickeyCore"]),
    ]
)
