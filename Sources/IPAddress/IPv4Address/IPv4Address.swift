import func Builtin.addressOfBorrow
import func Builtin.unprotectedAddressOfBorrow

/// An IPv4 address.
///
/// IPv4 addresses are defined as 32-bit integers in [IETF RFC 791].
/// They are usually represented as four bytes.
///
/// See [`AnyIPAddress`] for a type encompassing both IPv4 and IPv6 addresses.
///
/// [IETF RFC 791]: https://datatracker.ietf.org/doc/html/rfc791
///
/// # Textual representation
///
/// `IPv4Address` provides an initializer that accepts a string. The four bytes are in decimal
/// notation, divided by `.` (this is called "dot-decimal notation").
/// Notably, octal numbers (which are indicated with a leading `0`) and hexadecimal numbers (which
/// are indicated with a leading `0x`) are not allowed per [IETF RFC 6943].
///
/// [IETF RFC 6943]: https://datatracker.ietf.org/doc/html/rfc6943#section-3.1.1
@_addressableForDependencies
public struct IPv4Address: Sendable, Hashable {
    /// The byte size of an IPv4.
    public static var size: Int {
        4
    }

    /// The underlying 4 bytes representing this IPv4 address, in big-endian byte order.
    @usableFromInline
    var _storage: UInt32

    /// Whether this address is an IPv4 Loopback address, known as localhost, or not.
    /// Equivalent to `127.0.0.0/8` in CIDR notation.
    /// That is, any IPv4 address starting with this sequence of bits: `01111111`.
    /// In other words, any IPv4 address starting with `127`.
    ///
    /// Defined in [IETF RFC 1122].
    ///
    /// [IETF RFC 1122]: https://datatracker.ietf.org/doc/html/rfc1122
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var isLoopback: Bool {
        CIDR<Self>.loopback.contains(self)
    }

    /// Whether this address is an IPv4 Multicast address, or not.
    /// Equivalent to `224.0.0.0/4` in CIDR notation.
    /// That is, any IPv4 address starting with this sequence of bits: `1110`.
    /// In other words, any IPv4 address whose first byte is within the range of `224 ... 239`.
    /// For example `224.1.2.3` and `239.255.2.44` but not `223.x.x.x` and not `240.x.x.x`.
    ///
    /// Defined in [IETF RFC 5771].
    ///
    /// [IETF RFC 5771]: https://datatracker.ietf.org/doc/html/rfc5771
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var isMulticast: Bool {
        CIDR<Self>.multicast.contains(self)
    }

    /// Whether this address is an IPv4 Link Local address, or not.
    /// Equivalent to `169.254.0.0/16` in CIDR notation.
    /// That is, any IPv4 address starting with this sequence of bits: `1010100111111110`.
    /// In other words, any IPv4 address starting with `169.254`.
    ///
    /// Defined in [IETF RFC 3927].
    ///
    /// [IETF RFC 3927]: https://datatracker.ietf.org/doc/html/rfc3927
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var isLinkLocal: Bool {
        CIDR<Self>.linkLocal.contains(self)
    }

    /// Whether this address is the IPv4 unspecified address, or not.
    /// Equivalent to `0.0.0.0`.
    ///
    /// Defined in [IETF RFC 1122].
    ///
    /// [IETF RFC 1122]: https://datatracker.ietf.org/doc/html/rfc1122
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var isUnspecified: Bool {
        CIDR<Self>.unspecified.contains(self)
    }

    /// Whether this address is the IPv4 limited broadcast address, or not.
    /// Equivalent to `255.255.255.255`.
    ///
    /// Defined in [IETF RFC 919].
    ///
    /// [IETF RFC 919]: https://datatracker.ietf.org/doc/html/rfc919
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var isBroadcast: Bool {
        CIDR<Self>.broadcast.contains(self)
    }

    /// Whether this address is an IPv4 Private-Use address, or not.
    /// Equivalent to any of `10.0.0.0/8`, `172.16.0.0/12`, or `192.168.0.0/16` in CIDR notation.
    ///
    /// Defined in [IETF RFC 1918].
    ///
    /// [IETF RFC 1918]: https://datatracker.ietf.org/doc/html/rfc1918
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var isPrivate: Bool {
        CIDR<Self>(prefix: 0x0A_00_00_00, prefixLength: 8).contains(self)
            || CIDR<Self>(prefix: 0xAC_10_00_00, prefixLength: 12).contains(self)
            || CIDR<Self>(prefix: 0xC0_A8_00_00, prefixLength: 16).contains(self)
    }

    /// Whether this address is an IPv4 Shared Address Space address, or not.
    /// Equivalent to `100.64.0.0/10` in CIDR notation.
    ///
    /// Defined in [IETF RFC 6598].
    ///
    /// [IETF RFC 6598]: https://datatracker.ietf.org/doc/html/rfc6598
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var isShared: Bool {
        CIDR<Self>.shared.contains(self)
    }

    /// Whether this address is reserved for use in documentation, or not.
    /// Equivalent to any of `192.0.2.0/24`, `198.51.100.0/24`, or `203.0.113.0/24` in CIDR notation.
    ///
    /// Defined in [IETF RFC 5737].
    ///
    /// [IETF RFC 5737]: https://datatracker.ietf.org/doc/html/rfc5737
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var isDocumentation: Bool {
        CIDR<Self>(prefix: 0xC0_00_02_00, prefixLength: 24).contains(self)
            || CIDR<Self>(prefix: 0xC6_33_64_00, prefixLength: 24).contains(self)
            || CIDR<Self>(prefix: 0xCB_00_71_00, prefixLength: 24).contains(self)
    }

    /// Whether this address is contiguous, and thus suitable for use as a CIDR mask.
    ///
    /// A contiguous address has n contiguous 1-bits from the most significant bit and all other bits set to 0.
    /// For example `255.255.0.0` is contiguous, but `255.0.255.0` is not.
    ///
    /// Classless Inter-Domain Routing is defined in [IETF RFC 4632].
    ///
    /// [IETF RFC 4632]: https://datatracker.ietf.org/doc/html/rfc4632
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var isContiguous: Bool {
        let address = self.asUInt32(byteOrder: .native)
        return (address &<< 1) | address == address
    }

    /// Initialize an `IPv4Address` from its raw 32-bit unsigned integer representation.
    /// For example `IPv4Address(0x7F00_0001)` will result in an IP address equal to `127.0.0.1`.
    /// Or `IPv4Address(0x7F)` will result in an IP address equal to `0.0.0.127`.
    /// Or `IPv4Address(0x0100_007F, byteOrder: .bigEndian)` will result in an IP address equal to `127.0.0.1`.
    @inlinable
    public init(_ address: UInt32, byteOrder: ByteOrder = .native) {
        self._storage = byteOrder == .bigEndian ? address : address.byteSwapped
    }

    /// Initialize an IPv4 from the 4 8-bits (1-bytes) representing it.
    /// For example `IPv4Address(127, 0, 0, 1)` will result in an IP address equal to `127.0.0.1`.
    @inlinable
    public init(_ _1: UInt8, _ _2: UInt8, _ _3: UInt8, _ _4: UInt8) {
        let bytes =
            UInt32(_1)
            | UInt32(_2) &<< 8
            | UInt32(_3) &<< 16
            | UInt32(_4) &<< 24
        self._storage = bytes.littleEndian
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv4Address: _IPAddressProtocol {}

extension IPv4Address: ExpressibleByIntegerLiteral {
    /// Initialize an `IPv4Address` from its raw 32-bit unsigned integer representation.
    /// For example `IPv4Address(0x7F00_0001)` will result in an IP address equal to `127.0.0.1`.
    /// Or `IPv4Address(0x7F)` will result in an IP address equal to `0.0.0.127`.
    @inlinable
    public init(integerLiteral value: UInt32) {
        self.init(value)
    }
}

extension IPv4Address {
    /// The underlying 32 bits (4 bytes) representing this IPv4 address, as a `UInt32`.
    /// For example `IPv4Address("127.0.0.1")!.asUInt32()` is `0x7F00_0001`.
    /// Or `IPv4Address("127.0.0.1")!.asUInt32(byteOrder: .bigEndian)` is `0x0100_007F`.
    @inlinable
    public func asUInt32(byteOrder: ByteOrder = .native) -> UInt32 {
        byteOrder == .bigEndian ? self._storage : self._storage.byteSwapped
    }

    /// A view of exactly 4 (IPv4Address.size) bytes representing this IPv4 address, in network byte order.
    /// For example `IPv4Address("127.0.0.1")!.bytes` contains `[127, 0, 0, 1]`.
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var bytes: Span<UInt8> {
        @_lifetime(borrow self)
        get {
            let pointer = UnsafeRawPointer(Builtin.addressOfBorrow(self))
            let span = unsafe Span<UInt8>(_unsafeStart: pointer, byteCount: Self.size)
            return unsafe _overrideLifetime(span, borrowing: self)
        }
    }

    /// A stack-unprotected view of exactly 4 (IPv4Address.size) bytes representing this IPv4 address, in network byte order.
    /// For example `IPv4Address("127.0.0.1")!._unprotectedBytes` contains `[127, 0, 0, 1]`.
    ///
    /// This unprotected accessor means there is no stack canary to protect the stack frame where this
    /// accessor will land. An out-of-bounds write from any other code (e.g. when using unsafe-pointers)
    /// in that same function will go undetected instead of trapping on the stack canary.
    /// Therefore prefer `bytes` unless you trust the calling frame.
    @available(SwiftStdlib 5.1, *)
    @inlinable
    public var _unprotectedBytes: Span<UInt8> {
        @_lifetime(borrow self)
        get {
            let pointer = UnsafeRawPointer(Builtin.unprotectedAddressOfBorrow(self))
            let span = unsafe Span<UInt8>(_unsafeStart: pointer, byteCount: Self.size)
            return unsafe _overrideLifetime(span, borrowing: self)
        }
    }
}
