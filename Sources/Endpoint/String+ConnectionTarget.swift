@available(swiftEndpointApplePlatforms 13, *)
extension ConnectionTarget {
    public var description: String {
        self.target.description
    }
}

@available(swiftEndpointApplePlatforms 13, *)
extension ConnectionTarget.Target: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ipAddress(let ipAddress, let port):
            return "\(ipAddress.description):\(port)"
        case .domainName(let domainName, let port):
            return "\(domainName.description):\(port)"
        case .unixDomainSocketAddress(let unixDomainSocketAddress):
            return unixDomainSocketAddress
        }
    }
}

@available(swiftEndpointApplePlatforms 13, *)
extension ConnectionTarget.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidIPAddressString(let ipAddress):
            return "Invalid IP address string: \(ipAddress.debugDescription)"
        case .failedToParseDomainName(let domainName):
            return "Failed to parse domain name with error: \(String(reflecting: domainName))"
        }
    }
}
