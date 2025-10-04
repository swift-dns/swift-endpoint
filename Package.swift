// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-endpoint",
    products: [
        .library(name: "Endpoint", targets: ["Endpoint"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "IPAddress", targets: ["IPAddress"]),
        .library(name: "DomainIPAddressCompat", targets: ["DomainIPAddressCompat"]),
    ],
    traits: [
        .trait(name: "IDNA_SUPPORT"),
        .trait(name: "NIO_BYTE_BUFFER_SUPPORT"),
        /// IDNA to be removed from the default traits in the future
        .default(enabledTraits: ["IDNA_SUPPORT", "NIO_BYTE_BUFFER_SUPPORT"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mahdibm/swift-idna.git", from: "1.0.0-beta.7"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.82.0"),
    ],
    targets: [
        .target(
            name: "Endpoint",
            dependencies: [
                "Domain",
                "IPAddress",
                "DomainIPAddressCompat",
            ],
            swiftSettings: settings
        ),
        .target(
            name: "Domain",
            dependencies: [
                .product(
                    name: "NIOCore",
                    package: "swift-nio",
                    condition: .when(traits: ["NIO_BYTE_BUFFER_SUPPORT"])
                ),
                .product(
                    name: "SwiftIDNA",
                    package: "swift-idna",
                    condition: .when(traits: ["IDNA_SUPPORT"])
                ),
            ],
            swiftSettings: settings
        ),
        .target(
            name: "IPAddress",
            swiftSettings: settings
        ),
        .target(
            name: "DomainIPAddressCompat",
            dependencies: [
                .product(
                    name: "NIOCore",
                    package: "swift-nio",
                    condition: .when(traits: ["NIO_BYTE_BUFFER_SUPPORT"])
                ),
                "Domain",
                "IPAddress",
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "EndpointTests",
            dependencies: [
                .product(
                    name: "NIOCore",
                    package: "swift-nio",
                    condition: .when(traits: ["NIO_BYTE_BUFFER_SUPPORT"])
                ),
                "Endpoint",
            ],
            swiftSettings: settings
        ),
    ]
)

var settings: [SwiftSetting] {
    [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("StrictMemorySafety"),
        .enableExperimentalFeature(
            "AvailabilityMacro=endpointApplePlatforms 26:macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=endpointApplePlatforms 15:macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=endpointApplePlatforms 13:macOS 13, iOS 16, tvOS 16, watchOS 9"
        ),
    ]
}
