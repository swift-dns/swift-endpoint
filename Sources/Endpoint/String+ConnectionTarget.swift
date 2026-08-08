@available(SwiftStdlib 5.1, *)
extension ConnectionTarget {
    public var description: String {
        self.target.description
    }
}

@available(SwiftStdlib 5.1, *)
extension ConnectionTarget.Target: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ipAddress(let ipAddress, let port):
            /// An IPv6 address followed by a port number SHOULD be bracketed, so the port's `:` is
            /// not mistaken for one of the address's own, as per
            /// [RFC 5952, Section 6](https://datatracker.ietf.org/doc/html/rfc5952#section-6).
            let options = IPv6Address.DescriptionOptions.standardOptions
                .union(.encloseInSquareBrackets)
            return "\(ipAddress.description(ipv6Options: options)):\(port.value)"
        case .domainName(let domainName, let port):
            return "\(domainName.description):\(port.value)"
        case .unixDomainSocketAddress(let unixDomainSocketAddress):
            return unixDomainSocketAddress
        }
    }
}

@available(SwiftStdlib 5.1, *)
extension ConnectionTarget.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidIPAddressString(let ipString):
            return "Invalid IP address string: \(ipString.debugDescription)"
        case .failedToParseDomainName(let error):
            return "Failed to parse domain name with error: \(String(reflecting: error))"
        }
    }
}
