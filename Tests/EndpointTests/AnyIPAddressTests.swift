import Endpoint
import Testing

@Suite
struct AnyIPAddressTests {
    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: IPTestCase<AnyIPAddress>.stringAndAddress.compactMap(\.ip)
            + IPTestCase<IPv4Address>.stringAndAddress
            .compactMap(\.asAnyIPAddress?.ip)
            + IPTestCase<IPv6Address>.stringAndAddress
            .compactMap(\.asAnyIPAddress?.ip)
    )
    func `AnyIPAddress description`(ip: AnyIPAddress, expectedDescription: String) {
        #expect(ip.description == expectedDescription)

        let droppedFirstLast = String(expectedDescription.dropFirst().dropLast())
        let bracketLess = ip.isIPv6 ? droppedFirstLast : expectedDescription
        let produced = ip.withCString { span in
            span.withUnsafeBufferPointer { unsafe String(cString: $0.baseAddress!) }
        }
        #expect(produced == bracketLess)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: IPTestCase<IPv4Address>.stringAndAddress
            .compactMap(\.ip?.address).map(AnyIPAddress.v4)
            + IPTestCase<IPv6Address>.stringAndAddress
            .compactMap(\.ip?.address).map(AnyIPAddress.v6)
    )
    func `AnyIPAddress description round-trip`(ip: AnyIPAddress) {
        #expect(AnyIPAddress(ip.description) == ip)

        let viaCString = ip.withCString { span in
            span.withUnsafeBufferPointer { unsafe AnyIPAddress(cString: $0.baseAddress!) }
        }
        #expect(viaCString == ip)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: IPTestCase<AnyIPAddress>.stringAndAddress
            + IPTestCase<IPv4Address>.stringAndAddress.compactMap(\.asAnyIPAddress)
            + IPTestCase<IPv6Address>.stringAndAddress.compactMap(\.asAnyIPAddress)
    )
    func `AnyIPAddress from string`(testCase: IPTestCase<AnyIPAddress>) {
        let string = testCase.string
        let expectedAddress = testCase.ip?.address

        #expect(AnyIPAddress(string) == expectedAddress)

        string.withCString { #expect(unsafe AnyIPAddress(cString: $0) == expectedAddress) }
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPPropertyTestCase<AnyIPAddress>.all)
    func `AnyIPAddress CIDR-related properties work correctly`(
        testCase: IPPropertyTestCase<AnyIPAddress>
    ) throws {
        #expect(testCase.predicate(testCase.ip), "\(testCase.testCaseDescription)")
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: IPTestCase<IPv4Address>.stringAndAddress
            .compactMap(\.ip?.address).map(AnyIPAddress.v4)
            + IPTestCase<IPv6Address>.stringAndAddress
            .compactMap(\.ip?.address).map(AnyIPAddress.v6)
    )
    func `AnyIPAddress version accessors work correctly`(ip: AnyIPAddress) {
        switch ip {
        case .v4(let ipv4):
            #expect(ip.ipv4Value == ipv4)
            #expect(ip.ipv6Value == nil)
            #expect(ip.isIPv4)
            #expect(!ip.isIPv6)
            #expect(IPv4Address(exactly: ip) == ipv4)
            #expect(IPv6Address(exactly: ip) == nil)
        case .v6(let ipv6):
            #expect(ip.ipv6Value == ipv6)
            #expect(ip.ipv4Value == nil)
            #expect(ip.isIPv6)
            #expect(!ip.isIPv4)
            #expect(IPv6Address(exactly: ip) == ipv6)
            #expect(IPv4Address(exactly: ip) == nil)
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: IPTestCase<IPv4Address>.stringAndAddress.compactMap(\.ip?.address))
    func `AnyIPAddress from v4 arpa domain name`(ipv4: IPv4Address) throws {
        let domainName = try DomainName(ipv4.arpaDomainNameString)
        #expect(AnyIPAddress(arpaDomainName: domainName) == .v4(ipv4))
        #expect(AnyIPAddress(domainName: domainName) == .v4(ipv4))
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: IPTestCase<IPv6Address>.stringAndAddress.compactMap(\.ip?.address))
    func `AnyIPAddress from v6 arpa domain name`(ipv6: IPv6Address) throws {
        let domainName = try DomainName(ipv6.arpaDomainNameString)
        #expect(AnyIPAddress(arpaDomainName: domainName) == .v6(ipv6))
        #expect(AnyIPAddress(domainName: domainName) == .v6(ipv6))
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: [
            "1.2.3",
            "1.2.3.4",
            "b.a.9.8",
            "in-addr.arpa",
            "ip6.arpa",
            "4.3.2.1.in-addr.arpe",
            "4.3.2.1.xn-addr.arpa",
            "5.4.3.2.1.in-addr.arpa",
            "256.3.2.1.in-addr.arpa",
            "a.b.c.d.in-addr.arpa",
            "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6",
            "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.arpa",
            "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpe",
            "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ipx.arpa",
            "g.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa",
            "a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa",
            "c.b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa",
            "ab.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa",
        ]
    )
    func `AnyIPAddress from invalid arpa domain name is nil`(
        domainName: String
    ) throws {
        let domainName = try DomainName(domainName)
        #expect(AnyIPAddress(arpaDomainName: domainName) == nil)
    }
}
