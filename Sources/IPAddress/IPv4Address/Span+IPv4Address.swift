@available(endpointApplePlatforms 13, *)
extension IPv4Address {
    /// Initialize an `IPv4Address` from the 4 bytes representing it.
    public init?(from span: Span<UInt8>) {
        guard span.count >= 4 else {
            return nil
        }

        self.init(0)
        withUnsafeMutableBytes(of: &self.address) { ptr in
            for idx in 0..<4 {
                let reverseIdx = 3 &- idx
                ptr[reverseIdx] = span[unchecked: idx]
            }
        }
    }

    /// Encode the address into the provided span.
    /// Returns true if the address was encoded successfully, false otherwise.
    public func encode(into span: inout OutputSpan<UInt8>) -> Bool {
        guard span.freeCapacity >= 4 else {
            return false
        }

        withUnsafeBytes(of: self.address) { ptr in
            for idx in 0..<4 {
                let reverseIdx = 3 &- idx
                span.append(ptr[reverseIdx])
            }
        }

        return true
    }
}
