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
        /// 64 is the maximum number of bytes required to represent an IPv6 address,
        /// 9 more bytes are required for the "ip6" and "arpa" labels.
        buffer.writeWithUnsafeMutableBytes(minimumWritableBytes: 73) { bufferPtr in
            var bufferIdx = 0

            let lo = ipv6.address._low
            let hi = ipv6.address._high
            for idx in 0..<16 {
                let word = idx < 8 ? lo : hi
                let byte = UInt8(truncatingIfNeeded: word &>> ((idx & 7) &* 8))
                let num1 = byte &>> 4
                let num2 = byte & 0x0F

                bufferPtr[bufferIdx] = 1
                bufferPtr[bufferIdx &+ 1] =
                    num2 > 9
                    ? num2 &+ UInt8.asciiLowercasedA &- 10
                    : num2 &+ UInt8.ascii0

                bufferPtr[bufferIdx &+ 2] = 1
                bufferPtr[bufferIdx &+ 3] =
                    num1 > 9
                    ? num1 &+ UInt8.asciiLowercasedA &- 10
                    : num1 &+ UInt8.ascii0

                bufferIdx &+= 4
            }

            bufferPtr[bufferIdx] = 3
            bufferPtr[bufferIdx &+ 1] = UInt8(ascii: "i")
            bufferPtr[bufferIdx &+ 2] = UInt8(ascii: "p")
            bufferPtr[bufferIdx &+ 3] = UInt8(ascii: "6")
            bufferIdx &+= 4

            bufferPtr[bufferIdx] = 4
            bufferPtr[bufferIdx &+ 1] = UInt8(ascii: "a")
            bufferPtr[bufferIdx &+ 2] = UInt8(ascii: "r")
            bufferPtr[bufferIdx &+ 3] = UInt8(ascii: "p")
            bufferPtr[bufferIdx &+ 4] = UInt8(ascii: "a")
            bufferIdx &+= 5

            return bufferIdx
        }

        self.init(isFQDN: true, _uncheckedAssumingValidWireFormatBytes: buffer)

    }
}
