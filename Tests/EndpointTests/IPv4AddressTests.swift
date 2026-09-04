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
#error("The IPv4AddressTests module was unable to identify your C library.")
#endif

@Suite
struct IPv4AddressTests {
    @Test func ipv4Address() {
        let ip = IPv4Address(127, 0, 0, 1)
        #expect(ip.asUInt32() == 0x7F00_0001)
        #expect(ip.bytes == (0x7F, 0x00, 0x00, 0x01))
    }

    @Test func `IPv4Address serialize parse happy-path with span works correctly`() throws {
        let ip = IPv4Address(123, 251, 98, 234)

        let bufferPointer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 20)
        defer { unsafe bufferPointer.deallocate() }
        var outputSpan = unsafe OutputSpan(buffer: bufferPointer, initializedCount: 0)

        let didSerialize = ip.serialize(into: &outputSpan)

        #expect(didSerialize)
        #expect(outputSpan.capacity == 20)
        #expect(outputSpan.freeCapacity == 16)
        #expect(outputSpan.count == 4)
        let isFull = outputSpan.isFull
        #expect(!isFull)
        let isEmpty = outputSpan.isEmpty
        #expect(!isEmpty)
        outputSpan.span.withUnsafeBytes { ptr in
            let data = unsafe [UInt8](ptr)
            #expect(data == [123, 251, 98, 234])
        }

        let _parsedIP = IPv4Address(parsing: outputSpan.span)
        let parsedIP = try #require(_parsedIP)
        #expect(parsedIP == ip)
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `IPv4Address span parsing and serialization reject spans that are too small`() {
        let bytes: [UInt8] = [123, 251, 98]
        #expect(IPv4Address(parsing: bytes.span) == nil)

        let bufferPointer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 3)
        defer { unsafe bufferPointer.deallocate() }
        var outputSpan = unsafe OutputSpan(buffer: bufferPointer, initializedCount: 0)
        let didSerialize = IPv4Address(123, 251, 98, 234).serialize(into: &outputSpan)
        #expect(!didSerialize)
    }

    @Test(arguments: IPv4AddressTestCase.stringAndAddress.compactMap(\.ip))
    func ipv4AddressDescription(ip: IPv4Address, expectedDescription: String) {
        #expect(ip.description == expectedDescription)

        let produced = ip.withCString { span in
            #expect(span.count == expectedDescription.utf8.count + 1)
            return span.withUnsafeBufferPointer { unsafe String(cString: $0.baseAddress!) }
        }
        #expect(produced == expectedDescription)
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPv4DecimalLengthTestCase.all.map(\.address))
    func `IPv4Address from IPv4-embedded IPv6 addresses`(ipv4: IPv4Address) {
        #expect(IPv4Address(ipv6: ipv4.asIPv4MappedIPv6) == ipv4)
        #expect(IPv4Address(ipv6: ipv4.asNAT64WellKnownIPv4EmbeddedIPv6) == ipv4)

        let deprecatedIPv4Compatible = IPv6Address(
            UnsignedInteger128(_low: UInt64(ipv4.asUInt32()), _high: 0x0000_0000_0000_0000)
        )
        #expect(IPv4Address(ipv6: deprecatedIPv4Compatible) == nil)
        #expect(!deprecatedIPv4Compatible.isWellKnownIPv4Embedded)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: IPv4DecimalLengthTestCase.all)
    func `IPv4Address exhaustive byte-length cases`(testCase: IPv4DecimalLengthTestCase) throws {
        let ip = testCase.address
        #expect(IPv4Address(testCase.string) == ip)
        #expect(IPv4Address(Substring(testCase.string)) == ip)
        #expect(IPv4Address(textualRepresentation: testCase.string.utf8Span) == ip)
        #expect(IPv4Address(textualRepresentation: testCase.string.utf8Span.span) == ip)
        testCase.string.withCString { #expect(unsafe IPv4Address(cString: $0) == ip) }

        #expect(ip.description == testCase.description)
        let produced = ip.withCString { span in
            #expect(span.count == testCase.description.utf8.count + 1)
            return span.withUnsafeBufferPointer { unsafe String(cString: $0.baseAddress!) }
        }
        #expect(produced == testCase.description)
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPv4DecimalLengthTestCase.all)
    func `IPv4Address textual representation length and write capacity byte-length cases`(
        testCase: IPv4DecimalLengthTestCase
    ) {
        testTextualRepresentationLengths(of: testCase.address)
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `IPv4Address textual representation length and write capacity`() {
        /// Every value of every byte, against every digit count of the neighbouring bytes.
        for position in 0..<4 {
            for value in 0...UInt32(255) {
                for other in [UInt32]([0, 0x0909_0909, 0x6363_6363, 0xFFFF_FFFF]) {
                    let shift = UInt32(24 - position * 8)
                    let address = (other & ~(0xFF << shift)) | (value << shift)
                    testTextualRepresentationLengths(of: IPv4Address(address))
                }
            }
        }

        /// Every combination of the two low bytes, and of the two high bytes.
        for value in 0...UInt32(0xFFFF) {
            testTextualRepresentationLengths(of: IPv4Address(value))
            testTextualRepresentationLengths(of: IPv4Address(value << 16))
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: IPv4AddressTestCase.stringAndAddress.compactMap({ $0.ip?.address }))
    func `IPv4Address description and serialization round-trip`(ip: IPv4Address) {
        #expect(IPv4Address(ip.description) == ip)

        let viaCString = ip.withCString { span in
            span.withUnsafeBufferPointer { unsafe IPv4Address(cString: $0.baseAddress!) }
        }
        #expect(viaCString == ip)

        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: IPv4Address.size)
        defer { unsafe buffer.deallocate() }
        var outputSpan = unsafe OutputSpan(buffer: buffer, initializedCount: 0)
        let didSerialize = ip.serialize(into: &outputSpan)
        #expect(didSerialize)
        #expect(IPv4Address(parsing: outputSpan.span) == ip)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: IPv4AddressTestCase.stringAndAddress
            + IPv4AddressTestCase.idnaStringAndAddress.map {
                IPv4AddressTestCase(
                    $0.string,
                    ip: nil,
                    isValidAsOtherIPVersion: $0.isValidAsOtherIPVersion
                )
            }
    )
    func ipv4AddressFromString(testCase: IPv4AddressTestCase) {
        let string = testCase.string
        let expectedAddress = testCase.ip?.address
        let isValidIPv6 = testCase.isValidAsOtherIPVersion

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
            #expect(unsafe IPv4Address(cString: cString) == expectedAddress)
            if isValidIPv6 {
                #expect(unsafe AnyIPAddress(cString: cString)?.isIPv6 == true)
            } else {
                #expect(unsafe AnyIPAddress(cString: cString) == expectedAddress.map { .v4($0) })
            }
        }
    }

    @Test func ipv4AddressFromStringAcrossBytes() {
        let bytes: [UInt8] = [0, 1, 9, 10, 99, 100, 127, 128, 129, 199, 200, 249, 250, 255]
        for byte1 in bytes {
            for byte2 in bytes {
                for byte3 in bytes {
                    for byte4 in bytes {
                        let string = "\(byte1).\(byte2).\(byte3).\(byte4)"
                        let expected = IPv4Address(byte1, byte2, byte3, byte4)
                        guard IPv4Address(string) == expected else {
                            Issue.record("Mismatch for \(string.debugDescription)")
                            return
                        }
                    }
                }
            }
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: IPv4AddressTestCase.stringAndAddress
            + IPv4AddressTestCase.idnaStringAndAddress
    )
    func ipv4AddressFromStringThroughDomainName(testCase: IPv4AddressTestCase) {
        let string = testCase.string
        let expectedAddress = testCase.ip?.address
        let isValidIPv6 = testCase.isValidAsOtherIPVersion

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
    @Test(arguments: IPv4AddressTestCase.stringAndAddress)
    func ipv4AddressFromStringThroughArpaDomainName(testCase: IPv4AddressTestCase) {
        let string = testCase.string
        let expectedAddress = testCase.ip?.address
        let isValidIPv6 = testCase.isValidAsOtherIPVersion

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
        arguments: [
            (domainName: String, viaDomainName: IPv4Address?, viaArpaDomainName: IPv4Address?)
        ]([
            (
                domainName: "4.3.2.1.in-addr.arpa",
                viaDomainName: IPv4Address(1, 2, 3, 4),
                viaArpaDomainName: IPv4Address(1, 2, 3, 4)
            ),
            (
                domainName: "004.003.002.001.in-addr.arpa",
                viaDomainName: IPv4Address(1, 2, 3, 4),
                viaArpaDomainName: IPv4Address(1, 2, 3, 4)
            ),
            (
                domainName: "001.002.003.004",
                viaDomainName: IPv4Address(1, 2, 3, 4),
                viaArpaDomainName: nil
            ),
            /// A fourth digit is rejected even when the padding digits are all zeros.
            (domainName: "0004.3.2.1.in-addr.arpa", viaDomainName: nil, viaArpaDomainName: nil),
            (domainName: "4.3.2.0001.in-addr.arpa", viaDomainName: nil, viaArpaDomainName: nil),
            (domainName: "0001.0002.0003.0004", viaDomainName: nil, viaArpaDomainName: nil),
            (domainName: "4.3.2.1.in-addr.arpe", viaDomainName: nil, viaArpaDomainName: nil),
            (domainName: "4.3.2.1.xn-addr.arpa", viaDomainName: nil, viaArpaDomainName: nil),
            (domainName: "1.2.3", viaDomainName: nil, viaArpaDomainName: nil),
            (
                domainName: "1.2.3.4",
                viaDomainName: IPv4Address(1, 2, 3, 4),
                viaArpaDomainName: nil
            ),
        ])
    )
    func ipv4AddressFromArpaDomainNameHardcodedCases(
        domainName: String,
        viaDomainName: IPv4Address?,
        viaArpaDomainName: IPv4Address?
    ) throws {
        let domainName = try DomainName(domainName)
        #expect(IPv4Address(domainName: domainName) == viaDomainName)
        #expect(IPv4Address(arpaDomainName: domainName) == viaArpaDomainName)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: IPv6AddressTestCase.nonIPv4EmbeddedStrings)
    func ipv4AddressFromNonIPv4EmbeddedIPv6Address(ipv6String: String) throws {
        let ipv6 = try #require(IPv6Address(ipv6String))
        #expect(IPv4Address(ipv6: ipv6) == nil)
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPPropertyTestCase<IPv4Address>.all)
    func ipv4AddressPropertiesWorkCorrectly(testCase: IPPropertyTestCase<IPv4Address>) throws {
        #expect(testCase.predicate(testCase.ip), "\(testCase.testCaseDescription)")
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPv4AddressTestCase.stringAndAddress.compactMap({ $0.ip?.address }))
    func `IPv4Address cString APIs compatibility with C`(ip: IPv4Address) {
        let expectedBytes = [ip.bytes.0, ip.bytes.1, ip.bytes.2, ip.bytes.3]

        var inAddress = in_addr()
        let pton = ip.withCString { span in
            span.withUnsafeBufferPointer { unsafe inet_pton(AF_INET, $0.baseAddress!, &inAddress) }
        }
        #expect(pton == 1)
        #expect(withUnsafeBytes(of: inAddress) { unsafe Array($0) } == expectedBytes)

        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        let ntop = unsafe inet_ntop(AF_INET, &inAddress, &buffer, socklen_t(INET_ADDRSTRLEN))
        #expect(unsafe ntop != nil)
        #expect(unsafe IPv4Address(cString: buffer) == ip)
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPv4DecimalLengthTestCase.all)
    func `IPv4Address cString APIs compatibility with C in byte-length test cases`(
        testCase: IPv4DecimalLengthTestCase
    ) {
        let ip = testCase.address
        let expectedBytes = [ip.bytes.0, ip.bytes.1, ip.bytes.2, ip.bytes.3]

        var inAddress = in_addr()
        let pton = ip.withCString { span in
            span.withUnsafeBufferPointer { unsafe inet_pton(AF_INET, $0.baseAddress!, &inAddress) }
        }
        #expect(pton == 1)
        #expect(withUnsafeBytes(of: inAddress) { unsafe Array($0) } == expectedBytes)

        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        let ntop = unsafe inet_ntop(AF_INET, &inAddress, &buffer, socklen_t(INET_ADDRSTRLEN))
        #expect(unsafe ntop != nil)
        #expect(unsafe IPv4Address(cString: buffer) == ip)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: AnyIPAddressTestCase.rawByteReject)
    func `Non-ASCII byte inputs are rejected by the parser`(bytes: [UInt8]) {
        let span = bytes.span
        #expect(IPv4Address(textualRepresentation: span) == nil)
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `IPv4Address parses StaticString exactly like String`() {
        #expect(("0.0.0.0" as IPv4Address) == IPv4Address("0.0.0.0" as String))
        #expect(("127.0.0.1" as IPv4Address) == IPv4Address("127.0.0.1" as String))
        #expect(
            ("192.168.1.98" as IPv4Address) == IPv4Address("192.168.1.98" as String)
        )
        #expect(
            ("255.255.255.255" as IPv4Address)
                == IPv4Address("255.255.255.255" as String)
        )
        #expect(
            ("010.010.010.010" as IPv4Address)
                == IPv4Address("010.010.010.010" as String)
        )

        #expect(("192.168.1.98" as IPv4Address) == IPv4Address(192, 168, 1, 98))
        #expect(("255.255.255.255" as IPv4Address) == IPv4Address(255, 255, 255, 255))
    }

    /// A bare string literal must reach the `ExpressibleByStringLiteral` init, not the `String` one.
    @available(SwiftStdlib 5.1, *)
    @Test func `IPv4Address parses string literals`() {
        let zeros: IPv4Address = "0.0.0.0"
        #expect(zeros == IPv4Address(0, 0, 0, 0))

        let privateIP: IPv4Address = "192.168.1.98"
        #expect(privateIP == IPv4Address(192, 168, 1, 98))
    }

}

@available(SwiftStdlib 5.1, *)
private func testTextualRepresentationLengths(
    of ip: IPv4Address,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    let description = ip.description
    let length = description.utf8.count
    let lastByteDigits = String(ip.bytes.3).utf8.count

    #expect(ip.textualRepresentationLength == length, sourceLocation: sourceLocation)
    /// `_textualRepresentationWriteRequiredCapacity` includes possible extra 2 bytes of
    /// headroom for speculative writes.
    #expect(
        ip._textualRepresentationWriteRequiredCapacity == length + 3 - lastByteDigits,
        sourceLocation: sourceLocation
    )

    let capacity = ip._textualRepresentationWriteRequiredCapacity
    let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: capacity, alignment: 1)
    defer { unsafe buffer.deallocate() }
    let written = unsafe ip.writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
    #expect(written == length, sourceLocation: sourceLocation)
    let produced = unsafe String(decoding: buffer[0..<written], as: UTF8.self)
    #expect(produced == description, sourceLocation: sourceLocation)
}

#if os(macOS) || os(Linux)
extension IPv4AddressTests {
    /// Kept to three literals: each one is unrolled and constant-folded at compile time.
    @available(SwiftStdlib 5.1, *)
    @Test func `IPv4Address initializer crashes on an invalid StaticString`() async {
        await #expect(processExitsWith: .failure) {
            blackHole("" as IPv4Address)
        }
        await #expect(processExitsWith: .failure) {
            blackHole("1.2.3" as IPv4Address)
        }
        await #expect(processExitsWith: .failure) {
            blackHole("192.168.1.256" as IPv4Address)
        }
    }
}
#endif
