@available(SwiftStdlib 5.1, *)
extension CIDR<IPv4Address> {
    /// Representing 127.0.0.0/8
    ///
    /// Defined in [IETF RFC 1122].
    ///
    /// [IETF RFC 1122]: https://datatracker.ietf.org/doc/html/rfc1122
    @inlinable
    public static var loopback: Self {
        Self(
            prefix: 0x7F_00_00_00,
            prefixLength: 8
        )
    }

    /// Representing 224.0.0.0/4
    ///
    /// Defined in [IETF RFC 5771].
    ///
    /// [IETF RFC 5771]: https://datatracker.ietf.org/doc/html/rfc5771
    @inlinable
    public static var multicast: Self {
        Self(
            prefix: 0xE0_00_00_00,
            prefixLength: 4
        )
    }

    /// Representing 169.254.0.0/16
    ///
    /// Defined in [IETF RFC 3927].
    ///
    /// [IETF RFC 3927]: https://datatracker.ietf.org/doc/html/rfc3927
    @inlinable
    public static var linkLocal: Self {
        Self(
            prefix: 0xA9_FE_00_00,
            prefixLength: 16
        )
    }

    /// Representing 255.255.255.255/32
    ///
    /// Defined in [IETF RFC 919].
    ///
    /// [IETF RFC 919]: https://datatracker.ietf.org/doc/html/rfc919
    @inlinable
    public static var broadcast: Self {
        Self(
            prefix: 0xFF_FF_FF_FF,
            prefixLength: 32
        )
    }

    /// Representing 100.64.0.0/10
    ///
    /// Defined in [IETF RFC 6598].
    ///
    /// [IETF RFC 6598]: https://datatracker.ietf.org/doc/html/rfc6598
    @inlinable
    public static var shared: Self {
        Self(
            prefix: 0x64_40_00_00,
            prefixLength: 10
        )
    }

    /// Representing 0.0.0.0/32
    ///
    /// Defined in [IETF RFC 1122].
    ///
    /// [IETF RFC 1122]: https://datatracker.ietf.org/doc/html/rfc1122
    @inlinable
    public static var unspecified: Self {
        Self(
            prefix: 0x00_00_00_00,
            prefixLength: 32
        )
    }
}
