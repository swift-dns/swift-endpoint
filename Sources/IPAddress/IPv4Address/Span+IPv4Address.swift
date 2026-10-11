@available(SwiftStdlib 5.1, *)
extension IPv4Address {
    /// Initialize an `IPv4Address` by parsing the 4 bytes representing it.
    @inlinable
    public init?(parsing span: Span<UInt8>) {
        guard span.count >= 4 else {
            return nil
        }

        self.init(
            UInt32(span[0]) << 24
                | UInt32(span[1]) << 16
                | UInt32(span[2]) << 8
                | UInt32(span[3])
        )
    }

    /// Serialize the address into the provided span.
    /// Returns true if the address was serialized successfully, false otherwise.
    @inlinable
    public func serialize(into span: inout OutputSpan<UInt8>) -> Bool {
        guard span.freeCapacity >= 4 else {
            return false
        }

        let address = self.asUInt32(byteOrder: .bigEndian)
        /// Currently these multiple appends result in code containing a trap for each append.
        /// This is solved in the PR below, which hopefully will make it to Swift 6.5.
        /// The PR enables LLVM to correctly identify span-count bounds and notice that we already
        /// have 1 `freeCapacity` check, so it can get rid of the per-append traps.
        /// See https://github.com/swiftlang/swift/pull/92790.
        span.append(UInt8(truncatingIfNeeded: address))
        span.append(UInt8(truncatingIfNeeded: address >> 8))
        span.append(UInt8(truncatingIfNeeded: address >> 16))
        span.append(UInt8(truncatingIfNeeded: address >> 24))

        return true
    }
}
