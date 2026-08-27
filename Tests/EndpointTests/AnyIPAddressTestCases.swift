import Endpoint

extension IPPropertyTestCase where IPAddressType == AnyIPAddress {
    static let all: [Self] = [
        IPPropertyTestCase(.v4(IPv4Address(127, 0, 0, 0)), "isLoopback", \.isLoopback),
        IPPropertyTestCase(.v4(IPv4Address(127, 0, 0, 1)), "isLoopback", \.isLoopback),
        IPPropertyTestCase(.v4(IPv4Address(127, 128, 9, 22)), "isLoopback", \.isLoopback),
        IPPropertyTestCase(.v4(IPv4Address(127, 255, 255, 255)), "isLoopback", \.isLoopback),
        IPPropertyTestCase(
            .v4(IPv4Address(126, 0, 0, 0)),
            "!isLoopback",
            { @Sendable in !$0.isLoopback }
        ),
        IPPropertyTestCase(
            .v4(IPv4Address(128, 0, 0, 0)),
            "!isLoopback",
            { @Sendable in !$0.isLoopback }
        ),
        IPPropertyTestCase(.v4(IPv4Address(224, 0, 0, 0)), "isMulticast", \.isMulticast),
        IPPropertyTestCase(.v4(IPv4Address(239, 255, 255, 255)), "isMulticast", \.isMulticast),
        IPPropertyTestCase(.v4(IPv4Address(229, 28, 192, 233)), "isMulticast", \.isMulticast),
        IPPropertyTestCase(
            .v4(IPv4Address(244, 0, 0, 0)),
            "!isMulticast",
            { @Sendable in !$0.isMulticast }
        ),

        IPPropertyTestCase(.v6(IPv6Address("::1" as String)!), "isLoopback", \.isLoopback),
        IPPropertyTestCase(
            .v6(IPv6Address("::1:1" as String)!),
            "!isLoopback",
            { @Sendable in !$0.isLoopback }
        ),
        IPPropertyTestCase(.v6(IPv6Address("FF00::" as String)!), "isMulticast", \.isMulticast),
        IPPropertyTestCase(.v6(IPv6Address("FF92::" as String)!), "isMulticast", \.isMulticast),
        IPPropertyTestCase(
            .v6(IPv6Address("FFFF:998A::1" as String)!),
            "isMulticast",
            \.isMulticast
        ),
        IPPropertyTestCase(
            .v6(IPv6Address("FF::" as String)!),
            "!isMulticast",
            { @Sendable in !$0.isMulticast }
        ),
        IPPropertyTestCase(
            .v6(IPv6Address("00FF::" as String)!),
            "!isMulticast",
            { @Sendable in !$0.isMulticast }
        ),
        IPPropertyTestCase(
            .v6(IPv6Address("FAFF::" as String)!),
            "!isMulticast",
            { @Sendable in !$0.isMulticast }
        ),
        IPPropertyTestCase(.v4(IPv4Address(255, 255, 192, 0)), "isContiguous", \.isContiguous),
        IPPropertyTestCase(.v6(IPv6Address("FFFF::" as String)!), "isContiguous", \.isContiguous),
        IPPropertyTestCase(
            .v4(IPv4Address(255, 0, 0, 255)),
            "!isContiguous",
            { @Sendable in !$0.isContiguous }
        ),
        IPPropertyTestCase(
            .v6(IPv6Address("FFFF::FFFF" as String)!),
            "!isContiguous",
            { @Sendable in !$0.isContiguous }
        ),
    ]
}

extension AnyIPAddressTestCase {
    @available(SwiftStdlib 6.0, *)
    static let stringAndAddress: [Self] = [
        AnyIPAddressTestCase("192.168.1.1", ip: (.v4(IPv4Address(192, 168, 1, 1)), "192.168.1.1")),
        AnyIPAddressTestCase("[192.168.1.256]", ip: nil),
        AnyIPAddressTestCase(
            "[2001:0:0:1::]",
            ip: (.v6(IPv6Address(0x2001_0000_0000_0001_0000_0000_0000_0000)), "2001:0:0:1::")
        ),
        AnyIPAddressTestCase(
            "0:0:0:0:0:FFFF:204.152.189.116",
            ip: (
                .v6(IPv6Address(0x0000_0000_0000_0000_0000_FFFF_CC98_BD74)),
                "::ffff:204.152.189.116"
            )
        ),
        AnyIPAddressTestCase(
            "[2001:db8:85a3::100]",
            ip: (
                .v6(IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0100)), "2001:db8:85a3::100"
            )
        ),
        AnyIPAddressTestCase("[0:1:2:3:4:0:5:6::]", ip: nil),
    ]

    static let rawByteReject: [[UInt8]] = [
        [49, 57, 50, 46, 48, 46, 50, 46, 49, 57, 50, 46, 255, 46, 46],
        [49, 57, 50, 46, 48, 46, 50, 174],
        [49, 57, 50, 46, 48, 46, 178, 46],
        [49, 57, 50, 46, 48, 57, 50, 46, 174],
        [49, 57, 50, 46, 48, 174, 50, 46],
        [49, 57, 50, 46, 49, 57, 50, 46, 48, 46, 50, 54, 54, 49, 25],
        [49, 57, 50, 46, 57, 50, 46, 50, 49, 57, 19, 46],
        [49, 57, 50, 46, 176, 46, 50, 46],
        [50, 48, 48, 49, 58, 100, 98, 56, 58, 58, 49, 58, 58, 10],
        [50, 48, 48, 49, 58, 100, 98, 56, 58, 58, 49, 58, 58, 50, 10],
        [50, 48, 48, 49, 58, 100, 98, 56, 58, 58, 102, 102, 102, 102, 58, 50, 10],
        [50, 53, 53, 46, 50, 53, 53, 46, 50, 53, 53, 46, 50, 53, 53, 1],
        [
            50, 58, 97, 58, 56, 58, 69, 69, 69, 69, 58, 58, 69, 69, 69, 69, 58, 70, 58, 69, 69,
            69, 56,
            58, 69, 69, 69, 69, 28, 42, 58,
        ],
        [58, 186],
        [70, 58, 65, 58, 56, 58, 69, 69, 69, 69, 58, 56, 58, 69, 69, 69, 69, 28, 42, 58],
        [70, 58, 97, 58, 56, 58, 69, 69, 69, 69, 58, 56, 58, 69, 69, 69, 69, 28, 42, 58],
        [186, 58],
    ]
}
