@available(SwiftStdlib 5.1, *)
extension Port {
    /// Initialize a `Port` by parsing the 2 bytes representing it, in network byte order.
    public init?(parsing span: Span<UInt8>) {
        guard span.count >= 2 else {
            return nil
        }

        self.init(
            canonicalValue: UInt16(span[0]) &<< 8
                | UInt16(span[1])
        )
    }

    /// Serialize the port into the provided span, in network byte order.
    /// Returns true if the port was serialized successfully, false otherwise.
    public func serialize(into span: inout OutputSpan<UInt8>) -> Bool {
        guard span.freeCapacity >= 2 else {
            return false
        }

        span.append(UInt8(truncatingIfNeeded: self.canonicalValue &>> 8))
        span.append(UInt8(truncatingIfNeeded: self.canonicalValue))

        return true
    }
}
