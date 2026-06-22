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
  - [Notes](#notes)

## Implementations

- [x] `ConnectionTarget`
  - Representing a network-layer endpoint such as an ip address + port, a domain name + port, or a socket address.
- [x] `DomainName`
  - [x] Unicode-17-compliant IDNA support for non-ASCII domain names.
- [x] `IPv4Address`, `IPv6Address`, `AnyIPAddress`
- [x] `CIDR`
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
print(ipv6Address1) /// prints "[ff::]"
print(ipv6Address2) /// prints "[2001:db8:85a3::100]"

/// Define an IPv4-mapped IPv6 address (RFC 4291).
let ipv4InIPv6Address1 = IPv6Address("::FFFF:192.168.1.1")!
let ipv4InIPv6Address2 = IPv6Address("[0:0:0:0:0:FFFF:204.152.189.116]")!
print(ipv4InIPv6Address1) /// prints "[::ffff:c0a8:101]"
print(ipv4InIPv6Address2) /// prints "[::ffff:cc98:bd74]"

/// Define an any-ip-address. The type will automatically parse the ip address into the corrext type.
let anyIPv4Address = AnyIPAddress("192.168.1.1")
let anyIPv6Address = AnyIPAddress("[2001:DB8:85A3::100]")
print(anyIPv4Address) /// prints "192.168.1.1"
print(anyIPv6Address) /// prints "[2001:db8:85a3::100]"

/// Define a domain name containing an ip v4 address.
let domainName3 = try DomainName(ipv4: ipv4Address2)
print(domainName3) /// prints "192.168.1.1"

/// Define a CIDR. The type will store a `prefix` and a `mask`, representing this block of ips.
let cidr1 = CIDR(prefix: ipv4Address1, prefixLength: 8) /// ipv4Address1 == "127.0.0.1"
let cidr2 = CIDR<IPv4Address>("192.168.1.1")!
let containmentCheck1 = cidr1.contains(ipv4Address2) /// ipv4Address2 == "192.168.1.1"
let containmentCheck2 = cidr2.contains(ipv4Address2) /// ipv4Address2 == "192.168.1.1"
print(cidr1) /// prints "127.0.0.0/8"
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

In [this post](https://forums.swift.org/t/pitch-standard-network-address-types/82288/11) on the Swift forums I was asked to compare IP parsing implementations with the native C libraries which provide functions such as `inet_ntop` and `inet_pton` which are commonly used by everyone, including swift-nio.

Here's the result ~~at that point in time~~ (Last update: Jun 22, 2026):

In all 8 benchmarks this library performs better than the C libraries when called from Swift.

#### Against Darwin

These were performed on my M1 Pro MacBook, on macOS 27.0 (beta 1).

| Benchmark Name                              | Rounds      | Swift | inet_pton/ntop | Speedup |
| ------------------------------------------- | ----------- | ----- | -------------- | ------- |
| IPv4_String_Encoding_Mixed                  | 15 Millions | 121ms | 3696ms         | 30.55x  |
| IPv4_String_Decoding_Local_Broadcast        | 10 Millions | 273ms | 517ms          | 1.89x   |
| IPv6_String_Encoding_Mixed                  | 4 Millions  | 341ms | 1655ms         | 4.85x   |
| IPv6_String_Decoding_2_Groups_Compressed... | 3 Millions  | 121ms | 396ms          | 3.27x   |

#### Against glibc

These were performed on a dedicated-cpu-core machine from Hetzner in the Falkenstein region.

> Host with 2 'x86_64' processors with 7 GB memory, running: #85-Ubuntu SMP PREEMPT_DYNAMIC

| Benchmark Name                              | Rounds      | Swift | inet_pton/ntop | Speedup |
| ------------------------------------------- | ----------- | ----- | -------------- | ------- |
| IPv4_String_Encoding_Mixed                  | 15 Millions | 130ms | 1520ms         | 11.69x  |
| IPv4_String_Decoding_Local_Broadcast        | 10 Millions | 180ms | 200ms          | 1.11x   |
| IPv6_String_Encoding_Mixed                  | 4 Millions  | 200ms | 820ms          | 4.10x   |
| IPv6_String_Decoding_2_Groups_Compressed... | 3 Millions  | 90ms  | 120ms          | 1.33x   |

#### Notes

- To see up to date information about performance of this package, please go to this [benchmarks list](https://github.com/swift-dns/swift-endpoint/actions/workflows/benchmarks.yml?query=branch%3Amain), and choose the most recent benchmark. You'll see a summary of the benchmark there.
- The results above are all reproducible by simply running `scripts/benchmark.bash` on a machine of your own.
- All benchmarks on all platforms commit similar allocations.
- 3 of the benchmarks always do `0`, `IPv6_String_Encoding_Mixed` always does `1`.
