@available(swiftEndpointApplePlatforms 10.15, *)
extension UnsignedInt128: CustomStringConvertible {
    @inlinable
    public var description: String {
        /// Accurate approx amount of base-10 digits, based on the number of bits
        /// Simple logarithm trick:
        /// `2^x = 10^y` -> `x * log10(2) = y` -> `log10(2) = y / x` -> `0.301 ~= y / x`
        let significantBits = 128 - Double(self.leadingZeroBitCount)
        /// This could possibly be 1 more than needed
        let approximation = Int((significantBits * 301 / 1000).rounded(.up))
        let toReserve = Swift.max(approximation, 1)
        var value = self
        let _10 = Self(_low: 10, _high: 0)
        var idx = toReserve &- 1
        var string = String(unsafeUninitializedCapacity_Compatibility: toReserve) { buffer in
            while value >= _10 {
                let tenth = value / _10
                let remainder = value &- (tenth &* _10)
                let digit = remainder._low
                let ascii = UInt8(digit) &+ UInt8.ascii0
                value = tenth
                buffer[idx] = ascii
                idx &-= 1
            }
            let ascii = UInt8(value._low) &+ UInt8.ascii0
            buffer[idx] = ascii
            idx &-= 1
            return toReserve - Swift.max(idx, 0)
        }
        if idx == 0 {
            string.removeFirst()
        }
        return string
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
            result = UnsignedInt128(number)
        }

        var multiplier = UnsignedInt128(_low: 1, _high: 0)

        while let idx = iterator.next() {
            multiplier &*= Self(_low: 10, _high: 0)
            let reversedIdx = lastIndex &- idx
            let byte = span[unchecked: reversedIdx]
            guard let number = UInt8.mapUTF8ByteToUInt8(byte) else {
                return nil
            }
            result += UnsignedInt128(number) &* multiplier
        }

        return result
    }
}
