/// An IPv6 address.
///
/// IPv6 addresses are defined as 128-bit integers in [IETF RFC 4291].
/// They are usually represented as eight 16-bit segments.
///
/// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
///
/// # Embedding IPv4 Addresses
///
/// See [`AnyIPAddress`] for a type encompassing both IPv4 and IPv6 addresses.
///
/// To assist in the transition from IPv4 to IPv6 two types of IPv6 addresses that embed an IPv4 address were defined:
/// IPv4-compatible and IPv4-mapped addresses. Of these IPv4-compatible addresses have been officially deprecated.
/// [IETF RFC 6052] later defined IPv4-embedded IPv6 addresses for IPv4/IPv6 translation,
/// including the NAT64 Well-Known Prefix `64:ff9b::/96`.
///
/// None of these addresses are assigned any special meaning by this implementation,
/// other than what the relevant standards prescribe. This means that an address like `::ffff:127.0.0.1`,
/// while representing an IPv4 loopback address, is not itself an IPv6 loopback address; only `::1` is.
/// To handle these so called "IPv4-in-IPv6" addresses, they have to first be converted to their canonical IPv4 address.
///
/// [IETF RFC 6052]: https://datatracker.ietf.org/doc/html/rfc6052
///
/// ### IPv4-Compatible IPv6 Addresses
///
/// IPv4-compatible IPv6 addresses are defined in [IETF RFC 4291 Section 2.5.5.1], and have been officially deprecated.
/// The RFC describes the format of an "IPv4-Compatible IPv6 address" as follows:
///
/// ```text
/// |                80 bits               | 16 |      32 bits        |
/// +--------------------------------------+--------------------------+
/// |0000..............................0000|0000|    IPv4 address     |
/// +--------------------------------------+----+---------------------+
/// ```
/// So `::a.b.c.d` would be an IPv4-compatible IPv6 address representing the IPv4 address `a.b.c.d`.
///
/// [IETF RFC 4291 Section 2.5.5.1]: https://datatracker.ietf.org/doc/html/rfc4291#section-2.5.5.1
///
/// ### IPv4-Mapped IPv6 Addresses
///
/// IPv4-mapped IPv6 addresses are defined in [IETF RFC 4291 Section 2.5.5.2].
/// The RFC describes the format of an "IPv4-Mapped IPv6 address" as follows:
///
/// ```text
/// |                80 bits               | 16 |      32 bits        |
/// +--------------------------------------+--------------------------+
/// |0000..............................0000|FFFF|    IPv4 address     |
/// +--------------------------------------+----+---------------------+
/// ```
/// So `::ffff:a.b.c.d` would be an IPv4-mapped IPv6 address representing the IPv4 address `a.b.c.d`.
///
/// [IETF RFC 4291 Section 2.5.5.2]: https://datatracker.ietf.org/doc/html/rfc4291#section-2.5.5.2
///
/// ### NAT64 Well-Known-Prefixed IPv4-Embedded IPv6 Addresses
///
/// The NAT64 Well-Known Prefix is defined in [IETF RFC 6052 Section 2.1] as `64:ff9b::/96`.
/// Being a `/96` prefix, the embedded IPv4 address occupies the last 32 bits, as described in
/// [IETF RFC 6052 Section 2.2]:
///
/// ```text
/// |                     96 bits                    |    32 bits     |
/// +------------------------------------------------+----------------+
/// |0064:ff9b:0000:0000:0000:0000...............0000|  IPv4 address  |
/// +------------------------------------------------+----------------+
/// ```
/// So `64:ff9b::a.b.c.d` would be a well-known-prefixed IPv4-embedded IPv6 address
/// representing the IPv4 address `a.b.c.d`.
///
/// The Network-Specific Prefixes of the same RFC, as well as the local-use prefix `64:ff9b:1::/48`
/// of [IETF RFC 8215], are not assigned any special meaning by this implementation.
///
/// [IETF RFC 6052 Section 2.1]: https://datatracker.ietf.org/doc/html/rfc6052#section-2.1
/// [IETF RFC 6052 Section 2.2]: https://datatracker.ietf.org/doc/html/rfc6052#section-2.2
/// [IETF RFC 8215]: https://datatracker.ietf.org/doc/html/rfc8215
///
/// # Textual representation
///
/// `IPv6Address` provides an initializer that accepts a string. There are many ways to represent
/// an IPv6 address in text, but in general, each segments is written in hexadecimal
/// notation, and segments are separated by `:`. For more information, see
/// [IETF RFC 5952].
///
/// [IETF RFC 5952]: https://datatracker.ietf.org/doc/html/rfc5952
@available(SwiftStdlib 5.1, *)
public struct IPv6Address: Sendable, Hashable {
    /// The byte size of an IPv6.
    public static var size: Int {
        16
    }

    /// The underlying 128 bits (16 bytes) representing this IPv6 address.
    package var _address: UnsignedInteger128
    public var _address: UnsignedInteger128

    /// Whether this address is the IPv6 Loopback address, known as localhost, or not.
    /// Equivalent to `::1` or `0:0:0:0:0:0:0:1` in IPv6 description format.
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public var isLoopback: Bool {
        CIDR<Self>.loopback.contains(self)
    }

    /// Whether this address is an IPv6 Multicast address, or not.
    /// Equivalent to `FF00::/8` in CIDR notation.
    /// That is, any IPv6 address starting with this sequence of bits: `11111111`.
    /// In other words, any IPv6 address starting with `FFxx`. This does not include an address like
    /// `FF::` which is equivalent to `00FF::` and does not start with `FF`.
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public var isMulticast: Bool {
        CIDR<Self>.multicast.contains(self)
    }

    /// Whether this address is an IPv6 Link Local Unicast address, or not.
    /// Equivalent to `FE80::/10` in CIDR notation.
    /// That is, any IPv6 address starting with this sequence of bits: `1111111010`.
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public var isLinkLocalUnicast: Bool {
        CIDR<Self>.linkLocalUnicast.contains(self)
    }

    /// Whether this address is the IPv6 unspecified address, or not.
    /// Equivalent to `::` or `0:0:0:0:0:0:0:0` in IPv6 description format.
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public var isUnspecified: Bool {
        CIDR<Self>.unspecified.contains(self)
    }

    /// Whether this address is an IPv6 Unique Local address, or not.
    /// Equivalent to `FC00::/7` in CIDR notation.
    /// That is, any IPv6 address starting with this sequence of bits: `1111110`.
    ///
    /// Defined in [IETF RFC 4193].
    ///
    /// [IETF RFC 4193]: https://datatracker.ietf.org/doc/html/rfc4193
    @inlinable
    public var isUniqueLocal: Bool {
        CIDR<Self>.uniqueLocal.contains(self)
    }

    /// Whether this address is reserved for use in documentation, or not.
    /// Equivalent to `2001:DB8::/32` in CIDR notation.
    ///
    /// Defined in [IETF RFC 3849].
    ///
    /// [IETF RFC 3849]: https://datatracker.ietf.org/doc/html/rfc3849
    @inlinable
    public var isDocumentation: Bool {
        CIDR<Self>.documentation.contains(self)
    }

    /// Whether this address is an IPv4-mapped address, or not.
    /// Equivalent to `::FFFF:0:0/96` (aka `::FFFF:0.0.0.0/96`) in CIDR notation.
    ///
    /// Defined in [IETF RFC 4291].
    ///
    /// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
    @inlinable
    public var isIPv4Mapped: Bool {
        CIDR<Self>.ipv4Mapped.contains(self)
    }

    /// Whether this address is a NAT64 well-known IPv4-embedded address, or not.
    /// Equivalent to `64:ff9b::/96` in CIDR notation.
    ///
    /// Defined in [IETF RFC 6052].
    ///
    /// [IETF RFC 6052]: https://datatracker.ietf.org/doc/html/rfc6052#section-2.4
    @inlinable
    public var isNAT64WellKnownIPv4Embedded: Bool {
        CIDR<Self>.nat64WellKnownIPv4Embedded.contains(self)
    }

    /// Whether this address is a well-known IPv4-embedded address, or not.
    /// Equivalent to `::ffff:0:0/96` (aka `::FFFF:0.0.0.0/96`) or `64:ff9b::/96` in CIDR notation.
    ///
    /// Defined in [IETF RFC 5952].
    ///
    /// [IETF RFC 5952]: https://datatracker.ietf.org/doc/html/rfc5952#section-5
    @inlinable
    public var isWellKnownIPv4Embedded: Bool {
        self.isIPv4Mapped || self.isNAT64WellKnownIPv4Embedded
    }

    /// Initialize an `IPv6Address` from its raw 128-bit unsigned integer representation.
    /// For example `IPv6Address(0x0102_0304_0506_0708_090A_0B0C_0D0E_0F10)` will
    /// result in an IP address equal to `0102:0304:0506:0708:090A:0B0C:0D0E:0F10`.
    /// Or `IPv6Address(0x0102)` will result in an IP address equal to `::0102`.
    @inlinable
    public init(_ address: UnsignedInteger128) {
        self._address = address
    }

    /// Initialize an `IPv6Address` from its raw 128-bit unsigned integer representation.
    /// For example `IPv6Address(0x0102_0304_0506_0708_090A_0B0C_0D0E_0F10)` will
    /// result in an IP address equal to `0102:0304:0506:0708:090A:0B0C:0D0E:0F10`.
    /// Or `IPv6Address(0x0102)` will result in an IP address equal to `::0102`.
    @available(SwiftStdlib 6.0, *)
    @_disfavoredOverload
    @inlinable
    public init(_ address: UInt128) {
        self._address = UnsignedInteger128(address)
    }

    /// Initialize an IPv6 from the 8 16-bits (2-bytes) representing it.
    /// For example `IPv6Address(0x0102, 0x0304, 0x0506, 0x0708, 0x090A, 0x0B0C, 0x0D0E, 0x0F10)`
    /// will result in an IP address equal to `0102:0304:0506:0708:090A:0B0C:0D0E:0F10`.
    @inlinable
    public init(
        _ _1: UInt16,
        _ _2: UInt16,
        _ _3: UInt16,
        _ _4: UInt16,
        _ _5: UInt16,
        _ _6: UInt16,
        _ _7: UInt16,
        _ _8: UInt16
    ) {
        self._address = UnsignedInteger128(
            _low: UInt64(_5) &<< 48
                | UInt64(_6) &<< 32
                | UInt64(_7) &<< 16
                | UInt64(_8),
            _high: UInt64(_1) &<< 48
                | UInt64(_2) &<< 32
                | UInt64(_3) &<< 16
                | UInt64(_4)
        )
    }

    /// Initialize an IPv6 from the 16 bytes representing it.
    /// For example `IPv6Address(0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10)`
    /// will result in an IP address equal to `0102:0304:0506:0708:090A:0B0C:0D0E:0F10`.
    @inlinable
    public init(
        _ _1: UInt8,
        _ _2: UInt8,
        _ _3: UInt8,
        _ _4: UInt8,
        _ _5: UInt8,
        _ _6: UInt8,
        _ _7: UInt8,
        _ _8: UInt8,
        _ _9: UInt8,
        _ _10: UInt8,
        _ _11: UInt8,
        _ _12: UInt8,
        _ _13: UInt8,
        _ _14: UInt8,
        _ _15: UInt8,
        _ _16: UInt8
    ) {
        self._address = UnsignedInteger128(
            _low: UInt64(_9) &<< 56
                | UInt64(_10) &<< 48
                | UInt64(_11) &<< 40
                | UInt64(_12) &<< 32
                | UInt64(_13) &<< 24
                | UInt64(_14) &<< 16
                | UInt64(_15) &<< 8
                | UInt64(_16),
            _high: UInt64(_1) &<< 56
                | UInt64(_2) &<< 48
                | UInt64(_3) &<< 40
                | UInt64(_4) &<< 32
                | UInt64(_5) &<< 24
                | UInt64(_6) &<< 16
                | UInt64(_7) &<< 8
                | UInt64(_8)
        )
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv6Address: _IPAddressProtocol {}

@available(SwiftStdlib 6.0, *)
extension IPv6Address: ExpressibleByIntegerLiteral {
    /// Initialize an `IPv6Address` from its raw 128-bit unsigned integer representation.
    /// For example `IPv6Address(0x0102_0304_0506_0708_090A_0B0C_0D0E_0F10)` will
    /// result in an IP address equal to `0102:0304:0506:0708:090A:0B0C:0D0E:0F10`.
    /// Or `IPv6Address(0x0102)` will result in an IP address equal to `::0102`.
    @inlinable
    public init(integerLiteral value: UInt128) {
        self._address = UnsignedInteger128(value)
    }
}

@available(SwiftStdlib 6.0, *)
extension IPv6Address {
    /// The underlying 128 bits (16 bytes) representing this IPv6 address, as a `UInt128`.
    /// For example `IPv6Address("::1")!.asUInt128()` is `0x0000_0000_0000_0000_0000_0000_0000_0001`.
    @inlinable
    public func asUInt128() -> UInt128 {
        UInt128(
            _low: self._address._low,
            _high: self._address._high
        )
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv6Address {
    /// The 16 bytes representing this IPv6 address.
    @inlinable
    public var bytes:
        (
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
        )
    {
        let hi = self._address._high
        let lo = self._address._low
        return (
            UInt8(truncatingIfNeeded: hi &>> 56),
            UInt8(truncatingIfNeeded: hi &>> 48),
            UInt8(truncatingIfNeeded: hi &>> 40),
            UInt8(truncatingIfNeeded: hi &>> 32),
            UInt8(truncatingIfNeeded: hi &>> 24),
            UInt8(truncatingIfNeeded: hi &>> 16),
            UInt8(truncatingIfNeeded: hi &>> 8),
            UInt8(truncatingIfNeeded: hi),
            UInt8(truncatingIfNeeded: lo &>> 56),
            UInt8(truncatingIfNeeded: lo &>> 48),
            UInt8(truncatingIfNeeded: lo &>> 40),
            UInt8(truncatingIfNeeded: lo &>> 32),
            UInt8(truncatingIfNeeded: lo &>> 24),
            UInt8(truncatingIfNeeded: lo &>> 16),
            UInt8(truncatingIfNeeded: lo &>> 8),
            UInt8(truncatingIfNeeded: lo)
        )
    }

    /// The 8 segments representing this IPv6 address, each being 2 bytes / 16 bits.
    /// The same as 8-segments / groups divided by colons (`:`) in the textual representation.
    @inlinable
    public var segments: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16) {
        let hi = self._address._high
        let lo = self._address._low
        return (
            UInt16(truncatingIfNeeded: hi &>> 48),
            UInt16(truncatingIfNeeded: hi &>> 32),
            UInt16(truncatingIfNeeded: hi &>> 16),
            UInt16(truncatingIfNeeded: hi),
            UInt16(truncatingIfNeeded: lo &>> 48),
            UInt16(truncatingIfNeeded: lo &>> 32),
            UInt16(truncatingIfNeeded: lo &>> 16),
            UInt16(truncatingIfNeeded: lo)
        )
    }
}
