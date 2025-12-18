public import Domain
public import IPAddress

public import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 10.15, *)
extension IPv4Address {
    /// Initialize an `IPv4Address` from a `DomainName`.
    /// The domain name must correspond to a valid IPv4 address.
    /// For example a domain name like `"127.0.0.1"` will parse into the IPv4 address `127.0.0.1`.
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result = domainName._data.withUnsafeReadableBytes({ ptr -> IPv4Address? in
                ptr.withMemoryRebound(to: UInt8.self) { ptr in
                    var ipv4 = IPv4Address(0)
                    var iterator = domainName.makePositionIterator()

                    /// `DomainName.data` always only contains ASCII bytes
                    let asciiSpan = ptr.span

                    var idx = 0
                    while let (range, _) = iterator.nextRange() {
                        guard
                            let byte = UInt8(
                                decimalRepresentation: asciiSpan.extracting(unchecked: range)
                            )
                        else {
                            return nil
                        }

                        /// Unchecked because `idx` can't exceed `3` anyway
                        let shift = 8 &* (3 &- idx)
                        ipv4.address |= UInt32(byte) &<< shift

                        if idx == 3 {
                            if iterator.reachedEnd() {
                                /// We've had exactly enough labels, let's return
                                return ipv4
                            } else {
                                return nil
                            }
                        }

                        idx &+= 1
                    }

                    /// We had less than 4 labels, so this is an error
                    return nil
                }
            })
        else {
            return nil
        }

        self = result
    }

    /// Initialize an `IPv4Address` from a `DomainName` which is in the special arpa domain name format,
    /// according to [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035#section-3.5).
    ///
    /// The domain name must contain exactly 4 UInt8 labels containing the ipv4 address's value in reverse,
    /// followed by `in-addr.arpa`.
    /// For example a domain name like `"4.3.2.1.in-addr.arpa"` will parse into the IPv4 address `1.2.3.4`.
    @inlinable
    public init?(arpaDomainName domainName: DomainName) {
        guard
            let result = domainName._data.withUnsafeReadableBytes({ ptr -> IPv4Address? in
                ptr.withMemoryRebound(to: UInt8.self) { ptr -> IPv4Address? in
                    var ipv4 = IPv4Address(0)
                    var iterator = domainName.makePositionIterator()

                    /// `DomainName.data` always only contains ASCII bytes
                    let asciiSpan = ptr.span

                    for idx in 0..<4 {
                        guard let (range, _) = iterator.nextRange() else {
                            return nil
                        }
                        guard
                            let byte = UInt8(
                                decimalRepresentation: asciiSpan.extracting(unchecked: range)
                            )
                        else {
                            return nil
                        }
                        let shift = 8 &* idx
                        ipv4.address |= UInt32(byte) &<< shift
                    }

                    guard let (inAddrRange, _) = iterator.nextRange(),
                        let (arpaRange, _) = iterator.nextRange(),
                        iterator.reachedEnd()
                    else {
                        return nil
                    }

                    let inAddr = asciiSpan.extracting(unchecked: inAddrRange)
                    let arpa = asciiSpan.extracting(unchecked: arpaRange)
                    let inAddrBytes = [
                        UInt8(ascii: "i"), UInt8(ascii: "n"), UInt8(ascii: "-"), UInt8(ascii: "a"),
                        UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "r"),
                    ]
                    let arpaBytes = [
                        UInt8(ascii: "a"), UInt8(ascii: "r"), UInt8(ascii: "p"), UInt8(ascii: "a"),
                    ]
                    guard inAddr.swift_dns_equals(to: inAddrBytes),
                        arpa.swift_dns_equals(to: arpaBytes)
                    else {
                        return nil
                    }

                    return ipv4
                }
            })
        else {
            return nil
        }

        self = result
    }
}
