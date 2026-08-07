import Endpoint
import Testing

@Suite
struct CIDRTests {
    @available(SwiftStdlib 5.1, *)
    @Test(
        arguments: [(cidr: CIDR<IPv4Address>, expectedDescription: String)]([
            (
                cidr: CIDR(prefix: IPv4Address(1, 43, 255, 199), prefixLength: 8),
                expectedDescription: "1.43.255.199/8"
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

    @available(SwiftStdlib 6.2, *)
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
                expectedCIDR: nil
            ),
            (
                text: "233.122.61.98/0",
                expectedCIDR: CIDR(prefix: IPv4Address(233, 122, 61, 98), prefixLength: 0)
            ),
            (
                text: "233.122.61.98/8",
                expectedCIDR: CIDR(prefix: IPv4Address(233, 122, 61, 98), prefixLength: 8)
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
            (
                text: "192.168.1.0/024",
                expectedCIDR: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 24)
            ),
            (
                text: "192.168.1.0/00",
                expectedCIDR: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 0)
            ),
            (
                text: "192.168.1.0/032",
                expectedCIDR: CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: 32)
            ),
            (
                text: "010.020.030.040/024",
                expectedCIDR: CIDR(prefix: IPv4Address(10, 20, 30, 40), prefixLength: 24)
            ),
            (text: "256.122.61.98/8", expectedCIDR: nil),
            (text: "9.56.223.1782", expectedCIDR: nil),
            (text: "5.5.5.5/-1", expectedCIDR: nil),
            (text: "/", expectedCIDR: nil),
            (text: "/20", expectedCIDR: nil),
            (text: "1.1.1.1/", expectedCIDR: nil),
            /// A fourth prefix-length digit is rejected even when the padding digits are all zeros.
            (text: "192.168.1.0/0024", expectedCIDR: nil),
            (text: "192.168.1.0/0032", expectedCIDR: nil),
            (text: "192.168.1.0/0000", expectedCIDR: nil),
        ])
    )
    func `ipv4 CIDR description is read correctly`(
        text: String,
        expectedCIDR: CIDR<IPv4Address>?
    ) {
        Self.expectParses(text, expectedCIDR)
    }

    @available(SwiftStdlib 6.0, *)
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
        Self.expectContains(cidr, containsIP, result, asAnyIPAddress: AnyIPAddress.v4)
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `contains ignores the CIDR prefix host bits`() {
        /// The prefix is stored un-normalized (127.0.0.18, not 127.0.0.0), yet containment must
        /// behave as if the host bits were masked off. This would fail if `contains` compared
        /// against the raw prefix instead of `prefix & mask`.
        let cidr = CIDR(prefix: IPv4Address(127, 0, 0, 18), prefixLength: 8)
        #expect(cidr.prefix == IPv4Address(127, 0, 0, 18))
        #expect(cidr.contains(IPv4Address(127, 0, 0, 0)))
        #expect(cidr.contains(IPv4Address(127, 0, 0, 1)))
        #expect(cidr.contains(IPv4Address(127, 0, 0, 18)))
        #expect(cidr.contains(IPv4Address(127, 255, 255, 255)))
        #expect(!cidr.contains(IPv4Address(128, 0, 0, 18)))
        /// Same through the AnyIPAddress overload.
        #expect(cidr.contains(AnyIPAddress.v4(IPv4Address(127, 0, 0, 1))))
        #expect(!cidr.contains(AnyIPAddress.v4(IPv4Address(128, 0, 0, 18))))
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `CIDR equality and hashing account for the prefix host bits`() {
        /// Same prefix and mask: must be equal and hash equally.
        let a = CIDR(prefix: IPv4Address(127, 0, 0, 18), prefixLength: 8)
        let b = CIDR(prefix: IPv4Address(127, 0, 0, 18), prefixLength: 8)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        /// The un-normalized prefix is preserved for display.
        #expect(a.prefix == IPv4Address(127, 0, 0, 18))
        #expect(a.description == "127.0.0.18/8")

        /// Same network, different host bits: must not be equal, although containment is unaffected.
        let c = CIDR(prefix: IPv4Address(127, 0, 0, 0), prefixLength: 8)
        #expect(a != c)
        #expect(a.networkAddress == c.networkAddress)
        #expect(a.contains(c.prefix))
        #expect(c.contains(a.prefix))

        /// Different mask, same prefix: must not be equal.
        #expect(
            CIDR(prefix: IPv4Address(127, 0, 0, 0), prefixLength: 8)
                != CIDR(prefix: IPv4Address(127, 0, 0, 0), prefixLength: 16)
        )
        /// Different network: must not be equal.
        #expect(
            CIDR(prefix: IPv4Address(127, 0, 0, 18), prefixLength: 8)
                != CIDR(prefix: IPv4Address(128, 0, 0, 18), prefixLength: 8)
        )
    }

    /// Exhaustive mask validity lives in the IP property suite (`isContiguous`); here we
    /// only verify the initializer honors the check and derives the prefix length correctly.
    @available(SwiftStdlib 6.2, *)
    @Test
    func `CIDR checked mask initializer wires isContiguous and derives prefix length`() throws {
        let v4 = try #require(
            CIDR(
                prefix: IPv4Address(192, 168, 1, 0),
                mask: IPv4Address(255, 255, 192, 0)
            )
        )
        #expect(v4.prefixLength == 18)
        #expect(v4.mask == IPv4Address(255, 255, 192, 0))
        #expect(
            CIDR(
                prefix: IPv4Address(192, 168, 1, 0),
                mask: IPv4Address(255, 0, 0, 255)
            ) == nil
        )

        let v6 = try #require(
            CIDR(
                prefix: IPv6Address("2001:DB8::")!,
                mask: IPv6Address("FFFF::")!
            )
        )
        #expect(v6.prefixLength == 16)
        #expect(v6.mask == IPv6Address("FFFF::")!)
        #expect(
            CIDR(
                prefix: IPv6Address("2001:DB8::")!,
                mask: IPv6Address("FFFF::FFFF")!
            ) == nil
        )
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `CIDR containment check rejects the other IP version`() {
        #expect(!CIDR<IPv4Address>.loopback.contains(AnyIPAddress.v6(IPv6Address("::1")!)))
        #expect(!CIDR<IPv6Address>.loopback.contains(AnyIPAddress.v4(IPv4Address(127, 0, 0, 1))))
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `randomly generated ipv4 CIDR containment checks work as expected`() {
        for (cidr, containsIP, result) in Self.makeRandom(
            ofType: IPv4Address.self,
            countForEachBit: 100
        ) {
            Self.expectContains(cidr, containsIP, result, asAnyIPAddress: AnyIPAddress.v4)
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test(
        arguments: [(prefixLength: Int, ip: IPv4Address, expectedIP: IPv4Address)]([
            (
                prefixLength: 0,
                ip: 0b00000000_00000000_00000000_00000000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 0,
                ip: 0b10000000_00000000_00000000_00000000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 0,
                ip: 0b10000000_00001000_00000000_00100000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 1,
                ip: 0b00000000_00001000_00000000_00100000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 1,
                ip: 0b10000000_00000000_00000000_00000000,
                expectedIP: 0b10000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 1,
                ip: 0b11000000_00000000_00000000_00000000,
                expectedIP: 0b10000000_00000000_00000000_00000000
            ),
            (
                prefixLength: 9,
                ip: 0b1111111_10000000_00000000_00000000,
                expectedIP: 0b1111111_10000000_00000000_00000000
            ),
            (
                prefixLength: 9,
                ip: 0b1111111_10001000_00010010_00000001,
                expectedIP: 0b1111111_10000000_00000000_00000000
            ),
            (
                prefixLength: 24,
                ip: 0b1111111_11111111_11111111_00000000,
                expectedIP: 0b1111111_11111111_11111111_00000000
            ),
            (
                prefixLength: 24,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_00000000
            ),
            (
                prefixLength: 25,
                ip: 0b1111111_11111111_11111111_11111000,
                expectedIP: 0b1111111_11111111_11111111_10000000
            ),
            (
                prefixLength: 30,
                ip: 0b1111111_11111111_11111111_11111101,
                expectedIP: 0b1111111_11111111_11111111_11111100
            ),
            (
                prefixLength: 31,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_11111110
            ),
            (
                prefixLength: 32,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_11111111
            ),
        ])
    ) func `ipv4 CIDR standard initializer preserves the prefix without truncation`(
        prefixLength: Int,
        ip: IPv4Address,
        expectedIP: IPv4Address
    ) {
        let cidr = CIDR(
            prefix: ip,
            prefixLength: prefixLength
        )
        /// The prefix is stored exactly as provided, host bits are not truncated.
        #expect(
            cidr.prefix == ip,
            """
            prefixLength: \(prefixLength)
            prefix:   0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            ip:       0b\(String(ip.address, radix: 2)); \(ip.address.trailingZeroBitCount) trailing zeros
            """
        )
        /// The masked network address is still considered within the block.
        #expect(cidr.contains(expectedIP))
    }

    @available(SwiftStdlib 5.1, *)
    @Test(
        arguments: [(prefixLength: Int, expectedMask: UInt32)]([
            (0, 0b00000000_00000000_00000000_00000000 as UInt32),
            (1, 0b10000000_00000000_00000000_00000000 as UInt32),
            (2, 0b11000000_00000000_00000000_00000000 as UInt32),
            (3, 0b11100000_00000000_00000000_00000000 as UInt32),
            (19, 0b11111111_11111111_11100000_00000000 as UInt32),
            (20, 0b11111111_11111111_11110000_00000000 as UInt32),
            (27, 0b11111111_11111111_11111111_11100000 as UInt32),
            (30, 0b11111111_11111111_11111111_11111100 as UInt32),
            (31, 0b11111111_11111111_11111111_11111110 as UInt32),
            (32, 0b11111111_11111111_11111111_11111111 as UInt32),
            (33, 0b11111111_11111111_11111111_11111111 as UInt32),
            (34, 0b11111111_11111111_11111111_11111111 as UInt32),
            (50, 0b11111111_11111111_11111111_11111111 as UInt32),
            (150, 0b11111111_11111111_11111111_11111111 as UInt32),
            (255, 0b11111111_11111111_11111111_11111111 as UInt32),
            (100_000, 0b11111111_11111111_11111111_11111111 as UInt32),
            (Int.max, 0b11111111_11111111_11111111_11111111 as UInt32),
        ])
    )
    func `ipv4 mask is correctly calculated when using prefixLength`(
        prefixLength: Int,
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

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: [(cidr: CIDR<IPv6Address>, expectedDescription: String)]([
            (
                cidr: CIDR(
                    prefix: IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0100),
                    prefixLength: 24
                ),
                expectedDescription: "2001:db8:85a3::100/24"
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, prefixLength: 8),
                expectedDescription: "ff00::/8"
            ),
            (
                cidr: CIDR(prefix: 0x0, prefixLength: 0),
                expectedDescription: "::/0"
            ),
            (
                cidr: CIDR(prefix: IPv6Address(UInt128.max), prefixLength: 128),
                expectedDescription: "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128"
            ),
            (
                cidr: CIDR(
                    prefix: IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0000),
                    prefixLength: 48
                ),
                expectedDescription: "2001:db8:85a3::/48"
            ),
        ])
    )
    func `ipv6 CIDR description is calculated correctly`(
        cidr: CIDR<IPv6Address>,
        expectedDescription: String
    ) {
        #expect(cidr.description == expectedDescription)
    }

    @available(SwiftStdlib 6.2, *)
    static let ipv6ParseTestCases: [(text: String, expectedCIDR: CIDR<IPv6Address>?)] = [
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
            expectedCIDR: nil
        ),
        (
            text: "::1234/0",
            expectedCIDR: CIDR(prefix: IPv6Address("::1234")!, prefixLength: 0)
        ),
        (
            text: "[::]/8",
            expectedCIDR: CIDR(prefix: IPv6Address("::")!, prefixLength: 8)
        ),
        (
            text: "[FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF]/32",
            expectedCIDR: CIDR(
                prefix: IPv6Address("FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF")!,
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
        (
            text: "[2001:db8::]/064",
            expectedCIDR: CIDR(prefix: IPv6Address("2001:db8::")!, prefixLength: 64)
        ),
        (
            text: "[::]/000",
            expectedCIDR: CIDR(prefix: IPv6Address("::")!, prefixLength: 0)
        ),
        (
            text: "[0000:0db8::]/0",
            expectedCIDR: CIDR(prefix: IPv6Address("0:db8::")!, prefixLength: 0)
        ),
        (text: "[::]/-1", expectedCIDR: nil),
        (text: "/", expectedCIDR: nil),
        (text: "/20", expectedCIDR: nil),
        (text: "[::]/", expectedCIDR: nil),
        (
            text: "[FFFF:FFFF:FFFF:FFGF:FFFF:FFFF:FFFF:FFFF]/100",
            expectedCIDR: nil
        ),
        /// A fourth prefix-length digit is rejected even when the padding digits are all zeros.
        (text: "[2001:db8::]/0064", expectedCIDR: nil),
        (text: "[2001:db8::]/0128", expectedCIDR: nil),
        (text: "[::]/0000", expectedCIDR: nil),
    ]

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: CIDRTests.ipv6ParseTestCases)
    func `ipv6 CIDR description is read correctly`(
        text: String,
        expectedCIDR: CIDR<IPv6Address>?
    ) {
        Self.expectParses(text, expectedCIDR)
    }

    @available(SwiftStdlib 6.2, *)
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
        Self.expectContains(cidr, containsIP, result, asAnyIPAddress: AnyIPAddress.v6)
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `randomly generated ipv6 CIDR containment checks work as expected`() {
        for (cidr, containsIP, result) in Self.makeRandom(
            ofType: IPv6Address.self,
            countForEachBit: 15
        ) {
            Self.expectContains(cidr, containsIP, result, asAnyIPAddress: AnyIPAddress.v6)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: ipv6CIDRTruncationArguments
    ) func `ipv6 CIDR standard initializer preserves the prefix without truncating`(
        prefixLength: Int,
        ip: IPv6Address,
        expectedIP: IPv6Address
    ) {
        let cidr = CIDR(
            prefix: ip,
            prefixLength: prefixLength
        )
        let comment: Comment = """
            prefixLength: \(prefixLength)
            prefix:   0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            ip:       0b\(String(ip.address, radix: 2)); \(ip.address.trailingZeroBitCount) trailing zeros
            """
        /// The prefix is stored exactly as provided, host bits are not truncated.
        #expect(cidr.prefix == ip, comment)
        /// The masked network address is still considered within the block.
        #expect(cidr.contains(expectedIP))
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: [(prefixLength: Int, expectedMask: UInt128)]([
            (0, (0b0 << 128) as UInt128),
            (1, (0b1 << 127) as UInt128),
            (2, (0b11 << 126) as UInt128),
            (3, (0b111 << 125) as UInt128),
            (19, (0b11111111_11111111_111 << 109) as UInt128),
            (20, (0b11111111_11111111_1111 << 108) as UInt128),
            (27, (0b11111111_11111111_11111111_111 << 101) as UInt128),
            (28, (0b11111111_11111111_11111111_1111 << 100) as UInt128),
            (29, (0b11111111_11111111_11111111_11111 << 99) as UInt128),
            (30, (0b11111111_11111111_11111111_111111 << 98) as UInt128),
            (31, (0b11111111_11111111_11111111_1111111 << 97) as UInt128),
            (32, (0b11111111_11111111_11111111_11111111 << 96) as UInt128),
            (33, (0b11111111_11111111_11111111_11111111_1 << 95) as UInt128),
            (34, (0b11111111_11111111_11111111_11111111_11 << 94) as UInt128),
            (
                50,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11 << 78) as UInt128
            ),
            (
                99,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_111
                    << 29) as UInt128
            ),
            (
                100,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_1111
                    << 28) as UInt128
            ),
            (
                101,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111
                    << 27) as UInt128
            ),
            (
                127,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
                    as UInt128
            ),
            (
                128,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                129,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                150,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                255,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                100_000,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                Int.max,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
        ])
    )
    func `ipv6 mask is correctly calculated when using prefixLength`(
        prefixLength: Int,
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

    @available(SwiftStdlib 6.0, *)
    static func expectContains<IPAddressType: _IPAddressProtocol>(
        _ cidr: CIDR<IPAddressType>,
        _ ip: IPAddressType,
        _ expected: Bool,
        asAnyIPAddress: (IPAddressType) -> AnyIPAddress,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let details = """
            mask:    \(Self.binaryDescription(cidr.mask.address))
            prefix:  \(Self.binaryDescription(cidr.prefix.address))
            checked: \(Self.binaryDescription(ip.address))
            """
        #expect(
            cidr.contains(ip) == expected,
            """
            \(IPAddressType.self) containment check failed. A containment result of '\(expected)' was expected.
            \(details)
            """,
            sourceLocation: sourceLocation
        )
        #expect(
            cidr.contains(asAnyIPAddress(ip)) == expected,
            """
            AnyIPAddress containment check failed. A containment result of '\(expected)' was expected.
            \(details)
            """,
            sourceLocation: sourceLocation
        )
    }

    @available(SwiftStdlib 6.2, *)
    static func expectParses<IPAddressType: _IPAddressProtocol>(
        _ text: String,
        _ expected: CIDR<IPAddressType>?,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(CIDR<IPAddressType>(text) == expected, sourceLocation: sourceLocation)
        #expect(CIDR<IPAddressType>(Substring(text)) == expected, sourceLocation: sourceLocation)
        #expect(
            CIDR<IPAddressType>(textualRepresentation: text.utf8Span) == expected,
            sourceLocation: sourceLocation
        )
        #expect(
            CIDR<IPAddressType>(textualRepresentation: text.utf8Span.span) == expected,
            sourceLocation: sourceLocation
        )
    }

    @available(SwiftStdlib 6.0, *)
    static func binaryDescription<T: _IPAddressProtocolAddressValueType>(_ value: T) -> String {
        "0b\(String(value: value, radix: 2)); \(value.trailingZeroBitCount) trailing zeros"
    }

    @available(SwiftStdlib 6.0, *)
    /// We intentionally don't use much math operators here like bit-shift, to keep things
    /// simpler for tests.
    static func makeRandom<IPAddressType: _IPAddressProtocol>(
        ofType: IPAddressType.Type,
        countForEachBit: Int
    ) -> [(cidr: CIDR<IPAddressType>, containsIP: IPAddressType, result: Bool)] {
        let bitWidth = IPAddressType.AddressValueType.bitWidth
        var results: [(cidr: CIDR<IPAddressType>, containsIP: IPAddressType, result: Bool)] = []
        results.reserveCapacity((bitWidth + 1) * 2 * countForEachBit)

        for bitCount in 0...bitWidth {
            let cidr = CIDR(
                prefix: IPAddressType(.anyRandom()),
                prefixLength: bitCount
            )

            var cidrPrefixBits = String(value: cidr.prefix.address, radix: 2)
            let remainingBits = bitWidth - cidrPrefixBits.count
            cidrPrefixBits = String(repeating: "0", count: remainingBits) + cidrPrefixBits
            let matchingBits = cidrPrefixBits.prefix(bitCount)

            for _ in (0..<countForEachBit) {
                let theRest = (0..<(bitWidth - bitCount)).map { _ in
                    "\(UInt8.random(in: 0...1))"
                }
                let number = IPAddressType.AddressValueType(
                    matchingBits + theRest.joined(separator: ""),
                    radix: 2
                )!
                results.append((cidr, IPAddressType(number), true))
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
                let number = IPAddressType.AddressValueType(
                    messedUpBits + theRest.joined(separator: ""),
                    radix: 2
                )!
                results.append((cidr, IPAddressType(number), false))
            }
        }

        return results
    }
}

@available(SwiftStdlib 6.0, *)
extension _IPAddressProtocolAddressValueType {
    fileprivate static func anyRandom() -> Self {
        switch Self.self {
        case is UInt32.Type:
            return UInt32.random(in: .min ... .max) as! Self
        case is UnsignedInteger128.Type:
            return UnsignedInteger128.random(in: .min ... .max) as! Self
        default:
            fatalError("Unsupported type: \(Self.self)")
        }
    }

    @_disfavoredOverload
    fileprivate init?(_ value: String, radix: Int = 10) {
        switch Self.self {
        case is UInt32.Type:
            guard let value = UInt32(value, radix: radix) else { return nil }
            self = value as! Self
        case is UnsignedInteger128.Type:
            guard let value = UnsignedInteger128(value, radix: radix) else { return nil }
            self = value as! Self
        default:
            fatalError("Unsupported type: \(Self.self)")
        }
    }
}

@available(SwiftStdlib 6.0, *)
extension String {
    fileprivate init<T: _IPAddressProtocolAddressValueType>(value: T, radix: Int) {
        switch T.self {
        case is UInt32.Type:
            self = String(value as! UInt32, radix: radix)
        case is UnsignedInteger128.Type:
            self = String(value as! UnsignedInteger128, radix: radix)
        default:
            fatalError("Unsupported type: \(T.self)")
        }
    }
}

@available(SwiftStdlib 6.0, *)
private typealias TruncationTestCase = (
    prefixLength: Int, ip: IPv6Address, expectedIP: IPv6Address
)

@available(SwiftStdlib 6.0, *)
private let ipv6CIDRTruncationArguments: [TruncationTestCase] = [
    (
        prefixLength: 0,
        ip: IPv6Address(0b00000000_00000000_00000000_00000000 << 96),
        expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
    ),
    (
        prefixLength: 0,
        ip: IPv6Address(0b10000000_00000000_00000000_00000000 << 96),
        expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
    ),
    (
        prefixLength: 0,
        ip: IPv6Address(0b10000000_00001000_00000000_00100000 << 96),
        expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
    ),
    (
        prefixLength: 1,
        ip: IPv6Address(0b00000000_00001000_00000000_00100000 << 96),
        expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
    ),
    (
        prefixLength: 1,
        ip: IPv6Address(0b10000000_00000000_00000000_00000000 << 96),
        expectedIP: IPv6Address(0b10000000_00000000_00000000_00000000 << 96)
    ),
    (
        prefixLength: 1,
        ip: IPv6Address(0b11000000_00000000_00000000_00000000 << 96),
        expectedIP: IPv6Address(0b10000000_00000000_00000000_00000000 << 96)
    ),
    (
        prefixLength: 9,
        ip: IPv6Address(0b1111111_10000000_00000000_00000000 << 96),
        expectedIP: IPv6Address(0b1111111_10000000_00000000_00000000 << 96)
    ),
    (
        prefixLength: 9,
        ip: IPv6Address(0b1111111_10001000_00010010_00000001 << 96),
        expectedIP: IPv6Address(0b1111111_10000000_00000000_00000000 << 96)
    ),
    (
        prefixLength: 24,
        ip: IPv6Address(0b1111111_11111111_11111111_00000000 << 96),
        expectedIP: IPv6Address(0b1111111_11111111_11111111_00000000 << 96)
    ),
    (
        prefixLength: 24,
        ip: IPv6Address(0b1111111_11111111_11111111_11111111 << 96),
        expectedIP: IPv6Address(0b1111111_11111111_11111111_00000000 << 96)
    ),
    (
        prefixLength: 25,
        ip: IPv6Address(0b1111111_11111111_11111111_11111000 << 96),
        expectedIP: IPv6Address(0b1111111_11111111_11111111_10000000 << 96)
    ),
    (
        prefixLength: 120,
        ip: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_01000100
        ),
        expectedIP: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
        )
    ),
    (
        prefixLength: 120,
        ip: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
        ),
        expectedIP: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
        )
    ),
    (
        prefixLength: 120,
        ip: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
        ),
        expectedIP: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
        )
    ),
    (
        prefixLength: 126,
        ip: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
        ),
        expectedIP: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
        )
    ),
    (
        prefixLength: 126,
        ip: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111101
        ),
        expectedIP: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
        )
    ),
    (
        prefixLength: 126,
        ip: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
        ),
        expectedIP: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
        )
    ),
    (
        prefixLength: 127,
        ip: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
        ),
        expectedIP: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
        )
    ),
    (
        prefixLength: 127,
        ip: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
        ),
        expectedIP: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
        )
    ),
    (
        prefixLength: 128,
        ip: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
        ),
        expectedIP: IPv6Address(
            0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
        )
    ),
]

#if os(macOS) || os(Linux)
extension CIDRTests {
    @available(SwiftStdlib 5.1, *)
    @Test func `ipv4 CIDR standard initializer crashes when prefixLength is out of bounds`() async {
        await #expect(processExitsWith: .failure) {
            blackHole(CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: noOptimize(-1)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: noOptimize(33)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: noOptimize(Int.min)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(CIDR(prefix: IPv4Address(192, 168, 1, 0), prefixLength: noOptimize(Int.max)))
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `ipv6 CIDR standard initializer crashes when prefixLength is out of bounds`() async {
        await #expect(processExitsWith: .failure) {
            blackHole(CIDR(prefix: IPv6Address(0x1), prefixLength: noOptimize(-1)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(CIDR(prefix: IPv6Address(0x1), prefixLength: noOptimize(129)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(CIDR(prefix: IPv6Address(0x1), prefixLength: noOptimize(Int.min)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(CIDR(prefix: IPv6Address(0x1), prefixLength: noOptimize(Int.max)))
        }
    }
}
#endif
