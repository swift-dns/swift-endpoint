@available(SwiftStdlib 5.1, *)
extension IPv4Address {
    /// Calls `body` with a pointer to a null-terminated C string of this address's textual
    /// representation, in dot-decimal notation. For example `IPv4Address(127, 0, 0, 1)` results
    /// in the C string `"127.0.0.1"`.
    ///
    /// The textual representation is in the presentation format expected by C APIs.
    ///
    /// Parameters:
    /// - `body`: A closure that allows access to a `Span<CChar>` of the address's textual representation.
    ///    You can use `span.withUnsafeBufferPointer { $0.baseAddress! /*UnsafePointer<CChar>*/ }` on the
    ///    span if you need to, for C interoperability.
    /// - Returns: The result of the closure.
    @inlinable
    public func withCString<Result>(
        _ body: (Span<CChar>) throws -> Result
    ) rethrows -> Result {
        /// 15 bytes for the biggest possible textual representation, plus 1 for the null terminator.
        try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 16) { buffer in
            let count = self.writeTextualRepresentation(into: buffer)
            buffer[count] = 0
            return try unsafe buffer.withMemoryRebound(to: CChar.self) { cBuffer in
                let range = ClosedRange<Int>(uncheckedBounds: (0, count))
                let limitedSpan = cBuffer.span.extracting(unchecked: range)
                return try body(limitedSpan)
            }
        }
    }

    /// Initialize an IPv4 address from a null-terminated C string of its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    ///
    /// This is useful for interoperability with C APIs that produce null-terminated strings.
    ///
    /// Parameters:
    /// - `cString`: A pointer to a null-terminated C string of the address's textual representation.
    @inlinable
    public init?(cString: UnsafePointer<CChar>) {
        let length = CCalls.c_strlen(cString)
        let buffer = UnsafeBufferPointer(start: cString, count: length)
        let result = buffer.withMemoryRebound(to: UInt8.self) {
            IPv4Address(textualRepresentation: $0.span)
        }
        guard let result else {
            return nil
        }
        self = result
    }
}
