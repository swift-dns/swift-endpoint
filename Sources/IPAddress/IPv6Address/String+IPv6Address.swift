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
        let digitsPrintCountNoTrailing = self.countDigitsRequiredToPrintExcludingTrailingDigits()

        let bracketsCount = enclosingInSquareBrackets ? 2 : 0
        /// If no brackets, we need 2 extra byte for the possible colon that we speculatively write
        /// Also _writeSegmentAsLowercasedHexASCII needs 4 bytes of room, 1 of which is guaranteed to be
        /// present in the byte-count since the segments are non-zero. So 3.
        let speculativeBytes = 3
        /// `enclosingInSquareBrackets` if true, gives 1 byte worth of leading room
        let conservativeSpeculativeBytes =
            enclosingInSquareBrackets ? speculativeBytes &- 1 : speculativeBytes
        /// Exact required bytes to print, including headroom bytes for speculative writes.
        let toReserve =
            entry.minRawLayoutBytes
            &+ digitsPrintCountNoTrailing
            &+ bracketsCount
            &+ conservativeSpeculativeBytes

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
                buffer[writeIdx &+ 1] = .asciiColon
                /// We've reserved 2 speculative bytes worth of room so this is safe:
                writeIdx &+= idx == writeCsAtIdx ? 1 : 0
                writeIdx &+= offset == 0 ? 0 : 1

                self._writeSegmentAsLowercasedHexASCII(
                    into: buffer,
                    advancingIdx: &writeIdx,
                    segmentIdx: idx
                )
            }

            /// We've reserved 2 speculative bytes worth of room so this is safe:
            buffer[writeIdx] = .asciiColon
            buffer[writeIdx &+ 1] = .asciiColon
            writeIdx &+= entry.writeCsAtEnd ? 2 : 0

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
        /// 4x 16 bit lanes, each for a segment
        /// `0x7FFF` == `0b0111_1111_1111_1111`
        let m: UInt64 = 0x7FFF_7FFF_7FFF_7FFF
        /// For each lane, if the lane is all zeros, it will result in a 0x7FFF.
        /// Else it'll result in a value with the top bit set to 1, example: 0b1000_0010_1001_0100.
        /// The only exception is when the lane value is 0b1000_0000_0000_0000 which will be counted as zero.
        let partial_topBitsSetIfLaneNonZero = (word & m) &+ m
        /// Now we remove that exception by ORing the original word with the result.
        /// Now if a top bit in a lane/segment is set to 1, then the segment is not zero.
        let topBitsSetIfLaneNonZero = partial_topBitsSetIfLaneNonZero | word
        /// Make sure all bits are set to 0, other than the top bits, which are set to 1 if it was a non-zero segment.
        let topBitsZeroIfLaneZero = ~topBitsSetIfLaneNonZero

        let _0IsZero = (topBitsZeroIfLaneZero &>> 63) & 1
        let _1IsZero = (topBitsZeroIfLaneZero &>> 47) & 1
        let _2IsZero = (topBitsZeroIfLaneZero &>> 31) & 1
        let _3IsZero = (topBitsZeroIfLaneZero &>> 15) & 1

        return UInt8(
            truncatingIfNeeded:
                _0IsZero
                | (_1IsZero &<< 1)
                | (_2IsZero &<< 2)
                | (_3IsZero &<< 3)
        )
    }

    /// Counts the number of digits that will need to be written excluding the trailing
    /// digit that is always written even if it's 0.
    @inlinable
    @inline(__always)
    func countDigitsRequiredToPrintExcludingTrailingDigits() -> Int {
        let high = IPv6Address.countDigitsRequiredToPrintExcludingTrailingDigits(
            of: self.address._high
        )
        let low = IPv6Address.countDigitsRequiredToPrintExcludingTrailingDigits(
            of: self.address._low
        )
        return high &+ low
    }

    /// Counts the hex digits that each of the 4 segments of a 64-bit word needs beyond
    /// its first digit, summed over the 4 segments.
    /// That is, for each segment, 0 if the segment is in range `0x0...0xF`, up to 3 if
    /// the segment is in range `0x1000...0xFFFF`. All-zero segments count as 0.
    @inlinable
    @inline(__always)
    static func countDigitsRequiredToPrintExcludingTrailingDigits(of word: UInt64) -> Int {
        /// 4x 16 bit lanes, each for a segment
        /// `0x7777` == `0b0111_0111_0111_0111`
        let m: UInt64 = 0x7777_7777_7777_7777
        /// For each lane, if the lane is all zeros, it will result in a 0x7777.
        /// Else it'll result in a value with the top bit set to 1, example: 0b1000_0010_1001_0100.
        /// The only exception is when the lane value is like 0b1000_0000_0000_1000 which will be counted as zero.
        let partial_topBitsSetIfNibbleNonZero = (word & m) &+ m
        /// Now we remove that exception by ORing the original word with the result.
        /// Now iff a top bit in a lane/segment is set to 1, then the segment's top bit is set.
        let topBitsSetIfNibbleNonZero = partial_topBitsSetIfNibbleNonZero | word
        /// `0x8888` == `0b1000_1000_1000_1000`
        let m8: UInt64 = 0x8888_8888_8888_8888
        /// Now for each nibble where the nibble is not zero, we have `0b1000`. Otherwise we have `0b0000`.
        let onlyTopBitsSetIfNibbleNonZero = topBitsSetIfNibbleNonZero & m8
        /// `0x0888` == `0b0000_1000_1000_1000`
        let m0888: UInt64 = 0x0888_0888_0888_0888
        /// `0x0088` == `0b0000_0000_1000_1000`
        let m0088: UInt64 = 0x0088_0088_0088_0088
        /// In each lane, make sure if a previous nibble is set to 1, then the right-side nibble is also set to 1.
        /// Only that it'll leak into the next lane, so we mask out the lean with `m0888`.
        /// Then OR it with the original value to set back the left-side nibble.
        var s = onlyTopBitsSetIfNibbleNonZero | ((onlyTopBitsSetIfNibbleNonZero &>> 4) & m0888)
        /// In each lane, make sure if a previous nibble is set to 1, then the 2-right-side nibble is also set to 1.
        /// Only that it'll leak 2 nibbles into the next lane, so we mask out the leak with `m0088`.
        /// Then OR it with the original value to set back the 2 left-side nibbles.
        /// After this, in a lane, if a nibble or any nibbles after it are not zero, then they are set to `0b1000`.
        s = s | ((s &>> 8) & m0088)
        /// `0x1110` == `0b0001_0001_0001_0000`
        let m1110: UInt64 = 0x1110_1110_1110_1110
        /// Now we move the `0b1000` nibbles to be `0b0001` aka, 1.
        /// We mask out the first nibble because we have to write 1 digit anyway even for an empty segment,
        /// unless the segment is compressed which we don't care about here.
        let extraDigitFlags = (s &>> 3) & m1110
        /// `0x1111` == `0b0001_0001_0001_0001`
        let m1111: UInt64 = 0x1111_1111_1111_1111
        /// Count of all `0b0001` nibbles
        return Int(truncatingIfNeeded: (extraDigitFlags &* m1111) &>> 60)
    }

    /// The 16-bit segment at `segmentIdx`.
    /// Unchecked because `segmentIdx` is required to be in range of `0...7`.
    @inlinable
    @inline(__always)
    func _segment(atUncheckedIndex segmentIdx: Int) -> UInt16 {
        assert(segmentIdx >= 0 && segmentIdx <= 7)
        let word = segmentIdx < 4 ? self.address._high : self.address._low
        let shift = (3 &- (segmentIdx & 3)) &* 16
        return UInt16(truncatingIfNeeded: word &>> shift)
    }

    /// Writes the segment at `segmentIdx` as 1 to 4 lowercased hex ASCII bytes without
    /// `buffer` must have a capacity of at least `idx + 4` bytes,
    /// which we reserve anyway since we don't know if the segment contains leading zeros or not.
    @inlinable
    @inline(__always)
    func _writeSegmentAsLowercasedHexASCII(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        advancingIdx idx: inout Int,
        segmentIdx: Int
    ) {
        /// Get the segment's value as 4x nibbles (4bits) cramped into a UInt16.
        let segment = self._segment(atUncheckedIndex: segmentIdx)

        var nibbles = UInt32(segment)
        /// `nibbles` is in form `0x00_00_1c_2d` here.
        /// We make it `0x01_0c_02_0d`, so each nibble is in its own 8-bit lane.
        nibbles = ((nibbles &<< 8) | nibbles) & 0x00FF_00FF
        nibbles = ((nibbles &<< 4) | nibbles) & 0x0F0F_0F0F

        /// Now we add 6 to each lane, if it overflows to more than 4 bits, we know the lane contained
        /// a hex digit in range 10...15 (a...f). Otherwise it contained a digit in range 0...9.
        /// For `0x01_0c_02_0d`, we'll have something in form `0x00_01_00_01` here.
        /// If 1, then the lane contained a to f.
        let above9Mask = ((nibbles &+ 0x0606_0606) & 0x1010_1010) &>> 4
        /// 0x27
        let adjustment = UInt32(UInt8.asciiLowercasedA - UInt8.ascii0 - 10)
        /// This will make the a to f lanes contain 0x27, and the 0...9 lanes contain 0.
        /// 0x00_01_00_01 x 0x27 = 0x00_27_00_27
        let above9Base = above9Mask &* adjustment
        /// Now we add 0x30 (ascii code of 0) to each lane. If the lane contained 0...9, we'll be all-good.
        /// Otherwise we add the 0x27s to the lanes, which adds to he 0x30s and to the 0-15 values and
        /// will be in range (0x30 + 0x27 + 10)...(0x30 + 0x27 + 15), which is 0x61...0x6f,
        /// which is the range for ascii codes of a to f.
        let hexASCII = nibbles &+ 0x3030_3030 &+ above9Base

        /// Now let's take the leading 0s into account.
        /// We don't want to write any leading 0s.
        let systemRepresentationBytes = hexASCII.byteSwapped
        // segment.leadingZeroBitCount / 4
        let zeroDigitsCount = segment.leadingZeroBitCount &>> 2
        /// If all 4 digits are 0 we still need to write 1 zero.
        let zeroDigitsCountMax3 = min(3, zeroDigitsCount)
        let toStore = systemRepresentationBytes &>> (zeroDigitsCountMax3 &* 8)

        UnsafeMutableRawBufferPointer(buffer).storeBytes(
            of: toStore,
            toByteOffset: idx,
            as: UInt32.self
        )
        idx &+= 4 &- zeroDigitsCountMax3
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

        guard remainingBytesCount >= 2 else {
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
        @usableFromInline let _minRawLayoutBytes: UInt8
        @usableFromInline let _writeCsAtIdx: UInt8
        @usableFromInline let writeCsAtBeginning: Bool
        @usableFromInline let writeCsAtEnd: Bool
        @inlinable var segmentsCount: Int { Int(self._segmentsCount) }
        @inlinable var minRawLayoutBytes: Int { Int(self._minRawLayoutBytes) }
        @inlinable var writeCsAtIdx: Int { Int(self._writeCsAtIdx) }

        package init(
            _ packedIndices: UInt64,
            _ segmentsCount: UInt8,
            _ minRawLayoutBytes: UInt8,
            _ writeCsAtIdx: UInt8,
            _ writeCsAtBeginning: Bool,
            _ writeCsAtEnd: Bool
        ) {
            self.packedIndices = packedIndices
            self._segmentsCount = segmentsCount
            self._minRawLayoutBytes = minRawLayoutBytes
            self._writeCsAtIdx = writeCsAtIdx
            self.writeCsAtBeginning = writeCsAtBeginning
            self.writeCsAtEnd = writeCsAtEnd
        }
    }

    @usableFromInline
    package static let _segmentWriteTable: [SegmentWriteTableEntry] = [
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 11, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 9, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 11, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 11, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0500, 4, 9, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0605, 3, 7, 5, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 11, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 9, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 11, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 11, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 11, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 11, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0100, 4, 9, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0100, 4, 9, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0600, 3, 7, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0706, 2, 5, 6, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 11, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 9, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 11, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 11, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0500, 4, 9, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0605, 3, 7, 5, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 13, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 13, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 13, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 13, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 13, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 13, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 13, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0704_0302_0100, 6, 13, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 11, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 9, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 11, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 11, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 11, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 11, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 11, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 11, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0302_0100, 5, 11, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0702_0100, 4, 9, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0702_0100, 4, 9, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0702_0100, 4, 9, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0702_0100, 4, 9, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0100, 3, 7, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0100, 3, 7, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0700, 2, 5, 7, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0007, 1, 3, 7, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 11, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 9, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 11, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 11, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0500, 4, 9, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0605, 3, 7, 5, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0706_0504_0302_0100, 8, 15, 16, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 11, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 9, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0302_0100, 6, 13, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 11, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 11, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 11, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0602_0100, 5, 11, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0100, 4, 9, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0100, 4, 9, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0600, 3, 7, 6, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0706, 2, 5, 6, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0100, 6, 13, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 11, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 9, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0504_0302_0100, 6, 13, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0300, 6, 13, 3, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0502_0100, 6, 13, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0706_0504_0302, 6, 13, 2, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 11, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0100, 5, 11, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0500, 4, 9, 5, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0007_0605, 3, 7, 5, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0403, 5, 11, 3, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0004_0302_0100, 5, 11, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0007_0605_0400, 5, 11, 4, false, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0706_0504, 4, 9, 4, true, false),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 9, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 9, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 9, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 9, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 9, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 9, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 9, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0302_0100, 4, 9, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0002_0100, 3, 7, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0002_0100, 3, 7, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0002_0100, 3, 7, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0002_0100, 3, 7, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0100, 2, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0100, 2, 5, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0000, 1, 3, 15, false, true),
        IPv6Address.SegmentWriteTableEntry(0x0000_0000_0000_0000, 0, 2, 15, false, true),
    ]
}
