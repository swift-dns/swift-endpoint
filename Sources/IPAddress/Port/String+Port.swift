@available(SwiftStdlib 5.1, *)
extension Port: CustomStringConvertible {
    /// The textual representation of a port, in decimal notation and without leading zeros.
    /// For example `Port(8080)` is represented as `"8080"`.
    @inlinable
    public var description: String {
        /// 5 is enough for the biggest possible Port description.
        /// For example for "65535".
        /// Swift's `_SmallString` usually supports up to 15 bytes, which helps make
        /// this implementation as efficient as possible without a heap allocation.
        unsafe String(unsafeUninitializedCapacity_Compatibility: 5) { buffer in
            unsafe self.writeTextualRepresentation_RequiringMinimumCapacityOf5(
                into: UnsafeMutableRawBufferPointer(buffer)
            )
        }
    }

    /// Writes the textual representation of this port into `buffer` and returns the number of
    /// bytes written. `buffer` must have a capacity of at least 5 bytes.
    @inlinable
    @inline(always)
    package func writeTextualRepresentation_RequiringMinimumCapacityOf5(
        into buffer: UnsafeMutableRawBufferPointer
    ) -> Int {
        assert(buffer.count >= 5)

        var idx = 0

        /// The compiler is smart enough to not actually do division by 10.
        let (q1, r1) = self.canonicalValue.quotientAndRemainder(dividingBy: 10)
        let (q2, r2) = q1.quotientAndRemainder(dividingBy: 10)
        let (q3, r3) = q2.quotientAndRemainder(dividingBy: 10)
        let (q4, r4) = q3.quotientAndRemainder(dividingBy: 10)
        let r5 = q4 % 10

        /// Always write, but only advance past it when it should be kept.
        var notAllZerosSoFar = r5 != 0
        unsafe buffer[idx] = UInt8(truncatingIfNeeded: r5) &+ .ascii0
        idx &+= notAllZerosSoFar ? 1 : 0

        notAllZerosSoFar = notAllZerosSoFar || r4 != 0
        unsafe buffer[idx] = UInt8(truncatingIfNeeded: r4) &+ .ascii0
        idx &+= notAllZerosSoFar ? 1 : 0

        notAllZerosSoFar = notAllZerosSoFar || r3 != 0
        unsafe buffer[idx] = UInt8(truncatingIfNeeded: r3) &+ .ascii0
        idx &+= notAllZerosSoFar ? 1 : 0

        notAllZerosSoFar = notAllZerosSoFar || r2 != 0
        unsafe buffer[idx] = UInt8(truncatingIfNeeded: r2) &+ .ascii0
        idx &+= notAllZerosSoFar ? 1 : 0

        unsafe buffer[idx] = UInt8(truncatingIfNeeded: r1) &+ .ascii0
        idx &+= 1

        return idx
    }
}

@available(SwiftStdlib 6.2, *)
extension Port {
    /// Initialize a `Port` from a `UTF8Span` of its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    @inlinable
    public init?(textualRepresentation utf8Span: UTF8Span) {
        self.init(textualRepresentation: utf8Span.span)
    }
}

@available(SwiftStdlib 5.1, *)
extension Port: LosslessStringConvertible {
    /// Initialize a `Port` from its textual representation.
    /// That is, at most 5 decimal digits amounting to a value of at most 65535.
    /// For example `"8080"` will parse into `Port(8080)`.
    public init?(_ description: String) {
        var description = description
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
    public init?(_ description: Substring) {
        var description = description
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
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        var canonicalValue: UInt16 = 0
        let success = Port.parsePort(
            span: span,
            canonicalValue: &canonicalValue
        )

        guard success else {
            return nil
        }

        self.init(canonicalValue: canonicalValue)
    }

    @inlinable
    @inline(always)
    static func parsePort(
        span: Span<UInt8>,
        canonicalValue: inout UInt16
    ) -> Bool {
        let count = span.count

        /// The shortest possible port is "0" with 1 byte, and the longest possible
        /// one is "65535" with 5 bytes.
        guard count >= 1, count <= 5 else {
            return false
        }

        guard let digit1 = unsafe UInt8.mapUTF8ByteToUInt8(span[unchecked: 0]) else {
            return false
        }
        var value = UInt32(digit1)

        var idx = 1
        while idx < count {
            guard let digit = unsafe UInt8.mapUTF8ByteToUInt8(span[unchecked: idx]) else {
                return false
            }
            value = value &* 10 &+ UInt32(digit)
            idx &+= 1
        }

        guard value <= 65535 else {
            return false
        }

        canonicalValue = UInt16(truncatingIfNeeded: value)

        return true
    }
}
