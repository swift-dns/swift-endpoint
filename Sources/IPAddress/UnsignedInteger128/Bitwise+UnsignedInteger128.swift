extension UnsignedInteger128 {
    /// The number of bits equal to zero preceding the most significant bit equal to one.
    @inlinable
    public var leadingZeroBitCount: Int {
        if self._high == 0 {
            return 64 + self._low.leadingZeroBitCount
        } else {
            return self._high.leadingZeroBitCount
        }
    }

    /// The number of bits equal to zero following the least significant bit equal to one.
    @inlinable
    public var trailingZeroBitCount: Int {
        if self._low == 0 {
            return 64 + self._high.trailingZeroBitCount
        } else {
            return self._low.trailingZeroBitCount
        }
    }

    /// The value with the same bytes in reverse order.
    @inlinable
    public var byteSwapped: Self {
        Self(_low: self._high.byteSwapped, _high: self._low.byteSwapped)
    }

    /// The big-endian representation of this value.
    @inlinable
    public var bigEndian: Self {
        #if _endian(big)
        return self
        #else
        return self.byteSwapped
        #endif
    }

    /// The little-endian representation of this value.
    @inlinable
    public var littleEndian: Self {
        #if _endian(little)
        return self
        #else
        return self.byteSwapped
        #endif
    }

    /// Creates a value from its big-endian representation.
    @inlinable
    public init(bigEndian value: Self) {
        #if _endian(big)
        self = value
        #else
        self = value.byteSwapped
        #endif
    }

    /// Creates a value from its little-endian representation.
    @inlinable
    public init(littleEndian value: Self) {
        #if _endian(little)
        self = value
        #else
        self = value.byteSwapped
        #endif
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

    @inlinable
    public static func &<< (lhs: Self, rhs: some BinaryInteger) -> Self {
        lhs._shiftedLeft(by: UInt64(truncatingIfNeeded: rhs) & 127)
    }

    @inlinable
    public static func &<<= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs &<< rhs
    }

    @inlinable
    public static func &>> (lhs: Self, rhs: some BinaryInteger) -> Self {
        lhs._shiftedRight(by: UInt64(truncatingIfNeeded: rhs) & 127)
    }

    @inlinable
    public static func &>>= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs &>> rhs
    }
}
