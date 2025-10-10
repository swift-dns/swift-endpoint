@available(swiftEndpointApplePlatforms 15, *)
extension AnyIPAddress: CustomStringConvertible {
    public var description: String {
        switch self {
        case .v4(let ipv4):
            return ipv4.description
        case .v6(let ipv6):
            return ipv6.description
        }
    }
}

@available(swiftEndpointApplePlatforms 15, *)
extension AnyIPAddress: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .v4(let ipv4):
            return "AnyIPAddress(.v4(\(ipv4.description)))"
        case .v6(let ipv6):
            return "AnyIPAddress(.v6(\(ipv6.description)))"
        }
    }
}

@available(swiftEndpointApplePlatforms 26, *)
extension AnyIPAddress {
    /// Initialize an IP address from a `UTF8Span` of its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    @inlinable
    public init?(textualRepresentation utf8Span: UTF8Span) {
        var utf8Span = utf8Span
        guard utf8Span.checkForASCII() else {
            return nil
        }

        self.init(_uncheckedAssumingValidASCII: utf8Span.span)
    }
}

@available(swiftEndpointApplePlatforms 15, *)
extension AnyIPAddress: LosslessStringConvertible {
    /// Initialize an IP address from its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    public init?(_ description: String) {
        if #available(swiftEndpointApplePlatforms 26, *) {
            self.init(textualRepresentation: description.utf8Span)
            return
        }

        var description = description
        guard
            let result = description.withSpan_macOSUnder26({
                AnyIPAddress(_uncheckedAssumingValidUTF8: $0)
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
    public init?(_ description: Substring) {
        if #available(swiftEndpointApplePlatforms 26, *) {
            self.init(textualRepresentation: description.utf8Span)
            return
        }

        var description = description
        guard
            let result = description.withSpan_macOSUnder26({
                AnyIPAddress(_uncheckedAssumingValidUTF8: $0)
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
    public init?(_uncheckedAssumingValidUTF8 span: Span<UInt8>) {
        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            if !span[unchecked: idx].isASCII {
                return nil
            }
        }

        self.init(_uncheckedAssumingValidASCII: span)
    }

    /// Initialize an IP address from a `Span<UInt8>` of its textual representation.
    /// The provided **span is required to be ASCII**.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    ///
    /// You should usually use `init?(textualRepresentation: UTF8Span)`, or
    /// `init?(_uncheckedAssumingValidUTF8:)` instead.
    /// This initializer must only be used when you are 100% sure the span only contains ASCII characters.
    @inlinable
    public init?(_uncheckedAssumingValidASCII span: Span<UInt8>) {
        debugOnly {
            for idx in span.indices {
                /// Unchecked because `idx` comes right from `span.indices`
                if !span[unchecked: idx].isASCII {
                    fatalError(
                        "AnyIPAddress initializer should not be used with non-ASCII character: \(span[unchecked: idx])"
                    )
                }
            }
        }

        /// Finds the first either "." or ":" and based on that decide what IP version this could be.
        /// This works even for ipv4-mapped ipv6 addresses like `"::FFFF:204.152.189.116"`.
        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            switch span[unchecked: idx] {
            case .asciiDot:
                guard let ipv4 = IPv4Address(_uncheckedAssumingValidASCII: span) else {
                    return nil
                }
                self = .v4(ipv4)
                return
            case .asciiColon:
                guard let ipv6 = IPv6Address(_uncheckedAssumingValidASCII: span) else {
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
