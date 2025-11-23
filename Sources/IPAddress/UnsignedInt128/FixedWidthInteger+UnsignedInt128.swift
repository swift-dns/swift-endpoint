@available(swiftEndpointApplePlatforms 15, *)
extension UnsignedInt128: FixedWidthInteger {}

/// FixedWidthInteger conformance
extension UnsignedInt128 {
    @inlinable
    public static var bitWidth: Int {
        128
    }

    @inlinable
    public var nonzeroBitCount: Int {
        self._low.nonzeroBitCount + self._high.nonzeroBitCount
    }

    @inlinable
    public var leadingZeroBitCount: Int {
        if self._high == 0 {
            return 64 + self._low.leadingZeroBitCount
        } else {
            return self._high.leadingZeroBitCount
        }
    }

    @inlinable
    public static var max: Self {
        Self(_low: UInt64.max, _high: UInt64.max)
    }

    @inlinable
    public static var min: Self {
        Self(_low: 0, _high: 0)
    }

    @inlinable
    public static var zero: Self {
        Self(_low: 0, _high: 0)
    }

    @inlinable
    public var byteSwapped: Self {
        Self(_low: self._high.byteSwapped, _high: self._low.byteSwapped)
    }

    @inlinable
    public init(_truncatingBits source: some BinaryInteger) {
        self.init(
            _low: UInt64(truncatingIfNeeded: source),
            _high: UInt64(truncatingIfNeeded: source >> 64)
        )
    }

    @inlinable
    public func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let newLow = self._low.addingReportingOverflow(
            rhs._low
        )
        var newHigh = self._high.addingReportingOverflow(
            rhs._high
        )

        if newLow.overflow {
            let newerHigh = newHigh.partialValue.addingReportingOverflow(1)
            newHigh = (newerHigh.partialValue, newHigh.overflow || newerHigh.overflow)
        }

        return (
            partialValue: Self(
                _low: newLow.partialValue,
                _high: newHigh.partialValue
            ),
            overflow: newHigh.overflow
        )
    }

    @inlinable
    public func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let newLow = self._low.subtractingReportingOverflow(
            rhs._low
        )
        var newHigh = self._high.subtractingReportingOverflow(
            rhs._high
        )

        if newLow.overflow {
            let newerHigh = newHigh.partialValue.subtractingReportingOverflow(1)
            newHigh = (newerHigh.partialValue, newHigh.overflow || newerHigh.overflow)
        }

        return (
            partialValue: Self(
                _low: newLow.partialValue,
                _high: newHigh.partialValue
            ),
            overflow: newHigh.overflow
        )
    }

    @inlinable
    public func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let h1 = self._high.multipliedReportingOverflow(by: rhs._low)
        let h2 = self._low.multipliedReportingOverflow(by: rhs._high)
        let h3 = h1.partialValue.addingReportingOverflow(h2.partialValue)
        let (h, l) = self._low.multipliedFullWidth(by: rhs._low)
        let high = h3.partialValue.addingReportingOverflow(h)
        let overflow =
            (self._high != 0 && rhs._high != 0)
            || h1.overflow
            || h2.overflow
            || h3.overflow
            || high.overflow
        return (Self(_low: l, _high: high.partialValue), overflow)
    }

    @inlinable
    public func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs == .zero {
            return (self, true)
        }
        return (self / rhs, false)
    }

    @inlinable
    public func quotientAndRemainder(dividingBy rhs: Self) -> (quotient: Self, remainder: Self) {
        (self / rhs, self % rhs)
    }

    @inlinable
    public func remainderReportingOverflow(
        dividingBy rhs: Self
    ) -> (partialValue: Self, overflow: Bool) {
        if rhs == .zero {
            return (self, true)
        }

        let remainder = self.quotientAndRemainder(dividingBy: rhs).remainder
        return (remainder, false)
    }

    public init(bigEndian value: Self) {
        #if _endian(big)
        self = value
        #else
        self = value.byteSwapped
        #endif
    }

    public init(littleEndian value: Self) {
        #if _endian(little)
        self = value
        #else
        self = value.byteSwapped
        #endif
    }

    public var littleEndian: Self {
        #if _endian(little)
        return self
        #else
        return self.byteSwapped
        #endif
    }

    public var bigEndian: Self {
        #if _endian(big)
        return self
        #else
        return self.byteSwapped
        #endif
    }

    // MARK: - Bitwise Operations

    @inlinable
    public static func &<< (lhs: Self, rhs: Self) -> Self {
        lhs << (rhs % Self(_low: 128, _high: 0))
    }

    @inlinable
    public static func &<<= (lhs: inout Self, rhs: Self) {
        lhs = lhs &<< rhs
    }

    @inlinable
    public static func &>> (lhs: Self, rhs: Self) -> Self {
        lhs >> (rhs % Self(_low: 128, _high: 0))
    }

    @inlinable
    public static func &>>= (lhs: inout Self, rhs: Self) {
        lhs = lhs &>> rhs
    }

    // MARK: - Bitwise Operations + BinaryInteger

    @inlinable
    public static func &<< (lhs: Self, rhs: some BinaryInteger) -> Self {
        lhs << (rhs % 128)
    }

    @inlinable
    public static func &<<= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs &<< rhs
    }

    @inlinable
    public static func &>> (lhs: Self, rhs: some BinaryInteger) -> Self {
        lhs >> (rhs % 128)
    }

    @inlinable
    public static func &>>= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs &>> rhs
    }
}
