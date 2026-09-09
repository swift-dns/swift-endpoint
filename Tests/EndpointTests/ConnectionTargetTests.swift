import Endpoint
import Testing

@Suite
struct ConnectionTargetTests {
    @available(SwiftStdlib 6.0, *)
    @Test(arguments: ConnectionTargetTestCase.targetAndExpectedTarget)
    func `static funcs work as expected`(testCase: ConnectionTargetTestCase) throws {
        #expect(testCase.target?.target == testCase.expected)
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: [(target: ConnectionTarget, expected: String)]([
            (
                target: .ipAddress(IPv4Address(192, 168, 1, 1), port: 123),
                expected: "192.168.1.1:123"
            ),
            (
                target: .ipAddress(IPv6Address(0x1), port: 324),
                expected: "[::1]:324"
            ),
            (
                target: try! .domainName("www.example.com", port: 443),
                expected: "www.example.com:443"
            ),
            (
                target: .unixDomainSocketAddress("/var/run/docker.sock"),
                expected: "/var/run/docker.sock"
            ),
        ])
    )
    func `description works as expected`(target: ConnectionTarget, expected: String) throws {
        #expect(target.description == expected)
        #expect(target.description == target.target.description)
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `invalid inputs throw errors with descriptive messages`() throws {
        #expect(throws: ConnectionTarget.Error.self) {
            try ConnectionTarget.ipAddress("256.0.0.1", port: 80)
        }

        #expect(throws: ConnectionTarget.Error.self) {
            try ConnectionTarget.domainName(".invalid.example.com", port: 443)
        }
    }
}
