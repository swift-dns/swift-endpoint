public import Domain
public import IPAddress

public import struct NIOCore.ByteBuffer

@available(SwiftStdlib 5.1, *)
extension IPv4Address {
    /// Initialize an `IPv4Address` from a `DomainName` which is in the special arpa domain name format,
    /// according to [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://datatracker.ietf.org/doc/html/rfc1035#section-3.5)
    /// or is a simple IPv4 Address encoded in dotted quad notation like `"127.0.0.1"`.
    ///
    /// For a arpa-formatted domain name, it must contain exactly 4 UInt8 labels containing the ipv4 address's
    /// value in reverse, followed by `in-addr.arpa`.
    /// For example a domain name like `"4.3.2.1.in-addr.arpa"` will parse into the IPv4 address `1.2.3.4`.
    /// Or it can be a simple domain name like `"127.0.0.1"` which will parse into the IPv4 address `127.0.0.1`.
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result = unsafe domainName._data.withUnsafeReadableBytes({ ptr -> IPv4Address? in
                unsafe ptr.withMemoryRebound(to: UInt8.self) { ptr -> IPv4Address? in
                    var ipv4 = IPv4Address(0)
                    var iterator = domainName.makePositionIterator()

                    /// `DomainName.data` always only contains ASCII bytes
                    let asciiSpan = unsafe ptr.span

                    for idx in 0..<4 {
                        guard let range = iterator.next()?.range else {
                            return nil
                        }
                        guard
                            let byte = unsafe UInt8(
                                decimalRepresentation: asciiSpan.extracting(unchecked: range)
                            )
                        else {
                            return nil
                        }

                        /// Unchecked because `idx` can't exceed `3` anyway
                        let shift = 8 * (3 - idx)
                        ipv4._address |= UInt32(byte) &<< shift
                    }

                    if iterator.reachedEnd() {
                        /// We've had exactly enough labels, let's return
                        return ipv4
                    }

                    /// Check to see if this is an arpa domain name
                    guard let inAddrRange = iterator.next()?.range,
                        let arpaRange = iterator.next()?.range,
                        iterator.reachedEnd()
                    else {
                        return nil
                    }

                    let inAddr = unsafe asciiSpan.extracting(unchecked: inAddrRange)
                    let arpa = unsafe asciiSpan.extracting(unchecked: arpaRange)
                    let inAddrBytes = [
                        UInt8(ascii: "i"), UInt8(ascii: "n"), UInt8(ascii: "-"), UInt8(ascii: "a"),
                        UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "r"),
                    ]
                    let arpaBytes = [
                        UInt8(ascii: "a"), UInt8(ascii: "r"), UInt8(ascii: "p"), UInt8(ascii: "a"),
                    ]
                    guard inAddr.swift_endpoint_equals(to: inAddrBytes),
                        arpa.swift_endpoint_equals(to: arpaBytes)
                    else {
                        return nil
                    }

                    /// Arpa domain names have the domain name bytes in reversed order.
                    ipv4._address = ipv4._address.byteSwapped

                    return ipv4
                }
            })
        else {
            return nil
        }

        self = result
    }

    /// Initialize an `IPv4Address` from a `DomainName` which is in the special arpa domain name format,
    /// according to [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://datatracker.ietf.org/doc/html/rfc1035#section-3.5).
    ///
    /// The domain name must contain exactly 4 UInt8 labels containing the ipv4 address's value in reverse,
    /// followed by `in-addr.arpa`.
    /// For example a domain name like `"4.3.2.1.in-addr.arpa"` will parse into the IPv4 address `1.2.3.4`.
    @inlinable
    public init?(arpaDomainName domainName: DomainName) {
        guard
            let result = unsafe domainName._data.withUnsafeReadableBytes({ ptr -> IPv4Address? in
                unsafe ptr.withMemoryRebound(to: UInt8.self) { ptr -> IPv4Address? in
                    var ipv4 = IPv4Address(0)
                    var iterator = domainName.makePositionIterator()

                    /// `DomainName.data` always only contains ASCII bytes
                    let asciiSpan = unsafe ptr.span

                    for idx in 0..<4 {
                        guard let range = iterator.next()?.range else {
                            return nil
                        }
                        guard
                            let byte = unsafe UInt8(
                                decimalRepresentation: asciiSpan.extracting(unchecked: range)
                            )
                        else {
                            return nil
                        }
                        let shift = 8 * idx
                        ipv4._address |= UInt32(byte) &<< shift
                    }

                    guard let inAddrRange = iterator.next()?.range,
                        let arpaRange = iterator.next()?.range,
                        iterator.reachedEnd()
                    else {
                        return nil
                    }

                    let inAddr = unsafe asciiSpan.extracting(unchecked: inAddrRange)
                    let arpa = unsafe asciiSpan.extracting(unchecked: arpaRange)
                    let inAddrBytes = [
                        UInt8(ascii: "i"), UInt8(ascii: "n"), UInt8(ascii: "-"), UInt8(ascii: "a"),
                        UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "r"),
                    ]
                    let arpaBytes = [
                        UInt8(ascii: "a"), UInt8(ascii: "r"), UInt8(ascii: "p"), UInt8(ascii: "a"),
                    ]
                    guard inAddr.swift_endpoint_equals(to: inAddrBytes),
                        arpa.swift_endpoint_equals(to: arpaBytes)
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
