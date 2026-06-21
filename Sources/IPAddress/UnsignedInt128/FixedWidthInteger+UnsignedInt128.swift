@available(SwiftStdlib 6.0, *)
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
        /// We declare that:
        /// `self == (_high: h0, _low: l0)`
        /// `rhs == (_high: h1, _low: l1)`
        ///
        /// Assuming `B == 2^64`:
        /// `self * rhs`
        /// == `(h0*B + l0) * (h1*B + l1)`
        /// == `h0*h1*B^2 + (h0*l1 + h1*l0)*B + l0*l1`
        ///
        /// So we can say that:
        /// `l0*l1` is the new `_low`.
        /// Due to `*B`, `(h0*l1 + h1*l0)` is the new `_high`.
        ///
        /// We know that `B == 2^64`. Therefore if `h0*h1 > 0`, we will have `h0*h1*B^2 > 2^128`.
        /// So we can conclude that if `h0*h1 > 0`, we will have overflow.
        /// Therefore we skip multiplying `h0*h1*B^2` altogether.
        /// In the end, we check that `h0*h1` is `0` to ensure no overflow.

        let (h0, l0) = (self._high, self._low)
        let (h1, l1) = (rhs._high, rhs._low)

        let h0l1 = h0.multipliedReportingOverflow(by: l1)
        let h1l0 = h1.multipliedReportingOverflow(by: l0)
        let h0l1_h1l0 = h0l1.partialValue.addingReportingOverflow(h1l0.partialValue)

        let (l0l1_carryOver, l0l1) = l0.multipliedFullWidth(by: l1)

        let h0l1_h1l0_w_carryOver = h0l1_h1l0.partialValue.addingReportingOverflow(
            l0l1_carryOver
        )

        let h0h1B_isNotZero = h0 != 0 && h1 != 0

        let overflow =
            h0h1B_isNotZero
            || h0l1.overflow
            || h1l0.overflow
            || h0l1_h1l0.overflow
            || h0l1_h1l0_w_carryOver.overflow
        return (
            partialValue: Self(
                _low: l0l1,
                _high: h0l1_h1l0_w_carryOver.partialValue
            ),
            overflow: overflow
        )
    }

    public func multipliedFullWidth(by rhs: Self) -> (high: Self, low: Self) {
        /// We return (high: Self, low: Self). Let's name them like so:
        /// `high == (_high: H0, _low: L0)`
        /// `low == (_high: H1, _low: L1)`
        ///
        /// Also:
        /// `self == (_high: h0, _low: l0)`
        /// `rhs == (_high: h1, _low: l1)`
        ///
        /// Assuming `B == 2^64`:
        /// `self * rhs`
        /// == `(h0*B + l0) * (h1*B + l1)`
        /// == `h0*h1*B^2 + (h0*l1 + h1*l0)*B + l0*l1`
        ///
        /// So we can then say that:
        /// `l0*l1` is the new L1 and will carry over to H1.
        /// Due to `*B`, `(h0*l1 + h1*l0)` is the new H1 and will carry over to L0 and H0.
        /// Due to `*B^2`, `h0*h1` is the new L0 and will carry over to H0.

        let (h0, l0) = (self._high, self._low)
        let (h1, l1) = (rhs._high, rhs._low)

        let (L1_carryOver, L1) = l0.multipliedFullWidth(by: l1)

        let (h0l1_carryOver, h0l1) = h0.multipliedFullWidth(by: l1)
        let (h1l0_carryOver, h1l0) = h1.multipliedFullWidth(by: l0)
        let h0l1_h1l0 = h0l1.addingReportingOverflow(h1l0)
        let h0l1_h1l0_w_carryOver = h0l1_h1l0.partialValue.addingReportingOverflow(L1_carryOver)
        let H1 = h0l1_h1l0_w_carryOver.partialValue

        var (H1_carryOver, H1_carryOver_overflow) = h0l1_carryOver.addingReportingOverflow(
            h1l0_carryOver
        )
        if h0l1_h1l0.overflow {
            H1_carryOver += 1
        }
        if h0l1_h1l0_w_carryOver.overflow {
            H1_carryOver += 1
        }

        let (h0h1_carryOver, h0h1) = h0.multipliedFullWidth(by: h1)
        let h0h1_w_carryOver = h0h1.addingReportingOverflow(H1_carryOver)
        let L0 = h0h1_w_carryOver.partialValue

        var L0_carryOver = h0h1_carryOver
        if H1_carryOver_overflow {
            L0_carryOver += 1
        }
        if h0h1_w_carryOver.overflow {
            L0_carryOver += 1
        }
        let H0 = L0_carryOver

        return (
            high: Self(_low: L0, _high: H0),
            low: Self(_low: L1, _high: H1)
        )
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
