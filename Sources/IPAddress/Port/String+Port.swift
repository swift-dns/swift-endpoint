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
        /// one is "65535" with 5 bytes.
        guard count >= 1, count <= 5 else {
            return false
        }

        /// `count > 0` so `(0...4) ~ (count - 1)`.
        let last = count &- 1

        /// The reads are clamped to `last` instead of being skipped, so that the number of
        /// digits never decides control flow. A rolled or unrolled digit loop makes the
        /// branch predictor guess the length of every input, which costs a full mispredict
        /// per parse on real-world port lists, where the lengths vary unpredictably.
        /// Lanes past `last` re-read the final byte, and are discarded below.
        let bytes =
            UInt64(unsafe span[unchecked: 0])
            | (UInt64(unsafe span[unchecked: min(1, last)]) &<< 8)
            | (UInt64(unsafe span[unchecked: min(2, last)]) &<< 16)
            | (UInt64(unsafe span[unchecked: min(3, last)]) &<< 24)
            | (UInt64(unsafe span[unchecked: last]) &<< 32)

        let m30: UInt64 = 0x30_30_30_30_30
        let significantBits = UInt64(8 &* count)

        /// Shift the `count` real bytes up so the least significant digit always lands in
        /// lane 4, then fill the vacated low lanes — the most significant places — with
        /// ASCII `0`. So `"443"` becomes the 5 lanes of `"00443"`, and every input is
        /// weighted by the same fixed lane weights below.
        /// The duplicated lanes are pushed above bit 39, where nothing below reads them.
        let digits = (bytes &<< (40 &- significantBits)) | (m30 &>> significantBits)

        /// Subtracting `0x30` == ASCII `0` from each lane turns the ASCII codes into numbers.
        let lowered = digits &- m30
        /// Adding `0x46` pushes any lane above ASCII `9` into the top half of its lane.
        let raised = digits &+ 0x46_46_46_46_46
        /// A lane below ASCII `0` borrows and sets its own top bit in `lowered`; a lane above
        /// ASCII `9` sets its top bit in `raised`. Valid lanes set neither, and neither
        /// borrow nor carry, so they cannot disturb their neighbours.
        guard (lowered | raised) & 0x80_80_80_80_80 == 0 else {
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
