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
    static var asciiLowercasedF: UInt8 {
        0x66
    }

    @inlinable
    static var asciiUppercasedA: UInt8 {
        0x41
    }

    @inlinable
    static var asciiUppercasedF: UInt8 {
        0x46
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

        guard let digit1 = UInt8.mapUTF8ByteToUInt8(span[unchecked: 0]) else {
            return nil
        }
        var value = UInt32(digit1)

        if count > 1 {
            guard let digit2 = UInt8.mapUTF8ByteToUInt8(span[unchecked: 1]) else {
                return nil
            }
            value = value &* 10 &+ UInt32(digit2)

            if count > 2 {
                guard let digit3 = UInt8.mapUTF8ByteToUInt8(span[unchecked: 2]) else {
                    return nil
                }
                value = value &* 10 &+ UInt32(digit3)

                guard value <= 255 else {
                    return nil
                }
            }
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

    @inlinable
    package static func mapHexadecimalByteToUInt8(_ asciiByte: UInt8) -> UInt8? {
        if asciiByte <= UInt8.ascii9,
            asciiByte >= UInt8.ascii0
        {
            return asciiByte &- UInt8.ascii0
        }

        if asciiByte >= UInt8.asciiLowercasedA,
            asciiByte <= UInt8.asciiLowercasedF
        {
            return asciiByte &- UInt8.asciiLowercasedA &+ 10
        }

        if asciiByte >= UInt8.asciiUppercasedA,
            asciiByte <= UInt8.asciiUppercasedF
        {
            return asciiByte &- UInt8.asciiUppercasedA &+ 10
        }

        return nil
    }
}

extension UInt8 {
    @inlinable
    package func asDecimal_RequiringMinimumCapacityOf3(
        buffer: UnsafeMutableRawBufferPointer,
        advancingIdx idx: inout Int
    ) {
        assert(buffer.count >= 3)

        /// The compiler is smart enough to not actually do division by 10, but instead use the
        /// multiply-by-205-then-bitshift-by-11 trick.
        /// See it for yourself: https://godbolt.org/z/vYxTj78qd
        let (q, r1) = self.quotientAndRemainder(dividingBy: 10)
        let (q2, r2) = q.quotientAndRemainder(dividingBy: 10)
        let r3 = q2 % 10

        /// Always write, but only advance past it when it should be kept.
        var notAllZerosSoFar = r3 != 0
        buffer[idx] = r3 &+ UInt8.ascii0
        idx &+= notAllZerosSoFar ? 1 : 0

        notAllZerosSoFar = notAllZerosSoFar || r2 != 0
        buffer[idx] = r2 &+ UInt8.ascii0
        idx &+= notAllZerosSoFar ? 1 : 0

        buffer[idx] = r1 &+ UInt8.ascii0
        idx &+= 1
    }
}
