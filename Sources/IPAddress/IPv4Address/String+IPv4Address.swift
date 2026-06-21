@available(SwiftStdlib 5.1, *)
extension IPv4Address: CustomStringConvertible {
    /// The textual representation of an IPv4 address.
    @inlinable
    public var description: String {
        /// 15 is enough for the biggest possible IPv4Address description.
        /// For example for "255.255.255.255".
        /// Coincidentally, Swift's `_SmallString` supports up to 15 bytes, which helps make this
        /// implementation as efficient as possible.
        String(unsafeUninitializedCapacity_Compatibility: 15) { buffer in
            self.writeTextualRepresentation(into: buffer)
        }
    }

    /// Writes the textual representation of this address into `buffer` and returns the number of
    /// bytes written. `buffer` must have a capacity of at least 15 bytes.
    @inlinable
    @inline(__always)
    func writeTextualRepresentation(into buffer: UnsafeMutableBufferPointer<UInt8>) -> Int {
        assert(buffer.count >= 15)

        var resultIdx = 0

        let byte = UInt8(truncatingIfNeeded: self.address &>> 24)
        byte.asDecimal(
            writeUTF8Byte: {
                buffer[resultIdx] = $0
                resultIdx &+= 1
            }
        )

        for idx in 1..<4 {
            buffer[resultIdx] = .asciiDot
            resultIdx &+= 1

            let shift = 24 &- idx &* 8
            let byte = UInt8(truncatingIfNeeded: self.address &>> shift)
            byte.asDecimal(
                writeUTF8Byte: {
                    buffer[resultIdx] = $0
                    resultIdx &+= 1
                }
            )
        }

        return resultIdx
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv4Address: CustomDebugStringConvertible {
    /// The textual representation of an IPv4 address appropriate for debugging.
    @inlinable
    public var debugDescription: String {
        "IPv4Address(\(self.description))"
    }
}

@available(SwiftStdlib 6.2, *)
extension IPv4Address {
    /// Initialize an IPv4 address from a `UTF8Span` of its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(textualRepresentation utf8Span: UTF8Span) {
        var utf8Span = utf8Span
        guard utf8Span.checkForASCII() else {
            return nil
        }

        self.init(_uncheckedAssumingValidASCII: utf8Span.span)
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv4Address: LosslessStringConvertible {
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    public init?(_ description: String) {
        var description = description
        guard
            let result = description.withSpan_Compatibility({
                IPv4Address(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    public init?(_ description: Substring) {
        var description = description
        guard
            let result = description.withSpan_Compatibility({
                IPv4Address(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize an IPv4 address from a `Span<UInt8>` of its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        if !span.isASCII { return nil }

        self.init(_uncheckedAssumingValidASCII: span)
    }

    /// Initialize an IPv4 address from a `Span<UInt8>` of its textual representation.
    /// The provided **span is required to be ASCII**.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    ///
    /// You should usually use `init?(textualRepresentation: UTF8Span)`, or
    /// `init?(textualRepresentation: Span<UInt8>)` instead.
    /// This initializer must only be used when you are 100% sure the span only contains ASCII characters.
    @inlinable
    public init?(_uncheckedAssumingValidASCII span: Span<UInt8>) {
        debugOnly {
            if !span.isASCII {
                fatalError(
                    "IPv4Address initializer should not be used with non-ASCII character: \([UInt8](copying: span))"
                )
            }
        }

        var address: UInt32 = 0

        var currentSegment: UInt8 = 0
        var digitIdx: UInt8 = 0
        var segmentIdx: UInt8 = 0

        let spanLastIdx = span.count &- 1
        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            let backwardsIdx = spanLastIdx &- idx
            /// Unchecked because `backwardsIdx` is guaranteed to be in range of `0...spanLastIdx`
            let byte = span[unchecked: backwardsIdx]

            switch byte {
            case .asciiDot:
                if segmentIdx > 3 || digitIdx == 0 {
                    return nil
                }

                /// segmentIdx is guaranteed to be in range of 0...3
                let shift = 8 &* segmentIdx
                address |= UInt32(currentSegment) &<< shift

                currentSegment = 0
                digitIdx = 0
                segmentIdx &+= 1
            default:
                guard let byte = UInt8.mapUTF8ByteToUInt8(byte) else {
                    return nil
                }

                let multiplier: UInt8
                switch digitIdx {
                case 0: multiplier = 1
                case 1: multiplier = 10
                case 2: multiplier = 100
                default: return nil
                }

                let (multipliedByte, overflew1) = byte.multipliedReportingOverflow(
                    by: multiplier
                )
                if overflew1 {
                    return nil
                }

                let (newSegment, overflew2) = multipliedByte.addingReportingOverflow(
                    currentSegment
                )
                if overflew2 {
                    return nil
                }

                currentSegment = newSegment
                digitIdx &+= 1
            }
        }

        if segmentIdx == 3, digitIdx != 0 {
            address |= UInt32(currentSegment) &<< 24
            self.address = address
        } else {
            return nil
        }
    }
}
