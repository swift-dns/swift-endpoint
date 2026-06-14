/// A port number for networking operations.
public struct Port: Sendable, Hashable {
    /// The canonical value of the port.
    public let canonicalValue: UInt16

    /// Convenience accessor for the canonical value.
    public var value: Int {
        Int(self.canonicalValue)
    }

    /// Create a new port with the given canonical value.
    public init(canonicalValue: UInt16) {
        self.canonicalValue = canonicalValue
    }

    /// Create a new port with the given value.
    /// Precondition: the value must be inclusively between 0 and 65535.
    public init(_ value: Int) {
        guard let canonicalValue = UInt16(exactly: value) else {
            preconditionFailure("Port must be inclusively between 0 and 65535")
        }
        self.canonicalValue = canonicalValue
    }
}

extension Port: ExpressibleByIntegerLiteral {
    /// Create a new port with the given canonical value.
    public init(integerLiteral value: UInt16) {
        self.init(canonicalValue: value)
    }
}
