import Endpoint
import Testing

@Suite
struct ConnectionTargetTests {
    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: [(target: ConnectionTarget?, expected: ConnectionTarget.Target?)]([
            (
                target: try? .ipAddress("127.0.0.1", port: 11),
                expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 11)
            ),
            (
                target: .ipAddress(IPv4Address(127, 0, 0, 1), port: 22),
                expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 22)
            ),
            (
                target: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 33),
                expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 33)
            ),
            (
                target: try? .ipAddress("[::1]", port: 44),
                expected: .ipAddress(.v6(IPv6Address(0x1)), port: 44)
            ),
            (
                target: .ipAddress(IPv6Address(0x1), port: 55),
                expected: .ipAddress(.v6(IPv6Address(0x1)), port: 55)
            ),
            (
                target: .ipAddress(.v6(IPv6Address(0x1)), port: 66),
                expected: .ipAddress(.v6(IPv6Address(0x1)), port: 66)
            ),
            (
                target: try? .domainName(DomainName("www.example.com"), port: 77),
                expected: try? .domainName(DomainName("www.example.com"), port: 77)
            ),
            (
                target: try? .domainName(DomainName("127.0.0.1"), port: 88),
                expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 88)
            ),
            (
                target: try? .domainName(DomainName("::1"), port: 99),
                expected: nil
            ),
            (
                target: try? .domainName("www.example.com", port: 77),
                expected: try? .domainName(DomainName("www.example.com"), port: 77)
            ),
            (
                target: try? .domainName("127.0.0.1", port: 88),
                expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 88)
            ),
            (
                target: try? .domainName("::1", port: 99),
                expected: nil
            ),
            (
                target: .unixDomainSocketAddress("/tmp/socket"),
                expected: .unixDomainSocketAddress("/tmp/socket")
            ),
        ])
    )
    func `static funcs work as expected`(
        target: ConnectionTarget?,
        expected: ConnectionTarget.Target?
    ) throws {
        #expect(target?.target == expected)
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

    @Test func `Port works as expected`() {
        /// Use non-literal `Int`s so the `init(_ value: Int)` overload is exercised
        /// instead of `init(integerLiteral:)`.
        let low = 0
        let high = 65535
        #expect(Port(low) == Port(canonicalValue: 0))
        #expect(Port(high) == Port(canonicalValue: 65535))
        #expect(Port(low).value == 0)
        #expect(Port(high).value == 65535)
        #expect(Port(canonicalValue: 443).value == 443)
        #expect(Port(canonicalValue: 8080).description == "Port(8080)")
    }
}

#if os(macOS) || os(Linux)
extension ConnectionTargetTests {
    @Test func `Port initializer crashes when the value is out of bounds`() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Port(identity(-1)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Port(identity(65536)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Port(identity(Int.min)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Port(identity(Int.max)))
        }
    }
}
#endif
