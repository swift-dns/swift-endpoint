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
        guard count >= 7, count <= 15 else {
            return false
        }

        /// `0x30` == ASCII `0`
        let m30: UInt64 = 0x3030_3030_3030_3030

        /// Read 1 window per segment, each also covering the bytes that the dots around that
        /// segment can be at. All of these reads are in bounds because `count >= 7`.
        ///
        /// XORing with `m30` turns the ASCII codes of `0`...`9` into the numbers `0x00`...`0x09`, and
        /// the ASCII code of `.` (`0x2E`) into `0x1E`. So among digits and dots, only the dots have
        /// their 5th bit (`0x10`) set. Any other byte can look like either, and is rejected later on.
        ///
        /// Example for "192.168.1.98":
        /// `window1`: bytes 0...3 ("192.") -> `0x1E_02_09_01`.
        /// `window2`: bytes 2...7 ("2.168.") in lanes 0...5 -> `0x30_30_1E_08_06_01_1E_02`.
        /// `window3`: bytes 5...10 ("68.1.9") in lanes 1...6 -> `0x30_09_1E_01_1E_08_06_30`.
        /// `window4`: bytes 8...11 ("1.98") -> `0x08_09_1E_01`.
        let (window1, window2, window3, window4) = span.withUnsafeBytes { buffer in
            let base = unsafe buffer.baseAddress.unsafelyUnwrapped
            let window1 =
                unsafe IPv4Address._loadUInt32(from: base, at: 0)
                ^ UInt32(truncatingIfNeeded: m30)
            /// With `count == 7` the second read can't start at byte 4 without going out of bounds,
            /// so it starts at byte 3 and lanes 2...5 end up with the wrong bytes.
            /// Those lanes are only reached for a second dot at byte 4 or later, which with 7 bytes
            /// the end side can never agree with, so the dot check below rejects all such inputs.
            let window2 =
                unsafe (UInt64(IPv4Address._loadUInt32(from: base, at: 2))
                | (UInt64(IPv4Address._loadUInt32(from: base, at: min(4, count &- 4))) &<< 16))
                ^ m30
            /// Lane 0 is never read so it stays `0x00`, which XORing turns into `0x30`.
            /// That has the 5th bit set, which is used as a dot right before the window.
            let window3 =
                unsafe ((UInt64(IPv4Address._loadUInt32(from: base, at: count &- 7)) &<< 8)
                | (UInt64(IPv4Address._loadUInt32(from: base, at: count &- 5)) &<< 24))
                ^ m30
            let window4 =
                unsafe IPv4Address._loadUInt32(from: base, at: count &- 4)
                ^ UInt32(truncatingIfNeeded: m30)
            return (window1, window2, window3, window4)
        }

        /// Each segment is turned into 4x 8-bit lanes: Its digits in lanes 0...2, most significant
        /// first and right-aligned so the leading lanes are `0x00` for segments shorter than 3
        /// digits, and the byte after the segment, which must be a dot, in lane 3.

        /// The first dot is the first of bytes 1...3 with its 5th bit set. Byte 0 must be a digit.
        /// The `| 0x1000_0000` makes byte 3 count as the first dot if bytes 1 and 2 are not dots.
        /// Byte 3 still has to be an actual dot, which the checks after the folding make sure of.
        /// `firstDotBit` is `8 * index + 4` of the first dot.
        /// Example: `0x1E_02_09_01` -> `28`, so the first dot is byte 3.
        let firstDotBit = ((window1 & 0x1010_1000) | 0x1000_0000).trailingZeroBitCount
        /// Moves the first dot to lane 3, and the digits right before it to lanes 0...2.
        /// Example: `0x1E_02_09_01` -> `0x1E_02_09_01`. For "1.2.3.4" it'd be `0x1E_02_1E_01` -> `0x1E_01_00_00`.
        let segment1 = window1 &<< (28 &- firstDotBit)

        /// `window2` starts at byte 2, and segment 2 starts right after the first dot, so shift right
        /// by `8 * (firstDotIndex - 1)` == `firstDotBit - 12`.
        /// Example: `0x30_30_1E_08_06_01_1E_02` -> `0x1E_08_06_01`.
        let afterFirstDot = UInt32(truncatingIfNeeded: window2 &>> (firstDotBit &- 12))
        /// Same as for the first dot. Lane 0 is the first digit of segment 2.
        /// Example: `0x1E_08_06_01` -> `28`, so segment 2 has 3 digits.
        let secondDotBit = ((afterFirstDot & 0x1010_1000) | 0x1000_0000).trailingZeroBitCount
        /// Example: `0x1E_08_06_01` -> `0x1E_08_06_01`.
        let segment2 = afterFirstDot &<< (28 &- secondDotBit)

        /// The third dot is the last of bytes `count - 4`...`count - 2` with its 5th bit set.
        /// The last byte must be a digit.
        /// The `| 0x10` makes byte `count - 4` count as the third dot if the 2 bytes after it are not
        /// dots. Just like with the first dot, it's later made sure that it is an actual dot.
        /// `thirdDotBit` is `8 * (index - (count - 4)) + 4` of the third dot.
        /// Example: `0x08_09_1E_01` -> `12`, so the third dot is byte `count - 3`.
        let thirdDotBit = 31 &- ((window4 & 0x0010_1010) | 0x10).leadingZeroBitCount
        /// Keeps the digits after the third dot and moves them to lanes 0...2.
        /// Segment 4 has no dot after it, so lane 3 is left `0x00`.
        /// Example: `0x08_09_1E_01` -> `0x00_08_09_00`.
        let segment4 = (window4 & (0xFFFF_FFFF &<< (thirdDotBit &+ 4))) &>> 8

        /// Moves the third dot to lane 4, so the up-to-3 digits of segment 3 are in lanes 1...3, and
        /// the bytes that the second dot can be at are in lanes 0...2.
        /// Example: `0x30_09_1E_01_1E_08_06_30` -> `0x00_30_09_1E_01_1E_08_06`.
        let beforeThirdDot = window3 &>> (thirdDotBit &- 4)
        /// The second dot, from the end, is the last of lanes 0...2 with its 5th bit set.
        /// The `| 0x10` makes lane 0 count as the second dot if lanes 1 and 2 are not dots.
        /// Example: `0x00_30_09_1E_01_1E_08_06` -> `20`, so segment 3 has 1 digit.
        let secondDotBitFromEnd =
            63 &- ((beforeThirdDot & 0x0010_1010) | 0x10).leadingZeroBitCount
        /// Keeps lanes 1...4 after the second dot, and moves them to lanes 0...3.
        /// Example: `0x00_30_09_1E_01_1E_08_06` -> `0x1E_01_00_00`.
        let segment3 = UInt32(
            truncatingIfNeeded: (beforeThirdDot & (UInt64.max &<< (secondDotBitFromEnd &+ 4)))
                &>> 8
        )

        /// 2x 32-bit lanes, 1 segment each. XORing with `0x1E` turns the dot lanes into `0x00` if
        /// they are actual dots.
        /// Example: `0x1E_08_06_01_1E_02_09_01` -> `0x00_08_06_01_00_02_09_01`.
        let segments12 = (UInt64(segment1) | (UInt64(segment2) &<< 32)) ^ 0x1E00_0000_1E00_0000
        /// Segment 4 has no dot, so its lane 7 is not XORed and stays `0x00`.
        /// Example: `0x00_08_09_00_1E_01_00_00` -> `0x00_08_09_00_00_01_00_00`.
        let segments34 = (UInt64(segment3) | (UInt64(segment4) &<< 32)) ^ 0x0000_0000_1E00_0000

        /// `0x76` == `0x80` - 10, for the digit lanes. `0x7F` == `0x80` - 1, for the dot lanes.
        /// Adding this to the lanes sets the 8th bit of every digit lane above `0x09` and every dot
        /// lane above `0x00`, as long as the lane was below `0x80`. ORing with the lanes themselves
        /// covers the lanes from `0x80` up. Lanes can only overflow into the next lane when they
        /// are invalid themselves, so the first invalid lane is never missed.
        let m7f767676: UInt64 = 0x7F76_7676_7F76_7676
        let invalidLanes =
            (segments12 &+ m7f767676) | segments12 | (segments34 &+ m7f767676) | segments34

        /// `0x0A01` == `0x0A` (10) then `0x01` (1), so multiplying by it folds the lanes in pairs.
        let nA1: UInt64 = 0x0A01
        /// Each lane turns into `10 * previousLane + lane`, which is at most `10 * 9 + 9` == `99` < `256`,
        /// so no lane can ever overflow into the next one. The dot lanes are `0x00` by now, so the 2
        /// segments don't mix either.
        /// We only need lanes 0 and 2 of each segment, the hundreds and `10 * tens + ones`.
        /// Example: `0x00_08_06_01_00_02_09_01` -> `0x00_44_00_01_00_5C_00_01` (68, 1, 92, 1).
        let pairs12 = (segments12 &* nA1) & 0x00FF_00FF_00FF_00FF
        /// Example: `0x00_08_09_00_00_01_00_00` -> `0x00_62_00_00_00_01_00_00` (98, 0, 1, 0).
        let pairs34 = (segments34 &* nA1) & 0x00FF_00FF_00FF_00FF
        /// `0x0064_0001` == `100 << 16 | 1`.
        /// This means `100 * hundreds + (10 * tens + ones)` of each segment ends up in bits 16...31
        /// and 48...63.
        /// The biggest value this can produce is `999`, which needs 10 bits, so it stays within those
        /// bits, and anything that lands in bits 32...47 is at most `100 * 99 + 9` == `9909`, which
        /// needs 14 bits, so it never overflows into bit 48.
        /// Example: `0x00_44_00_01_00_5C_00_01` -> `0x00_A8_23_F1_00_C0_00_01` (168, 192).
        let values12 = pairs12 &* 0x0064_0001
        /// Example: `0x00_62_00_00_00_01_00_00` -> `0x00_62_00_64_00_01_00_00` (98, 1).
        let values34 = pairs34 &* 0x0064_0001

        /// `0x80` == `0b1000_0000`
        let m80: UInt64 = 0x8080_8080_8080_8080
        /// The 8th bit of any lane in `invalidLanes` means a byte that is neither a digit where a
        /// digit must be, nor a dot where a dot must be.
        /// Any of bits 24...31 or 56...63 set in a value means a segment above `255`.
        let invalid =
            (invalidLanes & m80)
            | ((values12 | values34) & 0xFF00_0000_FF00_0000)

        /// The second dot is at byte `(firstDotBit + secondDotBit) / 8` from the start, and at byte
        /// `count - 9 + (thirdDotBit + secondDotBitFromEnd) / 8` from the end.
        /// Those must be the same byte, which makes the 4 segments and the 3 dots cover every byte
        /// exactly once. The second dot was already checked to be an actual dot, as part of `segment2`.
        /// Example: `(28 + 28) / 8` == `7`, and `12 - 9 + (12 + 20) / 8` == `7`.
        guard
            invalid == 0,
            firstDotBit &+ secondDotBit &+ 72
                == (count &<< 3) &+ thirdDotBit &+ secondDotBitFromEnd
        else {
            return false
        }

        /// Puts the values of segments 1 and 2 at bits 24...31 and 56...63, and the values of
        /// segments 3 and 4 at bits 8...15 and 40...47.
        /// Example: `0x00_A8_23_F1_00_C0_00_01` and `0x00_62_00_64_00_01_00_00`
        /// -> `0xA8_00_62_00_C0_00_01_00`.
        let interleaved =
            ((values12 & 0x00FF_0000_00FF_0000) &<< 8) | ((values34 & 0x00FF_0000_00FF_0000) &>> 8)
        /// Moves segments 2 and 4 next to segments 1 and 3.
        /// Example: `0xA8_00_62_00_C0_00_01_00` -> `0xC0_A8_01_62` (192.168.1.98).
        address = UInt32(truncatingIfNeeded: interleaved | (interleaved &>> 40))

        return true
    }

    /// Reads 4 bytes at `offset` as a `UInt32` with the byte at `offset` in the lowest lane.
    @inlinable
    @inline(always)
    static func _loadUInt32(from base: UnsafeRawPointer, at offset: Int) -> UInt32 {
        unsafe UInt32(littleEndian: base.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
    }
}
