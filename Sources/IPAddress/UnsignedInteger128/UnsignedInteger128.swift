/// A replacement for `UInt128`. Swift's own UInt128 requires macOS 15.
///
/// Functionally, this implementation is expected to be identical to Swift's own `UInt128`.
/// However, for performance reasons you are encouraged to immediately turn this value into a
/// `UInt128` whenever you can, and perform your operations on that `UInt128` value instead.
///
/// This type provides identical APIs compared to `UInt128`.
/// In a future minor version, this whole type might be turned into a `typealias` for `UInt128`.
/// In a future major version, this whole type might be simply replaced by Swift's own `UInt128`.
///
/// This type conforms to all that `UInt128` currently does, other than `AtomicRepresentable`.
/// The following conformances on macOS are only available on macOS 15 or higher:
/// `BinaryInteger`, `FixedWidthInteger`, `Numeric`, `UnsignedInteger`, `ExpressibleByIntegerLiteral`.
/// Note that for the most part the implementations are available on all macOS versions, but the mere conformances are
/// limited to macOS 15 or higher.
/// This might make some behavior or some synthesized functions unavailable, but most functionality should still be available.
/// On other platforms the conformances are always available.
///
/// If you're trying to use this type in macOS versions lower than 15, you might need to make some adjustments to your code.
/// For example you might need to use the `init(_low:_high:)` instead of using the "ExpressibleByIntegerLiteral" initializer:
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
    public init(_low: UInt64, _high: UInt64) {
        self._low = _low
        self._high = _high
    }
}

extension UnsignedInteger128: Sendable, SendableMetatype, Hashable, BitwiseCopyable {}

extension UnsignedInteger128: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._low == rhs._low && lhs._high == rhs._high
    }

    @inlinable
    public static func == (lhs: Self, rhs: some BinaryInteger) -> Bool {
        lhs._low == UInt64(truncatingIfNeeded: rhs)
            && lhs._high == UInt64(truncatingIfNeeded: rhs >> 64)
            && (rhs.bitWidth <= 128 || rhs >> 128 == 0)
    }

    @inlinable
    public static func == (lhs: some BinaryInteger, rhs: Self) -> Bool {
        rhs == lhs
    }
}

@available(SwiftStdlib 6.0, *)
extension UnsignedInteger128: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: UInt128) {
        self.init(_low: value._low, _high: value._high)
    }
}

extension UnsignedInteger128: CustomReflectable {
    @inlinable
    public var customMirror: Mirror {
        Mirror(self, unlabeledChildren: EmptyCollection<Void>())
    }
}
