#if os(Linux) || os(FreeBSD) || os(Android)

#if canImport(Glibc)
@preconcurrency public import Glibc
#elseif canImport(Musl)
@preconcurrency public import Musl
#elseif canImport(Android)
@preconcurrency public import Android
#endif

#elseif os(Windows)
public import ucrt
#elseif canImport(Darwin)
public import Darwin
#elseif canImport(WASILibc)
@preconcurrency public import WASILibc
#else
#error("The String+IPv6Address module was unable to identify your C library.")
#endif

@available(SwiftStdlib 5.1, *)
extension IPv6Address: CustomStringConvertible {
    /// The textual representation of an IPv6 address.
    /// That is, 8 16-bits (2-bytes) separated by `:`, enclosed in `[]`, while using
    /// the compression sign (`::`) when possible.
    ///
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://tools.ietf.org/html/rfc5952).
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
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://tools.ietf.org/html/rfc5952).
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
        /// Short-circuit "0".
        if self.address == .zero {
            let toReserve = enclosingInSquareBrackets ? 4 : 2
            return try writingToUnsafeMutableBufferPointerOfUInt8(toReserve) { ptr in
                /// A bit of branching here, and in the rest of the function for `enclosingInSquareBrackets`,
                /// but theoretically shouldn't matter as `enclosingInSquareBrackets` is always known
                /// at compile time and the compiler should be able to optimize it away considering
                /// this function is internal and `inline(__always)`.
                if enclosingInSquareBrackets {
                    ptr[0] = .asciiLeftSquareBracket
                    ptr[1] = .asciiColon
                    ptr[2] = .asciiColon
                    ptr[3] = .asciiRightSquareBracket
                } else {
                    ptr[0] = .asciiColon
                    ptr[1] = .asciiColon
                }
                return toReserve
            }
        }

        func isZero(octalIdx idx: Int) -> Bool {
            self.segment(octalIdx: idx) == 0
        }

        var rangeToCompress: Range<Int>? = nil
        var idx = 0
        /// idx < `7` instead of `8` because even if 7 is a zero it'll be a lone zero and
        /// we won't compress it anyway.
        while idx < 7 {
            guard isZero(octalIdx: idx) else {
                idx &+= 1
                continue
            }

            var endIndex = idx

            /// This range is guaranteed to be non-empty because we know idx < 7 (6 max)
            /// and (6+1)..<8 is still a range with 1 number in it.
            for nextIdx in (idx + 1)..<8 {
                guard isZero(octalIdx: nextIdx) else {
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
        let toReserve = bracketsCount &+ colonsCount &+ (segmentsCount &* 4)

        return try writingToUnsafeMutableBufferPointerOfUInt8(toReserve) { buffer in
            var writeIdx = 0

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

                let value = self.segment(octalIdx: idx)
                IPv6Address._writeUInt16AsLowercasedASCII(
                    into: buffer,
                    advancingIdx: &writeIdx,
                    bytePair: value
                )

                if idx < 7 {
                    buffer[writeIdx] = .asciiColon
                    writeIdx &+= 1
                }

                idx &+= 1
            }

            if enclosingInSquareBrackets {
                buffer[writeIdx] = .asciiRightSquareBracket
                writeIdx &+= 1
            }

            return writeIdx
        }
    }

    @inlinable
    @inline(__always)
    func segment(octalIdx idx: Int) -> UInt16 {
        let hi = self.address._high
        let lo = self.address._low
        let word = idx < 4 ? hi : lo
        let shift = (3 &- (idx & 3)) &* 16
        return UInt16(truncatingIfNeeded: word &>> shift)
    }

    /// Equivalent to `String(bytePairAsUInt16, radix: 16, uppercase: false)`, but faster.
    @inlinable
    static func _writeUInt16AsLowercasedASCII(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        advancingIdx idx: inout Int,
        bytePair: UInt16
    ) {
        let _1 = UInt8(truncatingIfNeeded: bytePair &>> 8) &>> 4
        let _2 = UInt8(truncatingIfNeeded: bytePair &>> 8) & 0x0F
        let _3 = UInt8(truncatingIfNeeded: bytePair) &>> 4
        let _4 = UInt8(truncatingIfNeeded: bytePair) & 0x0F

        /// Always write, but only advance past it when it should be kept.
        var notAllZerosSoFar = _1 != 0
        buffer[idx] = _lowercasedHexASCII(nibble: _1)
        idx &+= notAllZerosSoFar ? 1 : 0

        notAllZerosSoFar = notAllZerosSoFar || _2 != 0
        buffer[idx] = _lowercasedHexASCII(nibble: _2)
        idx &+= notAllZerosSoFar ? 1 : 0

        notAllZerosSoFar = notAllZerosSoFar || _3 != 0
        buffer[idx] = _lowercasedHexASCII(nibble: _3)
        idx &+= notAllZerosSoFar ? 1 : 0

        buffer[idx] = _lowercasedHexASCII(nibble: _4)
        idx &+= 1
    }

    /// Maps a single hex nibble (0...15) to its lowercased ASCII byte.
    @inlinable
    static func _lowercasedHexASCII(nibble: UInt8) -> UInt8 {
        nibble > 9
            ? nibble &+ UInt8.asciiLowercasedA &- 10
            : nibble &+ UInt8.ascii0
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

        self.init(.zero)

        /// Swift stores integers in little-endian, so we need to do a little bit of gymnastics here
        /// and write backwards.
        var noIPv4MappedSegments = true
        let success = self.parseIPv6(
            span: span,
            noIPv4MappedSegments: &noIPv4MappedSegments
        )

        guard success,
            noIPv4MappedSegments || CIDR<IPv6Address>.ipv4Mapped.contains(self)
        else {
            return nil
        }
    }

    @inlinable
    @inline(__always)
    mutating func parseIPv6(span: Span<UInt8>, noIPv4MappedSegments: inout Bool) -> Bool {
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
        for idx in span.indices {
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
                self.address |= UnsignedInt128(currentSegmentValue) &<< shift

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
                self.address |= UnsignedInt128(ipv4.address) &<< shift

                noIPv4MappedSegments = false
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
            self.address |= UnsignedInt128(currentSegmentValue) &<< shift
        }

        if beforeCsBytesCountRemaining != -1 {
            guard remainingBytesCount >= 4 else {
                return false
            }
            /// cs == compression sign
            let afterCsBytesCount = beforeCsBytesCountRemaining &- remainingBytesCount

            withUnsafeMutableBytes(of: &self.address) { addressBufferPtr in
                let addressPtr = addressBufferPtr.baseAddress.unsafelyUnwrapped
                /// Swift stores integers in little-endian, so we need to do a little bit of gymnastics.
                ///
                /// Example:
                /// Assume at the end of this parsing process we need to have:
                /// 0x2001 0db8 85a3 0000 0000 0000 0100 0020
                ///
                /// For that, at this point in the process, the `self.address` looks like this:
                /// 0x2001 0db8 85a3 0100 0020 0000 0000 0000
                ///
                /// We need to move the bytes so it becomes like the first one.
                ///
                /// In little endian the integer we have right here looks like:
                /// 0x0000 0000 0000 0200 0010 3a58 08bd 1002
                ///
                /// For clearer demonstration, I'll use the big-endian representation in each ipv6 segment.
                /// So we assume in little-endian the integer looks like this:
                /// 0x0000 0000 0000 0020 0100 85a3 0db8 2001

                /// In this example, the memmove below will turn this:
                /// 0x0000 0000 0000 0020 0100 85a3 0db8 2001
                /// into this:
                /// 0x0020 0100 0000 0020 0100 85a3 0db8 2001
                ///   ~~^  ~~^
                memmove(
                    addressPtr,
                    addressPtr.advanced(by: beforeCsBytesCountRemaining &- afterCsBytesCount),
                    afterCsBytesCount
                )

                /// Now that we have:
                /// 0x0020 0100 0000 0020 0100 85a3 0db8 2001
                ///
                /// We set the middle 0020 0100 to zeros:
                /// 0x0020 0100 0000 0000 0000 85a3 0db8 2001
                ///                  ~~^  ~~^
                memset(
                    addressPtr.advanced(by: beforeCsBytesCountRemaining &- remainingBytesCount),
                    0,
                    remainingBytesCount
                )
            }
            /// Hurray! Now we have the correct ipv6 address!
            /// Swift will read this as:
            /// 0x2001 0db8 85a3 0000 0000 0000 0100 0020
            /// which is what we aimed for.
            return true
        } else {
            return remainingBytesCount == 0
        }
    }
}
