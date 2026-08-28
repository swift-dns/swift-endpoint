@available(SwiftStdlib 5.1, *)
extension Port {
    /// Calls `body` with a pointer to a null-terminated C string of this port's textual
    /// representation, in decimal notation. For example `Port(8080)` results in the C
    /// string `"8080"`.
    ///
    /// The textual representation is in the presentation format expected by C APIs.
    ///
    /// Parameters:
    /// - `body`: A closure that allows access to a `Span<CChar>` of the port's textual representation.
    ///    You can use `span.withUnsafeBufferPointer { $0.baseAddress! /*UnsafePointer<CChar>*/ }` on the
    ///    span if you need to, for C interoperability.
    /// - Returns: The result of the closure.
    @inlinable
    public func withCString<Result, E: Error>(
        _ body: (Span<CChar>) throws(E) -> Result
    ) throws(E) -> Result {
        /// 8 bytes for the biggest possible textual representation (5) plus its write headroom (3).
        /// The null terminator goes at index 5 at the most, so it needs no extra room.
        try withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer throws(E) in
            let count = unsafe self.writeTextualRepresentation_RequiringMinimumCapacityOf8(
                into: buffer
            )
            unsafe buffer[count] = 0
            return try unsafe buffer.withMemoryRebound(to: CChar.self) { cBuffer throws(E) in
                let range = unsafe ClosedRange<Int>(uncheckedBounds: (0, count))
                let limitedSpan = unsafe cBuffer.span.extracting(unchecked: range)
                return try body(limitedSpan)
            }
        }
    }

    /// Initialize a `Port` from a null-terminated C string of its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    ///
    /// This is useful for interoperability with C APIs that produce null-terminated strings.
    ///
    /// Parameters:
    /// - `cString`: A pointer to a null-terminated C string of the port's textual representation.
    @inlinable
    public init?(cString: UnsafePointer<CChar>) {
        let length = unsafe UTF8._nullCodeUnitOffset(in: cString)
        let buffer = unsafe UnsafeBufferPointer(start: cString, count: length)
        let result = unsafe buffer.withMemoryRebound(to: UInt8.self) {
            Port(textualRepresentation: unsafe $0.span)
        }
        guard let result else {
            return nil
        }
        self = result
    }
}
