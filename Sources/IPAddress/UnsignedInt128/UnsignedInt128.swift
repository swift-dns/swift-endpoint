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
public struct UnsignedInt128 {
    /// The least significant 64 bits of the value.
    public var _low: UInt64

    /// The most significant 64 bits of the value.
    public var _high: UInt64

    /// Initializes a new `UnsignedInt128` value with the given least significant 64 bits and most significant 64 bits.
    public init(_low: UInt64, _high: UInt64) {
        self._low = _low
        self._high = _high
    }
}

extension UnsignedInt128: Sendable, SendableMetatype, Hashable, BitwiseCopyable {}

extension UnsignedInt128: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._low == rhs._low && lhs._high == rhs._high
    }

    @inlinable
    public static func == (lhs: Self, rhs: some BinaryInteger) -> Bool {
        lhs._low == UInt64(truncatingIfNeeded: rhs)
            && lhs._high == UInt64(truncatingIfNeeded: rhs >> 64)
            && rhs >> 128 == 0
    }

    @inlinable
    public static func == (lhs: some BinaryInteger, rhs: Self) -> Bool {
        rhs == lhs
    }
}

@available(swiftEndpointApplePlatforms 15, *)
extension UnsignedInt128: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: UInt128) {
        self.init(_low: value._low, _high: value._high)
    }
}

extension UnsignedInt128: CustomReflectable {
    @inlinable
    public var customMirror: Mirror {
        Mirror(self, unlabeledChildren: EmptyCollection<Void>())
    }
}
