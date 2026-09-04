@available(SwiftStdlib 5.1, *)
extension IPv6Address {
    /// Initialize an `IPv6Address` by parsing the 16 bytes representing it.
    @inlinable
    public init?(parsing span: Span<UInt8>) {
        guard span.count >= 16 else {
            return nil
        }

        self.init(
            UnsignedInteger128(
                _low: UInt64(span[8]) &<< 56
                    | UInt64(span[9]) &<< 48
                    | UInt64(span[10]) &<< 40
                    | UInt64(span[11]) &<< 32
                    | UInt64(span[12]) &<< 24
                    | UInt64(span[13]) &<< 16
                    | UInt64(span[14]) &<< 8
                    | UInt64(span[15]),
                _high: UInt64(span[0]) &<< 56
                    | UInt64(span[1]) &<< 48
                    | UInt64(span[2]) &<< 40
                    | UInt64(span[3]) &<< 32
                    | UInt64(span[4]) &<< 24
                    | UInt64(span[5]) &<< 16
                    | UInt64(span[6]) &<< 8
                    | UInt64(span[7])
            )
        )
    }

    /// Serialize the address into the provided span.
    /// Returns true if the address was serialized successfully, false otherwise.
    @inlinable
    public func serialize(into span: inout OutputSpan<UInt8>) -> Bool {
        guard span.freeCapacity >= 16 else {
            return false
        }

        let hi = self._address._high
        let lo = self._address._low
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
