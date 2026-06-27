@available(SwiftStdlib 5.1, *)
extension IPv6Address: CustomStringConvertible {
    /// The textual representation of an IPv6 address.
    /// That is, 8 16-bits (2-bytes) separated by `:`, enclosed in `[]`, while using
    /// the compression sign (`::`) when possible.
    ///
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://datatracker.ietf.org/doc/html/rfc5952).
    @inlinable
    public var description: String {
        self.makeDescription(enclosingInSquareBrackets: true) { (maxWriteableBytes, callback) in
            String(unsafeUninitializedCapacity_Compatibility: maxWriteableBytes) { buffer in
                callback(buffer)
            }
        }
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv6Address: CustomDebugStringConvertible {
    /// The textual representation of an IPv6 address appropriate for debugging.
    /// That is, 8 16-bits (2-bytes) separated by `:`, enclosed in `[]`, while using
    /// the compression sign (`::`) when possible. Enclosed in `IPv6Address(` and `)`.
    ///
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://datatracker.ietf.org/doc/html/rfc5952).
    @inlinable
    public var debugDescription: String {
        "IPv6Address(\(self.description))"
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv6Address {
    @inlinable
    @inline(__always)
    package func makeDescription<Buffer>(
        enclosingInSquareBrackets: Bool,
        writingToUnsafeMutableBufferPointerOfUInt8: (
            _ maxWriteableBytes: Int,
            _ callbackReturningBytesWritten: (UnsafeMutableBufferPointer<UInt8>) -> Int
        ) throws -> Buffer
    ) rethrows -> Buffer {
        let mask = self.makeSegmentsMask()
        let entry = IPv6Address._segmentWriteTable[Int(mask)]

        /// Reserve the max possibly needed capacity.
        let bracketsCount = enclosingInSquareBrackets ? 2 : 0
        let segmentsCount = entry.segmentsCount
        let colonsCount = max(2, min(segmentsCount &+ 1, 7))
        /// If no brackets, we need 1 extra byte for the possible colon that we speculatively write
        let speculativeBytes = enclosingInSquareBrackets ? 0 : 1
        let toReserve = bracketsCount &+ colonsCount &+ (segmentsCount &* 4) &+ speculativeBytes

        return try writingToUnsafeMutableBufferPointerOfUInt8(toReserve) { buffer in
            withUnsafeTemporaryAllocation(byteCount: 32, alignment: 1) { hexBytes in
                self._expandToLowercasedHexASCII(into: hexBytes)

                var writeIdx = 0

                buffer[0] = .asciiLeftSquareBracket
                writeIdx &+= enclosingInSquareBrackets ? 1 : 0

                buffer[writeIdx] = .asciiColon
                writeIdx &+= entry.writeCsAtBeginning ? 1 : 0
                buffer[writeIdx] = .asciiColon
                writeIdx &+= entry.writeCsAtBeginning ? 1 : 0

                var offset = 0
                while offset < entry.segmentsCount {
                    let idx = Int(entry.packedIndices &>> (offset &* 8) & 0xFF)

                    buffer[writeIdx] = .asciiColon
                    writeIdx &+= idx == entry.writeCsAtIdx ? 1 : 0

                    buffer[writeIdx] = .asciiColon
                    writeIdx &+= offset == 0 ? 0 : 1

                    IPv6Address._writeSegmentFromHex(
                        into: buffer,
                        advancingIdx: &writeIdx,
                        hexBytes: hexBytes,
                        octalIdx: idx
                    )

                    offset &+= 1
                }

                buffer[writeIdx] = .asciiColon
                writeIdx &+= entry.writeCsAtEnd ? 1 : 0
                buffer[writeIdx] = .asciiColon
                writeIdx &+= entry.writeCsAtEnd ? 1 : 0

                buffer[writeIdx] = .asciiRightSquareBracket
                writeIdx &+= enclosingInSquareBrackets ? 1 : 0

                assert(writeIdx <= toReserve)

                return writeIdx
            }
        }
    }

    /// Returns a UInt8, each bit representing whether
    /// the corresponding IPv6 segment is all-zero (1) or not (0).
    @inlinable
    @inline(__always)
    func makeSegmentsMask() -> UInt8 {
        let highNibble = IPv6Address.makeNibbleFor4Segments(of: self.address._high)
        let lowNibble = IPv6Address.makeNibbleFor4Segments(of: self.address._low)
        return highNibble | (lowNibble &<< 4)
    }

    /// Makes a nibble for 4 segments of a 64-bit word,
    /// each bit representing whether the segment is all-zero (1) or not (0).
    @inlinable
    @inline(__always)
    static func makeNibbleFor4Segments(of word: UInt64) -> UInt8 {
        /// 4x 16 bits, each for a segment
        let m: UInt64 = 0x7FFF_7FFF_7FFF_7FFF
        /// For each 16-bit (a segment), if the 16-bit is all zeros, it will result in a 0x7FFF.
        /// Else it'll result in a value with the 15th bit set to 1, example: 0b1000_0010_1001_0100.
        /// The only exception is when the segment value is 0b1000_0000_0000_0000 which will be counted as zero.
        let partial_topBitsOneIfSegmentsNonZero = (word & m) &+ m
        /// Now we remove that exception by ORing the original word with the result.
        /// Now if a 15th bit in a segment is set to 1, then the segment is not zero.
        let topBitsOneIfSegmentsNonZero = partial_topBitsOneIfSegmentsNonZero | word
        /// Make sure all bits are set to 0, other than the 15th bits, which are set to 1 if it was a non-zero segment.
        let topBitsZero_IfSegmentsZero = ~topBitsOneIfSegmentsNonZero

        let _0IsZero = (topBitsZero_IfSegmentsZero &>> 63) & 1
        let _1IsZero = (topBitsZero_IfSegmentsZero &>> 47) & 1
        let _2IsZero = (topBitsZero_IfSegmentsZero &>> 31) & 1
        let _3IsZero = (topBitsZero_IfSegmentsZero &>> 15) & 1

        return UInt8(
            truncatingIfNeeded:
                _0IsZero
                | (_1IsZero &<< 1)
                | (_2IsZero &<< 2)
                | (_3IsZero &<< 3)
        )
    }

    /// Expands the 16 address bytes into 32 lowercased hex ASCII bytes.
    /// Written as a flat, branch-free loop so LLVM auto-vectorizes it, like `Span.isASCII`.
    @inlinable
    @inline(__always)
    func _expandToLowercasedHexASCII(into hexStorage: UnsafeMutableRawBufferPointer) {
        withUnsafeBytes(of: self.address.bigEndian) { bigBytes in
            for idx in 0..<16 {
                let byte = bigBytes[idx]
                let high = byte &>> 4
                let low = byte & 0x0F
                let startOffset = 2 &* idx
                hexStorage[startOffset] = IPv6Address._lowercasedHexASCII(nibble: high)
                hexStorage[startOffset &+ 1] = IPv6Address._lowercasedHexASCII(nibble: low)
            }
        }
    }

    /// Maps a single hex nibble (0...15) to its lowercased ASCII byte.
    @inlinable
    @inline(__always)
    static func _lowercasedHexASCII(nibble: UInt8) -> UInt8 {
        nibble > 9
            ? nibble &+ UInt8.asciiLowercasedA &- 10
            : nibble &+ UInt8.ascii0
    }

    @inlinable
    @inline(__always)
    static func _writeSegmentFromHex(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        advancingIdx idx: inout Int,
        hexBytes: UnsafeMutableRawBufferPointer,
        octalIdx: Int
    ) {
        let base = octalIdx &* 4
        let _1 = hexBytes[base]
        let _2 = hexBytes[base &+ 1]
        let _3 = hexBytes[base &+ 2]
        let _4 = hexBytes[base &+ 3]

        var notAllZerosSoFar = _1 != UInt8.ascii0
        buffer[idx] = _1
        idx &+= notAllZerosSoFar ? 1 : 0

        notAllZerosSoFar = notAllZerosSoFar || _2 != UInt8.ascii0
        buffer[idx] = _2
        idx &+= notAllZerosSoFar ? 1 : 0

        notAllZerosSoFar = notAllZerosSoFar || _3 != UInt8.ascii0
        buffer[idx] = _3
        idx &+= notAllZerosSoFar ? 1 : 0

        buffer[idx] = _4
        idx &+= 1
    }
}

@available(SwiftStdlib 6.2, *)
extension IPv6Address {
    /// Initialize an IPv6 address from a `UTF8Span` of its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
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
extension IPv6Address: LosslessStringConvertible {
    /// Initialize an IPv6 address from its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    public init?(_ description: String) {
        var description = description
        guard
            let result = description.withSpan_Compatibility({
                IPv6Address(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize an IPv6 address from its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    public init?(_ description: Substring) {
        var description = description
        guard
            let result = description.withSpan_Compatibility({
                IPv6Address(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize an IPv6 address from a `Span<UInt8>` of its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        if !span.isASCII { return nil }

        self.init(_uncheckedAssumingValidASCII: span)
    }

    /// Initialize an IPv6 address from a `Span<UInt8>` of its textual representation.
    /// The provided **span is required to be ASCII**.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    ///
    /// You should usually use `init?(textualRepresentation: UTF8Span)`, or
    /// `init?(textualRepresentation: Span<UInt8>)` instead.
    /// This initializer must only be used when you are 100% sure the span only contains ASCII characters.
    @inlinable
    public init?(_uncheckedAssumingValidASCII span: Span<UInt8>) {
        assert(
            span.isASCII,
            "IPv6Address initializer should not be used with non-ASCII character: \([UInt8](copying: span))"
        )

        /// Swift stores integers in little-endian, so we need to do a little bit of gymnastics here
        /// and write backwards.
        var address = _CompatibilityUInt128Typealias.zero
        let success = IPv6Address.parseIPv6(
            span: span,
            address: &address
        )
        self.init(address)

        guard success else {
            return nil
        }
    }

    @inlinable
    @inline(__always)
    static func parseIPv6(
        span: Span<UInt8>,
        address: inout _CompatibilityUInt128Typealias
    ) -> Bool {
        var span = span

        /// 2 == "::".count
        guard span.count >= 2 else {
            return false
        }

        /// Trim the left and right square brackets if they both exist

        /// Unchecked because we just checked count > 1 above
        let startsWithBracket = span[unchecked: 0] == .asciiLeftSquareBracket
        /// Unchecked because we just checked count > 1 above
        let endsWithBracket = span[unchecked: span.count &- 1] == .asciiRightSquareBracket
        switch (startsWithBracket, endsWithBracket) {
        case (false, false):
            break
        case (true, true):
            /// Unchecked because we just checked count > 1 above
            span = span.extracting(
                unchecked: Range(uncheckedBounds: (1, span.count &- 1))
            )
        case (true, false), (false, true):
            return false
        }

        /// 2 == "::".count
        guard span.count >= 2 else {
            return false
        }

        /// Special-case handling for when there is a compression sign at the beginning
        if span[unchecked: 0] == .asciiColon {
            span = span.extracting(
                unchecked: Range(uncheckedBounds: (1, span.count))
            )
            if span[unchecked: 0] != .asciiColon {
                return false
            }
        }

        let endIdx = span.count &- 1
        var segmentDigitIdx = 0
        var latestColonIdx = -1
        var currentSegmentValue: UInt16 = 0
        var remainingBytesCount = 16
        /// cs == compression sign
        var beforeCsBytesCountRemaining = -1

        var idx = 0
        while idx < span.count {
            defer { idx &+= 1 }

            let byte = span[unchecked: idx]

            if let digit = UInt8.mapHexadecimalByteToUInt8(byte) {
                if segmentDigitIdx == 4 {
                    return false
                }

                currentSegmentValue &<<= 4
                currentSegmentValue |= UInt16(digit)
                segmentDigitIdx &+= 1

                continue
            }

            if byte == .asciiColon {
                latestColonIdx = idx
                if segmentDigitIdx == 0 {
                    if beforeCsBytesCountRemaining != -1 {
                        return false
                    }
                    beforeCsBytesCountRemaining = remainingBytesCount
                    continue
                } else if idx == endIdx {
                    return false
                }

                /// We only do decrements of 2x to remainingBytesCount so it can't be 1.
                if remainingBytesCount == 0 {
                    return false
                }

                remainingBytesCount &-= 2
                let shift = remainingBytesCount &* 8
                address |= _CompatibilityUInt128Typealias(currentSegmentValue) &<< shift

                segmentDigitIdx = 0
                currentSegmentValue = 0

                continue
            }

            if byte == .asciiDot {
                guard
                    remainingBytesCount >= 4,
                    let ipv4 = IPv4Address(
                        _uncheckedAssumingValidASCII: span.extracting(
                            unchecked: Range(
                                uncheckedBounds: (latestColonIdx &+ 1, span.count)
                            )
                        )
                    )
                else {
                    return false
                }

                remainingBytesCount &-= 4
                let shift = remainingBytesCount &* 8
                address |= _CompatibilityUInt128Typealias(ipv4.address) &<< shift

                segmentDigitIdx = 0
                currentSegmentValue = 0

                break
            }

            /// Bad character
            return false
        }

        if segmentDigitIdx > 0 {
            guard remainingBytesCount >= 2 else {
                return false
            }
            remainingBytesCount &-= 2
            let shift = remainingBytesCount &* 8
            address |= _CompatibilityUInt128Typealias(currentSegmentValue) &<< shift
        }

        if beforeCsBytesCountRemaining == -1 {
            return remainingBytesCount == 0
        }

        guard remainingBytesCount >= 4 else {
            return false
        }

        let beforeBits = beforeCsBytesCountRemaining &* 8
        let aboveBits = _CompatibilityUInt128Typealias.bitWidth &- beforeBits
        let afterShift = remainingBytesCount &* 8
        let beforeSegments = (address &>> beforeBits) << beforeBits
        let afterSegments = ((address &<< aboveBits) &>> aboveBits) &>> afterShift
        address = beforeSegments | afterSegments

        return true
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv6Address {
    @usableFromInline
    package struct SegmentWriteTableEntry: Sendable, Equatable {
        @usableFromInline let packedIndices: UInt64
        @usableFromInline let segmentsCount: Int
        @usableFromInline let writeCsAtIdx: Int
        @usableFromInline let writeCsAtBeginning: Bool
        @usableFromInline let writeCsAtEnd: Bool

        package init(
            _ packedIndices: UInt64,
            _ segmentsCount: Int,
            _ writeCsAtIdx: Int,
            _ writeCsAtBeginning: Bool,
            _ writeCsAtEnd: Bool
        ) {
            self.packedIndices = packedIndices
            self.segmentsCount = segmentsCount
            self.writeCsAtIdx = writeCsAtIdx
            self.writeCsAtBeginning = writeCsAtBeginning
            self.writeCsAtEnd = writeCsAtEnd
        }
    }

    @usableFromInline
    package static let _segmentWriteTable: [SegmentWriteTableEntry] = [
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_072, 5, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_012, 4, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(30_165_762_304, 5, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_762_304, 5, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_008, 4, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(460293, 3, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_072, 5, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_012, 4, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(30_165_565_696, 5, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_565_696, 5, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_565_696, 5, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_565_696, 5, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(117_833_984, 4, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(117_833_984, 4, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(460288, 3, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(1798, 2, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_072, 5, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_012, 4, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(30_165_762_304, 5, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_762_304, 5, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_008, 4, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(460293, 3, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_713_811_726_592, 6, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(7_713_811_726_592, 6, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(7_713_811_726_592, 6, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_713_811_726_592, 6, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(7_713_811_726_592, 6, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_713_811_726_592, 6, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(7_713_811_726_592, 6, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(7_713_811_726_592, 6, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_072, 5, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_012, 4, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(30_115_234_048, 5, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(30_115_234_048, 5, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(30_115_234_048, 5, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(30_115_234_048, 5, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(30_115_234_048, 5, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(30_115_234_048, 5, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(30_115_234_048, 5, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(117_571_840, 4, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(117_571_840, 4, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(117_571_840, 4, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(117_571_840, 4, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(459008, 3, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(459008, 3, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(1792, 2, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(7, 1, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_072, 5, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_012, 4, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(30_165_762_304, 5, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_762_304, 5, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_008, 4, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(460293, 3, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(506_097_522_914_230_528, 8, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_072, 5, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_012, 4, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_401_661_184, 6, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(30_165_565_696, 5, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_565_696, 5, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_565_696, 5, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_565_696, 5, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(117_833_984, 4, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(117_833_984, 4, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(460288, 3, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(1798, 2, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_346_688, 6, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_072, 5, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_012, 4, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(5_514_788_471_040, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_200, 6, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_215_616, 6, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(7_722_435_347_202, 6, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(30_165_762_304, 5, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(30_165_762_304, 5, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_008, 4, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(460293, 3, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(30_165_763_075, 5, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(17_230_332_160, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(30_165_763_072, 5, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(117_835_012, 4, 14, true, false),
        IPv6Address.SegmentWriteTableEntry(50_462_976, 4, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(50_462_976, 4, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(50_462_976, 4, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(50_462_976, 4, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(50_462_976, 4, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(50_462_976, 4, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(50_462_976, 4, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(50_462_976, 4, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(131328, 3, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(131328, 3, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(131328, 3, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(131328, 3, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(256, 2, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(256, 2, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0, 1, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0, 0, 14, true, false),
    ]
}
