@available(SwiftStdlib 6.0, *)
extension UnsignedInt128: Numeric {}

/// Numeric conformance
extension UnsignedInt128 {
    @inlinable
    public init?(exactly source: some BinaryInteger) {
        guard let high = UInt64(exactly: source >> 64) else { return nil }
        let low = UInt64(truncatingIfNeeded: source)
        self.init(_low: low, _high: high)
    }

    @inlinable
    public init(_ source: some BinaryInteger) {
        guard let value = Self(exactly: source) else {
            fatalError(
                "value cannot be converted to UnsignedInt128 because it is outside the representable range"
            )
        }
        self = value
    }

    @inlinable
    public static func * (lhs: Self, rhs: Self) -> Self {
        let (partialValue, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow, "\(lhs) * \(rhs) overflows by \(partialValue)")
        return partialValue
    }

    @inlinable
    public static func &* (lhs: Self, rhs: Self) -> Self {
        let (partialValue, _) = lhs.multipliedReportingOverflow(by: rhs)
        return partialValue
    }

    @inlinable
    public static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    @inlinable
    public static func &*= (lhs: inout Self, rhs: Self) {
        lhs = lhs &* rhs
    }
}
