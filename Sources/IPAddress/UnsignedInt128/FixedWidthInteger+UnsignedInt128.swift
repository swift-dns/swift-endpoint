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
        let multiplicationResult = self.multipliedFullWidth(by: rhs)
        let overflow = multiplicationResult.high > .zero

        return (
            partialValue: multiplicationResult.low,
            overflow: overflow
        )
    }

    @inlinable
    public func multipliedFullWidth(by other: Self) -> (high: Self, low: Self) {
        // Bit mask that facilitates masking the lower 32 bits of a 64 bit UInt.
        let lower32 = UInt64(UInt32.max)

        // Decompose lhs into an array of 4, 32 significant bit UInt64s.
        let lhsArray = [
            self._high >> 32,
            self._high & lower32,
            self._low >> 32,
            self._low & lower32,
        ]

        // Decompose rhs into an array of 4, 32 significant bit UInt64s.
        let rhsArray = [
            other._high >> 32,
            other._high & lower32,
            other._low >> 32,
            other._low & lower32,
        ]

        // The future contents of this array will be used to store segment
        // multiplication results.
        var resultArray = [[UInt64]](
            repeating: [UInt64](repeating: 0, count: 4),
            count: 4
        )

        // Loop through every combination of lhsArray[x] * rhsArray[y]
        for rhsSegment in 0..<rhsArray.count {
            for lhsSegment in 0..<lhsArray.count {
                let currentValue = lhsArray[lhsSegment] * rhsArray[rhsSegment]
                resultArray[lhsSegment][rhsSegment] = currentValue
            }
        }

        // Perform multiplication similar to pen and paper in 64bit, 32bit masked increments.
        let bitSegment8 = resultArray[3][3] & lower32
        let bitSegment7 = Self._variadicAdditionWithOverflowCount(
            resultArray[2][3] & lower32,
            resultArray[3][2] & lower32,
            resultArray[3][3] >> 32
        )  // overflow from bitSegment8
        let bitSegment6 = Self._variadicAdditionWithOverflowCount(
            resultArray[1][3] & lower32,
            resultArray[2][2] & lower32,
            resultArray[3][1] & lower32,
            resultArray[2][3] >> 32,  // overflow from bitSegment7
            resultArray[3][2] >> 32,  // overflow from bitSegment7
            bitSegment7.overflowCount
        )
        let bitSegment5 = Self._variadicAdditionWithOverflowCount(
            resultArray[0][3] & lower32,
            resultArray[1][2] & lower32,
            resultArray[2][1] & lower32,
            resultArray[3][0] & lower32,
            resultArray[1][3] >> 32,  // overflow from bitSegment6
            resultArray[2][2] >> 32,  // overflow from bitSegment6
            resultArray[3][1] >> 32,  // overflow from bitSegment6
            bitSegment6.overflowCount
        )
        let bitSegment4 = Self._variadicAdditionWithOverflowCount(
            resultArray[0][2] & lower32,
            resultArray[1][1] & lower32,
            resultArray[2][0] & lower32,
            resultArray[0][3] >> 32,  // overflow from bitSegment5
            resultArray[1][2] >> 32,  // overflow from bitSegment5
            resultArray[2][1] >> 32,  // overflow from bitSegment5
            resultArray[3][0] >> 32,  // overflow from bitSegment5
            bitSegment5.overflowCount
        )
        let bitSegment3 = Self._variadicAdditionWithOverflowCount(
            resultArray[0][1] & lower32,
            resultArray[1][0] & lower32,
            resultArray[0][2] >> 32,  // overflow from bitSegment4
            resultArray[1][1] >> 32,  // overflow from bitSegment4
            resultArray[2][0] >> 32,  // overflow from bitSegment4
            bitSegment4.overflowCount
        )
        let bitSegment1 = Self._variadicAdditionWithOverflowCount(
            resultArray[0][0],
            resultArray[0][1] >> 32,  // overflow from bitSegment3
            resultArray[1][0] >> 32,  // overflow from bitSegment3
            bitSegment3.overflowCount
        )

        // Shift and merge the results into 64 bit groups, adding in overflows as we go.
        let lowerLowerBits = Self._variadicAdditionWithOverflowCount(
            bitSegment8,
            bitSegment7.truncatedValue << 32
        )
        let upperLowerBits = Self._variadicAdditionWithOverflowCount(
            bitSegment7.truncatedValue >> 32,
            bitSegment6.truncatedValue,
            bitSegment5.truncatedValue << 32,
            lowerLowerBits.overflowCount
        )
        let lowerUpperBits = Self._variadicAdditionWithOverflowCount(
            bitSegment5.truncatedValue >> 32,
            bitSegment4.truncatedValue,
            bitSegment3.truncatedValue << 32,
            upperLowerBits.overflowCount
        )
        let upperUpperBits = Self._variadicAdditionWithOverflowCount(
            bitSegment3.truncatedValue >> 32,
            bitSegment1.truncatedValue,
            lowerUpperBits.overflowCount
        )

        // Bring the 64bit unsigned integer results together into a high and low 128bit unsigned integer result.
        return (
            high: Self(
                _low: lowerUpperBits.truncatedValue,
                _high: upperUpperBits.truncatedValue
            ),
            low: Self(
                _low: lowerLowerBits.truncatedValue,
                _high: upperLowerBits.truncatedValue
            )
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
