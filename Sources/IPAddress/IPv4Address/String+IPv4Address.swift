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
    @inlinable
    @inline(always)
    package func writeTextualRepresentation_Requiring2HeadroomBytes(
        into buffer: UnsafeMutableRawBufferPointer
    ) -> Int {
        /// These are safe; We've already reserved max capacity needed for the longest possible
        /// IPv4 address, and only the last segment needs the 2 headroom bytes.
        let (paddedBytes, count) = UInt8(truncatingIfNeeded: self._address &>> 24).asDecimal()
        /// The first segment has no leading `.`, so it writes the digits a byte lower.
        unsafe buffer.storeBytes(of: paddedBytes &>> 8, toByteOffset: 0, as: UInt32.self)
        var resultIdx = count

        for idx in 1..<4 {
            let shift = 24 - idx * 8
            let byte = UInt8(truncatingIfNeeded: self._address &>> shift)
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
    /// For example for 192.168.1.98, this will be `0x02_02_00_01`, each lane representing a segment's `digitCount - 1`.
    @inlinable
    @inline(always)
    var _extraDecimalDigitsToPrintPerByte: UInt32 {
        let address = self._address
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
        let isAtLeast10 = atLeast10 &>> 7
        /// 1 in each lane if yes, 0 if no.
        let isAtLeast100 = atLeast100 &>> 7
        return isAtLeast10 &+ isAtLeast100
    }

    /// The number of bytes that the textual representation of this address will occupy, plus up
    /// to 2 extra headroom bytes for speculative writes.
    ///
    /// Essentially, this var has to assume that the least significant byte of the address which is
    /// written last, will require 3 bytes of room at all times.
    @inlinable
    @inline(always)
    package var _textualRepresentationWriteRequiredCapacity: Int {
        /// Mask out the last byte to avoid counting the extra digits it would require.
        /// At the end, we add 2 headroom bytes anyways.
        let extraDigits = self._extraDecimalDigitsToPrintPerByte & 0xFFFF_FF00
        /// Puts sum of all 4 lanes into bits 25th-28th.
        /// Then we bit shift by 24 to get the sum into bits 1st-3rd.
        let extraDigitsCount = (extraDigits &* 0x0101_0101) &>> 24
        /// 9 == 3 dots + the first digit of each of the 4 bytes + 2 headroom bytes.
        return 9 &+ Int(extraDigitsCount)
    }

    /// The exact number of bytes that the textual representation of this address occupies.
    @inlinable
    @inline(always)
    package var textualRepresentationLength: Int {
        let allDigits = self._extraDecimalDigitsToPrintPerByte
        /// Puts sum of all 4 lanes into bits 25th-28th.
        /// Then we bit shift by 24 to get the sum into bits 1st-3rd.
        let extraDigitsCount = (allDigits &* 0x0101_0101) &>> 24
        /// 7 == 3 dots + the first digit of each of the 4 bytes.
        return 7 &+ Int(extraDigitsCount)
    }
}

@available(SwiftStdlib 6.2, *)
extension IPv4Address {
    /// Initialize an IPv4 address from a `UTF8Span` of its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
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
    @inlinable
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
    @inlinable
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
    @inlinable
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

        var idx = 0

        guard
            let segment1 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx < count,
            span[idx] == .asciiDot
        else {
            return false
        }
        idx += 1

        guard
            let segment2 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx < count,
            span[idx] == .asciiDot
        else {
            return false
        }
        idx += 1

        guard
            let segment3 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx < count,
            span[idx] == .asciiDot
        else {
            return false
        }
        idx += 1

        guard
            let segment4 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx == count
        else {
            return false
        }

        address = (segment1 &<< 24) | (segment2 &<< 16) | (segment3 &<< 8) | segment4

        return true
    }

    @inlinable
    @inline(always)
    static func _parseSegment(
        from span: Span<UInt8>,
        count: Int,
        advancing idx: inout Int
    ) -> UInt32? {
        guard idx < count,
            let digit1 = UInt8.mapUTF8ByteToUInt8(span[idx])
        else {
            return nil
        }
        var segment = UInt32(digit1)
        idx += 1

        guard idx < count,
            let digit2 = UInt8.mapUTF8ByteToUInt8(span[idx])
        else {
            return segment
        }
        segment = segment * 10 + UInt32(digit2)
        idx += 1

        guard idx < count,
            let digit3 = UInt8.mapUTF8ByteToUInt8(span[idx])
        else {
            return segment
        }
        segment = segment * 10 + UInt32(digit3)
        idx += 1

        guard segment <= 255 else {
            return nil
        }

        return segment
    }
}
