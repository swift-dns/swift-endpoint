@available(SwiftStdlib 5.1, *)
extension Port: CustomStringConvertible {
    /// The textual representation of a port, in decimal notation and without leading zeros.
    /// For example `Port(8080)` is represented as `"8080"`.
    @inlinable
    public var description: String {
        /// 8 is enough for the biggest possible Port description (65535), plus 3 headroom bytes
        /// for speculative writes.
        /// Swift's `_SmallString` supports at least 8 bytes on every platform, so this
        /// still never heap-allocates.
        unsafe String(unsafeUninitializedCapacity_Compatibility: 8) { buffer in
            unsafe self.writeTextualRepresentation_RequiringMinimumCapacityOf8(
                into: UnsafeMutableRawBufferPointer(buffer)
            )
        }
    }

    /// Writes the textual representation of this port into `buffer` and returns the number of
    /// significant bytes written. `buffer` must have a capacity of at least 8 bytes.
    @inlinable
    @inline(always)
    package func writeTextualRepresentation_RequiringMinimumCapacityOf8(
        into buffer: UnsafeMutableRawBufferPointer
    ) -> Int {
        assert(buffer.count >= 8)

        let value = UInt32(self.rawValue)

        let high = value / 100
        /// value % 100
        let low = value &- (high &* 100)
        /// value / 10_000; 6 in `65432`
        let tenThousands = high / 100
        /// (value % 10_000) / 100; 54 in `65432`
        let middle = high &- (tenThousands &* 100)
        /// (value % 10_000) / 1_000; 5 in `65432`
        let thousands = middle / 10
        /// (value % 1_000) / 100; 4 in `65432`
        let hundreds = middle &- (thousands &* 10)
        /// (value % 100) / 10; 3 in `65432`
        let tens = low / 10
        /// value % 10; 2 in `65432`
        let ones = low &- (tens &* 10)

        /// 5x 8-bit lanes, one digit each, most significant first.
        /// We write backwards because we're later going to copy the exact memory, and
        /// integer byte-order is almost always little-endian.
        let digits =
            UInt64(tenThousands)
            | (UInt64(thousands) &<< 8)
            | (UInt64(hundreds) &<< 16)
            | (UInt64(tens) &<< 24)
            | (UInt64(ones) &<< 32)
        /// Add `0x30` == ASCII `0` to each to make ASCII codes out of the numbers.
        let m30: UInt64 = 0x30_30_30_30_30
        let asciiBytes = digits &+ m30

        /// Let's ensure we don't write leading 0s.
        /// We count trailing zeros because the bytes are written backwards.
        /// A leading zero is a trailing lane that is exactly `0x30`, so XORing out `m30` turns the
        /// `0x30` lanes into trailing `0`s.
        /// `& ~0b111` makes sure the number is a multiple of 8 (masks off 3 trailing bits).
        /// Essentially a `num - (num % 8)`.
        let zeroDigitsBits = (asciiBytes ^ m30).trailingZeroBitCount & ~0b111
        /// If all 5 digits are 0 (zeroDigitsBits >= 40; 64 actually) we still need to write 1 zero.
        let zeroDigitsBitsMax32 = min(zeroDigitsBits, 32)
        let toStore = asciiBytes &>> zeroDigitsBitsMax32

        /// Always store all 8 bytes, but only advance past the significant digits.
        unsafe buffer.storeBytes(of: toStore, toByteOffset: 0, as: UInt64.self)

        /// `zeroDigitsBitsMax32 &>> 3` == `zeroDigitsBitsMax32 / 8`
        /// Compiler will optimize `/ 8` to a shift by 3 anyway so 🤷‍♂️.
        let numPortTrailingZerosMax4 = zeroDigitsBitsMax32 &>> 3
        return 5 &- numPortTrailingZerosMax4
    }
}

@available(SwiftStdlib 6.2, *)
extension Port {
    /// Initialize a `Port` from a `UTF8Span` of its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    @inlinable
    @inline(always)
    public init?(textualRepresentation utf8Span: UTF8Span) {
        self.init(textualRepresentation: utf8Span.span)
    }
}

@available(SwiftStdlib 5.1, *)
extension Port: ExpressibleByStringLiteral {
    /// Initialize a `Port` from its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    ///
    /// **This initializer is free: It's unrolled to a constant at compile time.**
    /// That is, as long as the string literal is passed directly to the init like so: `let port: Port = "443"`.
    /// **Passing a dynamic `StaticString` (`let str: StaticString = "443"; Port(stringLiteral: str)`) to this init is a bad idea.**
    /// In that case, use `Port(String(str))` instead.
    /// Might be deprecated in favor of a Swift macro in the future. For now helps with skipping Swift compile-time macro issues.
    @inlinable
    @inline(always)
    public init(stringLiteral value: StaticString) {
        guard
            let result = value.withUTF8Buffer({
                Port(_inlined_textualRepresentation: unsafe $0.span)
            })
        else {
            fatalError("StaticString passed to Port initializer was invalid")
        }
        self = result
    }

    /// Initialize a `Port` from its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    ///
    /// **This initializer is free: It's unrolled to a constant at compile time.**
    /// That is, as long as the string literal is passed directly to the init like so: `let port: Port = "443"`.
    /// **Passing a dynamic `StaticString` (`let str: StaticString = "443"; Port(stringLiteral: str)`) to this init is a bad idea.**
    /// In that case, use `Port(String(str))` instead.
    /// Might be deprecated in favor of a Swift macro in the future. For now helps with skipping Swift compile-time macro issues.
    @inlinable
    @inline(always)
    @_disfavoredOverload
    @available(
        *,
        deprecated,
        message: """
            For literal strings, use `Port(stringLiteral:)` or `let port: Port = "443"` instead
            """
    )
    public init(_ value: StaticString) {
        self.init(stringLiteral: value)
    }
}

@available(SwiftStdlib 5.1, *)
extension Port: LosslessStringConvertible {
    /// Initialize a `Port` from its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    @inlinable
    @inline(always)
    public init?(_ description: String) {
        guard
            let result = description.withSpan_Compatibility({
                Port(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize a `Port` from its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    @inlinable
    @inline(always)
    public init?(_ description: Substring) {
        guard
            let result = description.withSpan_Compatibility({
                Port(textualRepresentation: $0)
            })
        else {
            return nil
        }
        self = result
    }

    /// Initialize a `Port` from a `Span<UInt8>` of its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    ///
    /// This init unlike the other ones above is intentionally not `@inline(always)` to act as the
    /// inlining boundary and allow the compiler to decide what to do.
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        self.init(_inlined_textualRepresentation: span)
    }

    /// Initialize a `Port` from a `Span<UInt8>` of its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    @inlinable
    @inline(always)
    init?(_inlined_textualRepresentation span: Span<UInt8>) {
        var rawValue: UInt16 = 0
        let success = Port.parsePort(
            span: span,
            rawValue: &rawValue
        )

        guard success else {
            return nil
        }

        self.init(rawValue: rawValue)
    }

    /// Credit goes to @aqrit for original impl.
    /// See:
    /// https://github.com/fastfloat/fast_float/blob/a8a02f77480d10c5dc90d39f7b890bc1dff9c1b9/include/fast_float/ascii_number.h#L143
    /// https://lemire.me/blog/2018/10/03/quickly-parsing-eight-digits/
    /// https://lemire.me/blog/2022/01/21/swar-explained-parsing-eight-digits/
    @inlinable
    @inline(always)
    static func parsePort(
        span: Span<UInt8>,
        rawValue: inout UInt16
    ) -> Bool {
        let count = span.count

        /// The shortest possible port is "0" with 1 byte, and the longest possible
        /// port is "65535" with 5 bytes.
        guard count >= 1, count <= 5 else {
            return false
        }

        let lastIdx = count &- 1
        /// Read all possible 5 digits, clamped to `lastIdx` so we don't read out of bounds.
        let bytes =
            UInt64(unsafe span[unchecked: 0])
            | (UInt64(unsafe span[unchecked: min(1, lastIdx)]) &<< 8)
            | (UInt64(unsafe span[unchecked: min(2, lastIdx)]) &<< 16)
            | (UInt64(unsafe span[unchecked: min(3, lastIdx)]) &<< 24)
            | (UInt64(unsafe span[unchecked: lastIdx]) &<< 32)

        /// `0x30` == ASCII `0`
        let m30: UInt64 = 0x30_30_30_30_30
        /// `0x46` == `0b0100_0110` == `0x80`(0b1000_0000) - (`0x39` + 1)
        /// (`0x39` + 1) == `0x39` (ASCII code of "9") + 1
        let m46: UInt64 = 0x46_46_46_46_46
        /// `0x80` == `0b1000_0000`
        let m80: UInt64 = 0x80_80_80_80_80

        let significantBits = UInt64(8 &* count)

        /// Make sure the least significant digit is in the 5th lane.
        /// Example: `0x33_3333_3434` ("33344" for "443") -> `0x33_3333_3434_0000`.
        /// The leading "33" in "33344" will be discarded later when it can matter.
        let pushedBytes = bytes &<< (40 &- significantBits)
        /// We want to later subtract, so we need to make sure any `0x00` lane don't underflow.
        /// Therefore we generate `0x30` for those trailing lanes.
        let m30ForInsignificantBits = m30 &>> significantBits
        /// Example: `0x33_3333_3434_0000` -> `0x33_3333_3434_3030` ("3334400").
        let digits = pushedBytes | m30ForInsignificantBits

        /// Subtracting `0x30` == ASCII `0` from each lane turns the ASCII codes into numbers.
        /// Example: `0x33_3333_3434_3030` ("3334400") -> `0x33_33_03_04_04_00_00`.
        ///
        ///
        /// For bad input with ASCII codes below `0x30`, this will set the 8th bit of the lower lane.
        ///
        /// Generally, if a < b, then `a &- b` == `(UInt_.max + 1) + a - b` or more
        /// accurately `UInt_.max - b + a + 1`.
        /// In other terms, `a &- b` == `2^n - b + a` where `n` is numbers of bits in the type.
        /// For example in `UInt64`, n == `64`. Also `2^64` == `UInt64.max + 1`.
        ///
        /// So if lane L is < 0x30, then `L - 0x30` == `L - 0x30 + 0x100` == `L + 0xD0`.
        /// `0x100` is `UInt_.max + 1`, where the `UInt_` type is `8 + 1` == `9` bits ("UInt9").
        /// `0xD0` is `1101_0000`, which has the 8th bit set.
        /// So for bad input, 8th bit of the lane will always be set.
        /// For UInt64 there will be overflows to higher lanes, but at that point we don't care anymore.
        /// We know that 1 lane has 8th bit set and later we'll detect that as a parsing failure.
        let digitsInBytes = digits &- m30
        /// `0x46` is `0x80`(0b1000_0000) - (`0x39` (ASCII code of "9") + 1).
        /// So any bad input above `0x39` will turn on the 8th bit of the lane, unconditionally.
        let raised = digits &+ m46
        /// Check if 8th bit of any lane in `digitsInBytes` or `raised` is set. If so, the port is invalid.
        guard (digitsInBytes | raised) & m80 == 0 else {
            return false
        }

        /// `0x0A01` == `0x0A` (10) then `0x01` (1), so multiplying by it folds the lanes in pairs.
        let nA1: UInt64 = 0x0A01
        /// The `&<<` that made `pushedBytes` left leftover digits above the 5 lanes, and the
        /// multiplication would fold those into the 7th lane, which we do read below.
        /// `& 0xFF_FFFF_FFFF` clears them so the 7th lane is guaranteed to stay `0x00`.
        let clearedDigitsInBytes = digitsInBytes & 0xFF_FFFF_FFFF
        /// Each lane turns into `10 * previousLane + lane`, which is at most
        /// `10 * 9 + 9` == `99` < `256`, so no lane can ever overflow into the next one.
        /// Example: `0x03_04_04_00_00` ("34400" for "443") -> `0x1E_2B_2C_04_00_00` (30, 43, 44, 4, 0, 0).
        let multipliedDigitsInBytes = clearedDigitsInBytes &* nA1
        /// We only need the 1st, 3rd and 5th lanes, so mask off the ones in between.
        /// Lane 1st is the ten-thousands, Lane 3rd is the hundreds + 10*thousands and lane 5th is the ones + 10*tens.
        /// Example: `0x1E_2B_2C_04_00_00` -> `0x2B_00_04_00_00` (43, 4, 0).
        ///
        /// The 7th lane survives too, but it's already `0x00`, and on arm64 this mask is a
        /// single `and` while one that also clears the 7th lane costs 3 instructions.
        let pairs = multipliedDigitsInBytes & 0x00FF_00FF_00FF_00FF
        /// `0x1388_0032_0000_8000` == `10_000 << 47 | 100 << 31 | 1 << 15`.
        /// This means (1st lane) * 10_000 + (3rd lane) * 100 + (5th lane) * 1 end up in bits 47th...63rd.
        /// Example: `0x2B_00_04_00_00` -> `0xDD_8002_0000_0000`, and `&>> 47` of that is `443`.
        ///
        /// The biggest value this can produce is `99999`, which needs 17 bits, and bits 47...63
        /// are exactly 17 bits.
        let value = UInt32(truncatingIfNeeded: (pairs &* 0x1388_0032_0000_8000) &>> 47)

        guard value <= 65535 else {
            return false
        }

        rawValue = UInt16(truncatingIfNeeded: value)

        return true
    }
}
