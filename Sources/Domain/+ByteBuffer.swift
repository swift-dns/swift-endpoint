public import struct NIOCore.ByteBuffer

@available(SwiftStdlib 5.1, *)
extension ByteBuffer {
    @inlinable
    init(swift_endpoint_copying span: Span<UInt8>) {
        self.init()
        unsafe self.writeWithUnsafeMutableBytes(minimumWritableBytes: span.count) { bufferPtr in
            span.withUnsafeBytes { spanPtr in
                unsafe bufferPtr.copyMemory(from: spanPtr)
            }
            return span.count
        }
    }
}
