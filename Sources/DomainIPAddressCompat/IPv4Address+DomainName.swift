public import struct NIOCore.ByteBuffer

extension DomainName {
    public enum IPv4AddressInDomainNameFormatting: Sendable {
        /// The IPv4 address format for representation in dotted quad notation.
        /// For example `127.0.0.1` will turn into the domain name `"127.0.0.1"`.
        case dottedQuad
        /// The IPv4 address format for representation in the arpa format, according to
        /// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035#section-3.5).
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
        buffer.reserveCapacity(16)

        let bytes = ipv4.bytes

        buffer.writeInteger(.zero, as: UInt8.self)
        var segmentStartIndex = buffer.writerIndex
        bytes.0.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(.zero, as: UInt8.self)
        segmentStartIndex = buffer.writerIndex
        bytes.1.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(.zero, as: UInt8.self)
        segmentStartIndex = buffer.writerIndex
        bytes.2.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(.zero, as: UInt8.self)
        segmentStartIndex = buffer.writerIndex
        bytes.3.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        self.init(isFQDN: true, _uncheckedAssumingValidWireFormatBytes: buffer)
    }

    @inlinable
    init(ipv4InArpaFormat ipv4: IPv4Address) {
        var buffer = ByteBuffer()
        /// 16 is the maximum number of bytes required to represent an IPv4 address,
        /// 13 more bytes are required for the "in-addr" and "arpa" labels.
        buffer.reserveCapacity(29)

        let bytes = ipv4.bytes

        buffer.writeInteger(.zero, as: UInt8.self)
        var segmentStartIndex = buffer.writerIndex
        bytes.3.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(.zero, as: UInt8.self)
        segmentStartIndex = buffer.writerIndex
        bytes.2.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(.zero, as: UInt8.self)
        segmentStartIndex = buffer.writerIndex
        bytes.1.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(.zero, as: UInt8.self)
        segmentStartIndex = buffer.writerIndex
        bytes.0.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(7, as: UInt8.self)
        buffer.writeBytes([
            UInt8(ascii: "i"), UInt8(ascii: "n"), UInt8(ascii: "-"),
            UInt8(ascii: "a"), UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "r"),
        ])

        buffer.writeInteger(4, as: UInt8.self)
        buffer.writeBytes([
            UInt8(ascii: "a"), UInt8(ascii: "r"), UInt8(ascii: "p"), UInt8(ascii: "a"),
        ])

        self.init(isFQDN: true, _uncheckedAssumingValidWireFormatBytes: buffer)
    }
}
