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

        /// Make sure the most significant digit is in the 5th lane.
        /// Example: `0x34_3434_3433` ("44443" for "443") -> `0x34_3433_0000`.
        /// The leading "44" in "44443" is practically discarded as we won't read above 5th lane.
        let pushedBytes = bytes &<< (40 &- significantBits)
        /// We want to later subtract, so we need to make sure any `0x00` lane don't overflow.
        /// Therefore we generate `0x30` for those trailing lanes.
        let m30ForInsignificantBits = m30 &>> significantBits
        /// Example: `0x34_3433_0000` -> `0x34_3433_3030` ("44300").
        let digits = pushedBytes | m30ForInsignificantBits

        /// Subtracting `0x30` == ASCII `0` from each lane turns the ASCII codes into numbers.
        /// Example: `0x34_3433_3030` ("44300") -> `0x04_04_03_00_00`.
        ///
        /// For bad input with ASCII codes below `0x30`, this will set the 8th bit of the lower lane.
        let lowered = digits &- m30
        /// `0x46` is `0x80`(0b1000_0000) - (`0x39` (ASCII code of "9") + 1).
        /// So anything above `0x39` will turn on the 8th bit of the lane, unconditionally.
        let raised = digits &+ m46
        /// Check if 8th bit of any lane in `lower` of `raised` is set. If so, the port is invalid.
        guard (lowered | raised) & m80 == 0 else {
            return false
        }

        let value =
            UInt32(lowered & 0xFF) &* 10_000
            &+ UInt32((lowered &>> 8) & 0xFF) &* 1_000
            &+ UInt32((lowered &>> 16) & 0xFF) &* 100
            &+ UInt32((lowered &>> 24) & 0xFF) &* 10
            &+ UInt32((lowered &>> 32) & 0xFF)

        guard value <= 65535 else {
            return false
        }

        rawValue = UInt16(truncatingIfNeeded: value)

        return true
    }
}
