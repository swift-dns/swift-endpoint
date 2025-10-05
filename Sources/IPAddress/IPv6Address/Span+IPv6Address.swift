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

    /// Initialize an `IPv6Address` from the `addressLength` bytes representing it.
    /// The rest of the bytes after `addressLength` are set to 0.
    public init?(from span: Span<UInt8>, addressLength: Int) {
        guard
            addressLength <= 16,
            span.count >= addressLength
        else {
            return nil
        }

        self.init(0)
        withUnsafeMutableBytes(of: &self.address) { ptr in
            let maxIdx = addressLength &- 1
            for idx in 0..<addressLength {
                let reverseIdx = maxIdx &- idx
                ptr[reverseIdx] = span[unchecked: idx]
            }
        }
    }
}

@available(endpointApplePlatforms 15, *)
extension IPv6Address {
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

    /// Encode the address into the provided span.
    /// Returns true if the address was encoded successfully, false otherwise.
    public func encode(into span: inout OutputSpan<UInt8>, addressLength: Int) -> Bool {
        guard
            addressLength <= 16,
            span.freeCapacity >= addressLength
        else {
            return false
        }

        withUnsafeBytes(of: self.address) { ptr in
            let maxIdx = addressLength &- 1
            for idx in 0..<addressLength {
                let reverseIdx = maxIdx &- idx
                span.append(ptr[reverseIdx])
            }
        }

        return true
    }
}
