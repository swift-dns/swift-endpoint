@available(SwiftStdlib 5.1, *)
extension IPv4Address: CustomStringConvertible {
    /// The textual representation of an IPv4 address.
    @inlinable
    public var description: String {
        /// 15 is enough for the biggest possible IPv4Address description.
        /// For example for "255.255.255.255".
        /// Coincidentally, Swift's `_SmallString` usually supports up to 15 bytes, which helps make
        /// this implementation as efficient as possible without a heap allocation.
        String(unsafeUninitializedCapacity_Compatibility: 15) { buffer in
            self.writeTextualRepresentation_RequiringMinimumCapacityOf15(
                into: UnsafeMutableRawBufferPointer(buffer)
            )
        }
    }

    /// Writes the textual representation of this address into `buffer` and returns the number of
    /// bytes written. `buffer` must have a capacity of at least 15 bytes.
    @inlinable
    @inline(__always)
    func writeTextualRepresentation_RequiringMinimumCapacityOf15(
        into buffer: UnsafeMutableRawBufferPointer
    ) -> Int {
        assert(buffer.count >= 15)

        var resultIdx = 0

        let byte = UInt8(truncatingIfNeeded: self.address &>> 24)
        /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
        byte.asDecimal_RequiringMinimumCapacityOf3(buffer: buffer, advancingIdx: &resultIdx)

        for idx in 1..<4 {
            buffer[resultIdx] = .asciiDot
            resultIdx &+= 1

            let shift = 24 &- idx &* 8
            let byte = UInt8(truncatingIfNeeded: self.address &>> shift)
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            byte.asDecimal_RequiringMinimumCapacityOf3(buffer: buffer, advancingIdx: &resultIdx)
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
        self.init(textualRepresentation: utf8Span.span)
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
        var address: UInt32 = 0
        let success = IPv4Address.parseIPv4(
            span: span,
            address: &address
        )

        guard success else {
            return nil
        }

        self.init(address)
    }

    @inlinable
    @inline(__always)
    static func parseIPv4(
        span: Span<UInt8>,
        address: inout UInt32
    ) -> Bool {
        var currentSegment: UInt32 = 0
        var digitsCount: UInt8 = 0
        var dotsCount: UInt8 = 0

        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            let byte = span[unchecked: idx]

            switch byte {
            case .asciiDot:
                if digitsCount == 0 || currentSegment > 255 || dotsCount == 3 {
                    return false
                }

                address = (address &<< 8) | currentSegment

                currentSegment = 0
                digitsCount = 0
                dotsCount &+= 1
            default:
                guard let digit = UInt8.mapUTF8ByteToUInt8(byte) else {
                    return false
                }

                digitsCount &+= 1
                if digitsCount > 3 {
                    return false
                }

                /// This is safe: `currentSegment` is guaranteed to be at most 99 at this point.
                currentSegment = currentSegment &* 10 &+ UInt32(digit)
            }
        }

        if dotsCount == 3, digitsCount != 0, currentSegment <= 255 {
            address = (address &<< 8) | currentSegment
            return true
        } else {
            return false
        }
    }
}
