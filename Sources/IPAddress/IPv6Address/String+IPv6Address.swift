@available(SwiftStdlib 5.1, *)
extension IPv6Address: CustomStringConvertible {
    /// The textual representation of an IPv6 address.
    /// That is, 8 16-bits (2-bytes) separated by `:`, enclosed in `[]`, while using
    /// the compression sign (`::`) when possible.
    ///
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://datatracker.ietf.org/doc/html/rfc5952).
    @inlinable
    public var description: String {
        IPv6Address.makeDescription(
            address: _CompatibilityUInt128Typealias(
                _low: self.address._low,
                _high: self.address._high
            ),
            enclosingInSquareBrackets: true
        ) { (maxWriteableBytes, callback) in
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
    package static func makeDescription<Buffer>(
        address: _CompatibilityUInt128Typealias,
        enclosingInSquareBrackets: Bool,
        writingToUnsafeMutableBufferPointerOfUInt8: (
            _ maxWriteableBytes: Int,
            _ callbackReturningBytesWritten: (UnsafeMutableBufferPointer<UInt8>) -> Int
        ) throws -> Buffer
    ) rethrows -> Buffer {
        var rangeToCompress: Range<Int>? = nil
        var idx = 0
        /// idx < `7` instead of `8` because even if 7 is a zero it'll be a lone zero and
        /// we won't compress it anyway.
        while idx < 7 {
            guard isZero(address, octalIdx: idx) else {
                idx &+= 1
                continue
            }

            var endIndex = idx

            /// This range is guaranteed to be non-empty because we know idx < 7 (6 max)
            /// and (6+1)..<8 is still a range with 1 number in it.
            for nextIdx in (idx &+ 1)..<8 {
                guard isZero(address, octalIdx: nextIdx) else {
                    break
                }
                endIndex = nextIdx
            }

            if endIndex != idx {
                /// If a `rangeToCompress` already exists and is not smaller than the new range,
                /// then don't do anything.
                /// Otherwise use the `newRange` as the `rangeToCompress`.
                let newRange = idx..<endIndex
                if let existingRange = rangeToCompress {
                    if existingRange.count < newRange.count {
                        rangeToCompress = newRange
                    }
                } else {
                    rangeToCompress = newRange
                }
            }

            idx = endIndex &+ 1
        }

        assert(rangeToCompress?.isEmpty != true)

        /// Reserve the max possibly needed capacity.
        let bracketsCount = enclosingInSquareBrackets ? 2 : 0
        let segmentsCount = 8 &- (rangeToCompress?.count ?? 0)
        let colonsCount = max(segmentsCount &- 1, 2)
        /// If no brackets, we need 1 extra byte for the possible colon that we speculatively write
        let speculativeBytes = enclosingInSquareBrackets ? 0 : 1
        let toReserve = bracketsCount &+ colonsCount &+ (segmentsCount &* 4) &+ speculativeBytes

        return try writingToUnsafeMutableBufferPointerOfUInt8(toReserve) { buffer in
            var hexStorage: (UInt64, UInt64, UInt64, UInt64) = (0, 0, 0, 0)
            return withUnsafeMutableBytes(of: &hexStorage) { hexBytes in
                IPv6Address._expandLowercasedHexASCII(
                    address: address,
                    into: hexBytes
                )

                var writeIdx = 0

                /// `enclosingInSquareBrackets` is always known at compile time so should result in no branches
                if enclosingInSquareBrackets {
                    buffer[0] = .asciiLeftSquareBracket
                    writeIdx &+= 1
                }

                /// Reset `idx`. It was used in a loop above.
                idx = 0
                while idx < 8 {
                    if let rangeToCompress,
                        idx == rangeToCompress.lowerBound
                    {
                        buffer[writeIdx] = .asciiColon
                        writeIdx &+= 1

                        if idx == 0 {
                            /// Need 2 colons in this case, so '::'
                            buffer[writeIdx] = .asciiColon
                            writeIdx &+= 1
                        }

                        idx = rangeToCompress.upperBound &+ 1
                        continue
                    }

                    IPv6Address._writeSegmentFromHex(
                        into: buffer,
                        advancingIdx: &writeIdx,
                        hexBytes: hexBytes,
                        octalIdx: idx
                    )

                    /// Speculative write, but we've already made sure we have the extra 1 byte capacity if needed
                    buffer[writeIdx] = .asciiColon
                    writeIdx &+= idx < 7 ? 1 : 0
                    assert(writeIdx < buffer.count)

                    idx &+= 1
                }

                /// `enclosingInSquareBrackets` is always known at compile time so should result in no branches
                if enclosingInSquareBrackets {
                    buffer[writeIdx] = .asciiRightSquareBracket
                    writeIdx &+= 1
                }

                return writeIdx
            }
        }
    }

    @inlinable
    static func isZero(_ address: _CompatibilityUInt128Typealias, octalIdx idx: Int) -> Bool {
        self.segment(address, octalIdx: idx) == 0
    }

    @inlinable
    @inline(__always)
    static func segment(_ address: _CompatibilityUInt128Typealias, octalIdx idx: Int) -> UInt16 {
        let hi = address._high
        let lo = address._low
        let word = idx < 4 ? hi : lo
        let shift = (3 &- (idx & 3)) &* 16
        return UInt16(truncatingIfNeeded: word &>> shift)
    }

    /// Expands the 16 address bytes into 32 lowercased hex ASCII bytes, most significant nibble first.
    /// Written as a flat, branch-free loop so LLVM auto-vectorizes it, like `Span.isASCII`.
    @inlinable
    static func _expandLowercasedHexASCII(
        address: _CompatibilityUInt128Typealias,
        into hexStorage: UnsafeMutableRawBufferPointer
    ) {
        withUnsafeBytes(of: address.bigEndian) { bigBytes in
            for idx in 0..<16 {
                let byte = bigBytes[idx]
                let high = byte &>> 4
                let low = byte & 0x0F
                let startOffset = 2 &* idx
                hexStorage[startOffset] = _lowercasedHexASCII(nibble: high)
                hexStorage[startOffset &+ 1] = _lowercasedHexASCII(nibble: low)
            }
        }
    }

    /// Maps a single hex nibble (0...15) to its lowercased ASCII byte.
    @inlinable
    static func _lowercasedHexASCII(nibble: UInt8) -> UInt8 {
        assert(nibble < 16)
        return nibble > 9
            ? nibble &+ UInt8.asciiLowercasedA &- 10
            : nibble &+ UInt8.ascii0
    }

    /// Equivalent to `String(bytePairAsUInt16, radix: 16, uppercase: false)`, but faster, reading
    /// the already-expanded chars for `octalIdx` from `hex` and suppressing leading zeros.
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

        /// Always write, but only advance past it when it should be kept.
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
