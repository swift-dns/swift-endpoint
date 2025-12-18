@available(swiftEndpointApplePlatforms 10.15, *)
extension Span<UInt8> {
    @inlinable
    @_transparent
    func swift_dns_equals(to bytes: [UInt8]) -> Bool {
        guard self.count == bytes.count else {
            return false
        }

        for idx in 0..<bytes.count {
            if self[unchecked: idx] != bytes[idx] {
                return false
            }
        }

        return true
    }
}
