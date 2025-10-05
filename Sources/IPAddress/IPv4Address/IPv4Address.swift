/// An IPv4 address.
///
/// IPv4 addresses are defined as 32-bit integers in [IETF RFC 791].
/// They are usually represented as four bytes.
///
/// See [`AnyIPAddress`] for a type encompassing both IPv4 and IPv6 addresses.
///
/// [IETF RFC 791]: https://tools.ietf.org/html/rfc791
///
/// # Textual representation
///
/// `IPv4Address` provides an initializer that accepts a string. The four bytes are in decimal
/// notation, divided by `.` (this is called "dot-decimal notation").
/// Notably, octal numbers (which are indicated with a leading `0`) and hexadecimal numbers (which
/// are indicated with a leading `0x`) are not allowed per [IETF RFC 6943].
///
/// [IETF RFC 6943]: https://tools.ietf.org/html/rfc6943#section-3.1.1
public struct IPv4Address: Sendable, Hashable, _IPAddressProtocol {
    /// The byte size of an IPv4.
    @usableFromInline
    static var size: Int {
        4
    }

    /// The underlying 32 bits (4 bytes) representing this IPv4 address.
    public var address: UInt32

    /// Whether this address is an IPv4 Loopback address, known as localhost, or not.
    /// Equivalent to `127.0.0.0/8` in CIDR notation.
    /// That is, any IPv4 address starting with this sequence of bits: `01111111`.
    /// In other words, any IPv4 address starting with `127`.
    @available(endpointApplePlatforms 15, *)
    @inlinable
    public var isLoopback: Bool {
        CIDR<Self>.loopback.contains(self)
    }

    /// Whether this address is an IPv4 Multicast address, or not.
    /// Equivalent to `224.0.0.0/4` in CIDR notation.
    /// That is, any IPv4 address starting with this sequence of bits: `1110`.
    /// In other words, any IPv4 address whose first byte is within the range of `224 ... 239`.
    /// For example `224.1.2.3` and `239.255.2.44` but not `223.x.x.x` and not `240.x.x.x`.
    @available(endpointApplePlatforms 15, *)
    @inlinable
    public var isMulticast: Bool {
        CIDR<Self>.multicast.contains(self)
    }

    /// Whether this address is an IPv4 Link Local address, or not.
    /// Equivalent to `169.254.0.0/16` in CIDR notation.
    /// That is, any IPv4 address starting with this sequence of bits: `1010100111111110`.
    /// In other words, any IPv4 address starting with `169.254`.
    @available(endpointApplePlatforms 15, *)
    @inlinable
    public var isLinkLocal: Bool {
        CIDR<Self>.linkLocal.contains(self)
    }

    /// Initialize an `IPv4Address` from its raw 32-bit unsigned integer representation.
    public init(_ address: UInt32) {
        self.address = address
    }

    /// Initialize an IPv4 from the 4 8-bits (1-bytes) representing it.
    /// For example `IPv4Address(127, 0, 0, 1)` will result in an IP address equal to `127.0.0.1`.
    @inlinable
    public init(_ _1: UInt8, _ _2: UInt8, _ _3: UInt8, _ _4: UInt8) {
        self.address = 0
        withUnsafeMutableBytes(of: &self.address) { ptr in
            ptr[3] = _1
            ptr[2] = _2
            ptr[1] = _3
            ptr[0] = _4
        }
    }
}

extension IPv4Address: ExpressibleByIntegerLiteral {
    /// Initialize an `IPv4Address` from its raw 32-bit unsigned integer representation.
    public init(integerLiteral value: UInt32) {
        self.address = value
    }
}

extension IPv4Address {
    /// The 4 bytes representing this IPv4 address.
    public var bytes: (UInt8, UInt8, UInt8, UInt8) {
        withUnsafeBytes(of: self.address) { ptr in
            (ptr[3], ptr[2], ptr[1], ptr[0])
        }
    }
}
