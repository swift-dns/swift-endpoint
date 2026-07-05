@available(SwiftStdlib 5.1, *)
extension IPv6Address {
    /// Calls `body` with a pointer to a null-terminated C string of this address's textual
    /// representation. For example `IPv6Address(0x2001, 0x0DB8, 0, 0, 0, 0, 0, 1)`
    /// results in the C string `"2001:db8::1"`.
    ///
    /// Unlike `description`, the textual representation is **not** enclosed in square brackets,
    /// because that is the presentation format expected by C APIs, which reject the bracketed form.
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
        try unsafe self.makeDescription(
            enclosingInSquareBrackets: false
        ) { (maxWriteableBytes, writeBytes) in
            try withUnsafeTemporaryAllocation(
                of: UInt8.self,
                /// 1 extra byte for the null terminator.
                capacity: maxWriteableBytes &+ 1
            ) { buffer in
                let count = unsafe writeBytes(buffer)
                unsafe buffer[count] = 0
                return try unsafe buffer.withMemoryRebound(to: CChar.self) { cBuffer in
                    let range = unsafe ClosedRange<Int>(uncheckedBounds: (0, count))
                    let limitedSpan = unsafe cBuffer.span.extracting(unchecked: range)
                    return try body(limitedSpan)
                }
            }
        }
    }

    /// Initialize an IPv6 address from a null-terminated C string of its textual representation.
    /// For example `"2001:db8:1111::"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    ///
    /// This is useful for interoperability with C APIs that produce null-terminated strings.
    ///
    /// Parameters:
    /// - `cString`: A pointer to a null-terminated C string of the address's textual representation.
    @inlinable
    public init?(cString: UnsafePointer<CChar>) {
        let length = unsafe CCalls.c_strlen(cString)
        let buffer = unsafe UnsafeBufferPointer(start: cString, count: length)
        let result = unsafe buffer.withMemoryRebound(to: UInt8.self) {
            IPv6Address(textualRepresentation: unsafe $0.span)
        }
        guard let result else {
            return nil
        }
        self = result
    }
}
