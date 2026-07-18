import Endpoint

struct IPTestCase<IPAddressType: Sendable & Hashable>: Sendable {
    let string: String
    let ip: (address: IPAddressType, description: String)?
    let isValidAsOtherIPVersion: Bool

    init(
        _ string: String,
        ip: (address: IPAddressType, description: String)?,
        isValidAsOtherIPVersion: Bool = false
    ) {
        self.string = string
        self.ip = ip
        self.isValidAsOtherIPVersion = isValidAsOtherIPVersion
    }
}

struct IPPropertyTestCase<IPAddressType: Sendable>: Sendable {
    let ip: IPAddressType
    let testCaseDescription: String
    let predicate: @Sendable (IPAddressType) -> Bool

    init(
        _ ip: IPAddressType,
        _ testCaseDescription: String,
        _ predicate: @escaping @Sendable (IPAddressType) -> Bool
    ) {
        self.ip = ip
        self.testCaseDescription = testCaseDescription
        self.predicate = predicate
    }
}

struct IPv4MappedIPv6TestCase: Sendable {
    let ipv6String: String
    let ipv4: IPv4Address?

    init(
        _ ipv6String: String,
        _ ipv4: IPv4Address? = nil
    ) {
        self.ipv6String = ipv6String
        self.ipv4 = ipv4
    }
}

extension IPv4Address {
    @available(SwiftStdlib 5.1, *)
    var arpaDomainNameString: String {
        let bytes = self.bytes
        return "\(bytes.3).\(bytes.2).\(bytes.1).\(bytes.0).in-addr.arpa."
    }
}

extension IPv6Address {
    @available(SwiftStdlib 5.1, *)
    var arpaDomainNameString: String {
        let bytes = self.bytes
        let reversedBytes = [
            bytes.15, bytes.14, bytes.13, bytes.12, bytes.11, bytes.10, bytes.9, bytes.8,
            bytes.7, bytes.6, bytes.5, bytes.4, bytes.3, bytes.2, bytes.1, bytes.0,
        ]
        var labels: [String] = []
        labels.reserveCapacity(32)
        for byte in reversedBytes {
            labels.append(String(byte & 0xF, radix: 16))
            labels.append(String(byte >> 4, radix: 16))
        }
        return labels.joined(separator: ".") + ".ip6.arpa."
    }
}

extension IPTestCase where IPAddressType == IPv4Address {
    @available(SwiftStdlib 5.1, *)
    var asAnyIPAddress: IPTestCase<AnyIPAddress>? {
        guard !isValidAsOtherIPVersion else { return nil }
        return IPTestCase<AnyIPAddress>(
            string,
            ip: ip.map { (AnyIPAddress.v4($0.address), $0.description) }
        )
    }
}

extension IPTestCase where IPAddressType == IPv6Address {
    @available(SwiftStdlib 5.1, *)
    var asAnyIPAddress: IPTestCase<AnyIPAddress>? {
        guard !isValidAsOtherIPVersion else { return nil }
        return IPTestCase<AnyIPAddress>(
            string,
            ip: ip.map { (AnyIPAddress.v6($0.address), $0.description) }
        )
    }
}
