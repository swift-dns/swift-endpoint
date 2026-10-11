@available(SwiftStdlib 5.1, *)
extension Port {
    /// Initialize a `Port` by parsing the 2 bytes representing it, in network byte order.
    @inlinable
    public init?(parsing span: Span<UInt8>) {
        guard span.count >= 2 else {
            return nil
        }

        self.init(
            rawValue: UInt16(span[0]) << 8
                | UInt16(span[1])
        )
    }

    /// Serialize the port into the provided span, in network byte order.
    /// Returns true if the port was serialized successfully, false otherwise.
    @inlinable
    public func serialize(into span: inout OutputSpan<UInt8>) -> Bool {
        guard span.freeCapacity >= 2 else {
            return false
        }

        /// Currently these multiple appends result in code containing a trap for each append.
        /// This is solved in the PR below, which hopefully will make it to Swift 6.5.
        /// The PR enables LLVM to correctly identify span-count bounds and notice that we already
        /// have 1 `freeCapacity` check, so it can get rid of the per-append traps.
        /// See https://github.com/swiftlang/swift/pull/92790.
        span.append(UInt8(truncatingIfNeeded: self.rawValue >> 8))
        span.append(UInt8(truncatingIfNeeded: self.rawValue))

        return true
    }
}
