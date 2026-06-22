#if canImport(Darwin)
@usableFromInline
package typealias _CompatibilityUInt128Typealias = UnsignedInteger128
#else
@usableFromInline
package typealias _CompatibilityUInt128Typealias = UInt128
#endif
