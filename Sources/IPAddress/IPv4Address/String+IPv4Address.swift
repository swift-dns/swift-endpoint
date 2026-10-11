@available(SwiftStdlib 5.1, *)
extension IPv4Address: CustomStringConvertible {
    /// The textual representation of an IPv4 address.
    @inlinable
    public var description: String {
        /// 15 is enough for the biggest possible IPv4Address description.
        /// For example for "255.255.255.255".
        ///
        /// This impl relies on an impl detail of `String` in `_SmallString.capacity` where it will
        /// inline-allocate 15 bytes at all times, for up to exactly 15 utf8 bytes.
        ///
        /// So if we know `String` will inline-allocate 15 bytes anyway (`_pointerBitWidth(_64) == true`),
        /// then we don't bother with calculating the exact required capacity. Otherwise we
        /// will calculate the exact required capacity to possibly avoid a heap allocation.
        #if _pointerBitWidth(_64)
        let requiredCapacity = 15
        #else
        let requiredCapacity = self._textualRepresentationWriteRequiredCapacity
        #endif

        return unsafe String(
            unsafeUninitializedCapacity_Compatibility: requiredCapacity
        ) { buffer in
            unsafe self.writeTextualRepresentation_Requiring2HeadroomBytes(
                into: UnsafeMutableRawBufferPointer(buffer)
            )
        }
    }

    /// Writes the textual representation of this address into `buffer` and returns the number of
    /// bytes written.
    /// Requires 3 bytes worth of room for the least significant byte at all times.
    @inline(always)
    package func writeTextualRepresentation_Requiring2HeadroomBytes(
        into buffer: UnsafeMutableRawBufferPointer
    ) -> Int {
        /// These are safe; We've already reserved max capacity needed for the longest possible
        /// IPv4 address, and only the last segment needs the 2 headroom bytes.
        let address = self.asUInt32(byteOrder: .bigEndian)
        let (paddedBytes, count) = UInt8(truncatingIfNeeded: address).asDecimal()
        /// The first segment has no leading `.`, so it writes the digits a byte lower.
        unsafe buffer.storeBytes(of: paddedBytes >> 8, toByteOffset: 0, as: UInt32.self)
        var resultIdx = count

        for idx in 1..<4 {
            let shift = idx * 8
            let byte = UInt8(truncatingIfNeeded: address >> shift)
            let (paddedBytes, count) = byte.asDecimal()
            unsafe buffer.storeBytes(
                of: paddedBytes | UInt32(UInt8.asciiDot),
                toByteOffset: resultIdx,
                as: UInt32.self
            )
            resultIdx += count + 1
        }

        return resultIdx
    }

    /// 4x 8-bit lanes, one for each byte, each holding how many decimal digits that byte needs
    /// beyond its first one which is always written even if 0 (Example: "0.0.0.0").
    /// The lanes run from the leftmost address byte upwards, so for 192.168.1.98 this is
    /// `0x01_00_02_02`, each lane representing a segment's `digitCount - 1`.
    @inlinable
    @inline(always)
    var _extraDecimalDigitsToPrintPerByte: UInt32 {
        let address = self.asUInt32(byteOrder: .bigEndian)
        /// `0x7F` == `0b0111_1111`
        let m7f: UInt32 = 0x7F7F_7F7F
        /// `0x76` == `0b0111_0110` == `118` == `128 - 10`
        let m76: UInt32 = 0x7676_7676
        /// `0x1C` == `0b0001_1100` == `28` == `128 - 100`
        let m1c: UInt32 = 0x1C1C_1C1C
        /// `0x80` == `0b1000_0000` == `128`
        let m80: UInt32 = 0x8080_8080
        /// Turn the most significant bit (MSB) off so next operations don't carry over per lane, or overflow.
        let low7Bits = address & m7f
        /// We add m76 to each lane (`128 - 10`), if the MSB is turned on, we know that the number
        /// was at least 10. This only misses to cover the case where the number is 0b1000_0000,
        /// because in `low7bits` we turned off the 8th bit in each lane.
        /// If 8th bit was on then the number was above 10 anyway, so a `| address` is enough.
        /// `& m80` is to only keep the 8th bit in each lane. If it's on, then the number was at least 10.
        let atLeast10 = ((low7Bits &+ m76) | address) & m80
        /// We do the same as above, but via m1c (`128 - 100`).
        let atLeast100 = ((low7Bits &+ m1c) | address) & m80
        /// 1 in each lane if yes, 0 if no.
        let isAtLeast10 = atLeast10 >> 7
        /// 1 in each lane if yes, 0 if no.
        let isAtLeast100 = atLeast100 >> 7
        return isAtLeast10 &+ isAtLeast100
    }

    /// The number of bytes that the textual representation of this address will occupy, plus up
    /// to 2 extra headroom bytes for speculative writes.
    ///
    /// Essentially, this var has to assume that the least significant byte of the address which is
    /// written last, will require 3 bytes of room at all times.
    @inline(always)
    package var _textualRepresentationWriteRequiredCapacity: Int {
        /// Mask out the last byte to avoid counting the extra digits it would require.
        /// At the end, we add 2 headroom bytes anyways.
        let extraDigits = self._extraDecimalDigitsToPrintPerByte & 0x00FF_FFFF
        /// Puts sum of all 4 lanes into bits 25th-28th.
        /// Then we bit shift by 24 to get the sum into bits 1st-3rd.
        let extraDigitsCount = (extraDigits &* 0x0101_0101) >> 24
        /// 9 == 3 dots + the first digit of each of the 4 bytes + 2 headroom bytes.
        return 9 &+ Int(extraDigitsCount)
    }

    /// The exact number of bytes that the textual representation of this address occupies.
    @inline(always)
    package var textualRepresentationLength: Int {
        let allDigits = self._extraDecimalDigitsToPrintPerByte
        /// Puts sum of all 4 lanes into bits 25th-28th.
        /// Then we bit shift by 24 to get the sum into bits 1st-3rd.
        let extraDigitsCount = (allDigits &* 0x0101_0101) >> 24
        /// 7 == 3 dots + the first digit of each of the 4 bytes.
        return 7 &+ Int(extraDigitsCount)
    }
}

@available(SwiftStdlib 6.2, *)
extension IPv4Address {
    /// Initialize an IPv4 address from a `UTF8Span` of its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inline(always)
    public init?(textualRepresentation utf8Span: UTF8Span) {
        self.init(textualRepresentation: utf8Span.span)
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv4Address: ExpressibleByStringLiteral {
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    ///
    /// This initializer will **crash** when given an invalid string literal value.
    ///
    /// **This initializer is free: It's unrolled to a constant at compile time.**
    /// That is, as long as the string literal is passed directly to the init like so: `let ip: IPv4Address = "192.168.1.1"`.
    /// **Passing a dynamic `StaticString` (`let str: StaticString = "192.168.1.1"; IPv4Address(stringLiteral: str)`) to this init is a bad idea.**
    /// In that case, use `IPv4Address(String(str))` instead.
    /// Might be deprecated in favor of a Swift macro in the future. For now helps with skipping Swift compile-time macro issues.
    @inline(always)
    public init(stringLiteral value: StaticString) {
        guard
            let result = value.withUTF8Buffer({
                IPv4Address(_inlined_textualRepresentation: unsafe $0.span, count: $0.count)
            })
        else {
            fatalError(
                """
                An invalid StaticString passed to an IPv4Address initializer:
                Example:
                let ip: IPv4Address = "500.168.1.98"
                ❌ Will CRASH due to invalid IPv4Address string literal value.

                Use `IPv4Address(String(str))` instead to validate the string literal if needed:
                let ip: IPv4Address? = IPv4Address(String("500.168.1.98"))
                ✅ Will return nil on invalid string literal values.

                Note that all initializers that take a `String` or `Substring` and return optional values are safe.
                These initializers that take a string-literal `StaticString` assume correct input and crash on invalid values.
                """
            )
        }
        self = result
    }

    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    ///
    /// This initializer will **crash** when given an invalid string literal value.
    ///
    /// **This initializer is free: It's unrolled to a constant at compile time.**
    /// That is, as long as the string literal is passed directly to the init like so: `let ip: IPv4Address = "192.168.1.1"`.
    /// **Passing a dynamic `StaticString` (`let str: StaticString = "192.168.1.1"; IPv4Address(stringLiteral: str)`) to this init is a bad idea.**
    /// In that case, use `IPv4Address(String(str))` instead.
    /// Might be deprecated in favor of a Swift macro in the future. For now helps with skipping Swift compile-time macro issues.
    @inlinable
    @inline(always)
    @_disfavoredOverload
    @available(
        *,
        deprecated,
        message: """
            For literal strings, use `IPv4Address(stringLiteral:)` or `let ip: IPv4Address = "192.168.1.1"` instead
            """
    )
    public init(_ value: StaticString) {
        self.init(stringLiteral: value)
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv4Address: LosslessStringConvertible {
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inline(always)
    public init?(_ description: String) {
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
    @inline(always)
    public init?(_ description: Substring) {
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
    ///
    /// This init unlike the other ones above is intentionally not `@inline(always)` to act as the
    /// inlining boundary and allow the compiler to decide what to do.
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        self.init(_inlined_textualRepresentation: span)
    }

    /// Initialize an IPv4 address from a `Span<UInt8>` of its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    @inline(always)
    init?(_inlined_textualRepresentation span: Span<UInt8>) {
        self.init(_inlined_textualRepresentation: span, count: span.count)
    }

    /// Initialize an IPv4 address from a `Span<UInt8>` of its textual representation, with the
    /// count of the span passed in explicitly.
    ///
    /// `StaticString` call sites pass the literal's length directly so no `Span.count` access
    /// remains on the path that is expected to be folded at compile time.
    @inlinable
    @inline(always)
    init?(_inlined_textualRepresentation span: Span<UInt8>, count: Int) {
        var address: UInt32 = 0
        let success = IPv4Address.parseIPv4(
            span: span,
            count: count,
            address: &address
        )

        guard success else {
            return nil
        }

        self.init(address)
    }

    @inlinable
    @inline(always)
    static func parseIPv4(
        span: Span<UInt8>,
        address: inout UInt32
    ) -> Bool {
        IPv4Address.parseIPv4(
            span: span,
            count: span.count,
            address: &address
        )
    }

    /// Each of the 4 segments is 1 to 3 digits, so each segment can only be in a small window at a
    /// fixed offset from either the start or the end of the span, no matter how long the other
    /// segments are. Segments 1 and 2 are found from the start, and segments 3 and 4 from the end,
    /// so all 4 are parsed at the same time instead of walking the bytes one by one.
    ///
    /// Additional Credits:
    /// To Wojciech Mula: The `&* nA1` pair-fold, and the fold after it.
    /// See:
    /// http://0x80.pl/notesen/2014-10-12-parsing-decimal-numbers-part-1-swar.html
    @inlinable
    @inline(always)
    static func parseIPv4(
        span: Span<UInt8>,
        count: Int,
        address: inout UInt32
    ) -> Bool {
        /// The shortest possible IPv4 address is "0.0.0.0" with 7 bytes, and the longest possible
        /// one is "255.255.255.255" with 15 bytes.
        /// We need to ensure of the 7 bytes at least, so we know we can read 4-bytes at a time.
        guard count >= 7 else { return false }

        /// `0x30` == ASCII `0`
        let m30: UInt64 = 0x3030_3030_3030_3030

        /// Read 1 window per segment, each also covering the dots around that segment.
        ///
        /// XORing with `m30` turns the ASCII codes of `0`...`9` into the numbers `0x00`...`0x09`, and
        /// the ASCII code of `.` (`0x2E`) into `0x1E`. So among digits and dots, only the dots have
        /// their 5th bit (`0x10`) set. Invalid bytes are rejected later on.
        ///
        /// Example for "192.168.1.98" (Notice little-endian byte-order):
        /// `window1`: bytes 0...3 ("192.") -> `0x1E_02_09_01`.
        /// `window2`: bytes 2...7 ("2.168.") -> `0x30_30_1E_08_06_01_1E_02` (in bytes 0...5).
        /// `window3`: bytes 5...10 ("68.1.9") -> `0x30_09_1E_01_1E_08_06_30` (in bytes 1...6).
        /// `window4`: bytes 8...11 ("1.98") -> `0x08_09_1E_01`.
        let (window1, window2, window3, window4) = span.withUnsafeBytes { buffer in
            /// `count >= 7` == `true`, so this is not nil.
            let base = unsafe buffer.baseAddress.unsafelyUnwrapped
            let m30_u32 = UInt32(truncatingIfNeeded: m30)
            /// Reads the "192." part.
            /// We know `count >= 7` so this won't be an out-of-bounds read.
            let w1 = unsafe _loadUInt32(from: base, at: 0)
            let window1 = w1 ^ m30_u32
            /// With `count == 7` the second read can't start at byte 4 without going out of bounds,
            /// so it starts at the 3rd byte. In the example, this fetches "2.16".
            /// We also fetch from the 4th byte up for the rest of the second candidate. In the example, this fetches "168.".
            /// "2.16" | "168." << 16 == "2.168.".
            let w2_p2 = unsafe _loadUInt32(from: base, at: min(4, count &- 4))
            let window2 = (UInt64(w1 >> 16) | (UInt64(w2_p2) << 16)) ^ m30
            /// Similar to the `window1`, but read from the end.
            /// Reads the "1.98" part.
            let w4 = unsafe _loadUInt32(from: base, at: count &- 4)
            let window4 = w4 ^ m30_u32
            /// Similar to the `window2`, but read from the end.
            /// Reads the "68.1.9" part.
            let w3_p1 = unsafe _loadUInt32(from: base, at: count &- 7)
            let window3 = (UInt64(w3_p1) << 8) | (UInt64(w4) << 32) ^ m30
            return (window1, window2, window3, window4)
        }

        let m10: UInt32 = 0x1010_1000
        let m1: UInt32 = 0x1000_0000

        /// Example: Assuming `window1` is `0x1E_02_09_01` (little-endian byte-order),
        /// then `window1 & 0x1010_1000` == `0x1000_0000`. `| 0x1000_0000` ensures at least
        /// the most significant lane (byte) is always considered a "dot" since we have 4 lanes but
        /// only 3 can ever be representing an IPv4 segment which is in the range `0...255`.
        /// `m10` intentionally turns of the least significant lane that can be a dot as well,
        /// but will mess up our calculations for finding the first dot's bit count situation.
        let firstDotBitCount = ((window1 & m10) | m1).trailingZeroBitCount
        /// Let's find the amount of bits that are for the digits after the dot.
        /// For example in an IP like `1.2.3.4`, we'll have `1.2.` in here and we'll need to get rid
        /// of the `2.` part. So we find the first dot (from left), and get rid of all after it.
        ///
        /// `0x10` == `0b0001_0000`. The low 4 bits will be included in `firstDotBitCount`.
        /// The top 4 bits no, since the `1` in `0001` is blocking `trailingZeroBitCount` from counting them.
        /// Therefore instead of `32 - firstDotBitCount`, we use `28 - firstDotBitCount`, to account for the top 4 bits.
        let w1_afterDotCount = 28 &- firstDotBitCount
        /// Example: `0x1E_02_09_01` -> `0x1E_02_09_01` (`firstDotBitCount` == 28).
        /// For "1.2.3.4" it'd be `0x1E_02_1E_01` -> `0x1E_01_00_00` (`firstDotBitCount` == 12).
        let segment1 = window1 &<< w1_afterDotCount

        /// We know where the first dot is. We want to get rid of anything before it in the 2nd candidate.
        /// `firstDotBitCount` is between 12 and 28. 12 in e.g. `1.2.3.4`, and 28 in e.g. `192.168.1.98`.
        /// Assuming window2 is "2.168.", we want to get rid of the "2." part.
        /// Example: `0x30_30_1E_08_06_01_1E_02` -> `0x00_00_30_30_1E_08_06_01` (`firstDotBitCount` == 28).
        let w2_afterFirstDot = UInt32(truncatingIfNeeded: window2 &>> (firstDotBitCount &- 12))
        /// Now `w2_afterFirstDot` is sure to only contain 1 dot. It's the second dot.
        /// We find it the same way we found the first dot.
        /// Example: `0x1E_08_06_01` -> `28`.
        let secondDotBitCount = ((w2_afterFirstDot & m10) | m1).trailingZeroBitCount
        /// Example: `0x1E_08_06_01` -> `0x1E_08_06_01`. For "1.2.3.4" it'd be `0x30_30_1E_02` -> `0x1E_02_00_00`.
        let segment2 = w2_afterFirstDot &<< (28 &- secondDotBitCount)

        let m10_r: UInt32 = 0x001010_10
        let m1_r: UInt32 = 0x0000_0010
        /// Now let’s find the third dot. We use the 4th candidate for this, not the 3rd which
        /// can potentially contain 2 dots.
        /// For example in "1.98", we need to find the “.” And get rid of anything before it.
        let thirdDotBitCount = 31 &- ((window4 & m10_r) | m1_r).leadingZeroBitCount
        /// Keeps the digits after the third dot and moves them to lanes 0...2.
        /// Example: `0x08_09_1E_01` -> `0x00_08_09_00`.
        let thirdDotAndBeforeMask: UInt32 = 0xFFFF_FFFF &<< (thirdDotBitCount &+ 4)
        let segment4 = (window4 & thirdDotAndBeforeMask) >> 8

        /// Now we know where the 2nd and 3rd dots are. We need to get what is in between them.
        /// That’d be the 3rd and last segment to find.

        /// Example for "68.1.9": `0x30_09_1E_01_1E_08_06_30` -> `0x00_30_09_1E_01_1E_08_06`.
        let beforeThirdDot = window3 &>> (thirdDotBitCount &- 4)
        /// The second dot, from the end, is the last of lanes 0...2 with its 5th bit set.
        /// The `| 0x10` makes byte 0 count as the second dot if bytes 1 and 2 are not dots.
        /// Example: `0x00_30_09_1E_01_1E_08_06` -> `20`, so segment 3 has 1 digit.
        let secondDotBitFromEnd =
            63 &- ((beforeThirdDot & 0x0010_1010) | 0x10).leadingZeroBitCount
        /// Keeps bytes 1...4 after the second dot, and moves them to bytes 0...3.
        /// Example: `0x00_30_09_1E_01_1E_08_06` -> `0x1E_01_00_00` (“001.”)
        let segment3 = UInt32(
            truncatingIfNeeded: (beforeThirdDot & (UInt64.max &<< (secondDotBitFromEnd &+ 4))) >> 8
        )

        /// 2x 32-bit lanes for 2 segments.
        //// XORing with `0x1E` turns the dot lanes into `0x00` if they are actual dots.
        /// Example: `0x1E_08_06_01_1E_02_09_01` -> `0x00_08_06_01_00_02_09_01`.
        let segments12 = (UInt64(segment1) | (UInt64(segment2) << 32)) ^ 0x1E00_0000_1E00_0000
        /// Segment 4 has no dot in the least significant bye, so it’s not XORed and stays `0x00`.
        /// Example: `0x00_08_09_00_1E_01_00_00` -> `0x00_08_09_00_00_01_00_00`.
        let segments34 = (UInt64(segment3) | (UInt64(segment4) << 32)) ^ 0x0000_0000_1E00_0000

        /// `0x76` == `0x80` - 10, for the digit lanes.
        /// `0x7F` == `0x80` - 1, for the dot lanes.
        /// Adding these to the lanes (bytes) sets the 8th bit of every digit lane above `0x09` and
        /// every dot lane above `0x00`, as long as the lane was below `0x80`.
        /// We OR with the values themselves again to cover for when the lanes themselves
        /// had the 8th bit set but lost the 8th bit in the addition operation.
        /// Lanes can only overflow into the next lane only when they are invalid themselves.
        let m7f767676: UInt64 = 0x7F76_7676_7F76_7676
        let invalidLanes12 = (segments12 &+ m7f767676) | segments12
        let invalidLanes34 = (segments34 &+ m7f767676) | segments34
        let invalidLanes = invalidLanes12 | invalidLanes34

        /// `0x0A01` == `0x0A` (10) then `0x01` (1).
        let nA1: UInt64 = 0x0A01
        /// We multiply by `nA1` so each lane turns into `10 * previousLane + lane`, which is at
        /// most `10 * 9 + 9` == `99` < `256` so it fits into one lane.
        /// Then we only need lanes 0 (`10 * tens + ones`) and 2 (the hundreds) of each segment,
        /// so we turn off the other lanes.
        /// Example: `0x00_08_06_01_00_02_09_01` -> `0x00_44_00_01_00_5C_00_01` (68, 1, 92, 1).
        let pairs12 = (segments12 &* nA1) & 0x00FF_00FF_00FF_00FF
        /// Example: `0x00_08_09_00_00_01_00_00` -> `0x00_62_00_00_00_01_00_00` (98, 0, 1, 0).
        let pairs34 = (segments34 &* nA1) & 0x00FF_00FF_00FF_00FF
        /// `0x0064_0001` == `100 << 16 | 1`.
        /// This means `100 * hundreds + (10 * tens + ones)` of each segment ends up in
        /// bits 16...31 and 48...63.
        /// The biggest value this can produce is much less than `255 * 100 + 255` which
        /// still fits into 15 bits.
        /// Example: `0x00_44_00_01_00_5C_00_01` -> `0x00_A8_23_F1_00_C0_00_01` (168, 192).
        let values12 = pairs12 &* 0x0064_0001
        /// Example: `0x00_62_00_00_00_01_00_00` -> `0x00_62_00_64_00_01_00_00` (98, 1).
        let values34 = pairs34 &* 0x0064_0001

        /// `0x80` == `0b1000_0000`
        let m80: UInt64 = 0x8080_8080_8080_8080
        let mff00: UInt64 = 0xFF00_0000_FF00_0000
        /// The 8th bit of any lane in `invalidLanes` means there's an invalid byte.
        /// Any of bits 24...31 or 56...63 set in a value means a segment above `255` which is also invalid.
        let invalid = (invalidLanes & m80) | ((values12 | values34) & mff00)

        guard invalid == 0 else { return false }

        /// The second dot is at byte `(firstDotBit + secondDotBit) / 8` from the start, and at byte
        /// `count - 9 + (thirdDotBit + secondDotBitFromEnd) / 8` from the end.
        /// Those must be the same byte, which makes the 4 segments and the 3 dots cover every byte
        /// exactly once.
        /// Example: `(28 + 28) / 8` == `7`, and `12 - 9 + (12 + 20) / 8` == `7`.
        let secondDotFromStart = firstDotBitCount &+ secondDotBitCount &+ 72
        let secondDotFromEnd = (count << 3) &+ thirdDotBitCount &+ secondDotBitFromEnd
        guard secondDotFromStart == secondDotFromEnd else { return false }

        /// Puts the values of segments 1 and 2 at bits 24...31 and 56...63, and the values of
        /// segments 3 and 4 at bits 8...15 and 40...47.
        /// Example: `0x00_A8_23_F1_00_C0_00_01` and `0x00_62_00_64_00_01_00_00`
        /// -> `0xA8_00_62_00_C0_00_01_00`.
        let interleaved12 = (values12 & 0x00FF_0000_00FF_0000) << 8
        let interleaved34 = (values34 & 0x00FF_0000_00FF_0000) >> 8
        let interleaved = interleaved12 | interleaved34
        /// Moves segments 2 and 4 next to segments 1 and 3.
        /// Example: `0xA8_00_62_00_C0_00_01_00` -> `0xC0_A8_01_62` (192.168.1.98).
        address = UInt32(truncatingIfNeeded: interleaved | (interleaved >> 40))

        return true
    }

    /// Reads 4 bytes at `offset` as a `UInt32` with the byte at `offset` in the lowest lane.
    @inlinable
    @inline(always)
    static func _loadUInt32(from base: UnsafeRawPointer, at offset: Int) -> UInt32 {
        unsafe UInt32(littleEndian: base.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
    }
}
