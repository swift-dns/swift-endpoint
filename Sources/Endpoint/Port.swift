/// A port number for networking operations.
public struct Port: Sendable, Hashable {
    /// The canonical value of the port.
    public let canonicalValue: UInt16

    /// Convenience accessor for the canonical value.
    public var value: Int {
        Int(self.canonicalValue)
    }

    /// Create a new port with the given canonical value.
    public init(_ canonicalValue: UInt16) {
        self.canonicalValue = canonicalValue
    }

    /// Create a new port with the given value.
    /// Precondition: the value must be between 0 and 65535.
    @_disfavoredOverload
    public init(_ value: Int) {
        precondition(value >= 0 && value <= 65535, "Port must be between 0 and 65535")
        self.canonicalValue = UInt16(value)
    }
}

extension Port: ExpressibleByIntegerLiteral {
    /// Create a new port with the given canonical value.
    public init(integerLiteral value: UInt16) {
        self.init(value)
    }
}
