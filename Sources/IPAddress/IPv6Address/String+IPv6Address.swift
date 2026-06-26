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
        let compressionRange = self.findCompressionSignRange()

        assert(
            compressionRange.lowerBound < compressionRange.upperBound
                || compressionRange.upperBound == 16
        )

        /// Reserve the max possibly needed capacity.
        let bracketsCount = enclosingInSquareBrackets ? 2 : 0
        let segmentsCount = 8 &- compressionRange.count
        let colonsCount = max(segmentsCount &- 1, 2)
        /// If no brackets, we need 1 extra byte for the possible colon that we speculatively write
        let speculativeBytes = enclosingInSquareBrackets ? 0 : 1
        let toReserve = bracketsCount &+ colonsCount &+ (segmentsCount &* 4) &+ speculativeBytes

        return try writingToUnsafeMutableBufferPointerOfUInt8(toReserve) { buffer in
            withUnsafeTemporaryAllocation(byteCount: 32, alignment: 1) { hexBytes in
                self._expandToLowercasedHexASCII(into: hexBytes)

                var writeIdx = 0

                /// `enclosingInSquareBrackets` is always known at compile time so should result in no branches
                if enclosingInSquareBrackets {
                    buffer[0] = .asciiLeftSquareBracket
                    writeIdx &+= 1
                }

                for idx in 0..<8 {
                    IPv6Address._writeSegment(
                        into: buffer,
                        advancingIdx: &writeIdx,
                        hexBytes: hexBytes,
                        octalIdx: idx,
                        compressionRange: compressionRange
                    )
                }

                /// `enclosingInSquareBrackets` is always known at compile time so should result in no branches
                if enclosingInSquareBrackets {
                    buffer[writeIdx] = .asciiRightSquareBracket
                    writeIdx &+= 1
                }

                assert(writeIdx <= toReserve)

                return writeIdx
            }
        }
    }

    /// Returns (16, 16) if no compression sign is found, otherwise the bounds of the compression sign.
    @inlinable
    @inline(__always)
    func findCompressionSignRange() -> Range<Int> {
        let zeroSegments = self.makeSegmentsMask()
        var runStarts = zeroSegments
        var longestRunStarts = zeroSegments
        var longestRunLength = 0
        while runStarts != 0 {
            longestRunStarts = runStarts
            runStarts &= runStarts &>> 1
            longestRunLength &+= 1
        }

        let hasRun = longestRunLength >= 2 ? 1 : 0
        let start = longestRunStarts.trailingZeroBitCount
        let lowerBound = hasRun &* start &+ (1 &- hasRun) &* 16
        let upperBound = hasRun &* (start &+ longestRunLength &- 1) &+ (1 &- hasRun) &* 16
        return Range(uncheckedBounds: (lowerBound, upperBound))
    }

    /// Returns a UInt8, each bit representing whether
    /// the corresponding IPv6 segment is zero (0) or not (1).
    @inlinable
    @inline(__always)
    func makeSegmentsMask() -> UInt8 {
        let highNibble = IPv6Address.makeNibbleFor4Segments(of: self.address._high)
        let lowNibble = IPv6Address.makeNibbleFor4Segments(of: self.address._low)
        return highNibble | (lowNibble &<< 4)
    }

    /// Makes a nibble for 4 segments of a 64-bit word,
    /// each bit representing whether the segment is zero (0) or not (1).
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

    /// Equivalent to `String(bytePairAsUInt16, radix: 16, uppercase: false)`, but faster.
    @inlinable
    @inline(__always)
    static func _writeSegment(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        advancingIdx idx: inout Int,
        hexBytes: UnsafeMutableRawBufferPointer,
        octalIdx: Int,
        compressionRange: Range<Int>
    ) {
        /// cs == compression sign
        let csLowerBound = compressionRange.lowerBound
        let csUpperBound = compressionRange.upperBound
        let isLowerBoundOfCs = octalIdx == csLowerBound ? 1 : 0
        let isUpperBoundOfCs = octalIdx == csUpperBound ? 1 : 0
        let isBelowCs = octalIdx < csLowerBound ? 1 : 0
        let isAboveCs = octalIdx > csUpperBound ? 1 : 0
        let isNotWithinCs = isBelowCs | isAboveCs

        let isNotLastSegment = octalIdx != csUpperBound &+ 1 ? 1 : 0
        let isNotFirstSegment = octalIdx != 0 ? 1 : 0
        let needsTheSeparatorColon = isNotWithinCs & isNotLastSegment & isNotFirstSegment
        let needsColon = isLowerBoundOfCs | isUpperBoundOfCs | needsTheSeparatorColon

        buffer[idx] = .asciiColon
        idx &+= needsColon

        let base = octalIdx &* 4
        let _1 = hexBytes[base]
        let _2 = hexBytes[base &+ 1]
        let _3 = hexBytes[base &+ 2]
        let _4 = hexBytes[base &+ 3]

        let nonZero1 = isNotWithinCs & (_1 == UInt8.ascii0 ? 0 : 1)
        let nonZero2 = _2 == UInt8.ascii0 ? 0 : 1
        let nonZero3 = _3 == UInt8.ascii0 ? 0 : 1

        var soFarNonZero = nonZero1
        buffer[idx] = _1
        idx &+= soFarNonZero

        buffer[idx] = _2
        soFarNonZero |= nonZero2
        idx &+= soFarNonZero

        buffer[idx] = _3
        soFarNonZero |= nonZero3
        idx &+= soFarNonZero

        buffer[idx] = _4
        idx &+= isNotWithinCs
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
