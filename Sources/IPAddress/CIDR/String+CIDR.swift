@available(SwiftStdlib 5.1, *)
extension CIDR: CustomStringConvertible {
    /// The textual representation of the CIDR, in form `<ip-address>/<prefix-length>`.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    public var description: String {
        "\(self.prefix)/\(self.prefixLength)"
    }
}

@available(SwiftStdlib 6.2, *)
extension CIDR {
    /// Initialize an CIDR from a `UTF8Span` of its textual representation.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    /// Prefix lengths greater than the address size are rejected.
    /// e.g. 2001::/220 will result in nil.
    /// The prefix itself is kept exactly as provided; host bits are not zeroed out.
    /// e.g. 192.168.1.98/24 stays 192.168.1.98/24, not 192.168.1.0/24.
    @inlinable
    @inline(always)
    public init?(textualRepresentation utf8Span: UTF8Span) {
        self.init(textualRepresentation: utf8Span.span)
    }
}

@available(SwiftStdlib 5.1, *)
extension CIDR: LosslessStringConvertible {
    /// Initialize an CIDR from its textual representation.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    /// Prefix lengths greater than the address size are rejected.
    /// e.g. 2001::/220 will result in nil.
    /// The prefix itself is kept exactly as provided; host bits are not zeroed out.
    /// e.g. 192.168.1.98/24 stays 192.168.1.98/24, not 192.168.1.0/24.
    @inlinable
    @inline(always)
    public init?(_ description: String) {
        guard
            let result = description.withSpan_Compatibility({
                CIDR(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize an CIDR from its textual representation.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    /// Prefix lengths greater than the address size are rejected.
    /// e.g. 2001::/220 will result in nil.
    /// The prefix itself is kept exactly as provided; host bits are not zeroed out.
    /// e.g. 192.168.1.98/24 stays 192.168.1.98/24, not 192.168.1.0/24.
    @inlinable
    @inline(always)
    public init?(_ description: Substring) {
        guard
            let result = description.withSpan_Compatibility({
                CIDR(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize an CIDR from a `Span<UInt8>` of its textual representation.
    /// For example `"192.168.1.98/24"`, or `"2001:db8:1111::/64"`.
    /// Prefix lengths greater than the address size are rejected.
    /// e.g. 2001::/220 will result in nil.
    /// The prefix itself is kept exactly as provided; host bits are not zeroed out.
    /// e.g. 192.168.1.98/24 stays 192.168.1.98/24, not 192.168.1.0/24.
    ///
    /// This init unlike the other ones above is intentionally not `@inline(always)` to act as the
    /// inlining boundary and allow the compiler to decide what to do.
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        let count = span.count
        /// Unchecked because `count` is `span.count`
        let maxIdx = count &- 1
        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            let backwardsIdx = maxIdx &- idx
            /// Unchecked because `backwardsIdx` is guaranteed to be in range of `0...maxIdx`
            let utf8Byte = unsafe span[unchecked: backwardsIdx]
            if utf8Byte == .asciiForwardSlash {
                /// Unchecked because `0 <= backwardsIdx <= maxIdx < span.count`
                let prefixSpanRange = unsafe Range(uncheckedBounds: (0, backwardsIdx))
                let prefixSpan = unsafe span.extracting(unchecked: prefixSpanRange)
                /// Unchecked because `0 <= backwardsIdx <= maxIdx < span.count`
                let maskSpanRange = unsafe Range(uncheckedBounds: (backwardsIdx &+ 1, span.count))
                let prefixLengthSpan = unsafe span.extracting(unchecked: maskSpanRange)
                guard
                    let prefix = IPAddressType(textualRepresentation: prefixSpan),
                    let prefixLength = UInt8(decimalRepresentation: prefixLengthSpan),
                    prefixLength <= _AddressValueType.bitWidth
                else {
                    return nil
                }

                self.init(
                    prefix: prefix,
                    prefixLength: Int(prefixLength)
                )
                return
            }
        }

        /// There was no forward slash found, so just decode this as the prefix.
        /// Set the prefix length to the full bit width of the IP address type (32 or 128).
        guard let prefix = IPAddressType(textualRepresentation: span) else {
            return nil
        }
        self.init(prefix: prefix, prefixLength: _AddressValueType.bitWidth)
    }
}
