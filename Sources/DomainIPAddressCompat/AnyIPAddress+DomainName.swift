public import Domain
public import IPAddress

import struct NIOCore.ByteBuffer

@available(SwiftStdlib 5.1, *)
extension DomainName {
    /// Initialize an `DomainName` from a `AnyIPAddress`.
    ///
    /// For ipv4, the address will follow the format specified in [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://datatracker.ietf.org/doc/html/rfc1035#section-3.5).
    /// For ipv6, the address will follow the format specified in [RFC 3596, DNS Extensions to Support IP Version 6, October 2003](https://datatracker.ietf.org/doc/html/rfc3596#section-2.5).
    ///
    /// For example an IPv4Address like `1.2.3.4` will turn into the domain name `"4.3.2.1.in-addr.arpa"`.
    /// Or an IPv6Address like `[4321:0:1:2:3:4:567:89ab]` will turn into the
    /// domain name `"b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa."`.
    @inlinable
    public init(ip: AnyIPAddress) {
        switch ip {
        case .v4(let ipv4):
            self.init(ipv4: ipv4, format: .arpa)
        case .v6(let ipv6):
            self.init(ipv6: ipv6)
        }
    }
}
