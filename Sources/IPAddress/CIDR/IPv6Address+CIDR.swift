@available(SwiftStdlib 5.1, *)
extension CIDR<IPv6Address> {
    /// Representing ::1/128
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public static var loopback: Self {
        Self(
            prefix: IPv6Address(
                UnsignedInteger128(
                    _low: 0x0000_0000_0000_0001,
                    _high: 0x0000_0000_0000_0000
                )
            ),
            prefixLength: 128
        )
    }

    /// Representing FF00::/8
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public static var multicast: Self {
        Self(
            prefix: IPv6Address(
                UnsignedInteger128(
                    _low: 0x0000_0000_0000_0000,
                    _high: 0xFF00_0000_0000_0000
                )
            ),
            prefixLength: 8
        )
    }

    /// Representing FE80::/10
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public static var linkLocalUnicast: Self {
        Self(
            prefix: IPv6Address(
                UnsignedInteger128(
                    _low: 0x0000_0000_0000_0000,
                    _high: 0xFE80_0000_0000_0000
                )
            ),
            prefixLength: 10
        )
    }

    /// Representing ::FFFF:0:0/96 (aka ::FFFF:0.0.0.0/96)
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public static var ipv4Mapped: Self {
        Self(
            prefix: IPv6Address(
                UnsignedInteger128(
                    _low: 0x0000_FFFF_0000_0000,
                    _high: 0x0000_0000_0000_0000
                )
            ),
            prefixLength: 96
        )
    }

    /// Representing 64:ff9b::/96
    ///
    /// Defined in [IETF RFC 6052].
    ///
    /// [IETF RFC 6052]: https://datatracker.ietf.org/doc/html/rfc6052#section-2.4
    @inlinable
    public static var nat64WellKnownIPv4Embedded: Self {
        Self(
            prefix: IPv6Address(
                UnsignedInteger128(
                    _low: 0x0000_0000_0000_0000,
                    _high: 0x0064_FF9B_0000_0000
                )
            ),
            prefixLength: 96
        )
    }

    /// Representing FC00::/7
    ///
    /// Defined in [IETF RFC 4193].
    ///
    /// [IETF RFC 4193]: https://datatracker.ietf.org/doc/html/rfc4193
    @inlinable
    public static var uniqueLocal: Self {
        Self(
            prefix: IPv6Address(
                UnsignedInteger128(
                    _low: 0x0000_0000_0000_0000,
                    _high: 0xFC00_0000_0000_0000
                )
            ),
            prefixLength: 7
        )
    }

    /// Representing 2001:DB8::/32
    ///
    /// Defined in [IETF RFC 3849].
    ///
    /// [IETF RFC 3849]: https://datatracker.ietf.org/doc/html/rfc3849
    @inlinable
    public static var documentation: Self {
        Self(
            prefix: IPv6Address(
                UnsignedInteger128(
                    _low: 0x0000_0000_0000_0000,
                    _high: 0x2001_0DB8_0000_0000
                )
            ),
            prefixLength: 32
        )
    }

    /// Representing ::/128
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public static var unspecified: Self {
        Self(
            prefix: IPv6Address(
                UnsignedInteger128(
                    _low: 0x0000_0000_0000_0000,
                    _high: 0x0000_0000_0000_0000
                )
            ),
            prefixLength: 128
        )
    }
}
