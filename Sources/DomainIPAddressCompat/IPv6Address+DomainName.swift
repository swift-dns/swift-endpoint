public import struct NIOCore.ByteBuffer

@available(SwiftStdlib 5.1, *)
extension DomainName {
    /// Initialize a `DomainName` from an `IPv6Address`.
    ///
    /// The IPv6Address will be represented in the arpa notation, according to
    /// [RFC 3596, DNS Extensions to Support IP Version 6, October 2003](https://datatracker.ietf.org/doc/html/rfc3596#section-2.5).
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
        unsafe buffer.writeWithUnsafeMutableBytes(minimumWritableBytes: 73) { bufferPtr in
            var bufferIdx = 0

            /// Arpa domain names have the address bytes in reversed order.
            let address = ipv6._storage.littleEndian
            let high = address._high
            let low = address._low
            for idx in 0..<16 {
                let word = idx < 8 ? high : low
                let shift = 56 - (idx & 7) * 8
                let byte = UInt8(truncatingIfNeeded: word &>> shift)
                let num1 = byte &>> 4
                let num2 = byte & 0x0F

                unsafe bufferPtr[bufferIdx] = 1
                unsafe bufferPtr[bufferIdx + 1] =
                    num2 > 9
                    ? num2 &+ UInt8.asciiLowercasedA &- 10
                    : num2 &+ UInt8.ascii0

                unsafe bufferPtr[bufferIdx + 2] = 1
                unsafe bufferPtr[bufferIdx + 3] =
                    num1 > 9
                    ? num1 &+ UInt8.asciiLowercasedA &- 10
                    : num1 &+ UInt8.ascii0

                bufferIdx += 4
            }

            unsafe bufferPtr[bufferIdx] = 3
            unsafe bufferPtr[bufferIdx + 1] = UInt8(ascii: "i")
            unsafe bufferPtr[bufferIdx + 2] = UInt8(ascii: "p")
            unsafe bufferPtr[bufferIdx + 3] = UInt8(ascii: "6")
            bufferIdx += 4

            unsafe bufferPtr[bufferIdx] = 4
            unsafe bufferPtr[bufferIdx + 1] = UInt8(ascii: "a")
            unsafe bufferPtr[bufferIdx + 2] = UInt8(ascii: "r")
            unsafe bufferPtr[bufferIdx + 3] = UInt8(ascii: "p")
            unsafe bufferPtr[bufferIdx + 4] = UInt8(ascii: "a")
            bufferIdx += 5

            return bufferIdx
        }

        self.init(isFQDN: true, _uncheckedAssumingValidWireFormatBytes: buffer)

    }
}
