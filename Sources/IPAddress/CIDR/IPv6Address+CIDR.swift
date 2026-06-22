@available(SwiftStdlib 5.1, *)
extension CIDR<IPv6Address> {
    /// Representing ::1/128
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
}
