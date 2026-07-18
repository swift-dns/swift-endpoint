@available(SwiftStdlib 5.1, *)
extension Span<UInt8> {
    /// Whether the span contains exactly the same bytes as `bytes`.
    ///
    /// `@_transparent` so it's inlined for when `[UInt8]` is a static array.
    @inlinable
    @_transparent
    package func swift_endpoint_equals(to bytes: [UInt8]) -> Bool {
        let count = bytes.count
        guard self.count == count else {
            return false
        }
        if count == 0 {
            return true
        }

        return self.withUnsafeBytes { lhsBuffer in
            bytes.withUnsafeBytes { rhsBuffer in
                /// Both are non-nil because `count` is non-zero at this point.
                let lhs = unsafe lhsBuffer.baseAddress.unsafelyUnwrapped
                let rhs = unsafe rhsBuffer.baseAddress.unsafelyUnwrapped
                var differenceBits: UInt64 = 0

                /// Try to compare the bytes with as few loads as possible
                if count >= 8 {
                    var idx = 0
                    while idx &+ 8 < count {
                        differenceBits |=
                            unsafe lhs.loadUnaligned(fromByteOffset: idx, as: UInt64.self)
                            ^ rhs.loadUnaligned(fromByteOffset: idx, as: UInt64.self)
                        idx &+= 8
                    }
                    let finalIdx = count &- 8
                    differenceBits |=
                        unsafe lhs.loadUnaligned(fromByteOffset: finalIdx, as: UInt64.self)
                        ^ rhs.loadUnaligned(fromByteOffset: finalIdx, as: UInt64.self)
                } else if count >= 4 {
                    let finalIdx = count &- 4
                    differenceBits |= UInt64(
                        unsafe lhs.loadUnaligned(fromByteOffset: 0, as: UInt32.self)
                            ^ rhs.loadUnaligned(fromByteOffset: 0, as: UInt32.self)
                    )
                    differenceBits |= UInt64(
                        unsafe lhs.loadUnaligned(fromByteOffset: finalIdx, as: UInt32.self)
                            ^ rhs.loadUnaligned(fromByteOffset: finalIdx, as: UInt32.self)
                    )
                } else if count >= 2 {
                    let finalIdx = count &- 2
                    differenceBits |= UInt64(
                        unsafe lhs.loadUnaligned(fromByteOffset: 0, as: UInt16.self)
                            ^ rhs.loadUnaligned(fromByteOffset: 0, as: UInt16.self)
                    )
                    differenceBits |= UInt64(
                        unsafe lhs.loadUnaligned(fromByteOffset: finalIdx, as: UInt16.self)
                            ^ rhs.loadUnaligned(fromByteOffset: finalIdx, as: UInt16.self)
                    )
                } else {
                    differenceBits = UInt64(
                        unsafe lhs.loadUnaligned(fromByteOffset: 0, as: UInt8.self)
                            ^ rhs.loadUnaligned(fromByteOffset: 0, as: UInt8.self)
                    )
                }

                return differenceBits == 0
            }
        }
    }
}
