extension IPv4Address {
    /// The exact translation of an `AnyIPAddress` to an `IPv4Address`.
    ///
    /// This does not handle ipv6-to-ipv4 mappings. Use `init?(ipv6:)` for that.
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public init?(exactly ipAddress: AnyIPAddress) {
        guard let ipv4 = ipAddress.ipv4Value else {
            return nil
        }
        self = ipv4
    }

    /// Maps an IPv6 address to an IPv4 address if the ipv6 is in one of the two well-known
    /// IPv4-embedding address spaces: `::ffff:0:0/96` of [RFC 4291, IP Version 6 Addressing Architecture, February 2006](https://datatracker.ietf.org/doc/rfc4291#section-2.5.5.2),
    /// or the NAT64 Well-Known Prefix `64:ff9b::/96` of [RFC 6052, IPv6 Addressing of IPv4/IPv6 Translators, October 2010](https://datatracker.ietf.org/doc/html/rfc6052#section-2.1).
    ///
    /// The deprecated IPv4-compatible address space `::/96` of
    /// [RFC 4291, Section 2.5.5.1](https://datatracker.ietf.org/doc/html/rfc4291#section-2.5.5.1)
    /// is not accepted.
    ///
    /// ```text
    /// 2.5.5.2.  IPv4-Mapped IPv6 Address
    ///
    ///    A second type of IPv6 address that holds an embedded IPv4 address is
    ///    defined.  This address type is used to represent the addresses of
    ///    IPv4 nodes as IPv6 addresses.  The format of the "IPv4-mapped IPv6
    ///    address" is as follows:
    ///
    /// Hinden                      Standards Track                    [Page 10]
    /// RFC 4291              IPv6 Addressing Architecture         February 2006
    ///
    ///    |                80 bits               | 16 |      32 bits        |
    ///    +--------------------------------------+--------------------------+
    ///    |0000..............................0000|FFFF|    IPv4 address     |
    ///    +--------------------------------------+----+---------------------+
    ///
    ///    See [RFC4038] for background on the usage of the "IPv4-mapped IPv6
    ///    address".
    /// ```
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public init?(ipv6: IPv6Address) {
        guard ipv6.isWellKnownIPv4Embedded else {
            return nil
        }

        self.init(
            UInt32(truncatingIfNeeded: UnsignedInteger128(bigEndian: ipv6._storage)._low)
        )
    }

    /// Maps this address to an IPv4-mapped IPv6 address, in the reserved address space by [RFC 4291, IP Version 6 Addressing Architecture, February 2006](https://datatracker.ietf.org/doc/rfc4291#section-2.5.5.2).
    /// Equivalent to `::ffff:0:0/96` in CIDR notation.
    ///
    /// ```text
    /// 2.5.5.2.  IPv4-Mapped IPv6 Address
    ///
    ///    A second type of IPv6 address that holds an embedded IPv4 address is
    ///    defined.  This address type is used to represent the addresses of
    ///    IPv4 nodes as IPv6 addresses.  The format of the "IPv4-mapped IPv6
    ///    address" is as follows:
    ///
    ///    |                80 bits               | 16 |      32 bits        |
    ///    +--------------------------------------+--------------------------+
    ///    |0000..............................0000|FFFF|    IPv4 address     |
    ///    +--------------------------------------+----+---------------------+
    ///
    ///    See [RFC4038] for background on the usage of the "IPv4-mapped IPv6
    ///    address".
    /// ```
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var asIPv4MappedIPv6: IPv6Address {
        IPv6Address(
            UnsignedInteger128(
                _low: 0x0000_FFFF_0000_0000 | UInt64(self.asUInt32()),
                _high: 0x0000_0000_0000_0000
            )
        )
    }

    /// Maps this address to an IPv4-embedded IPv6 address using the NAT64 Well-Known Prefix of [RFC 6052, IPv6 Addressing of IPv4/IPv6 Translators, October 2010](https://datatracker.ietf.org/doc/html/rfc6052#section-2.1).
    /// Equivalent to `64:ff9b::/96` in CIDR notation.
    ///
    /// ```text
    /// |                     96 bits                    |    32 bits     |
    /// +------------------------------------------------+----------------+
    /// |0064:ff9b:0000:0000:0000:0000...............0000|  IPv4 address  |
    /// +------------------------------------------------+----------------+
    /// ```
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var asNAT64WellKnownIPv4EmbeddedIPv6: IPv6Address {
        IPv6Address(
            UnsignedInteger128(
                _low: UInt64(self.asUInt32()),
                _high: 0x0064_FF9B_0000_0000
            )
        )
    }
}
