@available(swiftEndpointApplePlatforms 15, *)
extension UnsignedInt128: UnsignedInteger {}

extension UnsignedInt128 /*: UnsignedInteger*/ {
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
