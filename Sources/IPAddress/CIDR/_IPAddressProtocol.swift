/// DO NOT IMPLEMENT THIS PROTOCOL YOURSELF.
/// THIS PROTOCOL IS NOT CONSIDERED PART OF THE PUBLIC API, DENOTED BY THE UNDERSCORED NAME.
///
/// Use `AnyIPAddress`, `IPv4Address` or `IPv6Address` instead.
///
/// This is always either `IPv4Address` or `IPv6Address`.
/// There is no need to assume any other type will be added in the future, as that would
/// require a new IP version to be introduced, in which case it'll take years before that
/// new IP version is adopted, and at that point we'll have released a new major version
/// to support that new IP version.
public protocol _IPAddressProtocol:
    Sendable,
    Hashable,
    CustomStringConvertible
{
    associatedtype _AddressValueType: _IPAddressProtocolAddressValueType

    var _storage: _AddressValueType { get }

    init(_ value: _AddressValueType)

    init(_storage: _AddressValueType)

    @available(SwiftStdlib 5.1, *)
    init?(exactly ipAddress: AnyIPAddress)

    @available(SwiftStdlib 5.1, *)
    init?(textualRepresentation: Span<UInt8>)
}

@available(SwiftStdlib 5.1, *)
extension _IPAddressProtocol {
    /// Whether this address is contiguous, and thus suitable for use as a CIDR mask.
    ///
    /// A contiguous address has n contiguous 1-bits from the most significant bit and all other bits set to 0.
    /// For example `255.255.0.0` is contiguous, but `255.0.255.0` is not.
    ///
    /// Classless Inter-Domain Routing is defined in [IETF RFC 4632].
    ///
    /// [IETF RFC 4632]: https://datatracker.ietf.org/doc/html/rfc4632
    @inlinable
    public var isContiguous: Bool {
        let address = _AddressValueType(bigEndian: self._storage)
        return address == ~(_AddressValueType.max >> (~address).leadingZeroBitCount)
    }
}

/// DO NOT IMPLEMENT THIS PROTOCOL YOURSELF.
/// THIS PROTOCOL IS NOT CONSIDERED PART OF THE PUBLIC API, DENOTED BY THE UNDERSCORED NAME.
public protocol _IPAddressProtocolAddressValueType:
    Sendable,
    Hashable,
    Comparable,
    BitwiseCopyable
{
    static var bitWidth: Int { get }
    static var max: Self { get }
    var trailingZeroBitCount: Int { get }
    var leadingZeroBitCount: Int { get }

    init(bigEndian value: Self)

    static func >> (lhs: Self, rhs: Int) -> Self

    static func & (lhs: Self, rhs: Self) -> Self
    static prefix func ~ (x: Self) -> Self
}
