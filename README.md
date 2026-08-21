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
            alt="Benchmarks CI"
        >
    </a>
    <a href="https://codecov.io/gh/swift-dns/swift-endpoint">
        <img
            src="https://codecov.io/gh/swift-dns/swift-endpoint/graph/badge.svg?token=KW7Y46RYYD"
            alt="Codecov Tests Code Coverage"
        >
    </a>
    <a href="https://swift.org">
        <img
            src="https://design.vapor.codes/images/swift63up.svg"
            alt="Swift 6.3+"
        >
    </a>
</p>

# swift-endpoint

swift-endpoint is a high-performance package containing types representing an endpoint and related utilities.

The package contains a great amount of unit tests as well as benchmarks to ensure correctness and high performance.

## Table of Contents

- [Implementations](#implementations)
- [Usage](#usage)
- [Type Conversions](#type-conversions)
- [Performance](#performance)
  - [Against Darwin](#against-darwin)
  - [Against glibc](#against-glibc)
  - [Additional Notes](#additional-notes)

## Implementations

- [x] `ConnectionTarget`
  - Representing a network-layer endpoint such as an ip address + port, a domain name + port, or a socket address.
- [x] `DomainName`
  - [x] Unicode-17-compliant IDNA support for non-ASCII domain names.
- [x] `IPv4Address`, `IPv6Address`, `AnyIPAddress`
- [x] `CIDR`
- [x] `Port`
- [ ] `UnixDomainSocketAddress`

## Usage

swift-endpoint provides highly optimized implementations for converting its types to and from an String.

You can either initialize each type using a `String`, or initialize the exact underlying type they contain.

Here are some examples:

```swift
import Endpoint

/// Define a domain name. The type will parse the domain name and store it in DNS wire-format internally.
let domainName1 = try DomainName("mahdibm.com")
print(domainName1) /// prints "mahdibm.com"

/// Define a non-ASCII domain.
let domainName2 = try DomainName("新华网.中国")
print(domainName2) /// prints "新华网.中国"
print(domainName2.debugDescription) /// prints "xn--xkrr14bows.xn--fiqs8s"

/// Define an ipv4 address. The type will parse the ip address into a UInt32 internally.
let ipv4Address1 = IPv4Address("127.0.0.1")!
let ipv4Address2 = IPv4Address(192, 168, 1, 1)
print(ipv4Address1) /// prints "127.0.0.1"
print(ipv4Address2) /// prints "192.168.1.1"

/// Define an ipv6 address. The type will parse the ip address into a UInt128 internally.
let ipv6Address1 = IPv6Address("[FF::]")!
let ipv6Address2 = IPv6Address("2001:db8:85a3:0:0:0:0:100")!
/// Prints the ipv6 representations according to RFC 5952
print(ipv6Address1) /// prints "ff::"
print(ipv6Address2) /// prints "2001:db8:85a3::100"

/// Define IPv4-embedded IPv6 addresses via the mixed IPv4-embedded notation.
/// An IPv4-mapped IPv6 address (RFC 4291).
let ipv4InIPv6Address1 = IPv6Address("::FFFF:192.168.1.1")!
/// NAT64 well-known IPv4-Embedded addresses (RFC 6052).
let ipv4InIPv6Address2 = IPv6Address("[64:ff9b:0:0:0:0:c000:221]")!
/// Any other non-well-known IPv4-embedded IPv6 address containing an IPv4 in the trailing 32 bits.
let ipv4InIPv6Address3 = IPv6Address("[2001:db8:122:344::192.0.2.33]")!
print(ipv4InIPv6Address1) /// prints "::ffff:192.168.1.1"
print(ipv4InIPv6Address2) /// prints "64:ff9b::192.0.2.33"
print(ipv4InIPv6Address3) /// prints "2001:db8:122:344::c000:221", Not well-known so no mixed notation

/// Define an any-ip-address. The type will automatically parse the ip address into the correct type.
let anyIPv4Address = AnyIPAddress("192.168.1.1")
let anyIPv6Address = AnyIPAddress("[2001:DB8:85A3::100]")
print(anyIPv4Address) /// prints "192.168.1.1"
print(anyIPv6Address) /// prints "2001:db8:85a3::100"

/// Define a domain name containing an ip v4 address.
let domainName3 = try DomainName(ipv4: ipv4Address2)
print(domainName3) /// prints "192.168.1.1"

/// Define a CIDR. The type will store a `prefix` and a `mask`, representing this block of ips.
let cidr1 = CIDR(prefix: ipv4Address1, prefixLength: 8) /// ipv4Address1 == "127.0.0.1"
let cidr2 = CIDR<IPv4Address>("192.168.1.1")!
let containmentCheck1 = cidr1.contains(ipv4Address2) /// ipv4Address2 == "192.168.1.1"
let containmentCheck2 = cidr2.contains(ipv4Address2) /// ipv4Address2 == "192.168.1.1"
print(cidr1) /// prints "127.0.0.1/8"
print(cidr2) /// prints "192.168.1.1/32"
print(containmentCheck1) /// prints "false"
print(containmentCheck2) /// prints "true"
```

## Type Conversions

All types are convertible to each other in a performant way. Some examples:

```swift
import Endpoint

let simpleIpv4InDomainName = try DomainName("1.2.3.4")

let fastIPv4 = IPv4Address(domainName: simpleIpv4InDomainName)! /// ✅ Converts the domain into the equivalent ipv4 address
let slowIPv4 = IPv4Address(simpleIpv4InDomainName.description)! /// ❌ This does work, but has worse performance

let fastIPv4Conversion = DomainName(ipv4: fastIPv4) /// ✅ Converts the ipv4 into the equivalent domain name
let slowIPv4Conversion = try DomainName(fastIPv4.description) /// ❌ This does work, but has worse performance

print(fastIPv4Conversion) /// prints "4.3.2.1.in-addr.arpa."

let anyIPAddress = AnyIPAddress(domainName: simpleIpv4InDomainName)
print(anyIPAddress)/// prints "1.2.3.4"
```

For `IPv4Address`, the `DomainName` conversions are possible to/from:

- Dotted-quad notation, for example: "1.2.3.4"
- Arpa domain name format, for example: "4.3.2.1.in-addr.arpa."

For `IPv6Address`, the Arpa domain name format is supported. For example the followings are equivalent:

- `IPv6Address`: 4321::1:2:3:4:567:89ab
- `DomainName`: "b.a.9.8.7.6.5.0.4.0.0.0.3.0.0.0.2.0.0.0.1.0.0.0.0.0.0.0.1.2.3.4.ip6.arpa."

## Performance

* Below are benchmarks of this library against inet C-library APIs of macOS's Darwin and Linux's glibc.
* **In all cases, swift-endpoint wins against the inet C APIs.**
* These benchmarks are meant to represent real-world workloads.
* The C API benchmarks represent a C language user's experience.
  * Meaning They don't contain any possible overhead coming from interfacing with other Swift APIs.
* The benchmarks write into stack-allocated space if/where needed, to avoid malloc and show their full potential.
  * swift-endpoint would win by good margins anyway even if it used malloc and C APIs continued to use alloca.
* Each benchmark runs against 32 different IPs, one by one and in a random manner.
  * There is a constant seed to keep the benchmarks consistent across benchmark runs.
  * This means CPUs won't find a clear pattern to over-optimize for in any of the operations, which would make the benchmarks less realistic.
  * The randomization itself only adds minimal runtime (~0.3ns = 1 cycle) to the benchmarks and is not subtracted.
  * All addresses are operational real-world addresses, not documentation examples or such.
  * Different addresses test different branches of a possibly branchy parsing/serialization implementation.
  * 2 of the IPv6 IPs are IPv4-embedded, 1 of which is an IPv4-mapped IPv6 address.
    * IPv4-mapped addresses have a mixed-notation representation, per RFC 5952.

#### Against Darwin

These were performed on my M1 Pro MacBook, on macOS 27.

| IP Type | Operation   | Swift (ns/op) | inet (ns/op) | Speedup |
| ------- | ----------- | ------------- | ------------ | ------- |
| IPv4    | Serializing | 6.0           | 179.0        | 29.83x  |
| IPv4    | Parsing     | 15.1          | 46.8         | 3.10x   |
| IPv6    | Serializing | 29.3          | 221.0        | 7.56x   |
| IPv6    | Parsing     | 25.0          | 99.7         | 3.99x   |

#### Against glibc

These were performed on a dedicated-cpu-core AMD EPYC-Milan machine from Hetzner, on Ubuntu 24.04.

| IP Type | Operation   | Swift (ns/op) | inet (ns/op) | Speedup |
| ------- | ----------- | ------------- | ------------ | ------- |
| IPv4    | Serializing | 7.0           | 116.0        | 16.57x  |
| IPv4    | Parsing     | 16.7          | 27.2         | 1.63x   |
| IPv6    | Serializing | 36.3          | 166.0        | 4.58x   |
| IPv6    | Parsing     | 33.2          | 48.0         | 1.45x   |

#### Additional Notes

* To see up to date information about performance of this package, please go to this [benchmarks list](https://github.com/swift-dns/swift-endpoint/actions/workflows/benchmarks.yml?query=branch%3Amain), and choose the most recent benchmark. You'll see a summary of the benchmark there.
* The results above are all reproducible by simply running `scripts/benchmark.sh` on a machine of your own.
