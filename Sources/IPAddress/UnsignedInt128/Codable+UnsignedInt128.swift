@available(SwiftStdlib 5.1, *)
extension UnsignedInt128: Encodable {
    @inlinable
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}

@available(SwiftStdlib 5.1, *)
extension UnsignedInt128: Decodable {
    @inlinable
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let value = UnsignedInt128(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid UnsignedInt128 string representation"
            )
        }
        self = value
    }
}
