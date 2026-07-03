import Endpoint
import Testing

@Suite
struct AnyIPAddressTests {
    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: IPTestCase<AnyIPAddress>.stringAndAddress.compactMap(\.descriptionTestCase)
            + IPTestCase<IPv4Address>.stringAndAddress
            .compactMap(\.asAnyIPAddress).compactMap(\.descriptionTestCase)
            + IPTestCase<IPv6Address>.stringAndAddress
            .compactMap(\.asAnyIPAddress).compactMap(\.descriptionTestCase)
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
        arguments: IPTestCase<IPv4Address>.stringAndAddress.compactMap(\.address).map(
            AnyIPAddress.v4
        )
            + IPTestCase<IPv6Address>.stringAndAddress.compactMap(\.address).map(AnyIPAddress.v6)
    )
    func `AnyIPAddress description round-trip`(ip: AnyIPAddress) {
        #expect(AnyIPAddress(ip.description) == ip)

        let viaCString = ip.withCString { span in
            span.withUnsafeBufferPointer { AnyIPAddress(cString: $0.baseAddress!) }
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
        let expectedAddress = testCase.address

        #expect(AnyIPAddress(string) == expectedAddress)

        string.withCString { #expect(AnyIPAddress(cString: $0) == expectedAddress) }
    }

    @available(SwiftStdlib 5.1, *)
    @Test(arguments: IPPropertyTestCase<AnyIPAddress>.all)
    func `AnyIPAddress CIDR-related properties work correctly`(
        testCase: IPPropertyTestCase<AnyIPAddress>
    ) throws {
        #expect(testCase.predicate(testCase.ip), "\(testCase.testCaseDescription)")
    }
}
