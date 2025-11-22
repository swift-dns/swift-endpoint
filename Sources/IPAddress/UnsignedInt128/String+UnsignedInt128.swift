extension UnsignedInt128: CustomStringConvertible {
    @inlinable
    public var description: String {
        if self._high == 0 {
            return self._low.description
        }

        let lowDesc = self._low.description
        let highDesc = self._high.description
        let zeros = String(repeating: "0", count: 64 - lowDesc.count)
        return "\(highDesc)\(zeros)\(lowDesc)"
    }
}

@available(swiftEndpointApplePlatforms 13, *)
extension UnsignedInt128: LosslessStringConvertible {
    // @inlinable
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
            multiplier *= Self(_low: 10, _high: 0)
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
