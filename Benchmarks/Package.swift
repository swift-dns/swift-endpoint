// swift-tools-version: 6.3

import CompilerPluginSupport
// MARK: - BEGIN exact copy of the main package's Package.swift
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
        .package(url: "https://github.com/swift-dns/swift-idna.git", from: "1.0.0-beta.25"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.100.0"),
    ],
    targets: [
        .target(
            name: "Endpoint",
            dependencies: [
                "Domain",
                "IPAddress",
                "DomainIPAddressCompat",
                .product(
                    name: "SwiftIDNA",
                    package: "swift-idna",
                    condition: .when(traits: ["IDNA_SUPPORT"])
                ),
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
            "AvailabilityMacro=SwiftStdlib 6.2:macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=SwiftStdlib 6.0:macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=SwiftStdlib 5.3:macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=SwiftStdlib 5.1:macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0"
        ),
    ]
}
// MARK: - END exact copy of the main package's Package.swift

// MARK: - Add benchmark stuff now

package.platforms = [.macOS(.v26)]

package.dependencies.append(
    .package(
        url: "https://github.com/MahdiBM/package-benchmark.git",
        branch: "mmbm-range-relative-thresholds-options"
    ),
)

package.targets += [
    .executableTarget(
        name: "DomainNameBenchs",
        dependencies: [
            .product(name: "Benchmark", package: "package-benchmark"),
            "Domain",
        ],
        path: "DomainName",
        swiftSettings: settings,
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
    .executableTarget(
        name: "IPAddressBenchs",
        dependencies: [
            "Endpoint",
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "IPAddress",
        swiftSettings: settings,
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
]
