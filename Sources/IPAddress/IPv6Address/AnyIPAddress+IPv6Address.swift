@available(SwiftStdlib 5.1, *)
extension IPv6Address {
    /// The exact translation of an `AnyIPAddress` to an `IPv4Address`.
    ///
    /// This intentionally does not handle ipv4-embedded ipv6 addresses.
    /// Use `IPv4Address.asIPv4MappedIPv6` or
    /// `IPv4Address.asNAT64WellKnownIPv4EmbeddedIPv6` for that.
    @available(SwiftStdlib 5.1, *)
    public init?(exactly ipAddress: AnyIPAddress) {
        guard let ipv6 = ipAddress.ipv6Value else {
            return nil
        }
        self = ipv6
    }
}
