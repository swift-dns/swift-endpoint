import CSwiftEndpoint
import Endpoint

/// The C parser behind `IPv6Address(stringLiteral:)`, with the embedded IPv4 address parsed by
/// the Swift parser the same way that initializer does.
/// That initializer only takes literals, this takes anything, so the C parser can be pinned
/// against the Swift one everywhere the Swift one is tested.
@available(SwiftStdlib 5.1, *)
func cParsedIPv6(_ bytes: [UInt8]) -> IPv6Address? {
    let result = bytes.withUnsafeBufferPointer {
        unsafe cswift_endpoint_slow_static_parse_ipv6($0.baseAddress, $0.count)
    }
    guard result.ok else {
        return nil
    }
    var low = result.lo
    if result.ipv4Count > 0 {
        let ipv4 = bytes[result.ipv4Start..<(result.ipv4Start + result.ipv4Count)]
            .withUnsafeBufferPointer { unsafe IPv4Address(textualRepresentation: $0.span) }
        guard let ipv4 else {
            return nil
        }
        low |= UInt64(ipv4.asUInt32())
    }
    return IPv6Address(UnsignedInteger128(_low: low, _high: result.hi))
}

@available(SwiftStdlib 5.1, *)
func cParsedIPv6(_ string: some StringProtocol) -> IPv6Address? {
    cParsedIPv6(Array(string.utf8))
}
