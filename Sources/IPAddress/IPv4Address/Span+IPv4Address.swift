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

    /// Initialize an `IPv4Address` from the `addressLength` bytes representing it.
    /// The rest of the bytes after `addressLength` are set to 0.
    public init?(from span: Span<UInt8>, addressLength: Int) {
        guard
            addressLength <= 4,
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

@available(endpointApplePlatforms 13, *)
extension IPv4Address {
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

    /// Encode the address into the provided span.
    /// Returns true if the address was encoded successfully, false otherwise.
    public func encode(into span: inout OutputSpan<UInt8>, addressLength: Int) -> Bool {
        guard
            addressLength <= 4,
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
