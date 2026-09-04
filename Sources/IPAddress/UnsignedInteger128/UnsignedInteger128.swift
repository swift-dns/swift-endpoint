/// A shadow of `UInt128` which DOESN'T require macOS 15.
///
/// This type only provides what `IPv6Address` needs to store and manipulate its underlying
/// 128 bits. It is intentionally not a full integer type: it does not conform to
/// `BinaryInteger`, `FixedWidthInteger`, `Numeric` or `UnsignedInteger`, and provides no
/// arithmetic beyond bit manipulation.
///
/// On platforms where `UInt128` is unconditionally available, prefer `UInt128`.
/// Use `IPv6Address.asUInt128()` to convert.
/// In a future major version, this whole type might be simply replaced by Swift's own `UInt128`.
///
/// The `ExpressibleByIntegerLiteral` conformance is only available on macOS 15 or higher.
/// On lower versions, use `init(_low:_high:)`:
///
/// ```swift
/// /// On macOS 15 or higher:
/// let value: UnsignedInteger128 = 0x11223344556677889900665544332211
///
/// /// On macOS 14 or lower:
/// let value = UnsignedInteger128(
///     _low: 0x9900665544332211, /// The least significant half of the value
///     _high: 0x1122334455667788 /// The most significant half of the value
/// )
/// ```
public struct UnsignedInteger128 {
    // There is a half-implemented big-endian support below.
    // big-endian is pretty much extinct nowadays but I'm going to let this be.
    // Swift itself doesn't properly support big-endian either so ...

    #if _endian(little)
    /// The least significant 64 bits of the value.
    public var _low: UInt64
    /// The most significant 64 bits of the value.
    public var _high: UInt64
    #else
    /// The most significant 64 bits of the value.
    public var _high: UInt64
    /// The least significant 64 bits of the value.
    public var _low: UInt64
    #endif

    /// Initializes a new `UnsignedInteger128` value given the least significant 64 bits and the most significant 64 bits.
    ///
    /// For example these 2 are equivalent:
    /// ```swift
    /// let value: UnsignedInteger128 = 0x11223344556677889900665544332211
    ///
    /// let value = UnsignedInteger128(
    ///     _low: 0x9900665544332211, /// The least significant half of the value
    ///     _high: 0x1122334455667788 /// The most significant half of the value
    /// )
    /// ```
    @inlinable
    public init(_low: UInt64, _high: UInt64) {
        self._low = _low
        self._high = _high
    }

    /// Initializes a new `UnsignedInteger128` from a non-negative value that fits in 128 bits.
    @inlinable
    public init(_ source: some BinaryInteger) {
        guard let high = UInt64(exactly: source >> 64) else {
            fatalError(
                "value cannot be converted to UnsignedInteger128 because it is outside the representable range"
            )
        }
        self.init(
            _low: UInt64(truncatingIfNeeded: source),
            _high: high
        )
    }
}

extension UnsignedInteger128: Sendable, SendableMetatype, Hashable, BitwiseCopyable {}

extension UnsignedInteger128: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._low == rhs._low && lhs._high == rhs._high
    }
}

@available(SwiftStdlib 6.0, *)
extension UnsignedInteger128: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: UInt128) {
        self.init(_low: value._low, _high: value._high)
    }
}

extension UnsignedInteger128 {
    /// The number of bits in the binary representation of this type.
    @inlinable
    public static var bitWidth: Int {
        128
    }

    /// A value with all bits set to zero.
    @inlinable
    public static var zero: Self {
        Self(_low: 0, _high: 0)
    }

    /// The minimum representable value.
    @inlinable
    public static var min: Self {
        Self(_low: 0, _high: 0)
    }

    /// The maximum representable value.
    @inlinable
    public static var max: Self {
        Self(_low: UInt64.max, _high: UInt64.max)
    }
}
