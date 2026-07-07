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

Below are benchmarks of this library against inet C-library APIs of macOS's Darwin and Linux's glibc.

These benchmarks are meant to represent a slow-case scenario of real-world workloads.
Each benchmark runs against 16 different IPs one by one in a random manner, via a constant seed to keep the benchmarks consistent across benchmark runs.
This means the CPUs can't find a clear pattern and over-optimize any of the operations, which make the benchmarks less realistic.

#### Against Darwin

These were performed on my M1 Pro MacBook, on macOS 27.

##### Average CPU User Time

| IP Type | Operation   | Swift (ns/op) | inet_pton/ntop (ns/op) | Speedup |
| ------- | ----------- | ------------- | ---------------------- | ------- |
| IPv4    | Serializing | 14.6          | 241.0                  | 16.51x  |
| IPv4    | Parsing     | 18.7          | 46.3                   | 2.48x   |
| IPv6    | Serializing | 82.7          | 355.0                  | 4.29x   |
| IPv6    | Parsing     | 33.5          | 98.0                   | 2.93x   |

##### Average Instructions Executed

| IP Type | Operation   | Swift (instr/op) | inet_pton/ntop (instr/op) | Speedup |
| ------- | ----------- | ---------------- | ------------------------- | ------- |
| IPv4    | Serializing | 298.4            | 3000.0                    | 10.05x  |
| IPv4    | Parsing     | 196.8            | 687.5                     | 3.49x   |
| IPv6    | Serializing | 1375.0           | 4500.0                    | 3.27x   |
| IPv6    | Parsing     | 493.4            | 1625.0                    | 3.29x   |

> On Darwin the tooling reports instruction counts of 10,000 or more rounded to the nearest thousand, so the `inet_pton/ntop` cells (and IPv6 serializing Swift) are approximate.

#### Against glibc

These were performed on a dedicated-cpu-core machine from Hetzner in the Falkenstein region.

> Host with 2 'x86_64' processors with 7 GB memory, running: #85-Ubuntu SMP PREEMPT_DYNAMIC

##### Average CPU User Time

| IP Type | Operation   | Swift (ns/op) | inet_pton/ntop (ns/op) | Speedup |
| ------- | ----------- | ------------- | ---------------------- | ------- |
| IPv4    | Serializing | 20.0          | 130.0                  | 6.50x   |
| IPv4    | Parsing     | 28.3          | 26.7                   | 0.94x   |
| IPv6    | Serializing | 63.3          | 200.0                  | 3.16x   |
| IPv6    | Parsing     | 42.5          | 46.7                   | 1.10x   |

##### Average Instructions Executed

| IP Type | Operation   | Swift (instr/op) | inet_pton/ntop (instr/op) | Speedup |
| ------- | ----------- | ---------------- | ------------------------- | ------- |
| IPv4    | Serializing | 371.2            | 1895.9                    | 5.11x   |
| IPv4    | Parsing     | 327.1            | 350.6                     | 1.07x   |
| IPv6    | Serializing | 1087.6           | 3310.3                    | 3.04x   |
| IPv6    | Parsing     | 712.1            | 690.4                     | 0.97x   |

#### Allocations

Allocation counts are identical on Darwin and glibc.
The numbers are sum of allocation counts for all the 16 different IPs.

| IP Type | Operation   | Swift (allocs/16ops) | inet_pton/ntop (allocs/16ops) |
| ------- | ----------- | -------------------- | ----------------------------- |
| IPv4    | Serializing | 0                    | 0                             |
| IPv4    | Parsing     | 0                    | 0                             |
| IPv6    | Serializing | 14                   | 12                            |
| IPv6    | Parsing     | 0                    | 0                             |

<details>
  <summary>Why more allocations for IPv6 serialization?</summary>

swift-endpoint is usually 3 times faster in serializing ipv6 addresses, but sometimes it does an allocation where glibc/Darwin won't. Here's why that happens:

* IPv6 serialization, serializes the IPv6 into a `String`.
* `String` has the ability to inline-allocate the characters if there are no more than 15 utf8 bytes.
* In all serialization cases using Swift or C APIs, the benchmarks produce a `String` via asking `String` to allocate `X` amount of bytes required to store the IPv6's text representation.
* The C APIs don't inform you of how many exact bytes they need. They simply expect you to hand them a pointer with enough space.
* As a performance optimization for calling inet APIs, swift-endpoint benchmarks use stack allocations for the for passing that pointer to the C APIs.
* After that, the C API benchmark make a `String` out of the parsed result. At this point, `String` knows exactly how many bytes it needs to allocate on the heap or if it can store the bytes inline.
* swift-endpoint on the other hand doesn't do a stack allocation but in for other parts of the parsing operation, it has to ask for 2 more bytes that the exact amount required to store the IPv6 text representation.
* This is because swift-endpoint uses speculative writes when writing the IPv6 text representation, and needs a few bytes of headroom. Using speculative writes, combined with a few other technique such as SWAR is what makes IPv6 not only fast, but also almost branchless.
* So in cases where IPv6 serialization requires 14 or 15 utf8 bytes, via the C APIs it won't allocate anything on the heap and `String` will store the bytes inline, but via swift-endpoint, it has to ask for 14+2=16 or 15+2=17 bytes so `String` has to allocate on heap for the storage.


</details>

#### Notes

- To see up to date information about performance of this package, please go to this [benchmarks list](https://github.com/swift-dns/swift-endpoint/actions/workflows/benchmarks.yml?query=branch%3Amain), and choose the most recent benchmark. You'll see a summary of the benchmark there.
- The results above are all reproducible by simply running `scripts/benchmark.bash` on a machine of your own.
- All benchmarks on all platforms commit similar allocations.
- 3 of the benchmarks always do `0`, `IPv6_Serializing_Mixed` always does `1`.
