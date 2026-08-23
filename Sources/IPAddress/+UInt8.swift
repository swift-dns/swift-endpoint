public import CSwiftEndpoint

extension UInt8 {
    @inlinable
    package static var ascii0: UInt8 {
        0x30
    }

    @inlinable
    static var ascii9: UInt8 {
        0x39
    }

    @inlinable
    package static var asciiLowercasedA: UInt8 {
        0x61
    }

    @inlinable
    static var asciiForwardSlash: UInt8 {
        0x2F
    }

    @inlinable
    static var asciiDot: UInt8 {
        0x2E
    }

    @inlinable
    static var asciiLeftSquareBracket: UInt8 {
        0x5B
    }

    @inlinable
    static var asciiRightSquareBracket: UInt8 {
        0x5D
    }

    @inlinable
    static var asciiColon: UInt8 {
        0x3A
    }
}

@available(SwiftStdlib 5.1, *)
extension UInt8 {
    /// Reads a span of a text like "127" as a `UInt8`, if the bytes are in correct form.
    /// Otherwise returns `nil`.
    /// Equivalent to `UInt8(string, radix: 10)`, but faster.
    @inlinable
    package init?(decimalRepresentation span: Span<UInt8>) {
        let count = span.count

        guard count > 0, count < 4 else {
            return nil
        }

        let digit0 = span[0] &- UInt8.ascii0
        /// essentially `count &>> 1` == `max(count - 2, 0)`
        let digit1 = unsafe span[unchecked: count &>> 1] &- UInt8.ascii0
        /// `count > 0` so `(0...2) ~ (count - 1)`
        let digit2 = span[count - 1] &- UInt8.ascii0

        let shift = (count &- 1) &* 8
        let multiplier0 = (0x0064_0A00 as UInt32) &>> shift & 0xFF
        let multiplier1 = (0x0A_0000 as UInt32) &>> shift & 0xFF

        let value =
            UInt32(digit0) &* multiplier0
            &+ UInt32(digit1) &* multiplier1
            &+ UInt32(digit2)

        /// The digit checks reject non-decimal-digit bytes, whose wrapped values exceed 9.
        guard digit0 < 10, digit1 < 10, digit2 < 10, value < 256 else {
            return nil
        }

        self = UInt8(truncatingIfNeeded: value)
    }

    @inlinable
    static func mapUTF8ByteToUInt8(_ utf8Byte: UInt8) -> UInt8? {
        guard
            utf8Byte <= UInt8.ascii9,
            utf8Byte >= UInt8.ascii0
        else {
            return nil
        }
        return utf8Byte &- UInt8.ascii0
    }

    /// Maps a hexadecimal ASCII byte to its `0...15` value.
    @inlinable
    @inline(always)
    package static func mapHexadecimalByteToUInt8(_ asciiByte: UInt8) -> UInt8? {
        let digit = cswift_endpoint_hexadecimal_digit(asciiByte)
        let isInvalid = digit == 0xFF
        return isInvalid ? nil : digit
    }
}

extension UInt8 {
    @inlinable
    @inline(always)
    package func asDecimal_RequiringMinimumCapacityOf3(
        buffer: UnsafeMutableRawBufferPointer,
        advancingIdx idx: inout Int
    ) {
        assert(buffer.count >= idx + 3)

        let entry = cswift_endpoint_decimal_digits(self)

        /// Always write all 3 digits, but only advance past the significant ones.
        /// The insignificant ones are overwritten by whatever is written next.
        unsafe buffer.storeBytes(
            of: UInt16(truncatingIfNeeded: entry),
            toByteOffset: idx,
            as: UInt16.self
        )
        unsafe buffer.storeBytes(
            of: UInt8(truncatingIfNeeded: entry &>> 16),
            toByteOffset: idx + 2,
            as: UInt8.self
        )

        idx += Int(entry &>> 24)
    }
}
