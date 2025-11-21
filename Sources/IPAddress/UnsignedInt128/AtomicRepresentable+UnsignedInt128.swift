public import protocol Synchronization.AtomicRepresentable

@available(swiftEndpointApplePlatforms 15, *)
extension UnsignedInt128: AtomicRepresentable {
    public typealias AtomicRepresentation = UInt128

    @inlinable
    public static func encodeAtomicRepresentation(_ value: consuming Self) -> UInt128 {
        UInt128(value)
    }

    @inlinable
    public static func decodeAtomicRepresentation(_ storage: consuming UInt128) -> Self {
        Self(storage)
    }
}
