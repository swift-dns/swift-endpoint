@available(swiftEndpointApplePlatforms 15, *)
extension UnsignedInt128: BinaryInteger {}

extension UnsignedInt128 /*: BinaryInteger*/ {
    public struct Words {
        @usableFromInline
        let _value: UnsignedInt128

        @inlinable
        public init(_value: UnsignedInt128) {
            self._value = _value
        }
    }

    @inlinable
    public var words: Words {
        Words(_value: self)
    }

    @inlinable
    public init?(exactly source: some BinaryFloatingPoint) {
        let highAsFloat = (source * 0x1.0p-64).rounded(.towardZero)
        guard let high = UInt64(exactly: highAsFloat) else { return nil }
        let maybeLow = high == 0 ? source : source - 0x1.0p64 * highAsFloat
        guard let low = UInt64(exactly: maybeLow) else { return nil }
        self.init(_low: low, _high: high)
    }

    @inlinable
    public init(_ source: some BinaryFloatingPoint) {
        guard let value = Self(exactly: source.rounded(.towardZero)) else {
            fatalError(
                "value cannot be converted to UInt128 because it is outside the representable range"
            )
        }
        self = value
    }

    @inlinable
    public var trailingZeroBitCount: Int {
        if self._low == 0 {
            return 64 + self._high.trailingZeroBitCount
        } else {
            return self._low.trailingZeroBitCount
        }
    }

    @inlinable
    public init(truncatingIfNeeded source: some BinaryInteger) {
        self.init(
            _low: UInt64(truncatingIfNeeded: source),
            _high: UInt64(truncatingIfNeeded: source >> 64)
        )
    }

    @inlinable
    public init(clamping source: some BinaryInteger) {
        self.init(
            _low: UInt64(clamping: source),
            _high: UInt64(clamping: source >> 64)
        )
    }

    @inlinable
    public static func / (lhs: Self, rhs: Self) -> Self {
        let (partialValue, overflow) = lhs.dividedReportingOverflow(by: rhs)
        precondition(!overflow, "\(lhs) / \(rhs) overflows by \(partialValue)")
        return partialValue
    }

    @inlinable
    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    @inlinable
    public static func % (lhs: Self, rhs: Self) -> Self {
        lhs.remainderReportingOverflow(dividingBy: rhs).partialValue
    }

    @inlinable
    public static func %= (lhs: inout Self, rhs: Self) {
        lhs = lhs % rhs
    }

    @inlinable
    public static func & (lhs: Self, rhs: Self) -> Self {
        Self(
            _low: lhs._low & rhs._low,
            _high: lhs._high & rhs._high
        )
    }

    @inlinable
    public static func &= (lhs: inout Self, rhs: Self) {
        lhs = lhs & rhs
    }

    @inlinable
    public static func | (lhs: Self, rhs: Self) -> Self {
        Self(
            _low: lhs._low | rhs._low,
            _high: lhs._high | rhs._high
        )
    }

    @inlinable
    public static func |= (lhs: inout Self, rhs: Self) {
        lhs = lhs | rhs
    }

    @inlinable
    public static func ^ (lhs: Self, rhs: Self) -> Self {
        Self(
            _low: lhs._low ^ rhs._low,
            _high: lhs._high ^ rhs._high
        )
    }

    @inlinable
    public static func ^= (lhs: inout Self, rhs: Self) {
        lhs = lhs ^ rhs
    }

    // MARK: - Bitwise Operations

    @inlinable
    public static prefix func ~ (x: Self) -> Self {
        Self(
            _low: ~x._low,
            _high: ~x._high
        )
    }

    @inlinable
    public static func << (lhs: Self, rhs: Self) -> Self {
        Self(
            _low: rhs._high == 0 ? lhs._low << rhs._low : 0,
            _high: rhs._high == 0 ? lhs._high << rhs._low : 0
        )
    }

    @inlinable
    public static func <<= (lhs: inout Self, rhs: Self) {
        lhs = lhs << rhs
    }

    @inlinable
    public static func >> (lhs: Self, rhs: Self) -> Self {
        Self(
            _low: rhs._high == 0 ? lhs._low >> rhs._low : 0,
            _high: rhs._high == 0 ? lhs._high >> rhs._low : 0
        )
    }

    @inlinable
    public static func >>= (lhs: inout Self, rhs: Self) {
        lhs = lhs >> rhs
    }

    // MARK: - Bitwise Operations + BinaryInteger

    @inlinable
    public static func << (lhs: Self, rhs: some BinaryInteger) -> Self {
        Self(
            _low: lhs._low << rhs,
            _high: lhs._high << rhs
        )
    }

    @inlinable
    public static func <<= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs << rhs
    }

    @inlinable
    public static func >> (lhs: Self, rhs: some BinaryInteger) -> Self {
        Self(
            _low: lhs._low >> rhs,
            _high: lhs._high >> rhs
        )
    }

    @inlinable
    public static func >>= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs >> rhs
    }
}

extension UnsignedInt128.Words: Sendable, SendableMetatype {}

extension UnsignedInt128.Words: RandomAccessCollection {
    public typealias Element = UInt

    public typealias Index = Int

    public typealias SubSequence = Slice<Self>

    public typealias Indices = Range<Int>

    @inlinable
    public var count: Int {
        128 / UInt.bitWidth
    }

    @inlinable
    public var startIndex: Int {
        0
    }

    @inlinable
    public var endIndex: Int {
        count
    }

    @inlinable
    public var indices: Indices {
        startIndex..<endIndex
    }

    @inlinable
    public func index(after i: Int) -> Int {
        i + 1
    }

    @inlinable
    public func index(before i: Int) -> Int {
        i - 1
    }

    @inlinable
    public subscript(position: Int) -> UInt {
        @inlinable
        get {
            precondition(position >= 0 && position < count, "Index out of bounds")
            var value = _value
            #if _endian(little)
            let index = position
            #else
            let index = count - 1 - position
            #endif
            return unsafe _withUnprotectedUnsafePointer(to: &value) {
                unsafe $0.withMemoryRebound(to: UInt.self, capacity: count) { unsafe $0[index] }
            }
        }
    }
}
