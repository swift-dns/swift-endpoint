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
    struct IP: Sendable {
        let address: IPv6Address
        /// Not enclosed in square brackets.
        let description: String
        /// Not enclosed in square brackets.
        let mixedNotationDescription: String

        @available(SwiftStdlib 5.1, *)
        var standardDescription: String {
            self.address.isIPv4Mapped ? self.mixedNotationDescription : self.description
        }

        init(
            _ address: IPv6Address,
            _ description: String,
            _ mixedNotationDescription: String
        ) {
            self.address = address
            self.description = description
            self.mixedNotationDescription = mixedNotationDescription
        }
    }

    let string: String
    let ip: IP?
    let isValidAsOtherIPVersion: Bool

    init(
        _ string: String,
        ip: IP?,
        isValidAsOtherIPVersion: Bool = false
    ) {
        self.string = string
        self.ip = ip
        self.isValidAsOtherIPVersion = isValidAsOtherIPVersion
    }

    @available(SwiftStdlib 5.1, *)
    func expectedDescription(options: IPv6Address.DescriptionOptions) -> String? {
        guard let ip = self.ip else {
            return nil
        }
        let useMixedNotation =
            options.contains(.forceMixedNotation)
            || (options.contains(.useMixedNotation) && ip.address.isIPv4Mapped)
        let expected = useMixedNotation ? ip.mixedNotationDescription : ip.description
        let encloseInSquareBrackets = options.contains(.encloseInSquareBrackets)
        return encloseInSquareBrackets ? "[\(expected)]" : expected
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
    var nat64ExpandedIPv6Description: String {
        self.expandedIPv6Description(compressedPrefix: "64:ff9b")
    }

    /// The IPv4 address embedded in `2001:db8::/96`, which is not a well-known IPv4-embedding
    /// prefix, so mixed notation never applies to it.
    var documentationEmbeddedIPv6: IPv6Address {
        IPv6Address(
            UnsignedInteger128(
                _low: UInt64(self.rawAddress),
                _high: 0x2001_0DB8_0000_0000
            )
        )
    }

    /// The description of `documentationEmbeddedIPv6`, with or without mixed notation.
    var documentationEmbeddedIPv6Description: String {
        self.expandedIPv6Description(compressedPrefix: "2001:db8")
    }

    /// The IPv4 address embedded in `1:2:3:4:5:6::/96`, whose prefix is written out in full
    /// instead of being compressed, and to which mixed notation never applies either.
    var uncompressedPrefixEmbeddedIPv6: IPv6Address {
        IPv6Address(
            UnsignedInteger128(
                _low: 0x0005_0006_0000_0000 | UInt64(self.rawAddress),
                _high: 0x0001_0002_0003_0004
            )
        )
    }

    /// The description of `uncompressedPrefixEmbeddedIPv6`, with or without mixed notation.
    /// Only an entirely zeroed embedded IPv4 leaves a zero run long enough to compress.
    var uncompressedPrefixEmbeddedIPv6Description: String {
        if self.rawAddress == 0 {
            return "1:2:3:4:5:6::"
        }
        return "1:2:3:4:5:6:\(self.expandedIPv6SegmentHex)"
    }

    /// The description of the address embedded right after a `<prefix>::` compression sign.
    ///
    /// Unlike the IPv4-mapped form, there is no non-zero `ffff` segment separating the embedded
    /// IPv4 from the zeroed middle segments. So when the 7th segment is zero too, it is swallowed
    /// by the compression sign instead of being written out.
    private func expandedIPv6Description(compressedPrefix prefix: String) -> String {
        let high = self.rawAddress &>> 16
        let low = self.rawAddress & 0xFFFF
        switch (high, low) {
        case (0, 0):
            return "\(prefix)::"
        case (0, let low):
            return "\(prefix)::\(String(low, radix: 16))"
        default:
            return "\(prefix)::\(self.expandedIPv6SegmentHex)"
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
            ip: ip.map { (AnyIPAddress.v6($0.address), $0.standardDescription) }
        )
    }
}
