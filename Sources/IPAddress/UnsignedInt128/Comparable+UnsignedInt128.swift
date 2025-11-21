extension UnsignedInt128: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs._high == rhs._high {
            return lhs._low < rhs._low
        }
        return lhs._high < rhs._high
    }

    @inlinable
    public static func <= (lhs: Self, rhs: Self) -> Bool {
        if lhs._high == rhs._high {
            return lhs._low <= rhs._low
        }
        return lhs._high <= rhs._high
    }

    @inlinable
    public static func > (lhs: Self, rhs: Self) -> Bool {
        rhs < lhs
    }

    @inlinable
    public static func >= (lhs: Self, rhs: Self) -> Bool {
        rhs <= lhs
    }
}
