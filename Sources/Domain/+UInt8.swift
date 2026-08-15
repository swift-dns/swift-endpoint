extension UInt8 {
    /// Whether the byte is a valid character in a domain name.
    ///
    /// Only lowercased letter, digits, hyphen-minus, underscores, stars, and whitespaces are allowed in a domain name.
    /// Underscores are allowed for service names like "_sip._tcp.example.com".
    /// Stars are allowed for wildcards like "*.example.com".
    /// Whitespaces are allowed for labels like "Mijia Cloud" which some Xiaomi devices use.
    ///
    /// Looked up in a 128-bit bitmap instead of range-checked. Every acceptable byte is below
    /// 0x80, so the two halves cover `0x00...0x3F` and `0x40...0x7F` respectively.
    @inlinable
    public var isAcceptableDomainNameCharacter: Bool {
        /// `0x20`, `0x2A`, `0x2D`, and `0x30...0x39`.
        let lowHalf: UInt64 = 0x03FF_2401_0000_0000
        /// `0x5F`, and `0x61...0x7A`.
        let highHalf: UInt64 = 0x07FF_FFFE_8000_0000

        guard self < 0x80 else {
            return false
        }

        let half = self < 64 ? lowHalf : highHalf
        return (half &>> (self & 63)) & 1 == 1
    }

    @inlinable
    static var asciiStar: UInt8 {
        0x2A
    }

    @inlinable
    static var asciiDot: UInt8 {
        0x2E
    }
}
