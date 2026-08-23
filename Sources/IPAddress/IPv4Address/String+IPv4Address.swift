public import CSwiftEndpoint

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
        var resultIdx = 0

        let byte = UInt8(truncatingIfNeeded: self.address &>> 24)
        /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
        unsafe byte.asDecimal_RequiringMinimumCapacityOf3(buffer: buffer, advancingIdx: &resultIdx)

        for idx in 1..<4 {
            unsafe buffer[resultIdx] = .asciiDot
            resultIdx &+= 1

            let shift = 24 &- idx &* 8
            let byte = UInt8(truncatingIfNeeded: self.address &>> shift)
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            unsafe byte.asDecimal_RequiringMinimumCapacityOf3(
                buffer: buffer,
                advancingIdx: &resultIdx
            )
        }

        return resultIdx
    }

    /// 4x 8-bit lanes, one for each byte, each holding how many decimal digits that byte needs
    /// beyond its first one which is always written even if 0 (Example: "0.0.0.0").
    /// For example for 192.168.1.98, this will be `0x02_02_00_01`, each lane representing a segment's `digitCount - 1`.
    @inlinable
    @inline(always)
    var _extraDecimalDigitsToPrintPerByte: UInt32 {
        let address = self.address
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
    public init?(textualRepresentation utf8Span: UTF8Span) {
        self.init(textualRepresentation: utf8Span.span)
    }
}

@available(SwiftStdlib 5.1, *)
extension IPv4Address: LosslessStringConvertible {
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
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
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        var address: UInt32 = 0
        let success = IPv4Address.parseIPv4(
            span: span,
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
        let count = span.count

        /// The shortest possible IPv4 address is "0.0.0.0" with 7 bytes, and the longest possible
        /// one is "255.255.255.255" with 15 bytes.
        guard count >= 7, count <= 15 else {
            return false
        }

        #if arch(arm64)
        /// NEON is mandatory in ARMv8-A, so `arch(arm64)` implies the SIMD kernel exists.
        /// The closure only hands back the base pointer, which stays valid for as long as `span`
        /// is borrowed.
        let base = span.withUnsafeBufferPointer { unsafe $0.baseAddress.unsafelyUnwrapped }
        let packed = unsafe cswift_endpoint_parse_ipv4_dotted_decimal(base, Int32(count))

        /// `CSWIFT_ENDPOINT_IPV4_PARSE_FAILURE`. The macro itself does not survive the C importer.
        guard packed != UInt64.max else {
            return false
        }

        address = UInt32(truncatingIfNeeded: packed)

        return true
        #else
        var idx = 0

        /// No count checks, we already know it's at least 7, and we will check at most 4 here.
        guard
            let segment1 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            unsafe span[unchecked: idx] == .asciiDot
        else {
            return false
        }
        idx &+= 1

        /// No pre-parse count check, we know we have at least 7 bytes and at this
        /// point we have 3 remaining at least.
        guard
            let segment2 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx < count,
            unsafe span[unchecked: idx] == .asciiDot
        else {
            return false
        }
        idx &+= 1

        guard
            idx < count,
            let segment3 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx < count,
            unsafe span[unchecked: idx] == .asciiDot
        else {
            return false
        }
        idx &+= 1

        guard
            idx < count,
            let segment4 = IPv4Address._parseSegment(from: span, count: count, advancing: &idx),
            idx == count
        else {
            return false
        }

        address = (segment1 &<< 24) | (segment2 &<< 16) | (segment3 &<< 8) | segment4

        return true
        #endif
    }

    @inlinable
    @inline(always)
    static func _parseSegment(
        from span: Span<UInt8>,
        count: Int,
        advancing idx: inout Int
    ) -> UInt32? {
        guard let digit1 = unsafe UInt8.mapUTF8ByteToUInt8(span[unchecked: idx]) else {
            return nil
        }
        var segment = UInt32(digit1)
        idx &+= 1

        guard idx < count,
            let digit2 = unsafe UInt8.mapUTF8ByteToUInt8(span[unchecked: idx])
        else {
            return segment
        }
        segment = segment &* 10 &+ UInt32(digit2)
        idx &+= 1

        guard idx < count,
            let digit3 = unsafe UInt8.mapUTF8ByteToUInt8(span[unchecked: idx])
        else {
            return segment
        }
        segment = segment &* 10 &+ UInt32(digit3)
        idx &+= 1

        guard segment <= 255 else {
            return nil
        }

        return segment
    }
}
