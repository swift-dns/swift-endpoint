<p>
    <a href="https://github.com/swift-dns/swift-endpoint/actions/workflows/unit-tests.yml">
        <img
            src="https://img.shields.io/github/actions/workflow/status/swift-dns/swift-endpoint/unit-tests.yml?event=push&style=plastic&logo=github&label=unit-tests&logoColor=%23ccc"
            alt="Unit Tests CI"
        >
    </a>
    <a href="https://github.com/swift-dns/swift-endpoint/actions/workflows/benchmarks.yml">
        <img
            src="https://img.shields.io/github/actions/workflow/status/swift-dns/swift-endpoint/benchmarks.yml?event=push&style=plastic&logo=github&label=benchmarks&logoColor=%23ccc"
            alt="Benchamrks CI"
        >
    </a>
    <a href="https://swift.org">
        <img
            src="https://design.vapor.codes/images/swift62up.svg"
            alt="Swift 6.2+"
        >
    </a>
</p>

# swift-endpoint

swift-endpoint is a high-performance package containing types representing an endpoint.

The package contains a great amount of unit tests as well as benchmarks to ensure correctness and high performance.

## Implementations

- `DomainName`
  - With IDNA support for non-ASCII domain names. 
- `IPv4Address`, `IPv6Address`, `AnyIPAddress`
- `CIDR`

## Usage

swift-endpoint provides highly optimized implementations for converting its types to and from an String.
You can either initialize each types using an String, or initialize the exact underlying type they contain.

```swift
import Endpoint

/// Create a domain name. The type will parse the domain name and store it in DNS wire-format internally.
let domainName1 = try DomainName(string: "mahdibm.com")
print(domainName1) /// prints "mahdibm.com"

/// Create a non-ASCII domain. 
let domainName2 = try DomainName(string: "新华网.中国")
print(domainName2) /// prints "新华网.中国"
print(domainName2.debugDescription) /// prints "xn--xkrr14bows.xn--fiqs8s"

/// Create an ipv4 address. The type will parse the ip address into a UInt32 internally.
let ipv4Address1 = IPv4Address("127.0.0.1")!
let ipv4Address2 = IPv4Address(192, 168, 1, 1)!
print(ipv4Address1) /// prints "127.0.0.1"
print(ipv4Address2) /// prints "192.168.1.1"

/// Create an ipv6 address. The type will parse the ip address into a UInt128 internally.
let ipv6Address1 = IPv6Address("[FF::]")!
let ipv6Address2 = IPv6Address("2001:db8:85a3:0:0:0:0:100")!
let ipv6Address3 = IPv6Address("::FFFF:204.152.189.116")!
/// Prints the ipv6 representations according to RFC 5952
print(ipv6Address1) /// prints "[ff::]"
print(ipv6Address2) /// prints "[2001:db8:85a3::100]"
print(ipv6Address3) /// prints "[::ffff:cc98:bd74]"

let anyIPv4Address = AnyIPAddress("192.168.1.1")
let anyIPv6Address = AnyIPAddress("[2001:DB8:85A3::100]")
print(anyIPv4Address) /// prints "v4(192.168.1.1)"
print(anyIPv6Address) /// prints "v6([2001:db8:85a3::100])"

let cidr1 = CIDR(prefix: ipv4Address1, countOfMaskedBits: 8)
let cidr2 = CIDR<IPv4Address>("127.0.0.1/8")!
let containmentCheck = cidr1.contains(ipv4Address2)
print(cidr1) /// prints "127.0.0.1/8"
print(cidr2) /// prints "127.0.0.1/8"
print(containmentCheck) /// prints "false"
```

## Performance

TODO

