@available(SwiftStdlib 5.1, *)
extension AnyIPAddress: CustomStringConvertible {
    /// The textual representation of an IP address.
    /// The `v4` case is formatted in dot-decimal notation, and the `v6` case as
    /// 8 16-bits (2-bytes) separated by `:`, while using
    /// the compression sign (`::`) and mixed ipv4-embedded notation where applicable.
    ///
    /// As examples, the following descriptions might be emitted for their corresponding
    /// IP addresses:
    /// `192.168.1.1`, `::`, `::ffff:192.168.1.1`, `2001:db8:85a3::100`.
    ///
    /// Use `AnyIPAddress.description(ipv6Options:)` for a customized description.
    @inlinable
    public var description: String {
        self.description(ipv6Options: .standardOptions)
    }

    /// The textual representation of an IP address.
    /// The `v4` case is formatted in dot-decimal notation, and the `v6` case as
    /// 8 16-bits (2-bytes) separated by `:`,
    /// while using the compression sign (`::`) where applicable.
    /// Default options also add mixed ipv4-embedded notation where applicable.
    ///
    /// `ipv6Options` only applies to the `v6` case. The `v4` case has no options and
    /// is always formatted in dot-decimal notation.
    ///
    /// Parameters:
    /// - `ipv6Options`: The options to use for the description of the `v6` case.
    @inlinable
    public func description(
        ipv6Options: IPv6Address.DescriptionOptions = .standardOptions
    ) -> String {
        switch self {
        case .v4(let ipv4):
            return ipv4.description
        case .v6(let ipv6):
            return ipv6.description(options: ipv6Options)
        }
    }
}

@available(SwiftStdlib 6.2, *)
extension AnyIPAddress {
    /// Initialize an IP address from a `UTF8Span` of its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    @inlinable
    @inline(always)
    public init?(textualRepresentation utf8Span: UTF8Span) {
        self.init(textualRepresentation: utf8Span.span)
    }
}

@available(SwiftStdlib 5.1, *)
extension AnyIPAddress: LosslessStringConvertible {
    /// Initialize an IP address from its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    @inlinable
    @inline(always)
    public init?(_ description: String) {
        guard
            let result = description.withSpan_Compatibility({
                AnyIPAddress(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize an IP address from its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    @inlinable
    @inline(always)
    public init?(_ description: Substring) {
        guard
            let result = description.withSpan_Compatibility({
                AnyIPAddress(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize an IP address from a `Span<UInt8>` of its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        /// Finds the first either "." or ":" and based on that decide what IP version this could be.
        /// This works even for ipv4-mapped ipv6 addresses like `"::FFFF:204.152.189.116"`.
        for idx in span.indices {
            switch span[idx] {
            case .asciiDot:
                guard let ipv4 = IPv4Address(textualRepresentation: span) else {
                    return nil
                }
                self = .v4(ipv4)
                return
            case .asciiColon:
                guard let ipv6 = IPv6Address(textualRepresentation: span) else {
                    return nil
                }
                self = .v6(ipv6)
                return
            default:
                continue
            }
        }

        return nil
    }
}
