@available(swiftEndpointApplePlatforms 10.15, *)
extension [UInt8] {
    @inlinable
    init(copying span: Span<UInt8>) {
        let count = span.count
        if count == 0 {
            self.init()
            return
        }

        self.init(unsafeUninitializedCapacity: count) { buffer, initializedCount in
            let rawBuffer = UnsafeMutableRawBufferPointer(buffer)
            span.withUnsafeBytes { spanPtr in
                let rawSpanPtr = UnsafeRawBufferPointer(spanPtr)
                rawBuffer.copyMemory(from: rawSpanPtr)
            }
            initializedCount = count
        }
    }
}
