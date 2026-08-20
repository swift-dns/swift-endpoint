public import CSwiftEndpoint

@available(SwiftStdlib 5.1, *)
extension IPv6Address: CustomStringConvertible {
    /// Options for adjusting the textual representation of an IPv6 address.
    public struct DescriptionOptions: Sendable, OptionSet {
        /// The raw value of the description options.
        public let rawValue: Int

        /// Initialize a description options with a raw value.
        @inlinable
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Enclose the description in square brackets.
        /// Useful for when the description is used in different contexts such as when followed by a port number.
        /// Example: `[2001:db8::1]` instead of `2001:db8::1`.
        @inlinable
        public static var encloseInSquareBrackets: Self {
            Self(rawValue: 1 << 0)
        }

        /// If suitable, print the last 32 bits in the mixed notation format as described in
        /// [RFC 4291, Section 2.2](https://datatracker.ietf.org/doc/html/rfc4291#section-2.2),
        /// Currently only happens for well-known IPv4-mapped IP addresses (`::ffff:0:0/96`).
        ///
        /// Example: `::ffff:204.152.189.116` instead of `::ffff:cc98:bd74`.
        @inlinable
        public static var useMixedNotation: Self {
            Self(rawValue: 1 << 1)
        }

        /// Unconditionally print the last 32 bits in the mixed notation format as described in
        /// [RFC 4291, Section 2.2](https://datatracker.ietf.org/doc/html/rfc4291#section-2.2).
        ///
        /// Supersedes `useMixedNotation`.
        /// Useful for IPv4-embedding subnets other than `::ffff:0:0/96`, such as the NAT64 subnets,
        /// so they can generate mixed notation descriptions on demand.
        ///
        /// Example: `64:ff9b::192.0.2.33` instead of `64:ff9b::c000:221`.
        @inlinable
        public static var forceMixedNotation: Self {
            Self(rawValue: 1 << 2)
        }

        /// Options for compliance with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://datatracker.ietf.org/doc/html/rfc5952).
        /// Consists of `useMixedNotation`.
        @inlinable
        public static var standardOptions: Self {
            [.useMixedNotation]
        }
    }

    /// The textual representation of an IPv6 address.
    /// That is, 8 16-bits (2-bytes) separated by `:`, while using
    /// the compression sign (`::`) and mixed ipv4-embedded notation where applicable.
    ///
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://datatracker.ietf.org/doc/html/rfc5952).
    ///
    /// As examples, as discussed in the aforementioned RFC, the following descriptions might
    /// be emitted for their corresponding IP addresses:
    /// `::`, `::ffff:192.168.1.1`, `2001:db8:85a3::100`.
    /// Letters are always lowercased and no square brackets are present.
    /// For the well-known IPv4-mapped subnet `::ffff:0:0/96`, the mixed notation is emitted.
    ///
    /// Use `IPv6Address.description(options:)` for a customized description.
    @inlinable
    public var description: String {
        self._description_inlined(options: .standardOptions)
    }

    /// The textual representation of an IPv6 address.
    /// That is, 8 16-bits (2-bytes) separated by `:`,
    /// while using the compression sign (`::`) where applicable.
    /// Default options also add mixed ipv4-embedded notation where applicable.
    ///
    /// As examples, as discussed in the aforementioned RFC, the following descriptions might
    /// be emitted for their corresponding IP addresses.
    ///
    /// `::`, `::ffff:192.168.1.1`, `2001:db8:85a3::100`.
    /// If `useMixedNotation` is disabled, `::ffff:192.168.1.1` will be emitted as `::ffff:c0a8:101`.
    /// If `forceMixedNotation` is enabled, `2001:db8:85a3::100` will be emitted as
    /// `2001:db8:85a3::0.0.1.0`.
    /// If `encloseInSquareBrackets` is enabled, `2001:db8:85a3::100` will be emitted as `[2001:db8:85a3::100]`.
    /// Letters are always in lowercase.
    @inlinable
    public func description(options: DescriptionOptions = .standardOptions) -> String {
        self._description_inlined(options: options)
    }

    @inlinable
    @inline(always)
    func _description_inlined(options: DescriptionOptions) -> String {
        unsafe self.makeDescription(options: options) {
            (maxWriteableBytes, callback) in
            unsafe String(unsafeUninitializedCapacity_Compatibility: maxWriteableBytes) { buffer in
                unsafe callback(UnsafeMutableRawBufferPointer(buffer))
            }
        }
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv6Address {
    @inlinable
    @inline(always)
    package func makeDescription<Buffer, E: Error>(
        options: DescriptionOptions,
        writingToUnsafeMutableBufferPointerOfUInt8: (
            _ maxWriteableBytes: Int,
            _ callbackReturningBytesWritten: (UnsafeMutableRawBufferPointer) -> Int
        ) throws(E) -> Buffer
    ) throws(E) -> Buffer {
        let encloseInSquareBrackets = options.contains(.encloseInSquareBrackets)
        let forceMixedNotationOption = options.contains(.forceMixedNotation)
        let useMixedNotationOption = options.contains(.useMixedNotation)

        let isIPv4Mapped = self.isIPv4Mapped
        let useMixedNotationApplies = useMixedNotationOption && isIPv4Mapped
        let mustUseMixedNotation = forceMixedNotationOption || useMixedNotationApplies

        /// Intentional branchy code around all `mustUseMixedNotation`s.
        /// `mustUseMixedNotation` is often `false` so it will be a well-predicted branch.
        if mustUseMixedNotation {
            return try unsafe self.makeDescription(
                encloseInSquareBrackets: encloseInSquareBrackets,
                mustUseMixedNotation: true,
                writingToUnsafeMutableBufferPointerOfUInt8:
                    writingToUnsafeMutableBufferPointerOfUInt8
            )
        } else {
            return try unsafe self.makeDescription(
                encloseInSquareBrackets: encloseInSquareBrackets,
                mustUseMixedNotation: false,
                writingToUnsafeMutableBufferPointerOfUInt8:
                    writingToUnsafeMutableBufferPointerOfUInt8
            )
        }
    }

    @inlinable
    @inline(always)
    func makeDescription<Buffer, E: Error>(
        encloseInSquareBrackets: Bool,
        mustUseMixedNotation: Bool,
        writingToUnsafeMutableBufferPointerOfUInt8: (
            _ maxWriteableBytes: Int,
            _ callbackReturningBytesWritten: (UnsafeMutableRawBufferPointer) -> Int
        ) throws(E) -> Buffer
    ) throws(E) -> Buffer {
        var addressToPrint: IPv6Address = self
        /// This function in always inlined with static `mustUseMixedNotation` values.
        /// So all these branches around `mustUseMixedNotation` will be eliminated at compile time.
        if mustUseMixedNotation {
            /// The last 2 segments are always written as "0:0", which is 3 bytes.
            /// Never as a trailing compression sign "::" because `writeCsAtEnd` is only set when
            /// `upperBound == 7`, and since we mask off 2 segments, upperBound <= 5.
            addressToPrint = IPv6Address(
                UnsignedInteger128(
                    _low: self.address._low & 0xFFFF_FFFF_0000_0000,
                    _high: self.address._high
                )
            )
        }

        var mask = self.makeSegmentsMask()
        if mustUseMixedNotation {
            mask &= 0b0011_1111
        }
        let entry = SegmentWriteTableEntry.Unpacked(forMask: mask)
        let digitsPrintCountNoTrailing =
            addressToPrint.countAllDigitsRequiredToPrintExcludingTrailingDigits()

        let ipv4EmbeddedWalkBackBytes = 3
        var mixedNotationReserve: Int = 0
        if mustUseMixedNotation {
            let embeddedIPv4 = IPv4Address(UInt32(truncatingIfNeeded: self.address._low))
            let ipv4Length = embeddedIPv4.textualRepresentationLength
            /// The embedded IPv4 replaces the masked-off last two segments, which the walk-back bytes
            /// account for.
            /// The 2 headroom bytes the IPv4 write needs are already part of `minReserveBytes`.
            mixedNotationReserve = ipv4Length &- ipv4EmbeddedWalkBackBytes
        }

        var lastSegmentReserve: Int = 0
        if !mustUseMixedNotation {
            let lastSegmentBits = self.address._low & 0xFFFF
            let lastSegmentIsSingleDigit = lastSegmentBits <= 0xF
            /// We do speculative writes, but if the last segment is a single hex digit, then we only
            /// write 1 byte while we still need to reserve 4 bytes of headroom so the speculative write
            /// can fit. So we need to reserve 1 extra byte for that to have the full room needed.
            /// This only needs to happen if this is not a mixed-notation writing.
            /// Also if `writeCsAtEnd` is true, then we already have the needed speculative bytes room.
            let lastSegmentReserveInitial = lastSegmentIsSingleDigit ? 1 : 0
            lastSegmentReserve = entry.writeCsAtEnd ? 0 : lastSegmentReserveInitial
        }

        /// `minReserveBytes` already contains the 2 speculative bytes needed without square
        /// brackets. One of the brackets is written at the end so it can consume one of those
        /// speculative bytes of room, so we only need to reserve 1 extra.
        let bracketsReserve = encloseInSquareBrackets ? 1 : 0
        /// Exact required bytes to print, including headroom bytes for speculative writes.
        let toReserve =
            entry.minReserveBytes
            &+ digitsPrintCountNoTrailing
            &+ bracketsReserve
            &+ lastSegmentReserve
            &+ mixedNotationReserve

        return try unsafe writingToUnsafeMutableBufferPointerOfUInt8(toReserve) { buffer in
            var writeIdx = 0

            unsafe buffer[0] = .asciiLeftSquareBracket
            writeIdx &+= encloseInSquareBrackets ? 1 : 0

            let packedSegmentInfos = entry.packedSegmentInfos
            let range = unsafe Range(uncheckedBounds: (0, entry.segmentsCount))
            for offset in range {
                let segmentInfo = packedSegmentInfos &>> (offset &* 5)
                let segmentIdx = Int(truncatingIfNeeded: segmentInfo & 0x7)
                let colonsCount = Int(truncatingIfNeeded: (segmentInfo &>> 3) & 0x3)

                unsafe buffer[writeIdx] = .asciiColon
                unsafe buffer[writeIdx &+ 1] = .asciiColon
                /// We've reserved 2 speculative bytes worth of room so this is safe:
                writeIdx &+= colonsCount

                unsafe addressToPrint._writeSegmentAsLowercasedHexASCII_RequiringMinimumCapacityOf4(
                    into: buffer,
                    advancingIdx: &writeIdx,
                    segmentIdx: segmentIdx
                )
            }

            /// We've reserved 2 speculative bytes worth of room so this is safe:
            unsafe buffer[writeIdx] = .asciiColon
            unsafe buffer[writeIdx &+ 1] = .asciiColon
            writeIdx &+= entry.writeCsAtEnd ? 2 : 0

            if mustUseMixedNotation {
                assert(!entry.writeCsAtEnd)

                let embeddedIPv4 = IPv4Address(UInt32(truncatingIfNeeded: self.address._low))
                let lowerBound = writeIdx &- ipv4EmbeddedWalkBackBytes
                let ipv4Buffer = unsafe UnsafeMutableRawBufferPointer(
                    rebasing: buffer[lowerBound...]
                )
                let written =
                    unsafe embeddedIPv4.writeTextualRepresentation_Requiring2HeadroomBytes(
                        into: ipv4Buffer
                    )
                writeIdx = lowerBound &+ written
            }

            unsafe buffer[writeIdx] = .asciiRightSquareBracket
            writeIdx &+= encloseInSquareBrackets ? 1 : 0

            assert(
                writeIdx
                    == toReserve
                    &- (encloseInSquareBrackets ? 1 : 2)
                    &+ (entry.writeCsAtEnd ? 1 : 0)
                    &- lastSegmentReserve
            )

            return writeIdx
        }
    }

    /// Returns a UInt8, each bit representing whether
    /// the corresponding IPv6 segment is all-zero (1) or not (0).
    @inlinable
    @inline(always)
    func makeSegmentsMask() -> UInt8 {
        let highNibble = IPv6Address.makeNibbleFor4Segments(of: self.address._high)
        let lowNibble = IPv6Address.makeNibbleFor4Segments(of: self.address._low)
        return highNibble | (lowNibble &<< 4)
    }

    /// Makes a nibble for 4 segments of a 64-bit word,
    /// each bit representing whether the segment is all-zero (1) or not (0).
    @inlinable
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
        let m1111: UInt64 = 0b1000000000000000_1000000000000000_1000000000000000_1000000000000000
        let lowBitsZeroIfLaneZero = ((topBitsZeroIfLaneZero & m1111) &>> 15)
        let m1000100101: UInt64 =
            0b0000000000001000_0000000000000100_0000000000000010_0000000000000001
        /// Puts each low bit of a lane, into bits 49th-52nd.
        /// Then we bit shift by 48 to get each lane's bits into bits 1st-4th.
        let mask = ((lowBitsZeroIfLaneZero &* m1000100101) &>> 48)
        return UInt8(truncatingIfNeeded: mask)
    }

    /// Counts the number of digits that will need to be written excluding the trailing
    /// digit that is always written even if it's 0.
    @inlinable
    @inline(always)
    func countAllDigitsRequiredToPrintExcludingTrailingDigits() -> Int {
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
    func _segment(atUncheckedIndex segmentIdx: Int) -> UInt16 {
        assert(segmentIdx >= 0 && segmentIdx <= 7)
        let word = segmentIdx < 4 ? self.address._high : self.address._low
        let shift = (3 &- (segmentIdx & 3)) &* 16
        return UInt16(truncatingIfNeeded: word &>> shift)
    }

    @inlinable
    func _writeSegmentAsLowercasedHexASCII_RequiringMinimumCapacityOf4(
        into buffer: UnsafeMutableRawBufferPointer,
        advancingIdx idx: inout Int,
        segmentIdx: Int
    ) {
        /// Get the segment's value as 4x nibbles cramped into a UInt16.
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

        unsafe buffer.storeBytes(
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
    ///
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    /// Parses all IPv4-embedded address forms where the embedded IPv4 is in the last 32 bits.
    /// This includes blocks that are not used for embedded IPv4 addresses in practice or are deprecated.
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
    @inline(always)
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

        let startsWithBracket = span[0] == .asciiLeftSquareBracket
        let endsWithBracket = span[span.count &- 1] == .asciiRightSquareBracket
        switch (startsWithBracket, endsWithBracket) {
        case (false, false):
            break
        case (true, true):
            span = span.extracting(1..<(span.count &- 1))
        case (true, false), (false, true):
            return false
        }

        /// 2 == "::".count
        guard span.count >= 2 else {
            return false
        }

        let count = span.count
        /// cs == compression sign
        var beforeCs = _CompatibilityUInt128Typealias.zero
        var afterCs = _CompatibilityUInt128Typealias.zero
        var segmentsCount = 0
        var segmentsCountBeforeCs = -1
        var currentSegmentValue: UInt16 = 0
        var segmentDigitIdx = 0
        var idx = 0

        /// Special-case handling for when there is a compression sign at the beginning
        if span[0] == .asciiColon {
            guard unsafe span[unchecked: 1] == .asciiColon else {
                return false
            }
            segmentsCountBeforeCs = 0
            idx = 2
        }

        while idx < count {
            let byte = unsafe span[unchecked: idx]

            if let digit = UInt8.mapHexadecimalByteToUInt8(byte) {
                if segmentDigitIdx == 4 {
                    return false
                }

                currentSegmentValue = (currentSegmentValue &<< 4) | UInt16(digit)
                segmentDigitIdx &+= 1
                idx &+= 1

                continue
            }

            if byte == .asciiDot {
                /// The embedded IPv4 address starts where the digits of this segment started.
                var ipv4Address: UInt32 = 0
                guard
                    segmentDigitIdx > 0,
                    IPv4Address.parseIPv4(
                        span: unsafe span.extracting(
                            unchecked: Range(
                                uncheckedBounds: (idx &- segmentDigitIdx, count)
                            )
                        ),
                        address: &ipv4Address
                    )
                else {
                    return false
                }

                let isBeforeCs = segmentsCountBeforeCs == -1
                let forBeforeCs =
                    (beforeCs &<< 32) | _CompatibilityUInt128Typealias(ipv4Address)
                let forAfterCs =
                    (afterCs &<< 32) | _CompatibilityUInt128Typealias(ipv4Address)
                beforeCs = isBeforeCs ? forBeforeCs : beforeCs
                afterCs = isBeforeCs ? afterCs : forAfterCs

                segmentsCount &+= 2
                segmentDigitIdx = 0

                break
            }

            guard byte == .asciiColon, segmentDigitIdx > 0 else {
                return false
            }

            let isBeforeCs = segmentsCountBeforeCs == -1
            let forBeforeCs =
                (beforeCs &<< 16) | _CompatibilityUInt128Typealias(currentSegmentValue)
            let forAfterCs =
                (afterCs &<< 16) | _CompatibilityUInt128Typealias(currentSegmentValue)
            beforeCs = isBeforeCs ? forBeforeCs : beforeCs
            afterCs = isBeforeCs ? afterCs : forAfterCs

            segmentsCount &+= 1
            currentSegmentValue = 0
            segmentDigitIdx = 0
            idx &+= 1

            /// A trailing colon is only valid as part of a compression sign.
            guard idx < count else {
                return false
            }

            let isColon = unsafe span[unchecked: idx] == .asciiColon
            if isColon, !isBeforeCs {
                return false
            }

            segmentsCountBeforeCs = isColon ? segmentsCount : segmentsCountBeforeCs
            idx &+= isColon ? 1 : 0
        }

        let isBeforeCs = segmentsCountBeforeCs == -1
        let wasParsingSegments = segmentDigitIdx > 0

        let _forBeforeCs =
            (beforeCs &<< 16) | _CompatibilityUInt128Typealias(currentSegmentValue)
        let forBeforeCs = wasParsingSegments ? _forBeforeCs : beforeCs
        let _forAfterCs =
            (afterCs &<< 16) | _CompatibilityUInt128Typealias(currentSegmentValue)
        let forAfterCs = wasParsingSegments ? _forAfterCs : afterCs
        beforeCs = isBeforeCs ? forBeforeCs : beforeCs
        afterCs = isBeforeCs ? afterCs : forAfterCs

        segmentsCount &+= wasParsingSegments ? 1 : 0

        let _segmentsCountBeforeCs = max(segmentsCountBeforeCs, 0)
        address = (beforeCs &<< (16 &* (8 &- _segmentsCountBeforeCs))) | afterCs

        let segmentCountIs8 = segmentsCount == 8
        var success = segmentsCount < 8
        success = isBeforeCs ? segmentCountIs8 : success

        return success
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv6Address {
    @usableFromInline
    package struct SegmentWriteTableEntry: Sendable, Equatable {

        @usableFromInline
        package struct Unpacked: Sendable, Equatable {
            /// The packed segment-info of the writable segments in the address.
            /// Bits 0-2 of each segment-info are the segment index, bits 3-4 are how many colons
            /// precede that segment.
            @usableFromInline package let packedSegmentInfos: UInt64
            /// The number of writable segments in the address.
            @usableFromInline package let segmentsCount: Int
            /// The minimum number of bytes to reserve to print the address in its raw layout,
            /// assuming each segment is only 1 hex digit long.
            /// Includes the 2 speculative bytes the writer always needs beyond the exact output,
            /// 1 less when a trailing compression sign already occupies one of them.
            @usableFromInline package let minReserveBytes: Int
            /// Write the compression sign at the end of the address.
            @usableFromInline package let writeCsAtEnd: Bool

            @inlinable
            package init(
                packedSegmentInfos: UInt64,
                segmentsCount: Int,
                minReserveBytes: Int,
                writeCsAtEnd: Bool
            ) {
                self.packedSegmentInfos = packedSegmentInfos
                self.segmentsCount = segmentsCount
                self.minReserveBytes = minReserveBytes
                self.writeCsAtEnd = writeCsAtEnd
            }

            /// The entry for the given all-zero-segments mask.
            @inlinable
            @inline(always)
            package init(forMask mask: UInt8) {
                self = SegmentWriteTableEntry(forMask: mask).unpack()
            }
        }

        /// - Bits 0-39: 8 segment-infos, 5 bits each. Bits 0-2 of each segment-info are the segment index,
        ///   bits 3-4 are how many colons precede that segment.
        /// - Bits 40-43: segments count.
        /// - Bits 44-49: min reserve bytes.
        /// - Bit 50: whether to write the compression sign at the end.
        @usableFromInline let rawValue: UInt64

        @inlinable
        package init(_ rawValue: UInt64) {
            self.rawValue = rawValue
        }

        /// The entry for the given all-zero-segments mask.
        @inlinable
        @inline(always)
        package init(forMask mask: UInt8) {
            self.init(cswift_endpoint_ipv6_segment_write_entry(mask))
        }

        @inlinable
        package func unpack() -> Unpacked {
            Unpacked(
                packedSegmentInfos: self.rawValue & 0xFF_FFFF_FFFF,
                segmentsCount: Int(truncatingIfNeeded: (self.rawValue &>> 40) & 0xF),
                minReserveBytes: Int(truncatingIfNeeded: (self.rawValue &>> 44) & 0x3F),
                writeCsAtEnd: (self.rawValue &>> 50) & 1 == 1
            )
        }
    }
}
