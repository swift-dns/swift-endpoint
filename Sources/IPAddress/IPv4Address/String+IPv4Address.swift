@available(SwiftStdlib 5.1, *)
extension IPv4Address: CustomStringConvertible {
    /// The textual representation of an IPv4 address.
    @inlinable
    public var description: String {
        /// 15 is enough for the biggest possible IPv4Address description.
        /// For example for "255.255.255.255".
        ///
        /// This impl relies on an impl detail of `String` in `_SmallString.capacity` where it will
        /// inline-allocate up to 15 utf8-bytes most of the times.
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
        /// was at least 10. This can miss numbers with the 8th bit on, like `0b1000_0000`,
        /// because in `low7Bits` we turned off the 8th bit in each lane.
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
        /// Puts sum of all 4 lanes into bits 25th-27th.
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
        /// Then we bit shift by 24 to get the sum into bits 1st-4th.
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

        self.init(address, byteOrder: .bigEndian)
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

    /// Parses an IPv4 address from a `Span<UInt8>` of its textual representation.
    ///
    /// `address` is set in big-endian byte order.
    /// This func with `count` parameter is used for IPv4-literal folding, otherwise makes no other
    /// difference compared to the `parseIPv4` function without the `count` parameter.
    /// `count` must be `span.count`.
    ///
    /// Additional Credits:
    /// To Wojciech Mula: Folding digits with a multiplication.
    /// To Daniel Lemire: The 3-digit `&* n64A1` fold, and the `.byteSwapped` overflow check.
    /// To Jean-Marc Bourguet: The `0x0064_0A01` form of that fold.
    /// See:
    /// http://0x80.pl/notesen/2014-10-12-parsing-decimal-numbers-part-1-swar.html
    /// https://lemire.me/blog/2023/11/28/parsing-8-bit-integers-quickly/
    @inlinable
    @inline(always)
    static func parseIPv4(
        span: Span<UInt8>,
        count: Int,
        address: inout UInt32
    ) -> Bool {
        /// The shortest possible IPv4 address is "0.0.0.0" with 7 bytes.
        guard count >= 7 else { return false }

        /// `0x30` == ASCII `0`
        let m30: UInt64 = 0x3030_3030_3030_3030

        /// Read 1 window per segment, each also covering some dots around each segment.
        /// Segment 3's window is read further down, once all 3 dots are already known.
        ///
        /// XORing with `m30` turns the ASCII codes of `0`...`9` into the numbers `0x00`...`0x09`, and
        /// the ASCII code of `.` (`0x2E`) into `0x1E`. So among digits and dots, only the dots have
        /// their 5th bit (`0x10`) set. Invalid bytes are rejected later on.
        ///
        /// Example for "192.168.1.98" (Notice little-endian byte-order):
        /// `window1`: bytes 0...3 ("192.") -> `0x1E_02_09_01`.
        /// `window12`: bytes 0...7 ("192.168.") -> `0x1E_08_06_01_1E_02_09_01`.
        /// `window4`: bytes 8...11 ("1.98") -> `0x08_09_1E_01`.
        let (window1, window12, window4) = span.withUnsafeBytes { buffer in
            /// `count >= 7` == `true`, so this is not nil.
            let base = unsafe buffer.baseAddress.unsafelyUnwrapped
            let m30_u32 = UInt32(truncatingIfNeeded: m30)
            /// Reads the "192." part.
            /// We know `count >= 7` so this won't be an out-of-bounds read.
            let w1 = unsafe _loadUInt32(from: base, at: 0)
            /// Same as the low 32 bits of `window12`, but without waiting for `w2`.
            /// Helps with latency.
            let window1 = w1 ^ m30_u32
            /// Reads the "168." part.
            /// With `count == 7` a read at byte 4 would go out of bounds, so it starts at byte 0.
            /// `(count >> 1) & 4` == `4` for a `count` of 8...15, and `0` for a `count` of 7.
            let w2 = unsafe _loadUInt32(from: base, at: (count >> 1) & 4)
            /// "192." | "168." << 32 == "192.168.".
            let window12 = (UInt64(w1) | (UInt64(w2) << 32)) ^ m30
            /// Similar to the `window1`, but read from the end.
            /// Reads the "1.98" part.
            let w4 = unsafe _loadUInt32(from: base, at: count &- 4)
            let window4 = w4 ^ m30_u32
            return (window1, window12, window4)
        }

        let m01: UInt32 = 0x0101_0000

        /// Example: Assuming `window1` is `0x1E_02_09_01` (little-endian byte-order),
        /// then `(window1 << 4) & 0x0101_0000` == `0xE0_20_90_10 & 0x0101_0000` == `0x0000_0000`.
        ///
        /// `trailingZeroBitCount` of `0` is `32`, so at least the most significant lane (byte) is
        /// always considered a "dot" since we have 4 lanes but only 3 can ever be representing an
        /// IPv4 segment which is in the range `0...255`.
        /// `m01` intentionally turns off the 2 least significant lanes, since a segment has at least
        /// 1 digit and `<< 4` moves the "dot" of the 2nd lane to the 3rd anyway.
        /// First lane is always treated as a digit, so a dot there fails the digit check later on.
        ///
        /// `<< 4` makes it so `firstDotEndBitCount` also counts the bits of the first dot itself.
        /// Example: `0x1E_02_09_01` ("192.") -> `0x0000_0000` (32).
        /// Example: `0x1E_02_1E_01` ("1.2.") -> `0x0001_0000` (16).
        let firstDotEndBitCount = ((window1 << 4) & m01).trailingZeroBitCount
        /// Let's find the amount of bits that are for the bytes after the dot.
        /// For example in an IP like `1.2.3.4`, we'll have `1.2.` in here and we'll need to get rid
        /// of the `2.` part. So we find the first dot (from left), and get rid of all after it.
        let w1_afterDotCount = 32 &- firstDotEndBitCount
        /// Example: `0x1E_02_09_01` -> `0x1E_02_09_01` (`firstDotEndBitCount` == 32).
        /// For "1.2.3.4" it'd be `0x1E_02_1E_01` -> `0x1E_01_00_00` (`firstDotEndBitCount` == 16).
        let segment1 = window1 &<< w1_afterDotCount

        /// Assuming `window12` is "192.168.", we want to get rid of the "192." part.
        /// `firstDotEndBitCount` is between 16 and 32. 16 in e.g. `1.2.3.4`, and 32 in e.g. `192.168.1.98`.
        /// Example: `0x1E_08_06_01_1E_02_09_01` -> `0x1E_08_06_01` (`firstDotEndBitCount` == 32).
        let w2_afterFirstDot = window12 &>> firstDotEndBitCount
        /// `w2_afterFirstDot` starts right after the first dot. Its first dot is the second dot.
        /// We find it the same way we found the first dot.
        /// Example: `0x1E_08_06_01` -> `32`.
        let secondDotEndBitCount =
            ((UInt32(truncatingIfNeeded: w2_afterFirstDot) << 4) & m01).trailingZeroBitCount
        /// Example: `0x1E_08_06_01` -> `0x1E_08_06_01`. For "1.2.3.45" it'd be `0x1E_03_1E_02` -> `0x1E_02_00_00`.
        let segment2 = UInt32(truncatingIfNeeded: w2_afterFirstDot) &<< (32 &- secondDotEndBitCount)

        let m10_r: UInt32 = 0x001010_10
        let m1_r: UInt32 = 0x0000_0010
        /// Now let’s find the third dot which must be in `window4`.
        /// For example in "1.98", we need to find the “.” and get rid of it and anything before it.
        /// Example: `window4` == `0x08_09_1E_01` -> `19`.
        let thirdDotLeadingZeroBitCount = ((window4 & m10_r) | m1_r).leadingZeroBitCount
        /// Keeps the digits after the third dot.
        /// Example: `0x08_09_1E_01` -> `0x08_09_00_00`.
        let thirdDotAndBeforeMask = UInt32(
            truncatingIfNeeded: 0x0000_0007_FFFF_FFFF &>> thirdDotLeadingZeroBitCount
        )
        let segment4 = window4 & ~thirdDotAndBeforeMask

        /// The 3rd and last segment is between the 2nd and 3rd dots, which are both found by now.
        /// `thirdDotLeadingZeroBitCount` is 11, 19 or 27, so this only reads within bytes `count - 7`...`count - 2`.
        /// `thirdDotLeadingZeroBitCount >> 3` == `thirdDotLeadingZeroBitCount / 8`.
        let w3_idx = count &- 4 &- (thirdDotLeadingZeroBitCount >> 3)
        /// Example for "192.168.1.98": bytes 6...9 ("8.1.") -> `0x1E_01_1E_08`.
        let window3 = span.withUnsafeBytes { buffer in
            let base = unsafe buffer.baseAddress.unsafelyUnwrapped
            let w3 = unsafe _loadUInt32(from: base, at: w3_idx)
            return w3 ^ UInt32(truncatingIfNeeded: m30)
        }

        /// Example: `32 + 32` == `64` for "192.168.1.98", covering "192.168.".
        let secondDotEndBitCountFromStart = firstDotEndBitCount &+ secondDotEndBitCount
        /// Where `window3` starts, which is where segment 3 would start if it had 3 digits.
        /// `w3_idx << 3` == `w3_idx &* 8` == `48` for "192.168.1.98", covering "192.16".
        let window3BitCountFromStart = w3_idx << 3
        /// Example: `64 - 48` == `16` for "192.168.1.98", covering the "8." of "8.1.".
        let extraDigitsShift = secondDotEndBitCountFromStart &- window3BitCountFromStart
        /// Turns off the lanes before segment 3, like the 2nd dot.
        /// Example: `0x1E_01_1E_08` -> `0x1E_01_00_00` (“1.”)
        let segment3 = window3 & (0xFFFF_FFFF &<< extraDigitsShift)

        /// 2x 32-bit lanes for 2 segments.
        /// XORing with `0x1E` turns the dot lanes into `0x00` if they are actual dots.
        /// Example: `0x1E_08_06_01_1E_02_09_01` -> `0x00_08_06_01_00_02_09_01`.
        let segments12 = (UInt64(segment1) | (UInt64(segment2) << 32)) ^ 0x1E00_0000_1E00_0000
        /// Segment 4 has no dot in the most significant byte, so it’s not XORed and stays `0x00`.
        /// `<< 24` moves the digits of segment 4 to lanes 4...6.
        /// Example: `0x00_08_09_00_1E_01_00_00` -> `0x00_08_09_00_00_01_00_00`.
        let segments34 = (UInt64(segment3) | (UInt64(segment4) << 24)) ^ 0x0000_0000_1E00_0000

        /// `0x76` == `0x80` - 10, for the digit lanes.
        /// `0x7F` == `0x80` - 1, for the dot lanes.
        /// Adding these to the lanes (bytes) sets the 8th bit of every digit lane above `0x09` and
        /// every dot lane above `0x00`, as long as the lane was below `0x80`.
        /// We OR with the values themselves again to cover for when the lanes themselves
        /// had the 8th bit set but lost the 8th bit in the addition operation.
        /// Lanes can only overflow into the next lane when they are invalid themselves.
        let m7f76: UInt64 = 0x7F76_7676_7F76_7676
        let invalidLanes12 = (segments12 &+ m7f76) | segments12
        let invalidLanes34 = (segments34 &+ m7f76) | segments34
        let invalidLanes = invalidLanes12 | invalidLanes34

        /// `0x7DFA_FA00` == `0x8000_0000` - `0x0205_0600`, where `0x02_05_06_00` is “256.”.
        /// Adding it to a big-endian segment with valid lanes sets the 32nd bit when the segment is
        /// above `255`.
        /// `.byteSwapped` is to get big-endian version of the segments.
        ///
        /// Example: `0x00_08_06_01_00_02_09_01` -> `0x01_09_02_00_01_06_08_00`
        /// -> `0x7F_03_FC_00_7F_01_02_00` (bits 31 and 63 are `0`).
        let m7dfa: UInt64 = 0x7DFA_FA00_7DFA_FA00
        let overflows12 = segments12.byteSwapped &+ m7dfa
        let overflows34 = segments34.byteSwapped &+ m7dfa

        /// `0x80` == `0b1000_0000`
        let m80: UInt64 = 0x8080_8080_8080_8080
        let m8000: UInt64 = 0x8000_0000_8000_0000
        /// The 8th bit of any lane in `invalidLanes` means there's an invalid byte.
        /// Bit 31 or 63 set in an overflow means a segment above `255` which is also invalid.
        let invalid = (invalidLanes & m80) | ((overflows12 | overflows34) & m8000)

        guard invalid == 0 else { return false }

        /// Segment 3 must have 1 to 3 digits, so `0`, `8` or `16` bit-shifts.
        /// It's negative when segment 3 has more than 3 digits.
        guard UInt(bitPattern: extraDigitsShift) <= 16 else { return false }

        /// `0x0064_0A01` == `100 << 16 | 10 << 8 | 1`.
        /// We multiply by `n64A1` so `100 * hundreds + 10 * tens + ones` of each segment ends up in
        /// bits 16...23 and 48...55.
        /// Each segment is at most `255` by now, so its value fits into those 8 bits.
        /// Example: `0x00_08_06_01_00_02_09_01` -> `0xA8_A8_10_CC_98_C0_13_01` (168, 192).
        let n64A1: UInt64 = 0x0064_0A01
        let values12 = segments12 &* n64A1
        /// Example: `0x00_08_09_00_00_01_00_00` -> `0xD4_62_09_64_0A_01_00_00` (98, 1).
        let values34 = segments34 &* n64A1

        /// Puts the values of segments 1 and 2 at bits 0...7 and 32...39, and the values of
        /// segments 3 and 4 at bits 16...23 and 48...55.
        /// Example: `0xA8_A8_10_CC_98_C0_13_01` and `0xD4_62_09_64_0A_01_00_00`
        /// -> `0x00_62_00_A8_00_01_00_C0`.
        let interleaved12 = (values12 >> 16) & 0x0000_00FF_0000_00FF
        let interleaved34 = values34 & 0x00FF_0000_00FF_0000
        let interleaved = interleaved12 | interleaved34
        /// Moves segments 2 and 4 next to segments 1 and 3, with segment 1 in the lowest byte.
        /// Example: `0x00_62_00_A8_00_01_00_C0` -> `0x62_01_A8_C0` (192.168.1.98).
        address = UInt32(truncatingIfNeeded: interleaved | (interleaved >> 24)).littleEndian

        return true
    }

    /// Reads 4 bytes at `offset` as a `UInt32` with the byte at `offset` in the lowest lane.
    @inlinable
    @inline(always)
    static func _loadUInt32(from base: UnsafeRawPointer, at offset: Int) -> UInt32 {
        unsafe UInt32(littleEndian: base.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
    }
}
