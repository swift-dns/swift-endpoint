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
        /// If no brackets, we need 1 extra byte for the possible colon that we speculatively write
        let speculativeBytes = enclosingInSquareBrackets ? 0 : 1
        let toReserve = entry.maxRawLayoutBytes &+ bracketsCount &+ speculativeBytes

        return try writingToUnsafeMutableBufferPointerOfUInt8(toReserve) { buffer in
            var writeIdx = 0

            buffer[0] = .asciiLeftSquareBracket
            writeIdx &+= enclosingInSquareBrackets ? 1 : 0

            buffer[writeIdx] = .asciiColon
            writeIdx &+= entry.writeCsAtBeginning ? 1 : 0

            let writeCsAtIdx = entry.writeCsAtIdx
            let range = Range(uncheckedBounds: (0, entry.segmentsCount))
            for offset in range {
                let idx = Int(entry.packedIndices &>> (offset &* 8) & 0xFF)

                buffer[writeIdx] = .asciiColon
                writeIdx &+= idx == writeCsAtIdx ? 1 : 0

                buffer[writeIdx] = .asciiColon
                writeIdx &+= offset == 0 ? 0 : 1

                self._writeSegmentAsLowercasedHexASCII(
                    into: buffer,
                    advancingIdx: &writeIdx,
                    segmentIdx: idx
                )
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

    @inlinable
    @inline(__always)
    func _segment(atUncheckedIndex segmentIdx: Int) -> UInt16 {
        let word = segmentIdx < 4 ? self.address._high : self.address._low
        let shift = (3 &- (segmentIdx & 3)) &* 16
        return UInt16(truncatingIfNeeded: word &>> shift)
    }

    @inlinable
    @inline(__always)
    func _writeSegmentAsLowercasedHexASCII(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        advancingIdx idx: inout Int,
        segmentIdx: Int
    ) {
        let segment = self._segment(atUncheckedIndex: segmentIdx)

        var nibbles = UInt32(segment)
        nibbles = ((nibbles &<< 8) | nibbles) & 0x00FF_00FF
        nibbles = ((nibbles &<< 4) | nibbles) & 0x0F0F_0F0F

        let above9Mask = ((nibbles &+ 0x0606_0606) & 0x1010_1010) &>> 4
        let hexASCII = nibbles &+ 0x3030_3030 &+ above9Mask &* 0x27

        let stringOrderedHexASCII = hexASCII.byteSwapped
        let zeroDigitsCount = min(3, segment.leadingZeroBitCount &>> 2)
        let toStore = stringOrderedHexASCII &>> (zeroDigitsCount &* 8)

        UnsafeMutableRawBufferPointer(buffer).storeBytes(
            of: toStore,
            toByteOffset: idx,
            as: UInt32.self
        )
        idx &+= 4 &- zeroDigitsCount
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
        self.init(textualRepresentation: utf8Span.span)
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
                var ipv4Address: UInt32 = 0
                guard
                    remainingBytesCount >= 4,
                    IPv4Address.parseIPv4(
                        span: span.extracting(
                            unchecked: Range(
                                uncheckedBounds: (latestColonIdx &+ 1, span.count)
                            )
                        ),
                        address: &ipv4Address
                    )
                else {
                    return false
                }

                remainingBytesCount &-= 4
                let shift = remainingBytesCount &* 8
                address |= _CompatibilityUInt128Typealias(ipv4Address) &<< shift

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
        @usableFromInline let _segmentsCount: UInt8
        @usableFromInline let _maxRawLayoutBytes: UInt8
        @usableFromInline let _writeCsAtIdx: UInt8
        @usableFromInline let writeCsAtBeginning: Bool
        @usableFromInline let writeCsAtEnd: Bool
        @inlinable var segmentsCount: Int { Int(self._segmentsCount) }
        @inlinable var maxRawLayoutBytes: Int { Int(self._maxRawLayoutBytes) }
        @inlinable var writeCsAtIdx: Int { Int(self._writeCsAtIdx) }

        package init(
            _ packedIndices: UInt64,
            _ segmentsCount: UInt8,
            _ maxRawLayoutBytes: UInt8,
            _ writeCsAtIdx: UInt8,
            _ writeCsAtBeginning: Bool,
            _ writeCsAtEnd: Bool
        ) {
            self.packedIndices = packedIndices
            self._segmentsCount = segmentsCount
            self._maxRawLayoutBytes = maxRawLayoutBytes
            self._writeCsAtIdx = writeCsAtIdx
            self.writeCsAtBeginning = writeCsAtBeginning
            self.writeCsAtEnd = writeCsAtEnd
        }
    }

    @usableFromInline
    package static let _segmentWriteTable: [SegmentWriteTableEntry] = [
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 26, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 21, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 26, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 26, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0500, 4, 21, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0605, 3, 16, 5, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 26, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 21, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 26, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 26, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 26, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 26, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0100, 4, 21, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0100, 4, 21, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0600, 3, 16, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0706, 2, 11, 6, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 26, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 21, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 26, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 26, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0500, 4, 21, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0605, 3, 16, 5, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 31, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 31, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 31, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 31, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 31, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 31, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 31, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 31, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 26, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 21, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 26, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 26, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 26, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 26, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 26, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 26, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 26, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0702_0100, 4, 21, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0702_0100, 4, 21, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0702_0100, 4, 21, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0702_0100, 4, 21, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0100, 3, 16, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0100, 3, 16, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0700, 2, 11, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0007, 1, 6, 7, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 26, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 21, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 26, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 26, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0500, 4, 21, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0605, 3, 16, 5, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 39, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 26, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 21, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 31, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 26, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 26, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 26, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 26, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0100, 4, 21, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0100, 4, 21, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0600, 3, 16, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0706, 2, 11, 6, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 31, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 26, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 21, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 31, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 31, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 31, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 31, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 26, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 26, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0500, 4, 21, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0605, 3, 16, 5, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 26, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 26, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 26, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 21, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 21, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 21, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 21, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 21, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 21, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 21, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 21, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 21, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0002_0100, 3, 16, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0002_0100, 3, 16, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0002_0100, 3, 16, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0002_0100, 3, 16, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0100, 2, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0100, 2, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0000, 1, 6, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0000, 0, 2, 15, false, true),
    ]
}
