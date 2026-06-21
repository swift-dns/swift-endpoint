public import SwiftIDNA

public import struct NIOCore.ByteBuffer

@available(SwiftStdlib 5.1, *)
extension DomainName.Label: CustomStringConvertible {
    /// Unicode-friendly description of the label.
    /// Example: `"mahdibm"`
    /// Example: `"新华网"` (for `"xn--xkrr14bows"`)
    @inlinable
    public var description: String {
        self.description(format: .unicode)
    }
}

@available(SwiftStdlib 5.1, *)
extension DomainName.Label: CustomDebugStringConvertible {
    /// Source-accurate, ASCII description of the label, as in the wire format and IDNA.
    /// Example: `"mahdibm"`
    /// Example: `"xn--xkrr14bows"` (for `"新华网"`)
    @inlinable
    public var debugDescription: String {
        self.description(format: .ascii)
    }
}

@available(SwiftStdlib 5.1, *)
extension DomainName.Label {
    @inlinable
    public func description(format: DomainName.DescriptionFormat) -> String {
        if format == .unicode {
            let conversion = try? IDNA(configuration: .mostLax).toUnicode(
                _uncheckedAssumingValidUTF8: self._data.readableBytesUInt8Span
            )
            let collected = conversion?.collect()
            // FIXME: Handle error?
            return collected ?? self._makeDescriptionAssumingASCII()
        } else {
            return self._makeDescriptionAssumingASCII()
        }
    }

    @inlinable
    func _makeDescriptionAssumingASCII() -> String {
        let byteCount = self._data.readableBytes
        return String(unsafeUninitializedCapacity_Compatibility: byteCount) { stringBuffer in
            self._data.withUnsafeReadableBytes { ptr in
                let rawBuffer = UnsafeMutableRawBufferPointer(stringBuffer)
                rawBuffer.copyMemory(from: ptr)
            }
            return byteCount
        }
    }
}
