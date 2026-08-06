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
#error("The IPv6AddressTests module was unable to identify your C library.")
#endif

@Suite
struct IPv6AddressTests {
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

    @Test func `IPv6Address serialize parse happy-path with span works correctly`() throws {
        let ip = IPv6Address(0x0102, 0xF3F4, 0x1516, 0x7080, 0x90A0, 0xCBBC, 0x0D0E, 0x0F11)

        let bufferPointer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 20)
        defer { unsafe bufferPointer.deallocate() }
        var outputSpan = unsafe OutputSpan(buffer: bufferPointer, initializedCount: 0)

        let didSerialize = ip.serialize(into: &outputSpan)

        #expect(didSerialize)
        #expect(outputSpan.capacity == 20)
        #expect(outputSpan.freeCapacity == 4)
        #expect(outputSpan.count == 16)
        let isFull = outputSpan.isFull
        #expect(!isFull)
        let isEmpty = outputSpan.isEmpty
        #expect(!isEmpty)
        outputSpan.span.withUnsafeBytes { ptr in
            let data = unsafe [UInt8](ptr)
            #expect(
                data == [
                    0x01, 0x02, 0xF3, 0xF4,
                    0x15, 0x16, 0x70, 0x80,
                    0x90, 0xA0, 0xCB, 0xBC,
                    0x0D, 0x0E, 0x0F, 0x11,
                ]
            )
        }

        let _parsedIP = IPv6Address(parsing: outputSpan.span)
        let parsedIP = try #require(_parsedIP)
        #expect(parsedIP == ip)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: 0..<16)
    func `IPv6Address span parsing and serialization reject spans that are too small`(count: Int) {
        let bytes = [UInt8](repeating: 0x1F, count: count)
        #expect(IPv6Address(parsing: bytes.span) == nil)

        let bufferPointer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: count)
        defer { unsafe bufferPointer.deallocate() }
        var outputSpan = unsafe OutputSpan(buffer: bufferPointer, initializedCount: 0)
        let didSerialize = IPv6Address(0x1).serialize(into: &outputSpan)
        #expect(!didSerialize)
    }

    @available(SwiftStdlib 6.0, *)
    @Test(arguments: IPv6AddressTestCase.stringAndAddress.compactMap(\.ip))
    func ipv6AddressDescription(
        ipv6: IPv6Address,
        _: String,
        expectedMixedNotationDescription: String
    ) {
        #expect(ipv6.description == "[\(expectedMixedNotationDescription)]")

        let produced = ipv6.withCString { span in
            #expect(span.count - 1 == expectedMixedNotationDescription.utf8.count)
            return span.withUnsafeBufferPointer { unsafe String(cString: $0.baseAddress!) }
        }
        #expect(produced == expectedMixedNotationDescription)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: IPv6AddressTestCase.stringAndAddress.compactMap({ $0.ip?.address }))
    func `IPv6Address description and serialization round-trip`(ip: IPv6Address) {
        #expect(IPv6Address(ip.description) == ip)

        let viaCString = ip.withCString { span in
            span.withUnsafeBufferPointer { unsafe IPv6Address(cString: $0.baseAddress!) }
        }
        #expect(viaCString == ip)

        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: IPv6Address.size)
        defer { unsafe buffer.deallocate() }
        var outputSpan = unsafe OutputSpan(buffer: buffer, initializedCount: 0)
        let didSerialize = ip.serialize(into: &outputSpan)
        #expect(didSerialize)
        #expect(IPv6Address(parsing: outputSpan.span) == ip)
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: IPv6AddressTestCase.stringAndAddress.filter { $0.ip != nil },
        IPv6Address.DescriptionOptions.allCombos
    )
    func `IPv6Address description honours every description-options combination`(
        testCase: IPv6AddressTestCase,
        options: IPv6Address.DescriptionOptions
    ) throws {
        let ip = try #require(testCase.ip?.address)
        let expected = try #require(testCase.expectedDescription(options: options))
        #expect(ip.description(options: options) == expected)
        #expect(IPv6Address(expected) == ip)
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: IPv6AddressTestCase.stringAndAddress.filter { $0.ip != nil },
        IPv6Address.DescriptionOptions.allCombos
    )
    func `IPv6Address withCString honours every description-options combination`(
        testCase: IPv6AddressTestCase,
        options: IPv6Address.DescriptionOptions
    ) throws {
        let ip = try #require(testCase.ip?.address)
        let expected = try #require(testCase.expectedDescription(options: options))
        let produced = ip.withCString(options: options) { span in
            #expect(span.count == expected.utf8.count + 1)
            #expect(span[span.count - 1] == 0)
            return span.withUnsafeBufferPointer { unsafe String(cString: $0.baseAddress!) }
        }
        #expect(produced == expected)

        let reparsed = ip.withCString(options: options) { span in
            span.withUnsafeBufferPointer { unsafe IPv6Address(cString: $0.baseAddress!) }
        }
        #expect(reparsed == ip)
    }

    @available(SwiftStdlib 6.0, *)
    @Test(arguments: IPv6AddressTestCase.stringAndAddress.filter { $0.ip != nil })
    func `IPv6Address description and withCString defaults`(
        testCase: IPv6AddressTestCase
    ) throws {
        let mixedNotationDescription = try #require(testCase.ip?.mixedNotationDescription)
        let ip = try #require(testCase.ip?.address)
        #expect(ip.description == ip.description(options: .standardOptions))
        #expect(ip.description == "[\(mixedNotationDescription)]")

        let cStringDefault = ip.withCString { span in
            span.withUnsafeBufferPointer { unsafe String(cString: $0.baseAddress!) }
        }
        let cStringExplicit = ip.withCString(options: [.useMixedNotation]) { span in
            span.withUnsafeBufferPointer { unsafe String(cString: $0.baseAddress!) }
        }
        #expect(cStringDefault == cStringExplicit)
        #expect(cStringDefault == mixedNotationDescription)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: IPv6AddressTestCase.stringAndAddress
            + IPv6AddressTestCase.idnaStringAndAddress.map {
                IPv6AddressTestCase(
                    $0.string,
                    ip: nil,
                    isValidAsOtherIPVersion: $0.isValidAsOtherIPVersion
                )
            }
    )
    func ipv6AddressFromString(testCase: IPv6AddressTestCase) {
        let string = testCase.string
        let expectedAddress = testCase.ip?.address
        let isValidIPv4 = testCase.isValidAsOtherIPVersion

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
            #expect(unsafe IPv6Address(cString: cString) == expectedAddress)
            if isValidIPv4 {
                #expect(unsafe AnyIPAddress(cString: cString)?.isIPv4 == true)
            } else {
                #expect(unsafe AnyIPAddress(cString: cString) == expectedAddress.map { .v6($0) })
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
            ),
            (
                try! DomainName(
                    "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6"
                ),
                nil
            ),
            (
                try! DomainName(
                    "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.arpa"
                ),
                nil
            ),
            (
                try! DomainName(
                    "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpe"
                ),
                nil
            ),
            (
                try! DomainName(
                    "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ipx.arpa"
                ),
                nil
            ),
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
    @Test(arguments: IPv6AddressTestCase.stringAndAddress)
    func ipv6AddressFromStringThroughArpaDomainName(testCase: IPv6AddressTestCase) {
        let string = testCase.string
        let expectedAddress = testCase.ip?.address
        let isValidIPv4 = testCase.isValidAsOtherIPVersion

        let plainIPv6Address = IPv6Address(string)
        let arpa: String? = plainIPv6Address.map(\.arpaDomainNameString)
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

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPv4DecimalLengthTestCase.all)
    func ipv6AddressFromIPv4Address(testCase: IPv4DecimalLengthTestCase) {
        let mapped = testCase.address.asIPv4MappedIPv6
        let nat64 = testCase.address.asNAT64WellKnownIPv4EmbeddedIPv6

        #expect(mapped == IPv6Address(testCase.ipv4MappedExpandedIPv6Description))
        #expect(nat64 == IPv6Address(testCase.nat64ExpandedIPv6Description))
        #expect(mapped.isIPv4Mapped)
        #expect(nat64.isNAT64WellKnownIPv4Embedded)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: IPPropertyTestCase<IPv6Address>.all)
    func ipv6AddressPropertiesWorkCorrectly(testCase: IPPropertyTestCase<IPv6Address>) throws {
        #expect(testCase.predicate(testCase.ip), "\(testCase.testCaseDescription)")
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: IPv6AddressTestCase.stringAndAddress.filter { $0.ip != nil },
        IPv6Address.DescriptionOptions.allCombos
    )
    func `IPv6Address cString APIs compatibility with C`(
        testCase: IPv6AddressTestCase,
        options: IPv6Address.DescriptionOptions
    ) throws {
        let ip = try #require(testCase.ip?.address)
        let bytes = ip.bytes
        let expectedBytes = [
            bytes.0, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5, bytes.6, bytes.7,
            bytes.8, bytes.9, bytes.10, bytes.11, bytes.12, bytes.13, bytes.14, bytes.15,
        ]

        var in6Address = in6_addr()
        let pton = ip.withCString(options: options) { span in
            span.withUnsafeBufferPointer {
                unsafe inet_pton(AF_INET6, $0.baseAddress!, &in6Address)
            }
        }
        if options.contains(.encloseInSquareBrackets) {
            #expect(pton == 0)
            return
        }

        #expect(pton == 1)
        #expect(withUnsafeBytes(of: in6Address) { unsafe Array($0) } == expectedBytes)

        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        let ntop = unsafe inet_ntop(AF_INET6, &in6Address, &buffer, socklen_t(INET6_ADDRSTRLEN))
        #expect(unsafe ntop != nil)
        #expect(unsafe IPv6Address(cString: buffer) == ip)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: AnyIPAddressTestCase.rawByteReject)
    func `Non-ASCII byte inputs are rejected by the parser`(bytes: [UInt8]) {
        #expect(IPv6Address(textualRepresentation: bytes.span) == nil)
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: Array(0..<256))
    func `IPv6Address segments table contains correct values`(index: Int) {
        let (lowerBound, upperBound) = compressionRangeTable[index]
        var indices = [0, 1, 2, 3, 4, 5, 6, 7]
        var compressionSignIdx = 16
        var writeCsAtBeginning = false
        var writeCsAtEnd = false
        if upperBound != 16 {
            indices.removeSubrange(lowerBound...upperBound)
            if upperBound == 7 {
                writeCsAtEnd = true
                compressionSignIdx = 15
            } else if lowerBound == 0 {
                writeCsAtBeginning = true
                compressionSignIdx = upperBound &+ 1
            } else {
                compressionSignIdx = upperBound &+ 1
            }
        }
        var packedIndices: UInt64 = 0
        for (offset, idx) in indices.enumerated() {
            packedIndices |= UInt64(idx) &<< (offset * 3)
        }
        let segmentsCount = UInt64(exactly: indices.count)!
        let colonsCount: UInt64 = max(2, min(segmentsCount + 1, 7))
        let minRawLayoutBytes = UInt64(exactly: colonsCount + segmentsCount)!
        var rawValue = packedIndices
        rawValue |= segmentsCount &<< 24
        rawValue |= minRawLayoutBytes &<< 32
        rawValue |= UInt64(exactly: compressionSignIdx)! &<< 40
        rawValue |= (writeCsAtBeginning ? 1 : 0) &<< 48
        rawValue |= (writeCsAtEnd ? 1 : 0) &<< 49
        let entry = IPv6Address.SegmentWriteTableEntry(rawValue)

        #expect(IPv6Address._segmentWriteTable[index] == entry)

        let unpacked = IPv6Address.entry(forMask: UInt8(index))
        #expect(unpacked == entry.unpack())
        #expect(unpacked.packedIndices == UInt(packedIndices))
        #expect(unpacked.segmentsCount == indices.count)
        #expect(unpacked.minRawLayoutBytes == Int(minRawLayoutBytes))
        #expect(unpacked.writeCsAtIdx == compressionSignIdx)
        #expect(unpacked.writeCsAtBeginning == writeCsAtBeginning)
        #expect(unpacked.writeCsAtEnd == writeCsAtEnd)
    }
}

// 16 means no compression sign.
// Each Element is a pair of (lowerBound, upperBound) of range of segments that should be compressed.
// Each index of each element is the bitmap of the segments that are all-zero (1) or not (0).
// For example the element at index 0b0011_1000 is `(3, 5)`, meaning segments 3, 4, 5 should be compressed.
private let compressionRangeTable: [(Int, Int)] = {
    var table = [(Int, Int)]()
    table.reserveCapacity(256)

    for index in 0..<256 {
        let mask = UInt8(index)

        var bestStart = -1
        var bestLength = 0
        var segment = 0
        while segment < 8 {
            if (mask >> segment) & 1 == 1 {
                var runEnd = segment
                while runEnd < 8 && (mask >> runEnd) & 1 == 1 {
                    runEnd += 1
                }
                let length = runEnd - segment
                if length > bestLength {
                    bestLength = length
                    bestStart = segment
                }
                segment = runEnd
            }
            segment += 1
        }

        let expected: (Int, Int)
        if bestLength >= 2 {
            expected = (bestStart, bestStart + bestLength - 1)
        } else {
            expected = (16, 16)
        }
        table.append(expected)
    }

    return table
}()
