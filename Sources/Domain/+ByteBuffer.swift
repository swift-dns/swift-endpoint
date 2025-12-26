public import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 10.15, *)
extension ByteBuffer {
    @inlinable
    init(swift_endpoint_copying span: Span<UInt8>) {
        self.init()
        self.writeWithUnsafeMutableBytes(minimumWritableBytes: span.count) { bufferPtr in
            span.withUnsafeBytes { spanPtr in
                bufferPtr.copyMemory(from: spanPtr)
            }
            return span.count
        }
    }
}
