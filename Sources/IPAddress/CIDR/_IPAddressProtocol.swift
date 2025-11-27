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
    CustomStringConvertible,
    CustomDebugStringConvertible
{
    associatedtype AddressValueType: _IPAddressProtocolAddressValueType

    var address: AddressValueType { get }

    init(_ value: AddressValueType)

    @available(swiftEndpointApplePlatforms 10.15, *)
    init?(exactly ipAddress: AnyIPAddress)

    @available(swiftEndpointApplePlatforms 10.15, *)
    init?(_uncheckedAssumingValidASCII: Span<UInt8>)
}

public protocol _IPAddressProtocolAddressValueType:
    Sendable,
    Hashable,
    Comparable,
    BitwiseCopyable
{
    static var zero: Self { get }
    static var bitWidth: Int { get }
    static var max: Self { get }
    var trailingZeroBitCount: Int { get }

    static func &>> (lhs: Self, rhs: Self) -> Self
    static func &>> (lhs: Self, rhs: some BinaryInteger) -> Self

    static func &<< (lhs: Self, rhs: Self) -> Self
    static func &<< (lhs: Self, rhs: some BinaryInteger) -> Self

    static func & (lhs: Self, rhs: Self) -> Self
    static prefix func ~ (x: Self) -> Self
}
