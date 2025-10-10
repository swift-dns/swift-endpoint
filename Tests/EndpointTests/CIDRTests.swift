import Endpoint
import Testing

@Suite
struct CIDRTests {
    @available(swiftEndpointApplePlatforms 15, *)
    @Test(
        arguments: [(cidr: CIDR<IPv4Address>, expectedDescription: String)]([
            (
                cidr: CIDR(prefix: IPv4Address(1, 43, 255, 199), prefixLength: 8),
                expectedDescription: "1.0.0.0/8"
            ),
            (
                cidr: CIDR(prefix: IPv4Address(244, 89, 123, 0), prefixLength: 24),
                expectedDescription: "244.89.123.0/24"
            ),
            (
                cidr: CIDR(prefix: IPv4Address(0, 0, 0, 0), prefixLength: 0),
                expectedDescription: "0.0.0.0/0"
            ),
            (
                cidr: CIDR(prefix: IPv4Address(255, 255, 255, 255), prefixLength: 32),
                expectedDescription: "255.255.255.255/32"
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24),
                expectedDescription: "192.168.1.0/24"
            ),
        ])
    )
    func `ipv4 CIDR description is calculated correctly`(
        cidr: CIDR<IPv4Address>,
        expectedDescription: String
    ) {
        #expect(cidr.description == expectedDescription)
    }

    @available(swiftEndpointApplePlatforms 26, *)
    @Test(
        arguments: [(text: String, expectedCIDR: CIDR<IPv4Address>?)]([
            (
                text: "192.168.1.0/24",
                expectedCIDR: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24)
            ),
            (
                text: "192.168.1.0/27",
                expectedCIDR: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 27)
            ),
            (
                text: "192.168.1.1/120",
                expectedCIDR: CIDR(prefix: IPv4Address(192, 168, 1, 1), prefixLength: 32)
            ),
            (
                text: "233.122.61.98/0",
                expectedCIDR: CIDR(prefix: IPv4Address(0, 0, 0, 0), prefixLength: 0)
            ),
            (
                text: "233.122.61.98/8",
                expectedCIDR: CIDR(prefix: IPv4Address(233, 0, 0, 0), prefixLength: 8)
            ),
            (
                text: "255.255.255.255/32",
                expectedCIDR: CIDR(prefix: IPv4Address(255, 255, 255, 255), prefixLength: 32)
            ),
            (
                text: "9.56.223.178",
                expectedCIDR: CIDR(prefix: IPv4Address(9, 56, 223, 178), prefixLength: 32)
            ),
            (
                text: "0.0.0.0/0",
                expectedCIDR: CIDR(prefix: IPv4Address(0, 0, 0, 0), prefixLength: 0)
            ),
            (text: "256.122.61.98/8", expectedCIDR: nil),
            (text: "5.5.5.5/-1", expectedCIDR: nil),
            (text: "/", expectedCIDR: nil),
            (text: "/20", expectedCIDR: nil),
            (text: "1.1.1.1/", expectedCIDR: nil),
        ])
    )
    func `ipv4 CIDR description is read correctly`(
        text: String,
        expectedCIDR: CIDR<IPv4Address>?
    ) {
        #expect(CIDR<IPv4Address>(text) == expectedCIDR)
        #expect(CIDR<IPv4Address>(Substring(text)) == expectedCIDR)
        #expect(CIDR<IPv4Address>(textualRepresentation: text.utf8Span) == expectedCIDR)
        #expect(CIDR<IPv4Address>(_uncheckedAssumingValidUTF8: text.utf8Span.span) == expectedCIDR)
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test(
        arguments: [(cidr: CIDR<IPv4Address>, containsIP: IPv4Address, result: Bool)]([
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24),
                containsIP: IPv4Address(192, 168, 1, 0),
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24),
                containsIP: IPv4Address(192, 168, 1, 1),
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24),
                containsIP: IPv4Address(192, 168, 1, 255),
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24),
                containsIP: IPv4Address(192, 168, 1, 254),
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24),
                containsIP: IPv4Address(192, 168, 2, 123),
                result: false
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24),
                containsIP: IPv4Address(192, 168, 0, 123),
                result: false
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24),
                containsIP: IPv4Address(192, 168, 255, 123),
                result: false
            ),
        ])
    )
    func `ipv4 CIDR containment check works as expected`(
        cidr: CIDR<IPv4Address>,
        containsIP: IPv4Address,
        result: Bool
    ) {
        #expect(
            cidr.contains(containsIP) == result,
            """
            IPv4Address containment check failed. A containment result of '\(result)' was expected.
            mask:    0b\(String(cidr.mask.address, radix: 2)); \(cidr.mask.address.trailingZeroBitCount) trailing zeros
            prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
            """
        )
        #expect(
            cidr.contains(AnyIPAddress.v4(containsIP)) == result,
            """
            AnyIPAddress.v4 containment check failed. A containment result of '\(result)' was expected.
            mask:    0b\(String(cidr.mask.address, radix: 2)); \(cidr.mask.address.trailingZeroBitCount) trailing zeros
            prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `randomly generated ipv4 CIDR containment checks work as expected`() {
        for (cidr, containsIP, result) in Self.makeRandom(
            ofType: IPv4Address.self,
            countForEachBit: 100
        ) {
            #expect(
                cidr.contains(containsIP) == result,
                """
                IPv4Address containment check failed. A containment result of '\(result)' was expected.
                mask:    0b\(String(cidr.mask.address, radix: 2)); \(cidr.mask.address.trailingZeroBitCount) trailing zeros
                prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
                checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
                """
            )
            #expect(
                cidr.contains(AnyIPAddress.v4(containsIP)) == result,
                """
                AnyIPAddress.v4 containment check failed. A containment result of '\(result)' was expected.
                mask:    0b\(String(cidr.mask.address, radix: 2)); \(cidr.mask.address.trailingZeroBitCount) trailing zeros
                prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
                checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
                """
            )
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test(
        arguments: [(prefixLength: UInt8, ip: IPv4Address, expectedIP: IPv4Address)]([
            (
                prefixLength: 0 as UInt8,
                ip: 0b00000000_00000000_00000000_00000000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 0 as UInt8,
                ip: 0b10000000_00000000_00000000_00000000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 0 as UInt8,
                ip: 0b10000000_00001000_00000000_00100000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 1 as UInt8,
                ip: 0b00000000_00001000_00000000_00100000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 1 as UInt8,
                ip: 0b10000000_00000000_00000000_00000000,
                expectedIP: 0b10000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 1 as UInt8,
                ip: 0b11000000_00000000_00000000_00000000,
                expectedIP: 0b10000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 9 as UInt8,
                ip: 0b1111111_10000000_00000000_00000000,
                expectedIP: 0b1111111_10000000_00000000_00000000
            ),
            (
                prefixLength: 9 as UInt8,
                ip: 0b1111111_10001000_00010010_00000001,
                expectedIP: 0b1111111_10000000_00000000_00000000
            ),
            (
                prefixLength: 24 as UInt8,
                ip: 0b1111111_11111111_11111111_00000000,
                expectedIP: 0b1111111_11111111_11111111_00000000
            ),
            (
                prefixLength: 24 as UInt8,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_00000000
            ),
            (
                prefixLength: 25 as UInt8,
                ip: 0b1111111_11111111_11111111_11111000,
                expectedIP: 0b1111111_11111111_11111111_10000000
            ),
            (
                prefixLength: 30 as UInt8,
                ip: 0b1111111_11111111_11111111_11111101,
                expectedIP: 0b1111111_11111111_11111111_11111100
            ),
            (
                prefixLength: 31 as UInt8,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_11111110
            ),
            (
                prefixLength: 32 as UInt8,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_11111111
            ),
            (
                prefixLength: 33 as UInt8,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_11111111
            ),
        ])
    ) func `ipv4 CIDR standard initializer truncates prefix if needed`(
        prefixLength: UInt8,
        ip: IPv4Address,
        expectedIP: IPv4Address
    ) {
        let cidr = CIDR(
            prefix: ip,
            prefixLength: prefixLength
        )
        #expect(
            cidr.prefix == expectedIP,
            """
            prefixLength: \(prefixLength)
            prefix:   0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            expected: 0b\(String(expectedIP.address, radix: 2)); \(expectedIP.address.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test(
        arguments: [(prefixLength: UInt8, expectedMask: UInt32)]([
            (0 as UInt8, 0b00000000_00000000_00000000_00000000 as UInt32),
            (1 as UInt8, 0b10000000_00000000_00000000_00000000 as UInt32),
            (2 as UInt8, 0b11000000_00000000_00000000_00000000 as UInt32),
            (3 as UInt8, 0b11100000_00000000_00000000_00000000 as UInt32),
            (19 as UInt8, 0b11111111_11111111_11100000_00000000 as UInt32),
            (20 as UInt8, 0b11111111_11111111_11110000_00000000 as UInt32),
            (27 as UInt8, 0b11111111_11111111_11111111_11100000 as UInt32),
            (30 as UInt8, 0b11111111_11111111_11111111_11111100 as UInt32),
            (31 as UInt8, 0b11111111_11111111_11111111_11111110 as UInt32),
            (32 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (33 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (34 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (50 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (150 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (255 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
        ])
    )
    func `ipv4 mask is correctly calculated when using prefixLength`(
        prefixLength: UInt8,
        expectedMask: UInt32
    ) {
        let calculatedMask = CIDR<IPv4Address>.makeMaskBasedOn(
            prefixLength: prefixLength
        )
        #expect(
            calculatedMask.address == expectedMask,
            """
            prefixLength: \(prefixLength)
            calculated: 0b\(String(calculatedMask.address, radix: 2)); \(calculatedMask.address.trailingZeroBitCount) trailing zeros
            expected:   0b\(String(expectedMask, radix: 2)); \(expectedMask.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftEndpointApplePlatforms 26, *)
    @Test(
        arguments: [(cidr: CIDR<IPv6Address>, expectedDescription: String)]([
            (
                cidr: CIDR(
                    prefix: IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0100),
                    prefixLength: 24
                ),
                expectedDescription: "[2001:d00::]/24"
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, prefixLength: 8),
                expectedDescription: "[ff00::]/8"
            ),
            (
                cidr: CIDR(prefix: 0x0, prefixLength: 0),
                expectedDescription: "[::]/0"
            ),
            (
                cidr: CIDR(prefix: IPv6Address(UInt128.max), prefixLength: 128),
                expectedDescription: "[ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff]/128"
            ),
            (
                cidr: CIDR(
                    prefix: IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0000),
                    prefixLength: 48
                ),
                expectedDescription: "[2001:db8:85a3::]/48"
            ),
        ])
    )
    func `ipv6 CIDR description is calculated correctly`(
        cidr: CIDR<IPv6Address>,
        expectedDescription: String
    ) {
        #expect(cidr.description == expectedDescription)
    }

    @available(swiftEndpointApplePlatforms 26, *)
    @Test(
        arguments: [(text: String, expectedCIDR: CIDR<IPv6Address>?)]([
            (
                text: "FF::/24",
                expectedCIDR: CIDR(prefix: IPv6Address("FF::")!, prefixLength: 24)
            ),
            (
                text: "12::/111",
                expectedCIDR: CIDR(prefix: IPv6Address("12::")!, prefixLength: 111)
            ),
            (
                text: "[1234:5678::]/188",
                expectedCIDR: CIDR(prefix: IPv6Address("1234:5678::")!, prefixLength: 128)
            ),
            (
                text: "::1234/0",
                expectedCIDR: CIDR(prefix: IPv6Address("::")!, prefixLength: 0)
            ),
            (
                text: "[::]/8",
                expectedCIDR: CIDR(prefix: IPv6Address("::")!, prefixLength: 8)
            ),
            (
                text: "[FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF]/32",
                expectedCIDR: CIDR(
                    prefix: IPv6Address("FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:0000:0000")!,
                    prefixLength: 32
                )
            ),
            (
                text: "[1:2:33:Ff:AAaa::]",
                expectedCIDR: CIDR(prefix: IPv6Address("1:2:33:ff:aaaa::")!, prefixLength: 128)
            ),
            (
                text: "[::]/0",
                expectedCIDR: CIDR(prefix: IPv6Address("::")!, prefixLength: 0)
            ),
            (text: "[::]/-1", expectedCIDR: nil),
            (text: "/", expectedCIDR: nil),
            (text: "/20", expectedCIDR: nil),
            (text: "[::]/", expectedCIDR: nil),
            (
                text: "[FFFF:FFFF:FFFF:FFGF:FFFF:FFFF:FFFF:FFFF]/100",
                expectedCIDR: nil
            ),
        ])
    )
    func `ipv6 CIDR description is read correctly`(
        text: String,
        expectedCIDR: CIDR<IPv6Address>?
    ) {
        #expect(CIDR<IPv6Address>(text) == expectedCIDR)
        #expect(CIDR<IPv6Address>(Substring(text)) == expectedCIDR)
        #expect(CIDR<IPv6Address>(textualRepresentation: text.utf8Span) == expectedCIDR)
        #expect(CIDR<IPv6Address>(_uncheckedAssumingValidUTF8: text.utf8Span.span) == expectedCIDR)
    }

    @available(swiftEndpointApplePlatforms 26, *)
    @Test(
        arguments: [(cidr: CIDR<IPv6Address>, containsIP: IPv6Address, result: Bool)]([
            (
                /// `FF::` is equivalent to `00FF::`
                cidr: CIDR(prefix: IPv6Address("FF::")!, prefixLength: 8),
                containsIP: IPv6Address("FF00::")!,
                result: false
            ),
            (
                /// `FF::` is equivalent to `00FF::`
                cidr: CIDR(prefix: IPv6Address("FF::")!, prefixLength: 16),
                containsIP: IPv6Address("FF::")!,
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, prefixLength: 8),
                containsIP: IPv6Address("FF92::")!,
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, prefixLength: 8),
                containsIP: IPv6Address("FFEE:9328:3212:0:1::")!,
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, prefixLength: 8),
                containsIP: IPv6Address("FF00:9328:3212:0:1::")!,
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, prefixLength: 8),
                containsIP: IPv6Address("EEFF:9328:3212:0:1::")!,
                result: false
            ),
        ])
    )
    func `ipv6 CIDR containment check works as expected`(
        cidr: CIDR<IPv6Address>,
        containsIP: IPv6Address,
        result: Bool
    ) {
        #expect(
            cidr.contains(containsIP) == result,
            """
            IPv6Address containment check failed. A containment result of '\(result)' was expected.
            mask:    0b\(String(cidr.mask.address, radix: 2)); \(cidr.mask.address.trailingZeroBitCount) trailing zeros
            prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
            """
        )
        #expect(
            cidr.contains(AnyIPAddress.v6(containsIP)) == result,
            """
            AnyIPAddress.v6 containment check failed. A containment result of '\(result)' was expected.
            mask:    0b\(String(cidr.mask.address, radix: 2)); \(cidr.mask.address.trailingZeroBitCount) trailing zeros
            prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `randomly generated ipv6 CIDR containment checks work as expected`() {
        for (cidr, containsIP, result) in Self.makeRandom(
            ofType: IPv6Address.self,
            countForEachBit: 15
        ) {
            #expect(
                cidr.contains(containsIP) == result,
                """
                IPv6Address containment check failed. A containment result of '\(result)' was expected.
                mask:    0b\(String(cidr.mask.address, radix: 2)); \(cidr.mask.address.trailingZeroBitCount) trailing zeros
                prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
                checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
                """
            )
            #expect(
                cidr.contains(AnyIPAddress.v6(containsIP)) == result,
                """
                AnyIPAddress.v6 containment check failed. A containment result of '\(result)' was expected.
                mask:    0b\(String(cidr.mask.address, radix: 2)); \(cidr.mask.address.trailingZeroBitCount) trailing zeros
                prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
                checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
                """
            )
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test(
        arguments: [(prefixLength: UInt8, ip: IPv6Address, expectedIP: IPv6Address)]([
            (
                prefixLength: 0 as UInt8,
                ip: IPv6Address(0b00000000_00000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
            ),
            (
                prefixLength: 0 as UInt8,
                ip: IPv6Address(0b10000000_00000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
            ),
            (
                prefixLength: 0 as UInt8,
                ip: IPv6Address(0b10000000_00001000_00000000_00100000 << 96),
                expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
            ),
            (
                prefixLength: 1 as UInt8,
                ip: IPv6Address(0b00000000_00001000_00000000_00100000 << 96),
                expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
            ),
            (
                prefixLength: 1 as UInt8,
                ip: IPv6Address(0b10000000_00000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b10000000_00000000_00000000_00000000 << 96)
            ),
            (
                prefixLength: 1 as UInt8,
                ip: IPv6Address(0b11000000_00000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b10000000_00000000_00000000_00000000 << 96)
            ),
            (
                prefixLength: 9 as UInt8,
                ip: IPv6Address(0b1111111_10000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b1111111_10000000_00000000_00000000 << 96)
            ),
            (
                prefixLength: 9 as UInt8,
                ip: IPv6Address(0b1111111_10001000_00010010_00000001 << 96),
                expectedIP: IPv6Address(0b1111111_10000000_00000000_00000000 << 96)
            ),
            (
                prefixLength: 24 as UInt8,
                ip: IPv6Address(0b1111111_11111111_11111111_00000000 << 96),
                expectedIP: IPv6Address(0b1111111_11111111_11111111_00000000 << 96)
            ),
            (
                prefixLength: 24 as UInt8,
                ip: IPv6Address(0b1111111_11111111_11111111_11111111 << 96),
                expectedIP: IPv6Address(0b1111111_11111111_11111111_00000000 << 96)
            ),
            (
                prefixLength: 25 as UInt8,
                ip: IPv6Address(0b1111111_11111111_11111111_11111000 << 96),
                expectedIP: IPv6Address(0b1111111_11111111_11111111_10000000 << 96)
            ),
            (
                prefixLength: 120 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_01000100
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
                )
            ),
            (
                prefixLength: 120 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
                )
            ),
            (
                prefixLength: 120 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
                )
            ),
            (
                prefixLength: 126 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
                )
            ),
            (
                prefixLength: 126 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111101
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
                )
            ),
            (
                prefixLength: 126 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
                )
            ),
            (
                prefixLength: 127 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
                )
            ),
            (
                prefixLength: 127 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
                )
            ),
            (
                prefixLength: 128 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                )
            ),
            (
                prefixLength: 129 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                )
            ),
        ])
    ) func `ipv6 CIDR standard initializer truncates prefix if needed`(
        prefixLength: UInt8,
        ip: IPv6Address,
        expectedIP: IPv6Address
    ) {
        let cidr = CIDR(
            prefix: ip,
            prefixLength: prefixLength
        )
        #expect(
            cidr.prefix == expectedIP,
            """
            prefixLength: \(prefixLength)
            prefix:   0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            expected: 0b\(String(expectedIP.address, radix: 2)); \(expectedIP.address.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test(
        arguments: [(prefixLength: UInt8, expectedMask: UInt128)]([
            (0 as UInt8, (0b0 << 128) as UInt128),
            (1 as UInt8, (0b1 << 127) as UInt128),
            (2 as UInt8, (0b11 << 126) as UInt128),
            (3 as UInt8, (0b111 << 125) as UInt128),
            (19 as UInt8, (0b11111111_11111111_111 << 109) as UInt128),
            (20 as UInt8, (0b11111111_11111111_1111 << 108) as UInt128),
            (27 as UInt8, (0b11111111_11111111_11111111_111 << 101) as UInt128),
            (28 as UInt8, (0b11111111_11111111_11111111_1111 << 100) as UInt128),
            (29 as UInt8, (0b11111111_11111111_11111111_11111 << 99) as UInt128),
            (30 as UInt8, (0b11111111_11111111_11111111_111111 << 98) as UInt128),
            (31 as UInt8, (0b11111111_11111111_11111111_1111111 << 97) as UInt128),
            (32 as UInt8, (0b11111111_11111111_11111111_11111111 << 96) as UInt128),
            (33 as UInt8, (0b11111111_11111111_11111111_11111111_1 << 95) as UInt128),
            (34 as UInt8, (0b11111111_11111111_11111111_11111111_11 << 94) as UInt128),
            (
                50 as UInt8,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11 << 78) as UInt128
            ),
            (
                99 as UInt8,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_111
                    << 29) as UInt128
            ),
            (
                100 as UInt8,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_1111
                    << 28) as UInt128
            ),
            (
                101 as UInt8,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111
                    << 27) as UInt128
            ),
            (
                127 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
                    as UInt128
            ),
            (
                128 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                129 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                150 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                255 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
        ])
    )
    func `ipv6 mask is correctly calculated when using prefixLength`(
        prefixLength: UInt8,
        expectedMask: UInt128
    ) {
        let calculatedMask = CIDR<IPv6Address>.makeMaskBasedOn(
            prefixLength: prefixLength
        )
        #expect(
            calculatedMask.address == expectedMask,
            """
            prefixLength: \(prefixLength)
            calculated: 0b\(String(calculatedMask.address, radix: 2)); \(calculatedMask.address.trailingZeroBitCount) trailing zeros
            expected:   0b\(String(expectedMask, radix: 2)); \(expectedMask.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftEndpointApplePlatforms 15, *)
    /// We intentionally don't use much math operators here like bit-shift, to keep things
    /// simpler for tests.
    static func makeRandom<IPAddressType: _IPAddressProtocol>(
        ofType: IPAddressType.Type,
        countForEachBit: Int
    ) -> [(cidr: CIDR<IPAddressType>, containsIP: IPAddressType, result: Bool)] {
        let bitWidth = UInt8(IPAddressType.IntegerLiteralType.bitWidth)
        var results: [(cidr: CIDR<IPAddressType>, containsIP: IPAddressType, result: Bool)] = []
        results.reserveCapacity((Int(bitWidth) + 1) * 2 * countForEachBit)

        for bitCount in UInt8(0)...bitWidth {
            let cidr = CIDR(
                prefix: IPAddressType(integerLiteral: .random(in: .all)),
                prefixLength: bitCount
            )

            var cidrPrefixBits = String(cidr.prefix.address, radix: 2)
            let remainingBits = Int(bitWidth) - cidrPrefixBits.count
            cidrPrefixBits = String(repeating: "0", count: remainingBits) + cidrPrefixBits
            let matchingBits = cidrPrefixBits.prefix(Int(bitCount))

            for _ in (0..<countForEachBit) {
                let theRest = (0..<(bitWidth - bitCount)).map { _ in
                    "\(UInt8.random(in: 0...1))"
                }
                let number = IPAddressType.IntegerLiteralType(
                    matchingBits + theRest.joined(separator: ""),
                    radix: 2
                )!
                results.append((cidr, IPAddressType(integerLiteral: number), true))
            }

            guard bitCount > 0 else {
                continue
            }

            for _ in (0..<countForEachBit) {
                var messedUpBits = Array(matchingBits)
                let howManyToMessUp = Int.random(in: 1...matchingBits.count)
                let indicesToMessUp = messedUpBits.indices.shuffled().prefix(howManyToMessUp)
                for index in indicesToMessUp {
                    let toggled: Character = messedUpBits[index] == "1" ? "0" : "1"
                    messedUpBits[index] = toggled
                }
                let theRest = (0..<(bitWidth - bitCount)).map { _ in
                    "\(UInt8.random(in: 0...1))"
                }
                let number = IPAddressType.IntegerLiteralType(
                    messedUpBits + theRest.joined(separator: ""),
                    radix: 2
                )!
                results.append((cidr, IPAddressType(integerLiteral: number), false))
            }
        }

        return results
    }
}

extension ClosedRange where Bound: FixedWidthInteger {
    fileprivate static var all: Self {
        Bound.min...Bound.max
    }
}
