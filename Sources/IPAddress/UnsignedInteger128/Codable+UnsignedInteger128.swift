@available(SwiftStdlib 5.1, *)
extension UnsignedInteger128: Encodable {
    @inlinable
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
}

@available(SwiftStdlib 5.1, *)
extension UnsignedInteger128: Decodable {
    @inlinable
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let value = UnsignedInteger128(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid UnsignedInteger128 string representation"
            )
        }
        self = value
    }
}
