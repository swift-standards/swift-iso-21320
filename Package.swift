// swift-tools-version: 6.2

import PackageDescription

// ISO/IEC 21320-1:2015 - Document Container File
// A restricted ZIP format subset used by EPUB, ODF, OOXML
let package = Package(
    name: "swift-iso-21320",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: "ISO 21320", targets: ["ISO 21320"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.10.0"),
        .package(path: "../swift-rfc-1951"),
    ],
    targets: [
        .target(
            name: "ISO 21320",
            dependencies: [
                .product(name: "Standards", package: "swift-standards"),
                .product(name: "RFC 1951", package: "swift-rfc-1951"),
            ]
        ),
        .testTarget(
            name: "ISO 21320".tests,
            dependencies: ["ISO 21320"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ]
}
