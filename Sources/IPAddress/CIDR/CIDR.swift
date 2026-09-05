/// A CIDR block is a network address and a prefix length.
/// It is used to represent a range of IP addresses.
/// For example, 192.168.1.0/24 represents the range of IP addresses from 192.168.1.0 to 192.168.1.255.
///
/// Classless Inter-Domain Routing for IPv4 is defined in [IETF RFC 4632].
/// The address-prefix text representation for IPv6 is defined in [IETF RFC 4291].
///
/// [IETF RFC 4632]: https://datatracker.ietf.org/doc/html/rfc4632
/// [IETF RFC 4291]: https://datatracker.ietf.org/doc/html/rfc4291
///
/// This types stores the raw `prefix` as provided. The host bits are only ignored by containment
/// checks. Everywhere else, including equality and hashing, they are significant.
/// For example, 127.0.0.100/8 and 127.0.0.0/8 contain the same addresses, but are not equal,
/// because their prefixes are stored as `127.0.0.100` and `127.0.0.0` respectively.
@available(SwiftStdlib 5.1, *)
public struct CIDR<IPAddressType: _IPAddressProtocol>: Sendable {

    /// The underlying type of the IP address.
    /// This is always either `UInt32` or `UInt128`.
    ///
    /// There is no need to assume any other type will be added in the future, as that would
    /// require a new IP version to be introduced, in which case it'll take years before that
    /// new IP version is adopted, and at that point we'll just have released a new major version.
    public typealias _AddressValueType = IPAddressType._AddressValueType

    /// The IP address exactly as it was provided, without normalizing away the host bits.
    /// Of type `IPv4Address` or `IPv6Address`.
    /// Example: in 127.0.0.100/8, the prefix is 127.0.0.100.
    /// in 0xFF00::/8, the prefix is 0xFF00::.
    ///
    /// Note that this can contain host bits although nonsignificant for containment checks.
    /// For example, 127.0.0.100/8 and 127.0.0.1/8 contain the same addresses, but their prefix
    /// would be stored as `127.0.0.100` and `127.0.0.1` respectively, which makes them unequal.
    public let prefix: IPAddressType
    /// The masked part of the address.
    /// Of type `UInt32` for `IPv4Address` or `UInt128` for `IPv6Address`.
    ///
    /// Example: in 127.0.0.0/8, the mask is the first 8 bits / the first segment of the IP.
    /// in 0xFF00::/8, the mask is the first 8 bits / the first 2 letters of the IP.
    /// That means in those 2 cases, the mask is an integer with 8 leading 1s and all the rest bits
    /// set to zeros. For example for IPv4 that'd be: `0b11111111_00000000_00000000_00000000`,
    /// which is equal to `255.0.0.0`.
    public let mask: IPAddressType

    /// The number of trailing bits in the prefix that are significant to this CIDR block.
    /// Example: in 127.0.0.0/8, the prefix length is 8, which means any address that has matching
    /// initial 8 bits, is within this CIDR block. In other words, any address starting with `127`.
    /// in 0xFF00::/120, the prefix length is 120.
    @inlinable
    public var prefixLength: Int {
        _AddressValueType.bitWidth
            &- _AddressValueType(bigEndian: self.mask._storage).trailingZeroBitCount
    }

    /// The network address of the CIDR block.
    /// This is the canonical prefix with the host bits masked off.
    /// For example, in 127.0.0.100/8, the network address is 127.0.0.0.
    /// In 0xFF00::/8, the network address is 0xFF00::.
    @inlinable
    public var networkAddress: IPAddressType {
        IPAddressType(_storage: self.prefix._storage & self.mask._storage)
    }

    /// Create a new CIDR with the given prefix and mask.
    ///
    /// Examples:
    /// In 92.0.0.0/8, `92.0.0.0` is the prefix, and `0b11111111(24 zeros)` == `127.0.0.0` is the mask.
    /// In 0xFE80::/10, `0xFE80::` is the prefix, and `0b1111111111(118 zeros)` == `0xFFC0::` is the mask.
    ///
    /// - Parameters:
    ///   - prefix: The IP address, stored exactly as provided.
    ///     The host bits are preserved, not truncated.
    ///     Example: 192.168.1.1/24 keeps 192.168.1.1, even though the trailing 1 is insignificant
    ///     for containment.
    ///   - uncheckedMask: The masked part of the address.
    ///     The mask will not be verified by the initializer in optimized builds, and MUST be
    ///     in a "continuous" form.
    ///     e.g. 0b11110000 is good, but 0b11110001 is not. 0b00001111 is not good either.
    ///     There must be only 1 group of leading ones and 1 group of trailing zeros.
    ///     Example: in 127.0.0.0/8, the mask is `0b11111111_00000000_00000000_00000000`.
    @inlinable
    public init(prefix: IPAddressType, uncheckedMask mask: IPAddressType) {
        assert(mask.isContiguous)

        self.prefix = prefix
        self.mask = mask
    }

    /// Create a new CIDR with the given prefix and mask.
    ///
    /// Examples:
    /// In 92.0.0.0/8, `92.0.0.0` is the prefix, and `0b11111111(24 zeros)` == `127.0.0.0` is the mask.
    /// In 0xFE80::/10, `0xFE80::` is the prefix, and `0b1111111111(118 zeros)` == `0xFFC0::` is the mask.
    ///
    /// - Parameters:
    ///   - prefix: The IP address that is desired after the masking happens.
    ///   - mask: The masked part of the address.
    ///     Example: in 127.0.0.0/8, the mask is `0b11111111_00000000_00000000_00000000`.
    @inlinable
    public init?(prefix: IPAddressType, mask: IPAddressType) {
        guard mask.isContiguous else { return nil }
        self.init(prefix: prefix, uncheckedMask: mask)
    }

    /// Create a new CIDR with the given prefix and count of masked bits.
    ///
    /// Examples:
    /// In 92.0.0.0/8, `92.0.0.0` is the prefix, and `0b11111111(24 zeros)` == `127.0.0.0` is the mask.
    /// In the example above, the prefix and mask are equal, but that's not always the case.
    /// In 0xFE80::/10, `0xFE80::` is the prefix, and `0b1111111111(118 zeros)` == `0xFFC0::` is the mask.
    ///
    /// - Parameters:
    ///   - prefix: The IP address, stored exactly as provided.
    ///     The host bits are preserved, not truncated.
    ///     Example: 192.168.1.1/24 keeps 192.168.1.1, even though the trailing 1 is insignificant
    ///     for containment.
    ///   - prefixLength: The number of leading bits to mask.
    ///     This shouldn't be greater than 32 for IPv4 or 128 for IPv6. The host bits will be ignored.
    ///     Example: in 192.168.1.0/24, the prefix length is 24.
    @inlinable
    public init(prefix: IPAddressType, prefixLength: Int) {
        precondition(prefixLength >= 0 && prefixLength <= _AddressValueType.bitWidth)
        let mask = Self.makeMaskBasedOn(prefixLength: prefixLength)
        self.init(prefix: prefix, uncheckedMask: mask)
    }

    /// Makes a mask with `prefixLength` leading ones followed by all zeros.
    /// Amounts greater than the bit width of the IP address type are clamped to the bit width.
    @inlinable
    package static func makeMaskBasedOn(prefixLength: Int) -> IPAddressType {
        IPAddressType(~(_AddressValueType.max >> prefixLength))
    }

    /// Whether or not the given AnyIPAddress is within this CIDR block.
    /// Complexity: O(1)
    @inlinable
    public func contains(_ other: IPAddressType) -> Bool {
        other._storage & self.mask._storage == self.networkAddress._storage
    }

    /// Whether or not the given AnyIPAddress is within this CIDR block.
    /// Complexity: O(1)
    @inlinable
    public func contains(_ other: AnyIPAddress) -> Bool {
        guard let ip = IPAddressType(exactly: other) else {
            return false
        }
        return self.contains(ip)
    }
}

@available(SwiftStdlib 5.1, *)
extension CIDR: Hashable {
    /// Whether or not 2 CIDR blocks have the same prefix and mask.
    /// The host bits of ``prefix`` are significant here.
    /// For example, 127.0.0.100/8 and 127.0.0.0/8 are not equal, although they contain the
    /// same addresses.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.mask == rhs.mask
            && lhs.prefix == rhs.prefix
    }

    /// Hashes the prefix and the mask, consistent with ``==(_:_:)``.
    /// The host bits of ``prefix`` are significant here.
    /// For example, 127.0.0.100/8 and 127.0.0.0/8 are not required to hash equally, although
    /// they contain the same addresses.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.mask)
        hasher.combine(self.prefix)
    }
}
