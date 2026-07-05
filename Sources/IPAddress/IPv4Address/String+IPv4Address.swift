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
        let count = span.count

        /// The shortest possible IPv4 address is "0.0.0.0" with 7 bytes, and the longest possible
        /// one is "255.255.255.255" with 15 bytes.
        guard count >= 7, count <= 15 else {
            return false
        }

        var idx = 0

        /// No count checks, we already know it's at least 7, and we will check at most 4 here.
        guard
            let segment1 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            span[unchecked: idx] == .asciiDot
        else {
            return false
        }
        idx &+= 1

        /// No pre-parse count check, we know we have at least 7 bytes and at this
        /// point we have 3 remaining at least.
        guard
            let segment2 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx < count,
            span[unchecked: idx] == .asciiDot
        else {
            return false
        }
        idx &+= 1

        guard
            idx < count,
            let segment3 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx < count,
            span[unchecked: idx] == .asciiDot
        else {
            return false
        }
        idx &+= 1

        guard
            idx < count,
            let segment4 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx == count
        else {
            return false
        }

        address = (segment1 &<< 24) | (segment2 &<< 16) | (segment3 &<< 8) | segment4

        return true
    }

    @inlinable
    @inline(__always)
    static func _parseSegment(
        from span: Span<UInt8>,
        count: Int,
        advancing idx: inout Int
    ) -> UInt32? {
        guard let digit1 = UInt8.mapUTF8ByteToUInt8(span[unchecked: idx]) else {
            return nil
        }
        var segment = UInt32(digit1)
        idx &+= 1

        guard idx < count,
            let digit2 = UInt8.mapUTF8ByteToUInt8(span[unchecked: idx])
        else {
            return segment
        }
        segment = segment &* 10 &+ UInt32(digit2)
        idx &+= 1

        guard idx < count,
            let digit3 = UInt8.mapUTF8ByteToUInt8(span[unchecked: idx])
        else {
            return segment
        }
        segment = segment &* 10 &+ UInt32(digit3)
        idx &+= 1

        guard segment <= 255 else {
            return nil
        }

        return segment
    }
}
