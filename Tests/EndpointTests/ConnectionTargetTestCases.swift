import Endpoint

struct ConnectionTargetTestCase: Sendable {
    let target: ConnectionTarget?
    let expected: ConnectionTarget.Target?

    init(target: ConnectionTarget?, expected: ConnectionTarget.Target?) {
        self.target = target
        self.expected = expected
    }
}

extension ConnectionTargetTestCase {
    @available(SwiftStdlib 6.0, *)
    static let targetAndExpectedTarget: [Self] = [
        ConnectionTargetTestCase(
            target: try? .ipAddress("127.0.0.1", port: 11),
            expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 11)
        ),
        ConnectionTargetTestCase(
            target: .ipAddress(IPv4Address(127, 0, 0, 1), port: 22),
            expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 22)
        ),
        ConnectionTargetTestCase(
            target: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 33),
            expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 33)
        ),
        ConnectionTargetTestCase(
            target: try? .ipAddress("[::1]", port: 44),
            expected: .ipAddress(.v6(IPv6Address(0x1)), port: 44)
        ),
        ConnectionTargetTestCase(
            target: .ipAddress(IPv6Address(0x1), port: 55),
            expected: .ipAddress(.v6(IPv6Address(0x1)), port: 55)
        ),
        ConnectionTargetTestCase(
            target: .ipAddress(.v6(IPv6Address(0x1)), port: 66),
            expected: .ipAddress(.v6(IPv6Address(0x1)), port: 66)
        ),
        ConnectionTargetTestCase(
            target: try? .domainName(DomainName("www.example.com"), port: 77),
            expected: try? .domainName(DomainName("www.example.com"), port: 77)
        ),
        ConnectionTargetTestCase(
            target: try? .domainName(DomainName("127.0.0.1"), port: 88),
            expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 88)
        ),
        ConnectionTargetTestCase(
            target: try? .domainName(DomainName("::1"), port: 99),
            expected: nil
        ),
        ConnectionTargetTestCase(
            target: try? .domainName("www.example.com", port: 77),
            expected: try? .domainName(DomainName("www.example.com"), port: 77)
        ),
        ConnectionTargetTestCase(
            target: try? .domainName("127.0.0.1", port: 88),
            expected: .ipAddress(.v4(IPv4Address(127, 0, 0, 1)), port: 88)
        ),
        ConnectionTargetTestCase(
            target: try? .domainName("::1", port: 99),
            expected: nil
        ),
        ConnectionTargetTestCase(
            target: .unixDomainSocketAddress("/tmp/socket"),
            expected: .unixDomainSocketAddress("/tmp/socket")
        ),
    ]
}
