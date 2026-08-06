import Endpoint

struct IPv4AddressTestCase: Sendable {
    let string: String
    let ip: (address: IPv4Address, description: String)?
    let isValidAsOtherIPVersion: Bool

    init(
        _ string: String,
        ip: (address: IPv4Address, description: String)?,
        isValidAsOtherIPVersion: Bool = false
    ) {
        self.string = string
        self.ip = ip
        self.isValidAsOtherIPVersion = isValidAsOtherIPVersion
    }
}

struct IPv6AddressTestCase: Sendable {
    let string: String
    /// Neither description is enclosed in square brackets. The tests add the brackets themselves.
    /// `description` is the address as printed without `useMixedNotation`,
    /// `mixedNotationDescription` is the address as printed with it.
    /// The two are identical unless the address has a mixed-notation form.
    let ip: (address: IPv6Address, description: String, mixedNotationDescription: String)?
    let isValidAsOtherIPVersion: Bool

    init(
        _ string: String,
        ip: (address: IPv6Address, description: String)?,
        mixedNotationDescription: String? = nil,
        isValidAsOtherIPVersion: Bool = false
    ) {
        self.string = string
        self.ip = ip.map {
            ($0.address, $0.description, mixedNotationDescription ?? $0.description)
        }
        self.isValidAsOtherIPVersion = isValidAsOtherIPVersion
    }

    @available(SwiftStdlib 5.1, *)
    func expectedDescription(options: IPv6Address.DescriptionOptions) -> String? {
        guard let ip = self.ip else {
            return nil
        }
        let useMixedNotation = options.contains(.useMixedNotation)
        let encloseInSquareBrackets = options.contains(.encloseInSquareBrackets)
        let withMixedNotation = useMixedNotation ? ip.mixedNotationDescription : ip.description
        let withBrackets = encloseInSquareBrackets ? "[\(withMixedNotation)]" : withMixedNotation
        return withBrackets
    }
}

struct IPv4DecimalLengthTestCase: Sendable {
    /// The textual representation to parse. May contain leading zeros.
    let string: String
    let rawAddress: UInt32
    /// The canonical textual representation, without leading zeros.
    let description: String
    /// The last two segments of the corresponding IPv4-embedded IPv6 address, in lowercased hex.
    let expandedIPv6SegmentHex: String

    init(
        _ string: String,
        _ rawAddress: UInt32,
        _ description: String,
        _ expandedIPv6SegmentHex: String
    ) {
        self.string = string
        self.rawAddress = rawAddress
        self.description = description
        self.expandedIPv6SegmentHex = expandedIPv6SegmentHex
    }

    var address: IPv4Address {
        IPv4Address(self.rawAddress)
    }

    /// The description of `address.asIPv4MappedIPv6` without mixed notation.
    var ipv4MappedExpandedIPv6Description: String {
        "::ffff:\(self.expandedIPv6SegmentHex)"
    }

    /// The description of `address.asNAT64WellKnownIPv4EmbeddedIPv6` without mixed notation.
    ///
    /// Unlike the IPv4-mapped form, there is no non-zero `ffff` segment separating the embedded
    /// IPv4 from the zeroed middle segments. So when the 7th segment is zero too, it is swallowed
    /// by the compression sign instead of being written out.
    var nat64ExpandedIPv6Description: String {
        let high = self.rawAddress &>> 16
        let low = self.rawAddress & 0xFFFF
        switch (high, low) {
        case (0, 0):
            return "64:ff9b::"
        case (0, let low):
            return "64:ff9b::\(String(low, radix: 16))"
        default:
            return "64:ff9b::\(self.expandedIPv6SegmentHex)"
        }
    }
}

struct AnyIPAddressTestCase: Sendable {
    let string: String
    let ip: (address: AnyIPAddress, description: String)?

    init(_ string: String, ip: (address: AnyIPAddress, description: String)?) {
        self.string = string
        self.ip = ip
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

extension IPv4AddressTestCase {
    @available(SwiftStdlib 5.1, *)
    var asAnyIPAddress: AnyIPAddressTestCase? {
        guard !isValidAsOtherIPVersion else { return nil }
        return AnyIPAddressTestCase(
            string,
            ip: ip.map { (AnyIPAddress.v4($0.address), $0.description) }
        )
    }
}

extension IPv6AddressTestCase {
    @available(SwiftStdlib 5.1, *)
    var asAnyIPAddress: AnyIPAddressTestCase? {
        guard !isValidAsOtherIPVersion else { return nil }
        return AnyIPAddressTestCase(
            string,
            ip: ip.map { (AnyIPAddress.v6($0.address), "[\($0.mixedNotationDescription)]") }
        )
    }
}
