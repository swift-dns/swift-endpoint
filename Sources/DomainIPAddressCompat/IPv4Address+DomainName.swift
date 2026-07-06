public import struct NIOCore.ByteBuffer

extension DomainName {
    @nonexhaustive
    public enum IPv4AddressInDomainNameFormatting: Sendable {
        /// The IPv4 address format for representation in dotted-quad notation.
        /// For example `127.0.0.1` will turn into the domain name `"127.0.0.1"`.
        case dottedQuad
        /// The IPv4 address format for representation in the arpa format, according to
        /// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://datatracker.ietf.org/doc/html/rfc1035#section-3.5).
        ///
        /// For example `127.0.0.1` will turn into the domain name `"1.0.0.127.in-addr.arpa"`.
        case arpa
    }

    /// Initialize a `DomainName` from an `IPv4Address`.
    ///
    /// If the `format` parameter is set to `.arpa` (which is the default), the address will be represented in arpa notation.
    /// For example `IPv4Address(127, 0, 0, 1)` will turn into the domain name `"1.0.0.127.in-addr.arpa"`.
    ///
    /// If the `format` parameter is set to `.dottedQuad`, the address will be represented in dotted quad notation.
    /// For example `IPv4Address(127, 0, 0, 1)` will turn into the domain name `"127.0.0.1"`.
    @inlinable
    public init(ipv4: IPv4Address, format: IPv4AddressInDomainNameFormatting = .arpa) {
        switch format {
        case .dottedQuad:
            self.init(ipv4InDottedQuadNotation: ipv4)
        case .arpa:
            self.init(ipv4InArpaFormat: ipv4)
        }
    }

    @inlinable
    init(ipv4InDottedQuadNotation ipv4: IPv4Address) {
        var buffer = ByteBuffer()
        /// 16 is the maximum number of bytes required to represent an IPv4 address here
        unsafe buffer.writeWithUnsafeMutableBytes(minimumWritableBytes: 16) { bufferPtr in
            var bufferIdx = 0
            let bytes = ipv4.bytes

            unsafe bufferPtr[bufferIdx] = .zero
            bufferIdx &+= 1
            var segmentStartIndex = bufferIdx
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            unsafe bytes.0.asDecimal_RequiringMinimumCapacityOf3(
                buffer: bufferPtr,
                advancingIdx: &bufferIdx
            )
            unsafe bufferPtr[segmentStartIndex &- 1] = UInt8(
                truncatingIfNeeded: bufferIdx &- segmentStartIndex
            )

            unsafe bufferPtr[bufferIdx] = .zero
            bufferIdx &+= 1
            segmentStartIndex = bufferIdx
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            unsafe bytes.1.asDecimal_RequiringMinimumCapacityOf3(
                buffer: bufferPtr,
                advancingIdx: &bufferIdx
            )
            unsafe bufferPtr[segmentStartIndex &- 1] = UInt8(
                truncatingIfNeeded: bufferIdx &- segmentStartIndex
            )

            unsafe bufferPtr[bufferIdx] = .zero
            bufferIdx &+= 1
            segmentStartIndex = bufferIdx
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            unsafe bytes.2.asDecimal_RequiringMinimumCapacityOf3(
                buffer: bufferPtr,
                advancingIdx: &bufferIdx
            )
            unsafe bufferPtr[segmentStartIndex &- 1] = UInt8(
                truncatingIfNeeded: bufferIdx &- segmentStartIndex
            )

            unsafe bufferPtr[bufferIdx] = .zero
            bufferIdx &+= 1
            segmentStartIndex = bufferIdx
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            unsafe bytes.3.asDecimal_RequiringMinimumCapacityOf3(
                buffer: bufferPtr,
                advancingIdx: &bufferIdx
            )
            unsafe bufferPtr[segmentStartIndex &- 1] = UInt8(
                truncatingIfNeeded: bufferIdx &- segmentStartIndex
            )

            return bufferIdx
        }

        self.init(isFQDN: true, _uncheckedAssumingValidWireFormatBytes: buffer)
    }

    @inlinable
    init(ipv4InArpaFormat ipv4: IPv4Address) {
        var buffer = ByteBuffer()
        /// 16 is the maximum number of bytes required to represent an IPv4 address,
        /// 15 more bytes are required for the "in-addr" and "arpa" labels.
        unsafe buffer.writeWithUnsafeMutableBytes(minimumWritableBytes: 31) { bufferPtr in
            var bufferIdx = 0
            let bytes = ipv4.bytes

            unsafe bufferPtr[bufferIdx] = .zero
            bufferIdx &+= 1
            var segmentStartIndex = bufferIdx
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            unsafe bytes.3.asDecimal_RequiringMinimumCapacityOf3(
                buffer: bufferPtr,
                advancingIdx: &bufferIdx
            )
            unsafe bufferPtr[segmentStartIndex &- 1] = UInt8(
                truncatingIfNeeded: bufferIdx &- segmentStartIndex
            )

            unsafe bufferPtr[bufferIdx] = .zero
            bufferIdx &+= 1
            segmentStartIndex = bufferIdx
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            unsafe bytes.2.asDecimal_RequiringMinimumCapacityOf3(
                buffer: bufferPtr,
                advancingIdx: &bufferIdx
            )
            unsafe bufferPtr[segmentStartIndex &- 1] = UInt8(
                truncatingIfNeeded: bufferIdx &- segmentStartIndex
            )

            unsafe bufferPtr[bufferIdx] = .zero
            bufferIdx &+= 1
            segmentStartIndex = bufferIdx
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            unsafe bytes.1.asDecimal_RequiringMinimumCapacityOf3(
                buffer: bufferPtr,
                advancingIdx: &bufferIdx
            )
            unsafe bufferPtr[segmentStartIndex &- 1] = UInt8(
                truncatingIfNeeded: bufferIdx &- segmentStartIndex
            )

            unsafe bufferPtr[bufferIdx] = .zero
            bufferIdx &+= 1
            segmentStartIndex = bufferIdx
            /// This is safe; We've already reserved max capacity needed for the longest possible IPv4 address
            unsafe bytes.0.asDecimal_RequiringMinimumCapacityOf3(
                buffer: bufferPtr,
                advancingIdx: &bufferIdx
            )
            unsafe bufferPtr[segmentStartIndex &- 1] = UInt8(
                truncatingIfNeeded: bufferIdx &- segmentStartIndex
            )

            unsafe bufferPtr[bufferIdx] = 7
            unsafe bufferPtr[bufferIdx &+ 1] = UInt8(ascii: "i")
            unsafe bufferPtr[bufferIdx &+ 2] = UInt8(ascii: "n")
            unsafe bufferPtr[bufferIdx &+ 3] = UInt8(ascii: "-")
            unsafe bufferPtr[bufferIdx &+ 4] = UInt8(ascii: "a")
            unsafe bufferPtr[bufferIdx &+ 5] = UInt8(ascii: "d")
            unsafe bufferPtr[bufferIdx &+ 6] = UInt8(ascii: "d")
            unsafe bufferPtr[bufferIdx &+ 7] = UInt8(ascii: "r")

            unsafe bufferPtr[bufferIdx &+ 8] = 4
            unsafe bufferPtr[bufferIdx &+ 9] = UInt8(ascii: "a")
            unsafe bufferPtr[bufferIdx &+ 10] = UInt8(ascii: "r")
            unsafe bufferPtr[bufferIdx &+ 11] = UInt8(ascii: "p")
            unsafe bufferPtr[bufferIdx &+ 12] = UInt8(ascii: "a")

            bufferIdx &+= 13

            return bufferIdx
        }

        self.init(isFQDN: true, _uncheckedAssumingValidWireFormatBytes: buffer)
    }
}
