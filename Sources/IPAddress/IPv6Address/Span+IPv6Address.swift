@available(endpointApplePlatforms 15, *)
extension IPv6Address {
    /// Initialize an `IPv6Address` from the 16 bytes representing it.
    public init?(from span: Span<UInt8>) {
        guard span.count >= 16 else {
            return nil
        }

        self.init(0)
        withUnsafeMutableBytes(of: &self.address) { ptr in
            for idx in 0..<16 {
                let reverseIdx = 15 &- idx
                ptr[reverseIdx] = span[unchecked: idx]
            }
        }
    }

    /// Encode the address into the provided span.
    /// Returns true if the address was encoded successfully, false otherwise.
    public func encode(into span: inout OutputSpan<UInt8>) -> Bool {
        guard span.freeCapacity >= 16 else {
            return false
        }

        withUnsafeBytes(of: self.address) { ptr in
            for idx in 0..<16 {
                let reverseIdx = 15 &- idx
                span.append(ptr[reverseIdx])
            }
        }

        return true
    }
}
