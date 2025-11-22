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
    public func dividingFullWidth(
        _ dividend: (high: Self, low: Self.Magnitude)
    ) -> (quotient: Self, remainder: Self) {
        // Validate preconditions to guarantee that the quotient is representable.
        precondition(self != .zero, "Division by zero")
        precondition(dividend.high < self, "dividend.high must be smaller than the divisor")
        // UnsignedInteger should have a Magnitude = Self constraint, but does not,
        // so we have to do this conversion (we can't easily add the constraint
        // because it changes how generic signatures constrained to
        // <FixedWidth & Unsigned> are minimized, which changes the mangling).
        // In practice, "every" UnsignedInteger type will satisfy this, and if one
        // somehow manages not to in a way that would break this conversion then
        // a default implementation of this method never could have worked anyway.
        let low = dividend.low

        // The basic algorithm is taken from Knuth (TAoCP, Vol 2, §4.3.1), using
        // words that are half the size of Self (so the dividend has four words
        // and the divisor has two). The fact that the denominator has exactly
        // two words allows for a slight simplification vs. Knuth's Algorithm D,
        // in that our computed quotient digit is always exactly right, while
        // in the more general case it can be one too large, requiring a subsequent
        // borrow.
        //
        // Knuth's algorithm (and any long division, really), requires that the
        // divisor (self) be normalized (meaning that the high-order bit is set).
        // We begin by counting the leading zeros so we know how many bits we
        // have to shift to normalize.
        let lz = leadingZeroBitCount

        // If the divisor is actually a power of two, division is just a shift,
        // which we can handle much more efficiently. So we do a check for that
        // case and early-out if possible.
        let _1 = Self(_low: 1, _high: 0)
        if (self &- _1) & self == .zero {
            let shift = Self.bitWidth - 1 - lz
            let q = low &>> shift | dividend.high &<< -shift
            let r = low & (self &- _1)
            return (q, r)
        }

        // Shift the divisor left by lz bits to normalize it. We shift the
        // dividend left by the same amount so that we get the quotient is
        // preserved (we will have to shift right to recover the remainder).
        // Note that the right shift `low >> (Self.bitWidth - lz)` is
        // deliberately a non-masking shift because lz might be zero.
        let v = self &<< lz
        let uh = dividend.high &<< lz | low >> (Self.bitWidth - lz)
        let ul = low &<< lz

        // Now we have a normalized dividend (uh:ul) and divisor (v). Split
        // v into half-words (vh:vl) so that we can use the "normal" division
        // on Self as a word / halfword -> halfword division get one halfword
        // digit of the quotient at a time.
        let n_2 = Self.bitWidth / 2
        let mask = _1 &<< n_2 &- _1
        let vh = v &>> n_2
        let vl = v & mask

        // For the (fairly-common) special case where vl is zero, we can simplify
        // the arithmetic quite a bit:
        if vl == .zero {
            let qh = uh / vh
            let residual = (uh &- qh &* vh) &<< n_2 | ul &>> n_2
            let ql = residual / vh

            return (
                // Assemble quotient from half-word digits
                quotient: qh &<< n_2 | ql,
                // Compute remainder (we can re-use the residual to make this simpler).
                remainder: ((residual &- ql &* vh) &<< n_2 | ul & mask) &>> lz
            )
        }
        // Helper function: performs a (1½ word)/word division to produce a
        // half quotient word q. We'll need to use this twice to generate the
        // full quotient.
        //
        // high is the high word of the quotient for this sub-division.
        // low is the low half-word of the quotient for this sub-division (the
        //     high half of low must be zero).
        //
        // returns the quotient half-word digit. In a more general setting, this
        // computed digit might be one too large, which has to be accounted for
        // later on (see Knuth, Algorithm D), but when the divisor is only two
        // half-words (as here), that can never happen, because we use the full
        // divisor in the check for the while loop.
        func generateHalfDigit(high: Self, low: Self) -> Self {
            // Get q̂ satisfying a = vh q̂ + r̂ with 0 ≤ r̂ < vh:
            var (q̂, r̂) = high.quotientAndRemainder(dividingBy: vh)
            // Knuth's "Theorem A" establishes that q̂ is an approximation to
            // the quotient digit q, satisfying q ≤ q̂ ≤ q + 2. We adjust it
            // downward as needed until we have the correct q.
            while q̂ > mask || q̂ &* vl > (r̂ &<< n_2 | low) {
                q̂ &-= _1
                r̂ &+= vh
                if r̂ > mask { break }
            }
            return q̂
        }

        // Generate the first quotient digit, subtract off its product with the
        // divisor to generate the residual, then compute the second quotient
        // digit from that.
        let qh = generateHalfDigit(high: uh, low: ul &>> n_2)
        let residual = (uh &<< n_2 | ul &>> n_2) &- (qh &* v)
        let ql = generateHalfDigit(high: residual, low: ul & mask)

        return (
            // Assemble quotient from half-word digits
            quotient: qh &<< n_2 | ql,
            // Compute remainder (we can re-use the residual to make this simpler).
            remainder: ((residual &<< n_2 | ul & mask) &- (ql &* v)) &>> lz
        )
    }

    /// Returns the bit stored at the given position for the provided double width UInt128 input.
    ///
    /// - parameter at: position to grab bit value from.
    /// - parameter for: the double width UInt128 data value to grab the
    ///   bit from.
    /// - returns: single bit stored in a UInt128 value.
    @inlinable
    static func _bitFromDoubleWidth(
        at bitPosition: Int,
        for input: (high: Self, low: Self)
    ) -> Self {
        let _1 = Self(_low: 1, _high: 0)
        switch bitPosition {
        case 0:
            return input.low & _1
        case 1...127:
            return input.low >> bitPosition & _1
        case 128:
            return input.high & _1
        default:
            let _128 = Self(_low: 128, _high: 0)
            let bitPosition = Self(_low: UInt64(bitPosition), _high: 0)
            let shift = bitPosition - _128
            return input.high >> shift & _1
        }
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

    @inlinable
    public init(bigEndian value: Self) {
        #if _endian(big)
        self = value
        #else
        self = value.byteSwapped
        #endif
    }

    @inlinable
    public var littleEndian: Self {
        #if _endian(little)
        return self
        #else
        return byteSwapped
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
