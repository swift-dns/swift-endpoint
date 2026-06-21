public import Domain
public import IPAddress

public import struct NIOCore.ByteBuffer

@available(SwiftStdlib 5.1, *)
extension AnyIPAddress {
    /// Initialize an `AnyIPAddress` from a `DomainName` which is in the special arpa domain name format.
    /// For ipv4, the address must follow the format specified in [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035#section-3.5)
    /// or it must be a simple IPv4 Address encoded in dotted quad notation like `"127.0.0.1"`.
    /// For ipv6, the address must follow the format specified in [RFC 3596, DNS Extensions to Support IP Version 6, October 2003](https://tools.ietf.org/html/rfc3596#section-2.5).
    ///
    /// For example a domain name like `"4.3.2.1.in-addr.arpa"` will parse into the IPv4 address `1.2.3.4`.
    /// Or a domain name like `"127.0.0.1"` will parse into the IPv4 address `127.0.0.1`.
    /// Or a domain name like `"b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa."` will
    /// parse into the IPv6 address `[4321:0:1:2:3:4:567:89ab]`.
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result = domainName._data.withUnsafeReadableBytes({ ptr -> AnyIPAddress? in
                ptr.withMemoryRebound(to: UInt8.self) { ptr -> AnyIPAddress? in
                    var iterator = domainName.makePositionIterator()

                    /// `DomainName.data` always only contains ASCII bytes
                    let asciiSpan = ptr.span

                    for _ in 0..<4 {
                        guard iterator.next() != nil else {
                            return nil
                        }
                    }

                    /// If this is an IPv4, then the 5th label is always `in-addr`.
                    guard let identifierLabelRange = iterator.next()?.range else {
                        /// Can only be a simple IPv4 Address encoded in dotted quad notation like
                        /// `"127.0.0.1"` into the domain name.
                        return IPv4Address(domainName: domainName).map { .v4($0) }
                    }
                    let identifierLabel = asciiSpan.extracting(unchecked: identifierLabelRange)
                    let inAddrBytes = [
                        UInt8(ascii: "i"), UInt8(ascii: "n"), UInt8(ascii: "-"), UInt8(ascii: "a"),
                        UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "r"),
                    ]

                    /// If the 5th label is `in-addr`, then this can only be an IPv4.
                    if identifierLabel.swift_endpoint_equals(to: inAddrBytes) {
                        return IPv4Address(arpaDomainName: domainName).map { .v4($0) }
                    } else {
                        return IPv6Address(arpaDomainName: domainName).map { .v6($0) }
                    }
                }
            })
        else {
            return nil
        }

        self = result
    }

    /// Initialize an `AnyIPAddress` from a `DomainName` which is in the special arpa domain name format.
    /// For ipv4, the address must follow the format specified in [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035#section-3.5).
    /// For ipv6, the address must follow the format specified in [RFC 3596, DNS Extensions to Support IP Version 6, October 2003](https://tools.ietf.org/html/rfc3596#section-2.5).
    ///
    /// For example a domain name like `"4.3.2.1.in-addr.arpa"` will parse into the IPv4 address `1.2.3.4`.
    /// Or a domain name like `"b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa."` will
    /// parse into the IPv6 address `[4321:0:1:2:3:4:567:89ab]`.
    @inlinable
    public init?(arpaDomainName domainName: DomainName) {
        guard
            let result = domainName._data.withUnsafeReadableBytes({ ptr -> AnyIPAddress? in
                ptr.withMemoryRebound(to: UInt8.self) { ptr -> AnyIPAddress? in
                    var iterator = domainName.makePositionIterator()

                    /// `DomainName.data` always only contains ASCII bytes
                    let asciiSpan = ptr.span

                    for _ in 0..<4 {
                        guard let labelPosition = iterator.next() else {
                            return nil
                        }

                        /// If this is an IPv6, then the label length is always 1.
                        switch labelPosition.length {
                        case 1:
                            /// Can't know for sure if this is an IPv6 or IPv4, so continue.
                            continue
                        default:
                            /// If the label length is not 1, then this can only be an IPv4.
                            return IPv4Address(arpaDomainName: domainName).map { .v4($0) }
                        }
                    }

                    /// If this is an IPv4, then the 5th label is always `in-addr`.
                    guard let identifierLabelRange = iterator.next()?.range else {
                        return nil
                    }
                    let identifierLabel = asciiSpan.extracting(unchecked: identifierLabelRange)
                    let inAddrBytes = [
                        UInt8(ascii: "i"), UInt8(ascii: "n"), UInt8(ascii: "-"), UInt8(ascii: "a"),
                        UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "r"),
                    ]
                    /// If the 5th label is `in-addr`, then this can only be an IPv4.
                    if identifierLabel.swift_endpoint_equals(to: inAddrBytes) {
                        return IPv4Address(arpaDomainName: domainName).map { .v4($0) }
                    } else {
                        return IPv6Address(arpaDomainName: domainName).map { .v6($0) }
                    }
                }
            })
        else {
            return nil
        }

        self = result
    }
}
