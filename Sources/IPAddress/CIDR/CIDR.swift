/// A CIDR block is a network address and a prefix length.
/// It is used to represent a range of IP addresses.
/// For example, 192.168.1.0/24 represents the range of IP addresses from 192.168.1.0 to 192.168.1.255.
///
/// This types stores the raw `prefix` as provided, but for most purposes other than computing a string
/// representation, the host bits are ignored.
/// For example, 127.0.0.100/8 and 127.0.0.0/8 represent the same network, but their prefixes
/// are stored as `127.0.0.100` and `127.0.0.0` respectively, regardless of their equivalence.
@available(swiftEndpointApplePlatforms 10.15, *)
public struct CIDR<IPAddressType: _IPAddressProtocol>: Sendable {

    /// The underlying type of the IP address.
    /// This is always either `UInt32` or `UInt128`.
    ///
    /// There is no need to assume any other type will be added in the future, as that would
    /// require a new IP version to be introduced, in which case it'll take years before that
    /// new IP version is adopted, and at that point we'll just have released a new major version.
    public typealias AddressValueType = IPAddressType.AddressValueType

    /// The IP address exactly as it was provided, without normalizing away the host bits.
    /// Of type `IPv4Address` or `IPv6Address`.
    /// Example: in 127.0.0.100/8, the prefix is 127.0.0.100.
    /// in 0xFF00::/8, the prefix is 0xFF00::.
    ///
    /// Note that this can contain host bits although nonsignificant in context of a CIDR block.
    /// For example, 127.0.0.100/8 and 127.0.0.1/8 represent the same network, but their prefix
    /// would be stored as `127.0.0.100` and `127.0.0.1` respectively, regardless of their equivalence.
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
        AddressValueType.bitWidth &- self.mask.address.trailingZeroBitCount
    }

    /// The network address of the CIDR block.
    /// This is the canonical prefix with the host bits masked off.
    /// For example, in 127.0.0.100/8, the network address is 127.0.0.0.
    /// In 0xFF00::/8, the network address is 0xFF00::.
    @inlinable
    public var networkAddress: IPAddressType {
        IPAddressType(self.prefix.address & self.mask.address)
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
        assert(Self.makeMaskBasedOn(countOfTrailingZerosOf: mask) == mask)

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
        /// Make sure the mask is "continuous" and has no leading zeros
        /// e.g. 0b11110000 is good, but 0b11110001 is not. 0b00001111 is not good either.
        guard Self.makeMaskBasedOn(countOfTrailingZerosOf: mask) == mask else {
            return nil
        }

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
    public init(prefix: IPAddressType, prefixLength: UInt8) {
        let mask = Self.makeMaskBasedOn(prefixLength: prefixLength)
        self.init(prefix: prefix, uncheckedMask: mask)
    }

    /// Creates a number with `prefixLength` amount of leading 1s followed by all zeros.
    /// Parameters:
    ///   - prefixLength: The number of leading 1s to have, followed by all zeros.
    ///     Ignores amounts that are greater than the bit width of the IP address type,
    ///     which means 32 for IPv4 or 128 for IPv6.
    @inlinable
    package static func makeMaskBasedOn(prefixLength: UInt8) -> IPAddressType {
        let bitWidth = UInt8(AddressValueType.bitWidth)
        if prefixLength >= bitWidth {
            return IPAddressType(AddressValueType.max)
        }
        let mask = ~(AddressValueType.max &>> prefixLength)
        return IPAddressType(mask)
    }

    /// Makes a mask based on the number of trailing zeros.
    /// Parameters:
    ///   - countOfTrailingZeros: The number of trailing zeros to have.
    ///     This MUST NOT be greater than the bit width of `AddressValueType`,
    ///     which means 32 for IPv4 or 128 for IPv6.
    @inlinable
    static func makeMaskBasedOn(countOfTrailingZerosOf ip: IPAddressType) -> IPAddressType {
        let countOfTrailingZeros = ip.address.trailingZeroBitCount
        if countOfTrailingZeros == AddressValueType.bitWidth {
            return IPAddressType(.zero)
        } else {
            /// ~AddressValueType((AddressValueType(1) &<< countOfTrailingZeros) &- 1)
            /// also works. The compiler optimizes these anyway, so doesn't matter which
            /// one to use.
            let mask = (AddressValueType.max &>> countOfTrailingZeros) &<< countOfTrailingZeros
            return IPAddressType(mask)
        }
    }

    /// Whether or not the given AnyIPAddress is within this CIDR block.
    /// Complexity: O(1)
    @inlinable
    public func contains(_ other: IPAddressType) -> Bool {
        other.address & self.mask.address == self.networkAddress.address
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

@available(swiftEndpointApplePlatforms 10.15, *)
extension CIDR: Hashable {
    /// Whether or now 2 CIDR blocks represent the same network.
    /// For example, 127.0.0.100/8 and 127.0.0.0/8 represent the same network.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.mask == rhs.mask
            && lhs.networkAddress == rhs.networkAddress
    }

    /// Hashes the network this CIDR describes, consistent with ``==(_:_:)``.
    /// The host bits of ``prefix`` are masked off so equal CIDRs hash equally.
    /// For example, 127.0.0.100/8 and 127.0.0.0/8 represent the same network.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.mask)
        hasher.combine(self.networkAddress)
    }
}
