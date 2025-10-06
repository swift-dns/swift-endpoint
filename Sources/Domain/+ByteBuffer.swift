public import struct NIOCore.ByteBuffer

@available(endpointApplePlatforms 13, *)
extension ByteBuffer {
    @inlinable
    init(swiftEndpointReadingFromSpan span: Span<UInt8>) {
        self.init()
        self.writeWithUnsafeMutableBytes(minimumWritableBytes: span.count) { bufferPtr in
            span.withUnsafeBytes { spanPtr in
                bufferPtr.copyMemory(from: spanPtr)
            }
            return span.count
        }
    }
}
