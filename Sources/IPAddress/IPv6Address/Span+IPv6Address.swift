@available(SwiftStdlib 5.1, *)
extension IPv6Address {
    /// Initialize an `IPv6Address` from the 16 bytes representing it.
    public init?(from span: Span<UInt8>) {
        guard span.count >= 16 else {
            return nil
        }

        unsafe self.init(
            UnsignedInteger128(
                _low: UInt64(span[unchecked: 8]) &<< 56
                    | UInt64(span[unchecked: 9]) &<< 48
                    | UInt64(span[unchecked: 10]) &<< 40
                    | UInt64(span[unchecked: 11]) &<< 32
                    | UInt64(span[unchecked: 12]) &<< 24
                    | UInt64(span[unchecked: 13]) &<< 16
                    | UInt64(span[unchecked: 14]) &<< 8
                    | UInt64(span[unchecked: 15]),
                _high: UInt64(span[unchecked: 0]) &<< 56
                    | UInt64(span[unchecked: 1]) &<< 48
                    | UInt64(span[unchecked: 2]) &<< 40
                    | UInt64(span[unchecked: 3]) &<< 32
                    | UInt64(span[unchecked: 4]) &<< 24
                    | UInt64(span[unchecked: 5]) &<< 16
                    | UInt64(span[unchecked: 6]) &<< 8
                    | UInt64(span[unchecked: 7])
            )
        )
    }

    /// Encode the address into the provided span.
    /// Returns true if the address was encoded successfully, false otherwise.
    public func encode(into span: inout OutputSpan<UInt8>) -> Bool {
        guard span.freeCapacity >= 16 else {
            return false
        }

        let hi = self.address._high
        let lo = self.address._low
        span.append(UInt8(truncatingIfNeeded: hi &>> 56))
        span.append(UInt8(truncatingIfNeeded: hi &>> 48))
        span.append(UInt8(truncatingIfNeeded: hi &>> 40))
        span.append(UInt8(truncatingIfNeeded: hi &>> 32))
        span.append(UInt8(truncatingIfNeeded: hi &>> 24))
        span.append(UInt8(truncatingIfNeeded: hi &>> 16))
        span.append(UInt8(truncatingIfNeeded: hi &>> 8))
        span.append(UInt8(truncatingIfNeeded: hi))
        span.append(UInt8(truncatingIfNeeded: lo &>> 56))
        span.append(UInt8(truncatingIfNeeded: lo &>> 48))
        span.append(UInt8(truncatingIfNeeded: lo &>> 40))
        span.append(UInt8(truncatingIfNeeded: lo &>> 32))
        span.append(UInt8(truncatingIfNeeded: lo &>> 24))
        span.append(UInt8(truncatingIfNeeded: lo &>> 16))
        span.append(UInt8(truncatingIfNeeded: lo &>> 8))
        span.append(UInt8(truncatingIfNeeded: lo))

        return true
    }
}
