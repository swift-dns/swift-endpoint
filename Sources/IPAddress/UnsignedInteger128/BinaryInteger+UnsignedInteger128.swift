@available(SwiftStdlib 6.0, *)
extension UnsignedInteger128: BinaryInteger {}

/// BinaryInteger conformance
extension UnsignedInteger128 {
    public struct Words {
        @usableFromInline
        let _value: UnsignedInteger128

        @inlinable
        public init(_value: UnsignedInteger128) {
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
        if source.bitWidth > 128, source >> 128 != 0 {
            self = .max
        } else {
            self.init(
                _low: UInt64(truncatingIfNeeded: source),
                _high: UInt64(truncatingIfNeeded: source >> 64)
            )
        }
    }

    @inlinable
    public static func / (lhs: Self, rhs: Self) -> Self {
        precondition(rhs != .zero, "Division by zero")

        if lhs < rhs {
            return .zero
        }

        /// This algorithm works based on knowledge that all numbers in range of
        /// `0 ... (2^128 - 1)` are producible by summing up powers of 2 from 0 to 127.
        /// For example `3 == 2^0 + 2^1`. Or `111 == 2^6 + 2^5 + 2^3 + 2^2 + 2^1 + 2^0`.
        ///
        /// Therefore we can start from `2^127` and on each step check if the `2^n` fits the result.
        /// On each step we decrement `n` by 1 and continue the loop until we know we have the result.

        var result = Self.zero
        /// `rhs != 0` && `lhs < rhs` -> `lhs >= 1` -> `lhs.leadingZeroBitCount <= 127`
        /// -> `127 - lhs.leadingZeroBitCount >= 0` -> `shift >= 0`
        /// So the `shift` below is guaranteed to be greater than or equal to 0.
        let shift = 127 &- lhs.leadingZeroBitCount
        var step = Self(_low: 1, _high: 0) &<< shift

        var lhs = lhs

        let multiplied = step.multipliedReportingOverflow(by: rhs)
        if !multiplied.overflow,
            multiplied.partialValue <= lhs
        {
            result &+= step
            lhs &-= multiplied.partialValue
        }

        while step != Self(_low: 1, _high: 0), lhs != .zero {
            step &>>= 1

            let multiplied = step.multipliedReportingOverflow(by: rhs)
            if !multiplied.overflow,
                multiplied.partialValue <= lhs
            {
                result &+= step
                lhs &-= multiplied.partialValue
            }
        }

        return result
    }

    @inlinable
    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    @inlinable
    public static func % (lhs: Self, rhs: Self) -> Self {
        if rhs == .zero {
            fatalError("Division by zero in remainder operation")
        }

        return lhs - (lhs / rhs) * rhs
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
    func _shiftedLeft(by count: UInt64) -> Self {
        if count >= 64 {
            return Self(_low: 0, _high: self._low &<< (count &- 64))
        }
        if count == 0 {
            return self
        }
        return Self(
            _low: self._low &<< count,
            _high: (self._high &<< count) | (self._low &>> (64 &- count))
        )
    }

    @inlinable
    func _shiftedRight(by count: UInt64) -> Self {
        if count >= 64 {
            return Self(_low: self._high &>> (count &- 64), _high: 0)
        }
        if count == 0 {
            return self
        }
        return Self(
            _low: (self._low &>> count) | (self._high &<< (64 &- count)),
            _high: self._high &>> count
        )
    }

    @inlinable
    public static func << (lhs: Self, rhs: Self) -> Self {
        if rhs._high != 0 || rhs._low >= 128 {
            return .zero
        }
        return lhs._shiftedLeft(by: rhs._low)
    }

    @inlinable
    public static func <<= (lhs: inout Self, rhs: Self) {
        lhs = lhs << rhs
    }

    @inlinable
    public static func >> (lhs: Self, rhs: Self) -> Self {
        if rhs._high != 0 || rhs._low >= 128 {
            return .zero
        }
        return lhs._shiftedRight(by: rhs._low)
    }

    @inlinable
    public static func >>= (lhs: inout Self, rhs: Self) {
        lhs = lhs >> rhs
    }

    // MARK: - Bitwise Operations + BinaryInteger

    @inlinable
    public static func << (lhs: Self, rhs: some BinaryInteger) -> Self {
        if rhs < 0 || rhs >= 128 {
            return .zero
        }
        return lhs._shiftedLeft(by: UInt64(truncatingIfNeeded: rhs))
    }

    @inlinable
    public static func <<= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs << rhs
    }

    @inlinable
    public static func >> (lhs: Self, rhs: some BinaryInteger) -> Self {
        if rhs < 0 || rhs >= 128 {
            return .zero
        }
        return lhs._shiftedRight(by: UInt64(truncatingIfNeeded: rhs))
    }

    @inlinable
    public static func >>= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs >> rhs
    }
}

extension UnsignedInteger128.Words: Sendable, SendableMetatype {}

extension UnsignedInteger128.Words: RandomAccessCollection {
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
