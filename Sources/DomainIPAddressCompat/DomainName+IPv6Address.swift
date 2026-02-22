public import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 10.15, *)
extension IPv6Address {
    /// Initialize an `IPv6Address` from a `DomainName` which is in the special arpa domain name format,
    /// according to [RFC 3596, DNS Extensions to Support IP Version 6, October 2003](https://tools.ietf.org/html/rfc3596#section-2.5).
    ///
    /// The domain name must contain exactly 32 hexadecimal integer labels containing the ipv6 address's value in reverse,
    /// followed by `ipv6.arpa`.
    /// For example a domain name like `"b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa."` will
    /// parse into the IPv6 address `[4321:0:1:2:3:4:567:89ab]`.
    ///
    /// For `IPv6Address`, currently this initializer is identical to `init(arpaDomainName:)` and
    /// is only provided for consistency with `IPv4Address` and `AnyIPAddress`.
    @inlinable
    public init?(domainName: DomainName) {
        self.init(arpaDomainName: domainName)
    }

    /// Initialize an `IPv6Address` from a `DomainName` which is in the special arpa domain name format,
    /// according to [RFC 3596, DNS Extensions to Support IP Version 6, October 2003](https://tools.ietf.org/html/rfc3596#section-2.5).
    ///
    /// The domain name must contain exactly 32 hexadecimal integer labels containing the ipv6 address's value in reverse,
    /// followed by `ipv6.arpa`.
    /// For example a domain name like `"b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa."` will
    /// parse into the IPv6 address `[4321:0:1:2:3:4:567:89ab]`.
    @inlinable
    public init?(arpaDomainName domainName: DomainName) {
        guard
            let result = domainName._data.withUnsafeReadableBytes({ ptr -> IPv6Address? in
                ptr.withMemoryRebound(to: UInt8.self) { ptr -> IPv6Address? in
                    var ipv6 = IPv6Address(.zero)
                    var iterator = domainName.makePositionIterator()

                    /// `DomainName.data` always only contains ASCII bytes
                    let asciiSpan = ptr.span

                    for idx in 0..<32 {
                        guard
                            let labelPosition = iterator.next(),
                            labelPosition.length == 1,
                            let byte = UInt8.mapHexadecimalByteToUInt8(
                                asciiSpan[unchecked: labelPosition.startIndex]
                            )
                        else {
                            return nil
                        }
                        let shift = 4 &* idx
                        ipv6.address |= UnsignedInt128(byte) &<< shift
                    }

                    guard let ip6Range = iterator.next()?.range,
                        let arpaRange = iterator.next()?.range,
                        iterator.reachedEnd()
                    else {
                        return nil
                    }

                    let ip6 = asciiSpan.extracting(unchecked: ip6Range)
                    let arpa = asciiSpan.extracting(unchecked: arpaRange)
                    let ip6Bytes = [
                        UInt8(ascii: "i"), UInt8(ascii: "p"), UInt8(ascii: "6"),
                    ]
                    let arpaBytes = [
                        UInt8(ascii: "a"), UInt8(ascii: "r"), UInt8(ascii: "p"), UInt8(ascii: "a"),
                    ]
                    guard ip6.swift_endpoint_equals(to: ip6Bytes),
                        arpa.swift_endpoint_equals(to: arpaBytes)
                    else {
                        return nil
                    }

                    return ipv6
                }
            })
        else {
            return nil
        }

        self = result
    }
}
