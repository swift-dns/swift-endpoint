import Endpoint
import Testing

#if os(Linux) || os(FreeBSD) || os(Android)

#if canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Android)
@preconcurrency import Android
#endif

#elseif os(Windows)
import ucrt
#elseif canImport(Darwin)
import Darwin
#elseif canImport(WASILibc)
@preconcurrency import WASILibc
#else
#error("The IPAddressTests module was unable to identify your C library.")
#endif

@Suite
struct IPAddressTests {
    @Test func ipv4Address() {
        let ip = IPv4Address(127, 0, 0, 1)
        #expect(ip.address == 0x7F00_0001)
        #expect(ip.bytes == (0x7F, 0x00, 0x00, 0x01))
    }

    @Test func `IPv4Address encode decode happy-path with span works correctly`() throws {
        let ip = IPv4Address(123, 251, 98, 234)

        let bufferPointer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 20)
        defer { bufferPointer.deallocate() }
        var outputSpan = OutputSpan(buffer: bufferPointer, initializedCount: 0)

        let didEncode = ip.encode(into: &outputSpan)

        #expect(didEncode)
        #expect(outputSpan.capacity == 20)
        #expect(outputSpan.freeCapacity == 16)
        #expect(outputSpan.count == 4)
        let isFull = outputSpan.isFull
        #expect(!isFull)
        let isEmpty = outputSpan.isEmpty
        #expect(!isEmpty)
        outputSpan.span.withUnsafeBytes { ptr in
            let data = [UInt8](ptr)
            #expect(data == [123, 251, 98, 234])
        }

        let _decodedIP = IPv4Address(from: outputSpan.span)
        let decodedIP = try #require(_decodedIP)
        #expect(decodedIP == ip)
    }

    @Test(
        arguments: [
            (IPv4Address(127, 0, 0, 1), "127.0.0.1"),
            (IPv4Address(120, 102, 12, 100), "120.102.12.100"),
            (IPv4Address(0, 0, 0, 0), "0.0.0.0"),
            (IPv4Address(0, 0, 0, 1), "0.0.0.1"),
            (IPv4Address(0, 0, 1, 0), "0.0.1.0"),
            (IPv4Address(0, 1, 0, 0), "0.1.0.0"),
            (IPv4Address(1, 0, 0, 0), "1.0.0.0"),
            (IPv4Address(1, 1, 1, 1), "1.1.1.1"),
            (IPv4Address(123, 251, 98, 234), "123.251.98.234"),
            (IPv4Address(255, 255, 255, 255), "255.255.255.255"),
            (IPv4Address(192, 168, 1, 98), "192.168.1.98"),
        ]
    )
    func ipv4AddressDescription(ip: IPv4Address, expectedDescription: String) {
        #expect(ip.description == expectedDescription)

        let produced = ip.withCString { span in
            #expect(span.count == expectedDescription.utf8.count + 1)
            return span.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
        }
        #expect(produced == expectedDescription)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: ipv4StringAndAddressTestCases
            + ipv4IDNAStringAndAddressTestCases.map { ($0.0, nil, $0.2) }
    )
    func ipv4AddressFromString(
        string: String,
        expectedAddress: IPv4Address?,
        isValidIPv6: Bool
    ) {
        #expect(IPv4Address(string) == expectedAddress)
        #expect(IPv4Address(Substring(string)) == expectedAddress)
        #expect(IPv4Address(textualRepresentation: string.utf8Span) == expectedAddress)
        #expect(IPv4Address(textualRepresentation: string.utf8Span.span) == expectedAddress)

        if isValidIPv6 {
            #expect(AnyIPAddress(string)?.isIPv6 == true)
            #expect(AnyIPAddress(Substring(string))?.isIPv6 == true)
            #expect(AnyIPAddress(textualRepresentation: string.utf8Span)?.isIPv6 == true)
            #expect(AnyIPAddress(textualRepresentation: string.utf8Span.span)?.isIPv6 == true)
        } else {
            let expectedIPv4: AnyIPAddress? = expectedAddress.map { .v4($0) }
            #expect(AnyIPAddress(string) == expectedIPv4)
            #expect(AnyIPAddress(Substring(string)) == expectedIPv4)
            #expect(AnyIPAddress(textualRepresentation: string.utf8Span) == expectedIPv4)
            #expect(AnyIPAddress(textualRepresentation: string.utf8Span.span) == expectedIPv4)
        }

        string.withCString { cString in
            #expect(IPv4Address(cString: cString) == expectedAddress)
            if isValidIPv6 {
                #expect(AnyIPAddress(cString: cString)?.isIPv6 == true)
            } else {
                #expect(AnyIPAddress(cString: cString) == expectedAddress.map { .v4($0) })
            }
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: ipv4StringAndAddressTestCases
            + ipv4IDNAStringAndAddressTestCases
    )
    func ipv4AddressFromStringThroughDomainName(
        string: String,
        expectedAddress: IPv4Address?,
        isValidIPv6: Bool
    ) {
        let domainName = try? DomainName(string)

        let ipv4Address = domainName.flatMap { IPv4Address(domainName: $0) }
        #expect(ipv4Address == expectedAddress)

        let ipAddress = domainName.flatMap { AnyIPAddress(domainName: $0) }
        switch ipAddress {
        case .v4(let ipv4):
            #expect(ipv4 == expectedAddress)
        case .none:
            #expect(expectedAddress == nil)
        case .v6:
            if !isValidIPv6 {
                Issue.record("Expected IPv4 but got: \(ipAddress)")
            }
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: ipv4StringAndAddressTestCases)
    func ipv4AddressFromStringThroughArpaDomainName(
        string: String,
        expectedAddress: IPv4Address?,
        isValidIPv6: Bool
    ) {
        let arpa =
            string
            .split(separator: ".")
            .reversed()
            .joined(separator: ".")
            + ".in-addr.arpa."
        let domainName = try? DomainName(arpa)

        let ipv4Address1 = domainName.flatMap { IPv4Address(arpaDomainName: $0) }
        #expect(ipv4Address1 == expectedAddress)

        let ipv4Address2 = domainName.flatMap { IPv4Address(domainName: $0) }
        #expect(ipv4Address2 == expectedAddress)

        let anyIPAddress1 = domainName.flatMap { AnyIPAddress(arpaDomainName: $0) }
        let anyIPAddress2 = domainName.flatMap { AnyIPAddress(domainName: $0) }
        for ipAddress in [anyIPAddress1, anyIPAddress2] {
            switch ipAddress {
            case .v4(let ipv4):
                #expect(ipv4 == expectedAddress)
            case .none:
                #expect(expectedAddress == nil)
            case .v6:
                if !isValidIPv6 {
                    Issue.record("Expected IPv4 but got: \(ipAddress)")
                }
            }
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: [(IPv4Address?, String)]([
            (IPv4Address(192, 0, 2, 128), "::ffff:c000:0280"),
            (IPv4Address(18, 52, 86, 120), "::ffff:1234:5678"),
            (IPv4Address(171, 205, 239, 1), "::ffff:abcd:ef01"),
            (nil, "0:0:1:0:0:ffff:abcd:ef01"),
            (nil, "ffff:ffff:ffff:ffff:ffff:ffff:abcd:ef01"),
        ])
    )
    func ipv4AddressFromIpv6Address(
        ipv4: IPv4Address?,
        expectedIPv6: String
    ) throws {
        let ipv6 = try #require(IPv6Address(expectedIPv6))
        #expect(ipv4 == IPv4Address(ipv6: ipv6))
    }

    @available(SwiftStdlib 5.1, *)
    @Test(
        arguments: [(IPv4Address, String, (@Sendable (IPv4Address) -> Bool))]([
            (IPv4Address(127, 0, 0, 0), "isLoopback", \.isLoopback),
            (IPv4Address(127, 0, 0, 1), "isLoopback", \.isLoopback),
            (IPv4Address(127, 128, 9, 22), "isLoopback", \.isLoopback),
            (IPv4Address(127, 255, 255, 255), "isLoopback", \.isLoopback),
            (IPv4Address(126, 0, 0, 0), "!isLoopback", { @Sendable in !$0.isLoopback }),
            (IPv4Address(128, 0, 0, 0), "!isLoopback", { @Sendable in !$0.isLoopback }),
            (IPv4Address(224, 0, 0, 0), "isMulticast", \.isMulticast),
            (IPv4Address(239, 255, 255, 255), "isMulticast", \.isMulticast),
            (IPv4Address(229, 28, 192, 233), "isMulticast", \.isMulticast),
            (IPv4Address(244, 0, 0, 0), "!isMulticast", { @Sendable in !$0.isMulticast }),
            (IPv4Address(169, 254, 0, 0), "isLinkLocal", \.isLinkLocal),
            (IPv4Address(169, 254, 222, 138), "isLinkLocal", \.isLinkLocal),
            (IPv4Address(169, 254, 255, 255), "isLinkLocal", \.isLinkLocal),
            (
                IPv4Address(169, 253, 0, 0), "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
            (
                IPv4Address(169, 255, 0, 0), "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
            (
                IPv4Address(168, 254, 0, 0), "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
            (
                IPv4Address(170, 254, 0, 0), "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
        ])
    )
    func ipv4AddressPropertiesWorkCorrectly(
        ip: IPv4Address,
        testCaseDescription: String,
        predicate: @Sendable (IPv4Address) -> Bool
    ) throws {
        #expect(predicate(ip), "\(testCaseDescription)")
    }

    @available(SwiftStdlib 6.0, *)
    @Test func ipv6Address() {
        let ipWithUInt16 = IPv6Address(
            0x0102,
            0xF3F4,
            0x1516,
            0x7080,
            0x90A0,
            0xCBBC,
            0x0D0E,
            0x0F11,
        )
        let ip = IPv6Address(
            0x01,
            0x02,
            0xF3,
            0xF4,
            0x15,
            0x16,
            0x70,
            0x80,
            0x90,
            0xA0,
            0xCB,
            0xBC,
            0x0D,
            0x0E,
            0x0F,
            0x11,
        )
        #expect(ip.address == ipWithUInt16.address)
        let expectedAddress: UnsignedInteger128 = 0x0102_F3F4_1516_7080_90A0_CBBC_0D0E_0F11
        #expect(ip.address == expectedAddress)

        #expect(ip.bytes.0 == 0x01)
        #expect(ip.bytes.1 == 0x02)
        #expect(ip.bytes.2 == 0xF3)
        #expect(ip.bytes.3 == 0xF4)
        #expect(ip.bytes.4 == 0x15)
        #expect(ip.bytes.5 == 0x16)
        #expect(ip.bytes.6 == 0x70)
        #expect(ip.bytes.7 == 0x80)
        #expect(ip.bytes.8 == 0x90)
        #expect(ip.bytes.9 == 0xA0)
        #expect(ip.bytes.10 == 0xCB)
        #expect(ip.bytes.11 == 0xBC)
        #expect(ip.bytes.12 == 0x0D)
        #expect(ip.bytes.13 == 0x0E)
        #expect(ip.bytes.14 == 0x0F)
        #expect(ip.bytes.15 == 0x11)

        #expect(ip.segments.0 == 0x0102)
        #expect(ip.segments.1 == 0xF3F4)
        #expect(ip.segments.2 == 0x1516)
        #expect(ip.segments.3 == 0x7080)
        #expect(ip.segments.4 == 0x90A0)
        #expect(ip.segments.5 == 0xCBBC)
        #expect(ip.segments.6 == 0x0D0E)
        #expect(ip.segments.7 == 0x0F11)
    }

    @Test func `IPv6Address encode decode happy-path with span works correctly`() throws {
        let ip = IPv6Address(0x0102, 0xF3F4, 0x1516, 0x7080, 0x90A0, 0xCBBC, 0x0D0E, 0x0F11)

        let bufferPointer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 20)
        defer { bufferPointer.deallocate() }
        var outputSpan = OutputSpan(buffer: bufferPointer, initializedCount: 0)

        let didEncode = ip.encode(into: &outputSpan)

        #expect(didEncode)
        #expect(outputSpan.capacity == 20)
        #expect(outputSpan.freeCapacity == 4)
        #expect(outputSpan.count == 16)
        let isFull = outputSpan.isFull
        #expect(!isFull)
        let isEmpty = outputSpan.isEmpty
        #expect(!isEmpty)
        outputSpan.span.withUnsafeBytes { ptr in
            let data = [UInt8](ptr)
            #expect(
                data == [
                    0x01, 0x02, 0xF3, 0xF4,
                    0x15, 0x16, 0x70, 0x80,
                    0x90, 0xA0, 0xCB, 0xBC,
                    0x0D, 0x0E, 0x0F, 0x11,
                ]
            )
        }

        let _decodedIP = IPv6Address(from: outputSpan.span)
        let decodedIP = try #require(_decodedIP)
        #expect(decodedIP == ip)
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: [
            (
                0x1111_2222_3333_4444_5555_6666_7777_8888,
                "[1111:2222:3333:4444:5555:6666:7777:8888]"
            ),
            (0x2001_0DB8_85A0_0000_0000_0000_0000_0100, "[2001:db8:85a0::100]"),
            (0x2001_0DB8_8503_0000_0000_0000_0000_0100, "[2001:db8:8503::100]"),
            (0x2001_0DB8_80A3_0000_0000_0000_0000_0100, "[2001:db8:80a3::100]"),
            (0x2001_0DB8_0000_0000_0001_0000_0000_0002, "[2001:db8::1:0:0:2]"),
            (0x2001_0DB8_1111_2222_3333_4444_0000_0000, "[2001:db8:1111:2222:3333:4444::]"),
            (0x2001_0DB8_1111_2222_3333_4444_5555_0000, "[2001:db8:1111:2222:3333:4444:5555:0]"),
            (0x2001_0DB8_1111_2222_0000_3333_4444_5555, "[2001:db8:1111:2222:0:3333:4444:5555]"),
            (0x2001_0000_0000_0000_0001_0000_0000_0002, "[2001::1:0:0:2]"),
            (0x2001_0000_0000_0001_0000_0000_0000_0002, "[2001:0:0:1::2]"),
            (0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001, "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]"),
            (0x2001_0DB8_0000_0000_0001_0000_0000_0002, "[2001:db8::1:0:0:2]"),
            (0x0000_0000_0000_0000_0000_0000_0000_0000, "[::]"),
            (0x2001_0000_0000_0001_0000_0000_0000_0000, "[2001:0:0:1::]"),
            (0x0000_0000_0000_0000_0001_0000_0000_0002, "[::1:0:0:2]"),
            (0x0000_0000_0001_0002_0003_0000_0004_0005, "[::1:2:3:0:4:5]"),
            (0x0000_0001_0002_0003_0004_0000_0005_0006, "[0:1:2:3:4:0:5:6]"),
        ]
    )
    func ipv6AddressDescription(ip: UInt128, expectedDescription: String) {
        let ipv6 = IPv6Address(ip)
        #expect(ipv6.description == expectedDescription)

        let bracketLess = String(expectedDescription.dropFirst().dropLast())
        let produced = ipv6.withCString { span in
            #expect(span.count - 1 == bracketLess.utf8.count)
            return span.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
        }
        #expect(produced == bracketLess)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: ipv6StringAndAddressTestCases
            + ipv6IDNAStringAndAddressTestCases.map { ($0.0, nil, $0.2) }
    )
    func ipv6AddressFromString(
        string: String,
        expectedAddress: IPv6Address?,
        isValidIPv4: Bool
    ) {
        #expect(IPv6Address(string) == expectedAddress)
        #expect(IPv6Address(Substring(string)) == expectedAddress)
        #expect(IPv6Address(textualRepresentation: string.utf8Span) == expectedAddress)
        #expect(IPv6Address(textualRepresentation: string.utf8Span.span) == expectedAddress)

        if isValidIPv4 {
            #expect(AnyIPAddress(string)?.isIPv4 == true)
            #expect(AnyIPAddress(Substring(string))?.isIPv4 == true)
            #expect(AnyIPAddress(textualRepresentation: string.utf8Span)?.isIPv4 == true)
            #expect(AnyIPAddress(textualRepresentation: string.utf8Span.span)?.isIPv4 == true)
        } else {
            let expectedIPv6: AnyIPAddress? = expectedAddress.map { .v6($0) }
            #expect(AnyIPAddress(string) == expectedIPv6)
            #expect(AnyIPAddress(Substring(string)) == expectedIPv6)
            #expect(AnyIPAddress(textualRepresentation: string.utf8Span) == expectedIPv6)
            #expect(AnyIPAddress(textualRepresentation: string.utf8Span.span) == expectedIPv6)
        }

        string.withCString { cString in
            #expect(IPv6Address(cString: cString) == expectedAddress)
            if isValidIPv4 {
                #expect(AnyIPAddress(cString: cString)?.isIPv4 == true)
            } else {
                #expect(AnyIPAddress(cString: cString) == expectedAddress.map { .v6($0) })
            }
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: [
            (
                try! DomainName(
                    "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa."
                ),
                IPv6Address("4321:0:1:2:3:4:567:89ab")!
            )
        ]
    )
    func ipv6AddressFromStringThroughArpaDomainNameHardcodedCases(
        arpaDomainName domainName: DomainName,
        expectedAddress: IPv6Address?
    ) {
        let ipv6Address1 = IPv6Address(arpaDomainName: domainName)
        #expect(ipv6Address1 == expectedAddress)

        let ipv6Address2 = IPv6Address(domainName: domainName)
        #expect(ipv6Address2 == expectedAddress)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: ipv6StringAndAddressTestCases)
    func ipv6AddressFromStringThroughArpaDomainName(
        string: String,
        expectedAddress: IPv6Address?,
        isValidIPv4: Bool
    ) {
        let plainIPv6Address = IPv6Address(string)
        let arpa: String? = plainIPv6Address.map { address in
            let bytes = address.bytes
            func byteToLabel(_ byte: UInt8) -> String {
                let _1 = String(byte & 0xF, radix: 16)
                let _2 = String(byte >> 4, radix: 16)
                return "\(_1).\(_2)"
            }
            let byte0 = byteToLabel(bytes.0)
            let byte1 = byteToLabel(bytes.1)
            let byte2 = byteToLabel(bytes.2)
            let byte3 = byteToLabel(bytes.3)
            let byte4 = byteToLabel(bytes.4)
            let byte5 = byteToLabel(bytes.5)
            let byte6 = byteToLabel(bytes.6)
            let byte7 = byteToLabel(bytes.7)
            let byte8 = byteToLabel(bytes.8)
            let byte9 = byteToLabel(bytes.9)
            let byte10 = byteToLabel(bytes.10)
            let byte11 = byteToLabel(bytes.11)
            let byte12 = byteToLabel(bytes.12)
            let byte13 = byteToLabel(bytes.13)
            let byte14 = byteToLabel(bytes.14)
            let byte15 = byteToLabel(bytes.15)
            let segment1 = "\(byte1).\(byte0)"
            let segment2 = "\(byte3).\(byte2)"
            let segment3 = "\(byte5).\(byte4)"
            let segment4 = "\(byte7).\(byte6)"
            let segment5 = "\(byte9).\(byte8)"
            let segment6 = "\(byte11).\(byte10)"
            let segment7 = "\(byte13).\(byte12)"
            let segment8 = "\(byte15).\(byte14)"
            let firstHalf = "\(segment8).\(segment7).\(segment6).\(segment5)"
            let secondHalf = "\(segment4).\(segment3).\(segment2).\(segment1)"
            return "\(firstHalf).\(secondHalf).ip6.arpa."
        }
        let domainName = arpa.flatMap { try? DomainName($0) }

        let ipv6Address1 = domainName.flatMap { IPv6Address(arpaDomainName: $0) }
        #expect(ipv6Address1 == expectedAddress)

        let ipv6Address2 = domainName.flatMap { IPv6Address(domainName: $0) }
        #expect(ipv6Address2 == expectedAddress)

        let anyIPAddress1 = domainName.flatMap { AnyIPAddress(arpaDomainName: $0) }
        let anyIPAddress2 = domainName.flatMap { AnyIPAddress(domainName: $0) }
        for ipAddress in [anyIPAddress1, anyIPAddress2] {
            switch ipAddress {
            case .v6(let ipv6):
                #expect(ipv6 == expectedAddress)
            case .none:
                #expect(expectedAddress == nil)
            case .v4:
                if !isValidIPv4 {
                    Issue.record("Expected IPv6 but got: \(ipAddress)")
                }
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: [
            (AnyIPAddress.v4(IPv4Address(192, 168, 1, 1)), "192.168.1.1"),
            (
                AnyIPAddress.v6(IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0100)),
                "[2001:db8:85a3::100]"
            ),
        ]
    )
    func `AnyIPAddress description`(ip: AnyIPAddress, expectedDescription: String) {
        #expect(ip.description == expectedDescription)

        let droppedFirstLast = String(expectedDescription.dropFirst().dropLast())
        let bracketLess = ip.isIPv6 ? droppedFirstLast : expectedDescription
        let produced = ip.withCString { span in
            span.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
        }
        #expect(produced == bracketLess)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: [(String, AnyIPAddress?)]([
            ("192.168.1.1", .v4(IPv4Address(192, 168, 1, 1))),
            ("[192.168.1.256]", nil),
            ("[2001:0:0:1::]", .v6(IPv6Address(0x2001_0000_0000_0001_0000_0000_0000_0000))),
            (
                "0:0:0:0:0:FFFF:204.152.189.116",
                .v6(IPv6Address(0x0000_0000_0000_0000_0000_FFFF_CC98_BD74))
            ),
            ("[0:1:2:3:4:0:5:6::]", nil),
        ])
    )
    func `AnyIPAddress from string`(string: String, expectedAddress: AnyIPAddress?) {
        #expect(AnyIPAddress(string) == expectedAddress)

        string.withCString { #expect(AnyIPAddress(cString: $0) == expectedAddress) }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: [(String, IPv4Address)]([
            ("::ffff:c000:0280", IPv4Address(192, 0, 2, 128)),
            ("::ffff:1234:5678", IPv4Address(18, 52, 86, 120)),
            ("::ffff:abcd:ef01", IPv4Address(171, 205, 239, 1)),
            ("::ffff:7f00:0001", IPv4Address(127, 0, 0, 1)),
        ])
    )
    func ipv6AddressFromIpv4Address(
        ipv6: String,
        expectedIPv4: IPv4Address
    ) throws {
        let ipv6 = try #require(IPv6Address(ipv6))
        #expect(ipv6 == IPv6Address(ipv4: expectedIPv4))
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: [(String, String, (@Sendable (IPv6Address) -> Bool))]([
            ("::1", "isLoopback", \.isLoopback),
            ("::1:1", "!isLoopback", { @Sendable in !$0.isLoopback }),
            ("FF00::", "isMulticast", \.isMulticast),
            ("FF92::", "isMulticast", \.isMulticast),
            ("FFFF:998A::1", "isMulticast", \.isMulticast),
            ("FF::", "!isMulticast", { @Sendable in !$0.isMulticast }),
            ("00FF::", "!isMulticast", { @Sendable in !$0.isMulticast }),
            ("FAFF::", "!isMulticast", { @Sendable in !$0.isMulticast }),
            ("FE80::", "isLinkLocalUnicast", \.isLinkLocalUnicast),
            ("FE90::", "isLinkLocalUnicast", \.isLinkLocalUnicast),
            ("FEBF::", "isLinkLocalUnicast", \.isLinkLocalUnicast),
            ("FEAA:9876:1928::9", "isLinkLocalUnicast", \.isLinkLocalUnicast),
            ("FE70::", "!isLinkLocalUnicast", { @Sendable in !$0.isLinkLocalUnicast }),
        ])
    )
    func ipv6AddressPropertiesWorkCorrectly(
        ip: String,
        testCaseDescription: String,
        predicate: @Sendable (IPv6Address) -> Bool
    ) throws {
        let ip = try #require(IPv6Address(ip))
        #expect(predicate(ip), "\(testCaseDescription)")
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: anyIPAddressCIDRRelatedPropertiesTestCases)
    func `AnyIPAddress CIDR-related properties work correctly`(
        ip: AnyIPAddress,
        testCaseDescription: String,
        predicate: @Sendable (AnyIPAddress) -> Bool
    ) throws {
        #expect(predicate(ip), "\(testCaseDescription)")
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: ipv4StringAndAddressTestCases.compactMap(\.1))
    func `IPv4Address cString APIs compatibility with C`(ip: IPv4Address) {
        let expectedBytes = [ip.bytes.0, ip.bytes.1, ip.bytes.2, ip.bytes.3]

        var inAddress = in_addr()
        let pton = ip.withCString { span in
            span.withUnsafeBufferPointer { inet_pton(AF_INET, $0.baseAddress!, &inAddress) }
        }
        #expect(pton == 1)
        #expect(withUnsafeBytes(of: inAddress) { Array($0) } == expectedBytes)

        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        let ntop = inet_ntop(AF_INET, &inAddress, &buffer, socklen_t(INET_ADDRSTRLEN))
        #expect(ntop != nil)
        #expect(IPv4Address(cString: buffer) == ip)
    }

    @available(SwiftStdlib 6.0, *)
    @Test(arguments: ipv6StringAndAddressTestCases.compactMap(\.1))
    func `IPv6Address cString APIs compatibility with C`(ip: IPv6Address) {
        let bytes = ip.bytes
        let expectedBytes = [
            bytes.0, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5, bytes.6, bytes.7,
            bytes.8, bytes.9, bytes.10, bytes.11, bytes.12, bytes.13, bytes.14, bytes.15,
        ]

        var in6Address = in6_addr()
        let pton = ip.withCString { span in
            span.withUnsafeBufferPointer {
                inet_pton(AF_INET6, $0.baseAddress!, &in6Address)
            }
        }
        #expect(pton == 1)
        #expect(withUnsafeBytes(of: in6Address) { Array($0) } == expectedBytes)

        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        let ntop = inet_ntop(AF_INET6, &in6Address, &buffer, socklen_t(INET6_ADDRSTRLEN))
        #expect(ntop != nil)
        #expect(IPv6Address(cString: buffer) == ip)
    }
}

/// (IPv4String, IPv4Address, isValidIPv6)
private let ipv4StringAndAddressTestCases: [(String, IPv4Address?, Bool)] = [
    ("127.0.0.1", IPv4Address(127, 0, 0, 1), false),
    ("0.0.0.0", IPv4Address(0, 0, 0, 0), false),
    ("0.0.0.1", IPv4Address(0, 0, 0, 1), false),
    ("0.0.1.0", IPv4Address(0, 0, 1, 0), false),
    ("0.1.0.0", IPv4Address(0, 1, 0, 0), false),
    ("1.0.0.0", IPv4Address(1, 0, 0, 0), false),
    ("1.1.1.1", IPv4Address(1, 1, 1, 1), false),
    ("123.251.98.234", IPv4Address(123, 251, 98, 234), false),
    ("255.255.255.255", IPv4Address(255, 255, 255, 255), false),
    ("192.168.1.98", IPv4Address(192, 168, 1, 98), false),
    ("192.168.1.256", nil, false),
    ("192.168.1.", nil, false),
    ("1111.168.1.1", nil, false),
    ("192.168.1.2.3", nil, false),
    ("192.168.1", nil, false),
    (".168.1.123", nil, false),
    ("168.1.123", nil, false),
    ("-1.168.1.123", nil, false),
    ("1.-168.1.123", nil, false),
    ("1.-168.1.0xaa", nil, false),
    ("1.-168.1.aa", nil, false),
    ("9", nil, false),
    ("9.87", nil, false),
    ("", nil, false),
    (" ", nil, false),
    ("    ", nil, false),
    (".", nil, false),
    ("..", nil, false),
    ("...", nil, false),
    ("....", nil, false),
    (".....", nil, false),
    ("m.a.h.d", nil, false),
    ("m:a:h:d::", nil, false),
    ("1111:2222:3333:4444:5555:6666:7777:8888", nil, true),
    ("::1", nil, true),
]

/// (IPv4String, IPv4Address, isValidIPv6)
private let ipv4IDNAStringAndAddressTestCases: [(String, IPv4Address?, Bool)] = [
    /// These all should work based on IDNA.
    /// For example, the weird `1`s in the ip address below is:
    /// 2081          ; mapped     ; 0031          # 1.1  SUBSCRIPT ONE
    ///
    /// IDNA label separators other than U+002E ( . ) FULL STOP, are:
    /// U+FF0E ( ． ) FULLWIDTH FULL STOP
    /// U+3002 ( 。 ) IDEOGRAPHIC FULL STOP
    /// U+FF61 ( ｡ ) HALFWIDTH IDEOGRAPHIC FULL STOP
    ///
    /// Some ignored IDNA unicode scalars that are used below:
    /// U+00AD ( ­ ) SOFT HYPHEN
    /// U+200B ( ​ ) ZERO WIDTH SPACE
    /// U+2064 ( ⁤ ) INVISIBLE PLUS
    ///
    /// Would parse to 192.168.1.98 assuming IDNA-compliant parsing
    ("\u{AD}1\u{AD}92.₁₆\u{2064}\u{200B}\u{AD}₈.₁.98\u{AD}", IPv4Address(192, 168, 1, 98), false),
    /// Would parse to 192.168.1.98 assuming IDNA-compliant parsing
    ("192．168。1｡\u{AD}98", IPv4Address(192, 168, 1, 98), false),
    ("192.\u{AD}.166.9", nil, false),
]

/// (IPv6String, IPv6Address, isValidIPv4)
@available(SwiftStdlib 6.0, *)
private let ipv6StringAndAddressTestCases: [(String, IPv6Address?, Bool)] = [
    ("1111:2222:3333:4444:5555:6666:7777:8888", 0x1111_2222_3333_4444_5555_6666_7777_8888, false),
    ("[FF::]", 0x00FF_0000_0000_0000_0000_0000_0000_0000, false),
    ("[::FF]", 0x0000_0000_0000_0000_0000_0000_0000_00FF, false),
    ("[0:FF::]", 0x0000_00FF_0000_0000_0000_0000_0000_0000, false),
    ("[2001:db8:85a3::100]", 0x2001_0DB8_85A3_0000_0000_0000_0000_0100, false),
    ("2001:db8:85a3::100", 0x2001_0DB8_85A3_0000_0000_0000_0000_0100, false),
    ("[2001:db8::1:0:0:2]", 0x2001_0DB8_0000_0000_0001_0000_0000_0002, false),
    ("[2001:db8:1111:2222:3333:4444::]", 0x2001_0DB8_1111_2222_3333_4444_0000_0000, false),
    ("[2001:db8:1111:2222:3333:4444:5555:6666]", 0x2001_0DB8_1111_2222_3333_4444_5555_6666, false),
    ("[2001:DB8:1111:2222:0:3333:4444:5555]", 0x2001_0DB8_1111_2222_0000_3333_4444_5555, false),
    ("[2001::1:0:0:2]", 0x2001_0000_0000_0000_0001_0000_0000_0002, false),
    ("2001::1:0:0:2", 0x2001_0000_0000_0000_0001_0000_0000_0002, false),
    ("[2001:0:0:1::2]", 0x2001_0000_0000_0001_0000_0000_0000_0002, false),
    ("[2001:db8:aaaa:bbbb:cccc:DDDD:eeee:1]", 0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001, false),
    ("2001:db8:aaaa:BBBB:cccc:dddd:eeee:1", 0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001, false),
    ("01:db8:a0a:bb:cc0:0dd0:ee:1", 0x0001_0DB8_0A0A_00BB_0CC0_0DD0_00EE_0001, false),
    ("[2001:db8::1:0:0:2]", 0x2001_0DB8_0000_0000_0001_0000_0000_0002, false),
    ("[::]", 0x0000_0000_0000_0000_0000_0000_0000_0000, false),
    ("::", 0x0000_0000_0000_0000_0000_0000_0000_0000, false),
    ("[2001:0:0:1::]", 0x2001_0000_0000_0001_0000_0000_0000_0000, false),
    ("[::1:0:0:2]", 0x0000_0000_0000_0000_0001_0000_0000_0002, false),
    ("[::1:2:3:0:4:5]", 0x0000_0000_0001_0002_0003_0000_0004_0005, false),
    ("[0:1:2:3:4:0:5:6]", 0x0000_0001_0002_0003_0004_0000_0005_0006, false),
    ("[0:1:2:3:4:0:5:f]", 0x0000_0001_0002_0003_0004_0000_0005_000F, false),
    ("0:1:2:3:4:0:5:6", 0x0000_0001_0002_0003_0004_0000_0005_0006, false),
    ("[::1]", 0x0000_0000_0000_0000_0000_0000_0000_0001, false),
    ("::1", 0x0000_0000_0000_0000_0000_0000_0000_0001, false),
    ("::FFFF:204.152.189.116", 0x0000_0000_0000_0000_0000_FFFF_CC98_BD74, false),
    ("::FFFF:255.255.255.255", 0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF, false),
    ("::FFFF:1.1.1.1", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("[::ffff:1.1.1.1]", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("0:0:0:0:0:FFFF:204.152.189.116", 0x0000_0000_0000_0000_0000_FFFF_CC98_BD74, false),
    ("0:0:0:0:0:ffff:255.255.255.255", 0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF, false),
    (
        "[0000:0000:0000:0000:0000:FFFF:255.255.255.255]",
        0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF, false
    ),
    ("0:0:0:0:0:FFFF:1.1.1.1", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("0::0:FFFF:1.1.1.1", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("0:0::0:FFFF:1.1.1.1", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("0:0:0:0:0:0:FFFF:1.1.1.1", nil, false),
    ("0:0:1:0:0:FFFF:204.152.189.116", nil, false),
    ("0:0:0:0:FFFF:1.1.1.1:FFFF", nil, false),
    ("0:0:0:0:0:1.1.1.1:FFFF", nil, false),
    ("::FFFF:1.1.1.1:FFFF", nil, false),
    ("::1.1.1.1:FFFF", nil, false),
    (":FFFF:1.1.1.1", nil, false),
    ("::FFFF:1.", nil, false),
    ("::FFFF:1.1", nil, false),
    ("::FFFF:1.1.", nil, false),
    ("::FFFF:1.1.1", nil, false),
    ("::FFFF:1.1.1.", nil, false),
    ("::1.1.1.1", nil, false),
    (".1.1.1.1", nil, false),
    ("::FFFF:256.152.189.116", nil, false),
    ("[0000:0000:0000:0000:0000:FFFF:255.255.255.1111]", nil, false),
    ("::FFFF:204.152.189.116.", nil, false),
    ("::FFFF:.204.152.189.116", nil, false),
    ("::FFFF::204.152.189.116", nil, false),
    ("::FFFF:204.152.189", nil, false),
    ("::FFFF:204.152.189.", nil, false),
    ("::FFFF:.204.152.189", nil, false),
    ("", nil, false),
    (" ", nil, false),
    ("    ", nil, false),
    (".", nil, false),
    ("..", nil, false),
    ("...", nil, false),
    ("....", nil, false),
    (".....", nil, false),
    ("::FFFF:", nil, false),
    ("::FFFF: ", nil, false),
    ("::FFFF:    ", nil, false),
    ("::FFFF:.", nil, false),
    ("::FFFF:..", nil, false),
    ("::FFFF:...", nil, false),
    ("::FFFF:....", nil, false),
    ("::FFFF:.....", nil, false),
    (":", nil, false),
    ("[:]", nil, false),
    (":::", nil, false),
    ("[:::]", nil, false),
    ("::::", nil, false),
    (":::::", nil, false),
    ("::::::", nil, false),
    (":::::::", nil, false),
    ("[:::::::]", nil, false),
    ("::::::::", nil, false),
    (":::::::::", nil, false),
    ("::::::::::", nil, false),
    ("[::::::::::]", nil, false),
    ("[2001:0:0:1:::]", nil, false),
    ("[:::2001:0:0:1]", nil, false),
    ("[2001:0:0:1::2", nil, false),
    ("2001:0:0:1::2]", nil, false),
    ("[1::2::]", nil, false),
    ("[1::2::3]", nil, false),
    ("[:0:1:2:3:4:0:5:6]", nil, false),
    ("[0:1:2:3:4:0:5:6:]", nil, false),
    ("[0:1:2:3:4:0:5:6:]", nil, false),
    ("[::0:1:2:3:4:5:6:7]", nil, false),
    ("[0:1:2:3:4:5:6:7::]", nil, false),
    ("[0:1:2:3:4:0:5]", nil, false),
    ("[1:2:3:4:5:6:7]", nil, false),
    ("[1:2:3:4:5:6:7:8:9]", nil, false),
    ("[1:2:3]", nil, false),
    ("[1:2:3:]", nil, false),
    ("[:1:2:3]", nil, false),
    ("[0:1:2:3:4:0:5:6:7]", nil, false),
    ("[0:1:2:3:4:0:5:-6]", nil, false),
    ("[0:1:2:3:4:0:5:g]", nil, false),
    ("[0:11111:2:3:4:0:5:6]", nil, false),
    ("[0:11111::]", nil, false),
    ("[::11111:0]", nil, false),
    ("[11111::]", nil, false),
    ("[::11111]", nil, false),
    ("m.a.h.d", nil, false),
    ("m:a:h:d::", nil, false),
    ("192.168.1.255", nil, true),
]

/// (IPv6String, IPv6Address, isValidIPv4)
@available(SwiftStdlib 6.0, *)
private let ipv6IDNAStringAndAddressTestCases: [(String, IPv6Address?, Bool)] = [
    /// Contains weird characters that are mapped to the correct characters in IDNA
    /// These all should work based on IDNA.
    /// For example, the weird `1`s in the ip address below is:
    /// 2081          ; mapped     ; 0031          # 1.1  SUBSCRIPT ONE
    ///
    /// Some ignored IDNA unicode scalars that are used below:
    /// U+00AD ( ­ ) SOFT HYPHEN
    /// U+200B ( ​ ) ZERO WIDTH SPACE
    /// U+2064 ( ⁤ ) INVISIBLE PLUS
    ///
    /// Would parse to 1111:2222:3333:4444:5555:6666:7777:8888 assuming IDNA-compliant parsing
    ("₁₁₁₁:2222:3333:4444:5555:₆6₆6:7777:8888", 0x1111_2222_3333_4444_5555_6666_7777_8888, false),
    /// Would parse to 1111:2222:3333:4444:5555:6666:7777:8888 assuming IDNA-compliant parsing
    (
        "\u{AD}1\u{AD}111:2222︓\u{AD}3333:4444︓55\u{200B}\u{2064}55:₆6₆6:7777:8888\u{200B}",
        0x1111_2222_3333_4444_5555_6666_7777_8888,
        false
    ),
    /// Would parse to 2001:0DB8:85A3:F109:197A:8A2E:0370:7334 assuming IDNA-compliant parsing
    (
        "\u{200B}﹇₂₀\u{AD}\u{200B}₀₁︓\u{2064}₀ⒹⒷ₈︓₈₅Ⓐ₃\u{2064}︓Ⓕ₁₀₉︓₁₉₇Ⓐ︓₈Ⓐ₂Ⓔ︓₀₃₇₀︓₇₃₃₄﹈\u{2064}",
        0x2001_0DB8_85A3_F109_197A_8A2E_0370_7334,
        false
    ),
    ("\u{AD}", nil, false),
    ("\u{AD}\u{200B}\u{2064}", nil, false),
    ("[\u{AD}]", nil, false),
    ("[\u{AD}\u{200B}\u{2064}]", nil, false),
    /// We should support parsing these next 4 as valid if we were to support IDNA-compliant parsing,
    /// but we can skip them if necessary for performance.
    /// If you remove the IDNA-ignored unicode scalars, it becomes clear they are valid.
    ("[\u{AD}::]", 0x0000_0000_0000_0000_0000_0000_0000_0000, false),
    ("[::\u{AD}]", 0x0000_0000_0000_0000_0000_0000_0000_0000, false),
    ("[1:\u{AD}:1]", 0x0001_0000_0000_0000_0000_0000_0000_0001, false),
    ("[1:\u{AD}\u{200B}:1]", 0x0001_0000_0000_0000_0000_0000_0000_0001, false),
]

let anyIPAddressCIDRRelatedPropertiesTestCases:
    [(AnyIPAddress, String, (@Sendable (AnyIPAddress) -> Bool))] = [
        (.v4(IPv4Address(127, 0, 0, 0)), "isLoopback", \.isLoopback),
        (.v4(IPv4Address(127, 0, 0, 1)), "isLoopback", \.isLoopback),
        (.v4(IPv4Address(127, 128, 9, 22)), "isLoopback", \.isLoopback),
        (.v4(IPv4Address(127, 255, 255, 255)), "isLoopback", \.isLoopback),
        (.v4(IPv4Address(126, 0, 0, 0)), "!isLoopback", { @Sendable in !$0.isLoopback }),
        (.v4(IPv4Address(128, 0, 0, 0)), "!isLoopback", { @Sendable in !$0.isLoopback }),
        (.v4(IPv4Address(224, 0, 0, 0)), "isMulticast", \.isMulticast),
        (.v4(IPv4Address(239, 255, 255, 255)), "isMulticast", \.isMulticast),
        (.v4(IPv4Address(229, 28, 192, 233)), "isMulticast", \.isMulticast),
        (.v4(IPv4Address(244, 0, 0, 0)), "!isMulticast", { @Sendable in !$0.isMulticast }),

        (.v6(IPv6Address("::1")!), "isLoopback", \.isLoopback),
        (.v6(IPv6Address("::1:1")!), "!isLoopback", { @Sendable in !$0.isLoopback }),
        (.v6(IPv6Address("FF00::")!), "isMulticast", \.isMulticast),
        (.v6(IPv6Address("FF92::")!), "isMulticast", \.isMulticast),
        (.v6(IPv6Address("FFFF:998A::1")!), "isMulticast", \.isMulticast),
        (.v6(IPv6Address("FF::")!), "!isMulticast", { @Sendable in !$0.isMulticast }),
        (.v6(IPv6Address("00FF::")!), "!isMulticast", { @Sendable in !$0.isMulticast }),
        (.v6(IPv6Address("FAFF::")!), "!isMulticast", { @Sendable in !$0.isMulticast }),
    ]
