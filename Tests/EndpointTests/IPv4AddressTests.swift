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
        #expect(ip.address == 0x7F00_0001)
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

    @Test(arguments: IPTestCase<IPv4Address>.stringAndAddress.compactMap(\.ip))
    func ipv4AddressDescription(ip: IPv4Address, expectedDescription: String) {
        #expect(ip.description == expectedDescription)

        let produced = ip.withCString { span in
            #expect(span.count == expectedDescription.utf8.count + 1)
            return span.withUnsafeBufferPointer { unsafe String(cString: $0.baseAddress!) }
        }
        #expect(produced == expectedDescription)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: IPTestCase<IPv4Address>.stringAndAddress.compactMap({ $0.ip?.address }))
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
        arguments: IPTestCase<IPv4Address>.stringAndAddress
            + IPTestCase<IPv4Address>.idnaStringAndAddress.map {
                IPTestCase<IPv4Address>(
                    $0.string,
                    ip: nil,
                    isValidAsOtherIPVersion: $0.isValidAsOtherIPVersion
                )
            }
    )
    func ipv4AddressFromString(testCase: IPTestCase<IPv4Address>) {
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
        arguments: IPTestCase<IPv4Address>.stringAndAddress
            + IPTestCase<IPv4Address>.idnaStringAndAddress
    )
    func ipv4AddressFromStringThroughDomainName(testCase: IPTestCase<IPv4Address>) {
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
    @Test(arguments: IPTestCase<IPv4Address>.stringAndAddress)
    func ipv4AddressFromStringThroughArpaDomainName(testCase: IPTestCase<IPv4Address>) {
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
    @Test(arguments: IPv4MappedIPv6TestCase.all)
    func ipv4AddressFromIpv6Address(testCase: IPv4MappedIPv6TestCase) throws {
        let ipv6 = try #require(IPv6Address(testCase.ipv6String))
        #expect(testCase.ipv4 == IPv4Address(ipv6: ipv6))
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPPropertyTestCase<IPv4Address>.all)
    func ipv4AddressPropertiesWorkCorrectly(testCase: IPPropertyTestCase<IPv4Address>) throws {
        #expect(testCase.predicate(testCase.ip), "\(testCase.testCaseDescription)")
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPTestCase<IPv4Address>.stringAndAddress.compactMap({ $0.ip?.address }))
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

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: IPTestCase<AnyIPAddress>.rawByteReject)
    func `Non-ASCII byte inputs are rejected by the parser`(bytes: [UInt8]) {
        let span = bytes.span
        #expect(IPv4Address(textualRepresentation: span) == nil)
    }
}
