@available(SwiftStdlib 5.1, *)
extension Span<UInt8> {
    @inlinable
    var isASCII: Bool {
        var result: UInt8 = 0
        for idx in self.indices {
            result |= self[unchecked: idx]
        }
        return result <= 127
    }
}
