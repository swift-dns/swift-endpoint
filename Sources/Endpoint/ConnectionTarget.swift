public import SwiftIDNA

/// A target for a connection.
@available(swiftEndpointApplePlatforms 10.15, *)
public struct ConnectionTarget: Sendable, Hashable {
    @nonexhaustive
    public enum Error: Swift.Error {
        case invalidIPAddressString(String)
        case failedToParseDomainName(any Swift.Error)
    }

    /// The target of a connection.
    @nonexhaustive
    public enum Target: Sendable, Hashable {
        case ipAddress(AnyIPAddress, port: Port)
        case domainName(DomainName, port: Port)
        case unixDomainSocketAddress(String)
    }

    public private(set) var target: Target

    private init(target: Target) {
        self.target = target
    }

    /// Create a ``ConnectionTarget`` from an IP address string and the port number.
    public static func ipAddress(
        _ ipAddress: String,
        port: Port
    ) throws(ConnectionTarget.Error) -> Self {
        guard let ipAddress = AnyIPAddress(ipAddress) else {
            throw Error.invalidIPAddressString(ipAddress)
        }
        return Self(target: .ipAddress(ipAddress, port: port))
    }

    /// Create a ``ConnectionTarget`` from an IP address and the port number.
    public static func ipAddress(_ ipAddress: AnyIPAddress, port: Port) -> Self {
        Self(target: .ipAddress(ipAddress, port: port))
    }

    /// Create a ``ConnectionTarget`` from an IP address and the port number.
    public static func ipAddress(_ ipv4Address: IPv4Address, port: Port) -> Self {
        Self(target: .ipAddress(.v4(ipv4Address), port: port))
    }

    /// Create a ``ConnectionTarget`` from an IP address and the port number.
    public static func ipAddress(_ ipv6Address: IPv6Address, port: Port) -> Self {
        Self(target: .ipAddress(.v6(ipv6Address), port: port))
    }

    /// Create a ``ConnectionTarget`` from a domain name string and the port number.
    public static func domainName(
        _ domainName: String,
        port: Port,
        idnaConfiguration: IDNA.Configuration = .default
    ) throws -> Self {
        do {
            let domainName = try DomainName(domainName, idnaConfiguration: idnaConfiguration)
            return .domainName(domainName, port: port)
        } catch {
            throw Error.failedToParseDomainName(error)
        }
    }

    /// Create a ``ConnectionTarget`` from a domain name and the port number.
    public static func domainName(_ domainName: DomainName, port: Port) -> Self {
        if let ip = AnyIPAddress(domainName: domainName) {
            return Self.ipAddress(ip, port: port)
        } else {
            return Self(target: .domainName(domainName, port: port))
        }
    }

    /// Create a ``ConnectionTarget`` from a unix domain socket address.
    public static func unixDomainSocketAddress(_ unixDomainSocketAddress: String) -> Self {
        Self(target: .unixDomainSocketAddress(unixDomainSocketAddress))
    }
}
