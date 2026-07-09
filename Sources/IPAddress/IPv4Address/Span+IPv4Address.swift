@available(SwiftStdlib 5.1, *)
extension IPv4Address {
    /// Initialize an `IPv4Address` by parsing the 4 bytes representing it.
    public init?(parsing span: Span<UInt8>) {
        guard span.count >= 4 else {
            return nil
        }

        self.init(
            UInt32(span[0]) &<< 24
                | UInt32(span[1]) &<< 16
                | UInt32(span[2]) &<< 8
                | UInt32(span[3])
        )
    }

    /// Serialize the address into the provided span.
    /// Returns true if the address was serialized successfully, false otherwise.
    public func serialize(into span: inout OutputSpan<UInt8>) -> Bool {
        guard span.freeCapacity >= 4 else {
            return false
        }

        span.append(UInt8(truncatingIfNeeded: self.address &>> 24))
        span.append(UInt8(truncatingIfNeeded: self.address &>> 16))
        span.append(UInt8(truncatingIfNeeded: self.address &>> 8))
        span.append(UInt8(truncatingIfNeeded: self.address))

        return true
    }
}
