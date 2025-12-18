public import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 10.15, *)
extension DomainName {
    /// Initialize a `DomainName` from an `IPv6Address`.
    ///
    /// The IPv6Address will be represented in the arpa notation, according to
    /// [RFC 3596, DNS Extensions to Support IP Version 6, October 2003](https://tools.ietf.org/html/rfc3596#section-2.5).
    ///
    /// For example an IPv6Address like `[4321:0:1:2:3:4:567:89ab]` will turn into the following domain name:
    /// `b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa.`
    /// That is, 32 4-bit hexadecimal integer labels (so 128 bits total) consisting of the IPv6 address's value in reverse,
    /// followed by the 2 arpa labels: `ip6` and `arpa`.
    @inlinable
    public init(ipv6: IPv6Address) {
        var buffer = ByteBuffer()
        /// 16 is the maximum number of bytes required to represent an IPv4 address,
        /// 13 more bytes are required for the "in-addr" and "arpa" labels.
        buffer.reserveCapacity(29)

        withUnsafeBytes(of: ipv6.address) { bytes in
            for idx in 0..<16 {
                let num1 = bytes[idx] &>> 4
                let num2 = bytes[idx] & 0x0F

                buffer.writeInteger(1, as: UInt8.self)
                buffer.writeInteger(
                    num2 > 9
                        ? num2 &+ UInt8.asciiLowercasedA &- 10
                        : num2 &+ UInt8.ascii0
                )

                buffer.writeInteger(1, as: UInt8.self)
                buffer.writeInteger(
                    num1 > 9
                        ? num1 &+ UInt8.asciiLowercasedA &- 10
                        : num1 &+ UInt8.ascii0
                )
            }
        }

        buffer.writeInteger(3, as: UInt8.self)
        buffer.writeBytes([
            UInt8(ascii: "i"), UInt8(ascii: "p"), UInt8(ascii: "6"),
        ])

        buffer.writeInteger(4, as: UInt8.self)
        buffer.writeBytes([
            UInt8(ascii: "a"), UInt8(ascii: "r"), UInt8(ascii: "p"), UInt8(ascii: "a"),
        ])

        self.init(isFQDN: true, _uncheckedAssumingValidWireFormatBytes: buffer)
    }
}
