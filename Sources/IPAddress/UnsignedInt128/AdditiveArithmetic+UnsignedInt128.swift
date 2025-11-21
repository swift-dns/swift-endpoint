extension UnsignedInt128: AdditiveArithmetic {
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        let (partialValue, overflow) = lhs.addingReportingOverflow(rhs)
        precondition(!overflow, "\(lhs) + \(rhs) overflows by \(partialValue)")
        return partialValue
    }

    @inlinable
    public static func &+ (lhs: Self, rhs: Self) -> Self {
        let (partialValue, _) = lhs.addingReportingOverflow(rhs)
        return partialValue
    }

    @inlinable
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    @inlinable
    public static func &+= (lhs: inout Self, rhs: Self) {
        lhs = lhs &+ rhs
    }

    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        let (partialValue, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow, "\(lhs) - \(rhs) overflows by \(partialValue)")
        return partialValue
    }

    @inlinable
    public static func &- (lhs: Self, rhs: Self) -> Self {
        let (partialValue, _) = lhs.subtractingReportingOverflow(rhs)
        return partialValue
    }

    @inlinable
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    @inlinable
    public static func &-= (lhs: inout Self, rhs: Self) {
        lhs = lhs &- rhs
    }
}
