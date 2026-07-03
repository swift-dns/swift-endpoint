import Endpoint

extension IPTestCase where IPAddressType == AnyIPAddress {
    @available(SwiftStdlib 6.0, *)
    static var stringAndAddress: [Self] {
        [
            IPTestCase(
                "192.168.1.1",
                .v4(IPv4Address(192, 168, 1, 1)),
                canonicalDescription: "192.168.1.1"
            ),
            IPTestCase("[192.168.1.256]"),
            IPTestCase(
                "[2001:0:0:1::]",
                .v6(IPv6Address(0x2001_0000_0000_0001_0000_0000_0000_0000)),
                canonicalDescription: "[2001:0:0:1::]"
            ),
            IPTestCase(
                "0:0:0:0:0:FFFF:204.152.189.116",
                .v6(IPv6Address(0x0000_0000_0000_0000_0000_FFFF_CC98_BD74)),
                canonicalDescription: "[::ffff:cc98:bd74]"
            ),
            IPTestCase(
                "[2001:db8:85a3::100]",
                .v6(IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0100)),
                canonicalDescription: "[2001:db8:85a3::100]"
            ),
            IPTestCase("[0:1:2:3:4:0:5:6::]"),
        ]
    }
}

extension IPPropertyTestCase where IPAddressType == AnyIPAddress {
    static var all: [Self] {
        [
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

            IPPropertyTestCase(.v6(IPv6Address("::1")!), "isLoopback", \.isLoopback),
            IPPropertyTestCase(
                .v6(IPv6Address("::1:1")!),
                "!isLoopback",
                { @Sendable in !$0.isLoopback }
            ),
            IPPropertyTestCase(.v6(IPv6Address("FF00::")!), "isMulticast", \.isMulticast),
            IPPropertyTestCase(.v6(IPv6Address("FF92::")!), "isMulticast", \.isMulticast),
            IPPropertyTestCase(.v6(IPv6Address("FFFF:998A::1")!), "isMulticast", \.isMulticast),
            IPPropertyTestCase(
                .v6(IPv6Address("FF::")!),
                "!isMulticast",
                { @Sendable in !$0.isMulticast }
            ),
            IPPropertyTestCase(
                .v6(IPv6Address("00FF::")!),
                "!isMulticast",
                { @Sendable in !$0.isMulticast }
            ),
            IPPropertyTestCase(
                .v6(IPv6Address("FAFF::")!),
                "!isMulticast",
                { @Sendable in !$0.isMulticast }
            ),
        ]
    }
}

extension IPTestCase where IPAddressType == AnyIPAddress {
    static var rawByteReject: [[UInt8]] {
        [
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
}
