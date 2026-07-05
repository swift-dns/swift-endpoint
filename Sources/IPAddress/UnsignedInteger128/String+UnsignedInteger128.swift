@available(SwiftStdlib 5.1, *)
extension UnsignedInteger128: CustomStringConvertible {
    @inlinable
    public var description: String {
        /// Accurate approx amount of base-10 digits, based on the number of bits
        /// Simple logarithm trick:
        /// `2^x = 10^y` -> `x * log10(2) = y` -> `log10(2) = y / x` -> `0.301 ~= y / x`
        let significantBits = Double(128 - self.leadingZeroBitCount)
        /// This could possibly be 1 more than needed
        let approximation = Int((significantBits * 301 / 1000).rounded(.up))
        let toReserve = Swift.max(approximation, 1)
        var value = self
        let _10 = Self(_low: 10, _high: 0)
        return unsafe String(unsafeUninitializedCapacity_Compatibility: toReserve) { buffer in
            var idx = toReserve
            repeat {
                let tenth = value / _10
                let remainder = value &- (tenth &* _10)
                idx &-= 1
                unsafe buffer[idx] = UInt8(remainder._low) &+ UInt8.ascii0
                value = tenth
            } while value != .zero

            /// `approximation` can over-reserve by one, leaving a leading gap.
            /// Use `memmove` to close the gap if needed.
            let count = toReserve &- idx
            if idx != 0 {
                let base = unsafe buffer.baseAddress.unsafelyUnwrapped
                unsafe CCalls.c_memmove(base, base + idx, count)
            }
            return count
        }
    }

    public init?(_ description: String) {
        var description = description
        guard
            let result =
                description
                .withSpan_Compatibility(Self.parse(textualRepresentationSpan:))
        else {
            return nil
        }
        self = result
    }

    @inlinable
    static func parse(textualRepresentationSpan span: Span<UInt8>) -> Self? {
        let _10 = Self(_low: 10, _high: 0)
        var result = Self.zero

        var idx = 0
        while idx < span.count {
            let byte = unsafe span[unchecked: idx]
            guard let number = UInt8.mapUTF8ByteToUInt8(byte) else {
                return nil
            }
            result = result &* _10 &+ UnsignedInteger128(number)
            idx &+= 1
        }

        return result
    }
}
