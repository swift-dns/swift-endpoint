@available(SwiftStdlib 6.0, *)
extension UnsignedInteger128: UnsignedInteger {}

/// UnsignedInteger conformance
extension UnsignedInteger128 {
    public typealias Magnitude = Self

    @inlinable
    public var magnitude: Magnitude {
        self
    }

    @inlinable
    public static var isSigned: Bool {
        false
    }
}
