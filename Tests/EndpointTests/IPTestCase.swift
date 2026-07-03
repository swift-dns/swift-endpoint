import Endpoint

struct IPTestCase<IPAddressType: Sendable & Hashable>: Sendable {
    let string: String
    let address: IPAddressType?
    let canonicalDescription: String?
    let isValidAsOtherIPVersion: Bool

    init(
        _ string: String,
        _ address: IPAddressType? = nil,
        canonicalDescription: String? = nil,
        isValidAsOtherIPVersion: Bool = false
    ) {
        self.string = string
        self.address = address
        self.canonicalDescription = canonicalDescription
        self.isValidAsOtherIPVersion = isValidAsOtherIPVersion
    }

    var descriptionTestCase: (IPAddressType, String)? {
        guard let address, let canonicalDescription else {
            return nil
        }
        return (address, canonicalDescription)
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
