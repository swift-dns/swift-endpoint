@available(SwiftStdlib 5.1, *)
extension AnyIPAddress {
    /// Calls `body` with a pointer to a null-terminated C string of this address's textual
    /// representation. The `v4` case is formatted in dot-decimal notation, and the `v6` case is
    /// formatted in the bracket-less presentation format.
    ///
    /// The textual representation is in the presentation format expected by C APIs.
    ///
    /// Parameters:
    /// - `body`: A closure that allows access to a `Span<CChar>` of the address's textual representation.
    ///    You can use `span.withUnsafeBufferPointer { $0.baseAddress! /*UnsafePointer<CChar>*/ }` on the
    ///    span if you need to, for C interoperability.
    /// - Returns: The result of the closure.
    @inlinable
    public func withCString<Result, E: Error>(
        _ body: (Span<CChar>) throws(E) -> Result
    ) throws(E) -> Result {
        switch self {
        case .v4(let ipv4):
            return try ipv4.withCString(body)
        case .v6(let ipv6):
            return try ipv6.withCString(body)
        }
    }

    /// Initialize an IP address from a null-terminated C string of its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"2001:db8:1111::"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    ///
    /// This is useful for interoperability with C APIs that produce null-terminated strings.
    ///
    /// Parameters:
    /// - `cString`: A pointer to a null-terminated C string of the address's textual representation.
    @inlinable
    public init?(cString: UnsafePointer<CChar>) {
        let length = unsafe UTF8._nullCodeUnitOffset(in: cString)
        let buffer = unsafe UnsafeBufferPointer(start: cString, count: length)
        let result = unsafe buffer.withMemoryRebound(to: UInt8.self) {
            AnyIPAddress(textualRepresentation: unsafe $0.span)
        }
        guard let result else {
            return nil
        }
        self = result
    }
}
