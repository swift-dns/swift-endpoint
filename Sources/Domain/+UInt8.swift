extension UInt8 {
    @inlinable
    var isASCII: Bool {
        self & 0b1000_0000 == 0
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
