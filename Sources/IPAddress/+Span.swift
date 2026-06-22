@available(SwiftStdlib 5.1, *)
extension Span<UInt8> {
    @inlinable
    var isASCII: Bool {
        var result: UInt8 = 0
        var idx = 0
        let count = self.count
        while idx < count {
            result |= self[unchecked: idx]
            idx &+= 1
        }
        return result <= 127
    }
}
