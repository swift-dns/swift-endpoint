import Benchmark
import IPAddress

#if os(Linux) || os(FreeBSD) || os(Android)

#if canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Android)
@preconcurrency import Android
#endif

#elseif os(Windows)
import ucrt
#elseif canImport(Darwin)
import Darwin
#elseif canImport(WASILibc)
@preconcurrency import WASILibc
#else
#error("The IPv6AddressParsing benchmarks module was unable to identify your C library.")
#endif

let ipv6AddressFromStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv6_Parsing_Uncompressed

    Benchmark(
        "IPv6_Parsing_Uncompressed_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<5_000_000 {
            let ip = unsafe IPv6Address("[2001:0db8:85a3:f109:197a:8a2e:0370:7334]")
                .unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_Parsing_Zero_Compressed

    Benchmark(
        "IPv6_Parsing_Zero_Compressed_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let ip = unsafe IPv6Address("[::]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_Parsing_Zero_Uncompressed

    Benchmark(
        "IPv6_Parsing_Zero_Uncompressed_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<5_000_000 {
            let ip = unsafe IPv6Address("[0000:0000:0000:0000:0000:0000:0000:0000]")
                .unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_Parsing_Localhost_Compressed

    Benchmark(
        "IPv6_Parsing_Localhost_Compressed_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let ip = unsafe IPv6Address("[::1]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_Parsing_2_Groups_Compressed_In_The_Middle_No_Brackets

    Benchmark(
        "IPv6_Parsing_2_Groups_Compressed_In_The_Middle_No_Brackets_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<5_000_000 {
            let ip = unsafe IPv6Address("2001:0db8:85a3::8a2e:0370:7334").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_Parsing_2_Groups_Compressed_In_The_Middle_No_Brackets_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = unsafe IPv6Address("2001:0db8:85a3::8a2e:0370:7334").unsafelyUnwrapped
        blackHole(ip)
    }

    Benchmark(
        "IPv6_Parsing_2_Groups_Compressed_In_The_Middle_No_Brackets_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = unsafe IPv6Address("2001:0db8:85a3::8a2e:0370:7334").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_Parsing_2_Groups_Compressed_At_The_End

    Benchmark(
        "IPv6_Parsing_2_Groups_Compressed_At_The_End_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<5_000_000 {
            let ip = unsafe IPv6Address("[2001:0db8:85a3:8a2e:0370:7334::]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_Parsing_2_Groups_Compressed_At_The_Begining

    Benchmark(
        "IPv6_Parsing_2_Groups_Compressed_At_The_Begining_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<5_000_000 {
            let ip = unsafe IPv6Address("[::2001:0db8:85a3:8a2e:0370:7334]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: IPv6_Parsing_2_Groups_Compressed_In_The_Middle_No_Brackets_inet_pton

    let cString2GroupsCompressedInTheMiddleNoBrackets =
        "2001:0db8:85a3::8a2e:0370:7334".utf8CString

    Benchmark(
        "IPv6_Parsing_2_Groups_Compressed_In_The_Middle_No_Brackets_inet_pton_4M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<4_000_000 {
            var ipv6Address = in6_addr()
            _ = cString2GroupsCompressedInTheMiddleNoBrackets.withUnsafeBufferPointer { ptr in
                unsafe inet_pton(AF_INET6, ptr.baseAddress.unsafelyUnwrapped, &ipv6Address)
            }
            blackHole(ipv6Address)
        }
    }

    Benchmark(
        "IPv6_Parsing_2_Groups_Compressed_In_The_Middle_No_Brackets_inet_pton_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var ipv6Address = in6_addr()
        _ = cString2GroupsCompressedInTheMiddleNoBrackets.withUnsafeBufferPointer { ptr in
            unsafe inet_pton(AF_INET6, ptr.baseAddress.unsafelyUnwrapped, &ipv6Address)
        }
        blackHole(ipv6Address)
    }

    Benchmark(
        "IPv6_Parsing_2_Groups_Compressed_In_The_Middle_No_Brackets_inet_pton_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var ipv6Address = in6_addr()
        _ = cString2GroupsCompressedInTheMiddleNoBrackets.withUnsafeBufferPointer { ptr in
            unsafe inet_pton(AF_INET6, ptr.baseAddress.unsafelyUnwrapped, &ipv6Address)
        }
        blackHole(ipv6Address)
    }

    // MARK: - IPv6_Parsing_Multiple_IPs

    // [
    //     "::1",
    //     "2606:4700:4700::1111",
    //     "2001:4860:4860::8888",
    //     "2620:fe::fe",
    //     "2620:119:35::35",
    //     "2a03:2880:f177:185:face:b00c:0:25de",
    //     "2a00:1450:4001:c15::8a",
    //     "2606:4700::6810:84e5",
    //     "2600:9000:2241:5800:1:5a21:7c40:93a1",
    //     "2001:db8:85a3::8a2e:370:7334",
    //     "64:ff9b::808:808",
    //     "fe80::1ff:fe23:4567:890a",
    //     "ff02::1",
    //     "2001:41d0:302:2200::180",
    //     "2a01:4f8:c010:d56::1",
    //     "2400:cb00:2049:1::a29f:1804",
    // ]
    let ipv6MultipleIPs: [16 of [UInt8]] = [
        [0x3A, 0x3A, 0x31],
        [
            0x32, 0x36, 0x30, 0x36, 0x3A, 0x34, 0x37, 0x30, 0x30,
            0x3A, 0x34, 0x37, 0x30, 0x30, 0x3A, 0x3A, 0x31, 0x31,
            0x31, 0x31,
        ],
        [
            0x32, 0x30, 0x30, 0x31, 0x3A, 0x34, 0x38, 0x36, 0x30,
            0x3A, 0x34, 0x38, 0x36, 0x30, 0x3A, 0x3A, 0x38, 0x38,
            0x38, 0x38,
        ],
        [
            0x32, 0x36, 0x32, 0x30, 0x3A, 0x66, 0x65, 0x3A, 0x3A,
            0x66, 0x65,
        ],
        [
            0x32, 0x36, 0x32, 0x30, 0x3A, 0x31, 0x31, 0x39, 0x3A,
            0x33, 0x35, 0x3A, 0x3A, 0x33, 0x35,
        ],
        [
            0x32, 0x61, 0x30, 0x33, 0x3A, 0x32, 0x38, 0x38, 0x30,
            0x3A, 0x66, 0x31, 0x37, 0x37, 0x3A, 0x31, 0x38, 0x35,
            0x3A, 0x66, 0x61, 0x63, 0x65, 0x3A, 0x62, 0x30, 0x30,
            0x63, 0x3A, 0x30, 0x3A, 0x32, 0x35, 0x64, 0x65,
        ],
        [
            0x32, 0x61, 0x30, 0x30, 0x3A, 0x31, 0x34, 0x35, 0x30,
            0x3A, 0x34, 0x30, 0x30, 0x31, 0x3A, 0x63, 0x31, 0x35,
            0x3A, 0x3A, 0x38, 0x61,
        ],
        [
            0x32, 0x36, 0x30, 0x36, 0x3A, 0x34, 0x37, 0x30, 0x30,
            0x3A, 0x3A, 0x36, 0x38, 0x31, 0x30, 0x3A, 0x38, 0x34,
            0x65, 0x35,
        ],
        [
            0x32, 0x36, 0x30, 0x30, 0x3A, 0x39, 0x30, 0x30, 0x30,
            0x3A, 0x32, 0x32, 0x34, 0x31, 0x3A, 0x35, 0x38, 0x30,
            0x30, 0x3A, 0x31, 0x3A, 0x35, 0x61, 0x32, 0x31, 0x3A,
            0x37, 0x63, 0x34, 0x30, 0x3A, 0x39, 0x33, 0x61, 0x31,
        ],
        [
            0x32, 0x30, 0x30, 0x31, 0x3A, 0x64, 0x62, 0x38, 0x3A,
            0x38, 0x35, 0x61, 0x33, 0x3A, 0x3A, 0x38, 0x61, 0x32,
            0x65, 0x3A, 0x33, 0x37, 0x30, 0x3A, 0x37, 0x33, 0x33,
            0x34,
        ],
        [
            0x36, 0x34, 0x3A, 0x66, 0x66, 0x39, 0x62, 0x3A, 0x3A,
            0x38, 0x30, 0x38, 0x3A, 0x38, 0x30, 0x38,
        ],
        [
            0x66, 0x65, 0x38, 0x30, 0x3A, 0x3A, 0x31, 0x66, 0x66,
            0x3A, 0x66, 0x65, 0x32, 0x33, 0x3A, 0x34, 0x35, 0x36,
            0x37, 0x3A, 0x38, 0x39, 0x30, 0x61,
        ],
        [0x66, 0x66, 0x30, 0x32, 0x3A, 0x3A, 0x31],
        [
            0x32, 0x30, 0x30, 0x31, 0x3A, 0x34, 0x31, 0x64, 0x30,
            0x3A, 0x33, 0x30, 0x32, 0x3A, 0x32, 0x32, 0x30, 0x30,
            0x3A, 0x3A, 0x31, 0x38, 0x30,
        ],
        [
            0x32, 0x61, 0x30, 0x31, 0x3A, 0x34, 0x66, 0x38, 0x3A,
            0x63, 0x30, 0x31, 0x30, 0x3A, 0x64, 0x35, 0x36, 0x3A,
            0x3A, 0x31,
        ],
        [
            0x32, 0x34, 0x30, 0x30, 0x3A, 0x63, 0x62, 0x30, 0x30,
            0x3A, 0x32, 0x30, 0x34, 0x39, 0x3A, 0x31, 0x3A, 0x3A,
            0x61, 0x32, 0x39, 0x66, 0x3A, 0x31, 0x38, 0x30, 0x34,
        ],
    ]

    Benchmark(
        "IPv6_Parsing_Multiple_IPs_4M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<4_000_000 {
            let idx = Int(rng.next() % UInt64(ipv6MultipleIPs.count))
            let ip = unsafe IPv6Address(
                textualRepresentation: ipv6MultipleIPs[idx].span
            ).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_Parsing_Multiple_IPs_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv6MultipleIPs.indices {
            let ip = unsafe IPv6Address(
                textualRepresentation: ipv6MultipleIPs[idx].span
            ).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_Parsing_Multiple_IPs_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv6MultipleIPs.indices {
            let ip = unsafe IPv6Address(
                textualRepresentation: ipv6MultipleIPs[idx].span
            ).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: IPv6_Parsing_Multiple_IPs_inet_pton

    /// Same as ipv6MultipleIPs.map(\.utf8CString) but inlined
    let ipv6MultipleIPsInet: [16 of [Int8]] = [
        [0x3A, 0x3A, 0x31, 0x0],
        [
            0x32, 0x36, 0x30, 0x36, 0x3A, 0x34, 0x37, 0x30, 0x30,
            0x3A, 0x34, 0x37, 0x30, 0x30, 0x3A, 0x3A, 0x31, 0x31,
            0x31, 0x31, 0x0,
        ],
        [
            0x32, 0x30, 0x30, 0x31, 0x3A, 0x34, 0x38, 0x36, 0x30,
            0x3A, 0x34, 0x38, 0x36, 0x30, 0x3A, 0x3A, 0x38, 0x38,
            0x38, 0x38, 0x0,
        ],
        [
            0x32, 0x36, 0x32, 0x30, 0x3A, 0x66, 0x65, 0x3A, 0x3A,
            0x66, 0x65, 0x0,
        ],
        [
            0x32, 0x36, 0x32, 0x30, 0x3A, 0x31, 0x31, 0x39, 0x3A,
            0x33, 0x35, 0x3A, 0x3A, 0x33, 0x35, 0x0,
        ],
        [
            0x32, 0x61, 0x30, 0x33, 0x3A, 0x32, 0x38, 0x38, 0x30,
            0x3A, 0x66, 0x31, 0x37, 0x37, 0x3A, 0x31, 0x38, 0x35,
            0x3A, 0x66, 0x61, 0x63, 0x65, 0x3A, 0x62, 0x30, 0x30,
            0x63, 0x3A, 0x30, 0x3A, 0x32, 0x35, 0x64, 0x65, 0x0,
        ],
        [
            0x32, 0x61, 0x30, 0x30, 0x3A, 0x31, 0x34, 0x35, 0x30,
            0x3A, 0x34, 0x30, 0x30, 0x31, 0x3A, 0x63, 0x31, 0x35,
            0x3A, 0x3A, 0x38, 0x61, 0x0,
        ],
        [
            0x32, 0x36, 0x30, 0x36, 0x3A, 0x34, 0x37, 0x30, 0x30,
            0x3A, 0x3A, 0x36, 0x38, 0x31, 0x30, 0x3A, 0x38, 0x34,
            0x65, 0x35, 0x0,
        ],
        [
            0x32, 0x36, 0x30, 0x30, 0x3A, 0x39, 0x30, 0x30, 0x30,
            0x3A, 0x32, 0x32, 0x34, 0x31, 0x3A, 0x35, 0x38, 0x30,
            0x30, 0x3A, 0x31, 0x3A, 0x35, 0x61, 0x32, 0x31, 0x3A,
            0x37, 0x63, 0x34, 0x30, 0x3A, 0x39, 0x33, 0x61, 0x31, 0x0,
        ],
        [
            0x32, 0x30, 0x30, 0x31, 0x3A, 0x64, 0x62, 0x38, 0x3A,
            0x38, 0x35, 0x61, 0x33, 0x3A, 0x3A, 0x38, 0x61, 0x32,
            0x65, 0x3A, 0x33, 0x37, 0x30, 0x3A, 0x37, 0x33, 0x33,
            0x34, 0x0,
        ],
        [
            0x36, 0x34, 0x3A, 0x66, 0x66, 0x39, 0x62, 0x3A, 0x3A,
            0x38, 0x30, 0x38, 0x3A, 0x38, 0x30, 0x38, 0x0,
        ],
        [
            0x66, 0x65, 0x38, 0x30, 0x3A, 0x3A, 0x31, 0x66, 0x66,
            0x3A, 0x66, 0x65, 0x32, 0x33, 0x3A, 0x34, 0x35, 0x36,
            0x37, 0x3A, 0x38, 0x39, 0x30, 0x61, 0x0,
        ],
        [0x66, 0x66, 0x30, 0x32, 0x3A, 0x3A, 0x31, 0x0],
        [
            0x32, 0x30, 0x30, 0x31, 0x3A, 0x34, 0x31, 0x64, 0x30,
            0x3A, 0x33, 0x30, 0x32, 0x3A, 0x32, 0x32, 0x30, 0x30,
            0x3A, 0x3A, 0x31, 0x38, 0x30, 0x0,
        ],
        [
            0x32, 0x61, 0x30, 0x31, 0x3A, 0x34, 0x66, 0x38, 0x3A,
            0x63, 0x30, 0x31, 0x30, 0x3A, 0x64, 0x35, 0x36, 0x3A,
            0x3A, 0x31, 0x0,
        ],
        [
            0x32, 0x34, 0x30, 0x30, 0x3A, 0x63, 0x62, 0x30, 0x30,
            0x3A, 0x32, 0x30, 0x34, 0x39, 0x3A, 0x31, 0x3A, 0x3A,
            0x61, 0x32, 0x39, 0x66, 0x3A, 0x31, 0x38, 0x30, 0x34, 0x0,
        ],
    ]

    Benchmark(
        "IPv6_Parsing_Multiple_IPs_inet_pton_3M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<3_000_000 {
            var ipv6Address = in6_addr()
            let idx = Int(rng.next() % UInt64(ipv6MultipleIPs.count))
            _ = ipv6MultipleIPsInet[idx].withUnsafeBufferPointer { ptr in
                unsafe inet_pton(AF_INET6, ptr.baseAddress.unsafelyUnwrapped, &ipv6Address)
            }
            blackHole(ipv6Address)
        }
    }

    Benchmark(
        "IPv6_Parsing_Multiple_IPs_inet_pton_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv6MultipleIPs.indices {
            var ipv6Address = in6_addr()
            _ = ipv6MultipleIPsInet[idx].withUnsafeBufferPointer { ptr in
                unsafe inet_pton(AF_INET6, ptr.baseAddress.unsafelyUnwrapped, &ipv6Address)
            }
            blackHole(ipv6Address)
        }
    }

    Benchmark(
        "IPv6_Parsing_Multiple_IPs_inet_pton_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv6MultipleIPs.indices {
            var ipv6Address = in6_addr()
            _ = ipv6MultipleIPsInet[idx].withUnsafeBufferPointer { ptr in
                unsafe inet_pton(AF_INET6, ptr.baseAddress.unsafelyUnwrapped, &ipv6Address)
            }
            blackHole(ipv6Address)
        }
    }
}
