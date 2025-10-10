@available(swiftEndpointApplePlatforms 15, *)
extension CIDR: CustomStringConvertible {
    /// The textual representation of the CIDR, in form `<ip-address>/<prefix-length>`.
    /// For example `"192.168.1.98/24"`, or `"[2001:db8:1111::]/64"`.
    public var description: String {
        "\(self.prefix)/\(self.prefixLength)"
    }
}

@available(swiftEndpointApplePlatforms 15, *)
extension CIDR: CustomDebugStringConvertible {
    /// The textual representation of the CIDR, in form `IPAddressType(<ip-address>)/<prefix-length>`.
    /// For example `"IPv4Address(192.168.1.98)/24"`, or `"IPv6Address([2001:db8:1111::])/64"`.
    public var debugDescription: String {
        "\(self.prefix.debugDescription)/\(self.prefixLength)"
    }
}

@available(swiftEndpointApplePlatforms 26, *)
extension CIDR: LosslessStringConvertible {
    /// Initialize an CIDR from its textual representation.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    /// This initializer tolerates and repairs the CIDR range if needed.
    /// For example it'll ignore if the mask is greater than the address size, and it'll
    /// repair the prefix if it contains bits that don't matter.
    /// e.g. 192.168.1.98/24 will be repaired to 192.168.1.0/24, and
    /// 2001::/220 will be repaired to 2001::/128.
    @inlinable
    public init?(_ description: String) {
        self.init(textualRepresentation: description.utf8Span)
    }

    /// Initialize an CIDR from its textual representation.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    /// This initializer tolerates and repairs the CIDR range if needed.
    /// For example it'll ignore if the mask is greater than the address size, and it'll
    /// repair the prefix if it contains bits that don't matter.
    /// e.g. 192.168.1.98/24 will be repaired to 192.168.1.0/24, and
    /// 2001::/220 will be repaired to 2001::/128.
    @inlinable
    public init?(_ description: Substring) {
        self.init(textualRepresentation: description.utf8Span)
    }

    /// Initialize an CIDR from a `UTF8Span` of its textual representation.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    /// This initializer tolerates and repairs the CIDR range if needed.
    /// For example it'll ignore if the mask is greater than the address size, and it'll
    /// repair the prefix if it contains bits that don't matter.
    /// e.g. 192.168.1.98/24 will be repaired to 192.168.1.0/24, and
    /// 2001::/220 will be repaired to 2001::/128.
    @inlinable
    public init?(textualRepresentation utf8Span: UTF8Span) {
        var utf8Span = utf8Span
        guard utf8Span.checkForASCII() else {
            return nil
        }

        self.init(__uncheckedASCIIspan: utf8Span.span)
    }
}

@available(swiftEndpointApplePlatforms 15, *)
extension CIDR {
    /// Initialize an CIDR from a `Span<UInt8>` of its textual representation.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    /// This initializer tolerates and repairs the CIDR range if needed.
    /// For example it'll ignore if the mask is greater than the address size, and it'll
    /// repair the prefix if it contains bits that don't matter.
    /// e.g. 192.168.1.98/24 will be repaired to 192.168.1.0/24, and
    /// 2001::/220 will be repaired to 2001::/128.
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            if !span[unchecked: idx].isASCII {
                return nil
            }
        }

        self.init(__uncheckedASCIIspan: span)
    }

    /// Initialize an CIDR from a `Span<UInt8>` of its textual representation.
    /// The provided **span is required to be ASCII**.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    /// This initializer tolerates and repairs the CIDR range if needed.
    /// For example it'll ignore if the mask is greater than the address size, and it'll
    /// repair the prefix if it contains bits that don't matter.
    /// e.g. 192.168.1.98/24 will be repaired to 192.168.1.0/24, and
    /// 2001::/220 will be repaired to 2001::/128.
    @inlinable
    init?(__uncheckedASCIIspan span: Span<UInt8>) {
        debugOnly {
            for idx in span.indices {
                /// Unchecked because `idx` comes right from `span.indices`
                if !span[unchecked: idx].isASCII {
                    fatalError(
                        "CIDR initializer should not be used with non-ASCII character: \(span[unchecked: idx])"
                    )
                }
            }
        }

        let count = span.count
        /// Unchecked because `count` is `span.count`
        let maxIdx = count &- 1
        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            let backwardsIdx = maxIdx &- idx
            /// Unchecked because `backwardsIdx` is guaranteed to be in range of `0...maxIdx`
            let utf8Byte = span[unchecked: backwardsIdx]
            if utf8Byte == .asciiForwardSlash {
                /// Unchecked because `0 <= backwardsIdx <= maxIdx < span.count`
                let prefixSpanRange = Range(uncheckedBounds: (0, backwardsIdx))
                let prefixSpan = span.extracting(unchecked: prefixSpanRange)
                /// Unchecked because `0 <= backwardsIdx <= maxIdx < span.count`
                let maskSpanRange = Range(uncheckedBounds: (backwardsIdx &+ 1, span.count))
                let prefixLengthSpan = span.extracting(unchecked: maskSpanRange)
                guard
                    let prefix = IPAddressType(__uncheckedASCIIspan: prefixSpan),
                    let prefixLength = UInt8(decimalRepresentation: prefixLengthSpan)
                else {
                    return nil
                }
                self.init(prefix: prefix, prefixLength: prefixLength)
                return
            }
        }

        /// There was no forward slash found, so just decode this as the prefix.
        /// Set the prefix length to the full bit width of the IP address type (32 or 128).
        guard let prefix = IPAddressType(__uncheckedASCIIspan: span) else {
            return nil
        }
        self.init(prefix: prefix, prefixLength: UInt8(IntegerLiteralType.bitWidth))
    }
}
