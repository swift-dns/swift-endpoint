extension UnsignedInt128: Strideable {
    public typealias Stride = Int

    @inlinable
    public func distance(to other: UnsignedInt128) -> Int {
        let diff = other > self ? other - self : self - other
        let sign = other > self ? 1 : -1
        precondition(
            diff._high == 0,
            "Distance between \(self) and \(other) is too large to represent as an Int"
        )
        return sign * Int(diff._low)
    }

    @inlinable
    public func advanced(by n: Int) -> UnsignedInt128 {
        self + UnsignedInt128(n)
    }
}
