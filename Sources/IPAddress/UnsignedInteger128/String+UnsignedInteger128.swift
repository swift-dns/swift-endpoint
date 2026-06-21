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
        return String(unsafeUninitializedCapacity_Compatibility: toReserve) { buffer in
            var idx = toReserve
            repeat {
                let tenth = value / _10
                let remainder = value &- (tenth &* _10)
                idx &-= 1
                buffer[idx] = UInt8(remainder._low) &+ UInt8.ascii0
                value = tenth
            } while value != .zero

            /// `approximation` can over-reserve by one, leaving a leading gap. Close
            /// it so the initialized digits start at offset 0 and the returned count
            /// covers only initialized bytes. `memmove` handles the overlap.
            let count = toReserve &- idx
            if idx != 0 {
                let base = buffer.baseAddress.unsafelyUnwrapped
                CCalls.c_memmove(base, base + idx, count)
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
        var result = Self.zero
        var iterator = span.indices.makeIterator()
        let lastIndex = span.count - 1

        if iterator.next() != nil {
            let byte = span[unchecked: lastIndex]
            guard let number = UInt8.mapUTF8ByteToUInt8(byte) else {
                return nil
            }
            result = UnsignedInteger128(number)
        }

        var multiplier = UnsignedInteger128(_low: 1, _high: 0)
        let _10 = Self(_low: 10, _high: 0)

        while let idx = iterator.next() {
            multiplier &*= _10
            let reversedIdx = lastIndex &- idx
            let byte = span[unchecked: reversedIdx]
            guard let number = UInt8.mapUTF8ByteToUInt8(byte) else {
                return nil
            }
            result += UnsignedInteger128(number) &* multiplier
        }

        return result
    }
}
