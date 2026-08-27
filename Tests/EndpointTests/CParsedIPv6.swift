import CSwiftEndpoint
import Endpoint

/// The C parser behind `IPv6Address(_ description: StaticString)`.
/// That initializer only takes literals, this takes anything, so the C parser can be pinned
/// against the Swift one everywhere the Swift one is tested.
@available(SwiftStdlib 5.1, *)
func cParsedIPv6(_ bytes: [UInt8]) -> IPv6Address? {
    let result = unsafe bytes.withUnsafeBufferPointer {
        unsafe cswift_endpoint_slow_static_parse_ipv6($0.baseAddress, $0.count)
    }
    guard result.ok else {
        return nil
    }
    return IPv6Address(UnsignedInteger128(_low: result.lo, _high: result.hi))
}

@available(SwiftStdlib 5.1, *)
func cParsedIPv6(_ string: some StringProtocol) -> IPv6Address? {
    cParsedIPv6(Array(string.utf8))
}
