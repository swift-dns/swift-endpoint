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
#error("The IPv4AddressParsing benchmarks module was unable to identify your C library.")
#endif

let ipv4AddressFromStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_Parsing_Zero

    Benchmark(
        "IPv4_Parsing_Zero_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let ip = unsafe IPv4Address("0.0.0.0").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv4_Parsing_Localhost

    Benchmark(
        "IPv4_Parsing_Localhost_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let ip = unsafe IPv4Address("127.0.0.1").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv4_Parsing_Local_Broadcast

    Benchmark(
        "IPv4_Parsing_Local_Broadcast_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let ip = unsafe IPv4Address("255.255.255.255").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_Parsing_Local_Broadcast_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = unsafe IPv4Address("255.255.255.255").unsafelyUnwrapped
        blackHole(ip)
    }

    Benchmark(
        "IPv4_Parsing_Local_Broadcast_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = unsafe IPv4Address("255.255.255.255").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: IPv4_Parsing_Broadcast_inet_pton

    let cStringBroadcastIP = "255.255.255.255".utf8CString

    Benchmark(
        "IPv4_Parsing_Local_Broadcast_inet_pton_8M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<8_000_000 {
            var ipv4Address = in_addr()
            _ = cStringBroadcastIP.withUnsafeBufferPointer { ptr in
                unsafe inet_pton(AF_INET, ptr.baseAddress.unsafelyUnwrapped, &ipv4Address)
            }
            blackHole(ipv4Address)
        }
    }

    Benchmark(
        "IPv4_Parsing_Local_Broadcast_inet_pton_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var ipv4Address = in_addr()
        _ = cStringBroadcastIP.withUnsafeBufferPointer { ptr in
            unsafe inet_pton(AF_INET, ptr.baseAddress.unsafelyUnwrapped, &ipv4Address)
        }
        blackHole(ipv4Address)
    }

    Benchmark(
        "IPv4_Parsing_Local_Broadcast_inet_pton_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var ipv4Address = in_addr()
        _ = cStringBroadcastIP.withUnsafeBufferPointer { ptr in
            unsafe inet_pton(AF_INET, ptr.baseAddress.unsafelyUnwrapped, &ipv4Address)
        }
        blackHole(ipv4Address)
    }

    // MARK: - IPv4_Parsing_Multiple_IPs

    // [
    //     "127.0.0.1",
    //     "1.1.1.1",
    //     "8.8.8.8",
    //     "9.9.9.9",
    //     "255.255.255.255",
    //     "192.168.1.1",
    //     "10.0.0.1",
    //     "172.16.0.1",
    //     "100.64.0.1",
    //     "208.67.222.222",
    //     "185.199.108.153",
    //     "151.101.1.140",
    //     "104.16.132.229",
    //     "142.250.185.78",
    //     "13.107.42.14",
    //     "23.185.0.2",
    // ]
    let ipv4MultipleIPs: [16 of [UInt8]] = [
        [0x31, 0x32, 0x37, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31],
        [0x31, 0x2E, 0x31, 0x2E, 0x31, 0x2E, 0x31],
        [0x38, 0x2E, 0x38, 0x2E, 0x38, 0x2E, 0x38],
        [0x39, 0x2E, 0x39, 0x2E, 0x39, 0x2E, 0x39],
        [
            0x32, 0x35, 0x35, 0x2E, 0x32, 0x35, 0x35, 0x2E,
            0x32, 0x35, 0x35, 0x2E, 0x32, 0x35, 0x35,
        ],
        [
            0x31, 0x39, 0x32, 0x2E, 0x31, 0x36, 0x38, 0x2E,
            0x31, 0x2E, 0x31,
        ],
        [0x31, 0x30, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31],
        [
            0x31, 0x37, 0x32, 0x2E, 0x31, 0x36, 0x2E, 0x30, 0x2E,
            0x31,
        ],
        [
            0x31, 0x30, 0x30, 0x2E, 0x36, 0x34, 0x2E, 0x30, 0x2E,
            0x31,
        ],
        [
            0x32, 0x30, 0x38, 0x2E, 0x36, 0x37, 0x2E, 0x32, 0x32,
            0x32, 0x2E, 0x32, 0x32, 0x32,
        ],
        [
            0x31, 0x38, 0x35, 0x2E, 0x31, 0x39, 0x39, 0x2E, 0x31,
            0x30, 0x38, 0x2E, 0x31, 0x35, 0x33,
        ],
        [
            0x31, 0x35, 0x31, 0x2E, 0x31, 0x30, 0x31, 0x2E, 0x31,
            0x2E, 0x31, 0x34, 0x30,
        ],
        [
            0x31, 0x30, 0x34, 0x2E, 0x31, 0x36, 0x2E, 0x31, 0x33,
            0x32, 0x2E, 0x32, 0x32, 0x39,
        ],
        [
            0x31, 0x34, 0x32, 0x2E, 0x32, 0x35, 0x30, 0x2E, 0x31,
            0x38, 0x35, 0x2E, 0x37, 0x38,
        ],
        [
            0x31, 0x33, 0x2E, 0x31, 0x30, 0x37, 0x2E, 0x34, 0x32,
            0x2E, 0x31, 0x34,
        ],
        [
            0x32, 0x33, 0x2E, 0x31, 0x38, 0x35, 0x2E, 0x30, 0x2E,
            0x32,
        ],
    ]

    Benchmark(
        "IPv4_Parsing_Multiple_IPs_6M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<6_000_000 {
            let idx = Int(rng.next() % UInt64(ipv4MultipleIPs.count))
            let ip = unsafe IPv4Address(
                textualRepresentation: ipv4MultipleIPs[idx].span
            ).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_Parsing_Multiple_IPs_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv4MultipleIPs.indices {
            let ip = unsafe IPv4Address(
                textualRepresentation: ipv4MultipleIPs[idx].span
            ).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_Parsing_Multiple_IPs_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv4MultipleIPs.indices {
            let ip = unsafe IPv4Address(
                textualRepresentation: ipv4MultipleIPs[idx].span
            ).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: IPv4_Parsing_Multiple_IPs_inet_pton

    /// Same as ipv4MultipleIPs.map(\.utf8CString) but inlined
    let ipv4MultipleIPsInet: [16 of [Int8]] = [
        [0x31, 0x32, 0x37, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31, 0x0],
        [0x31, 0x2E, 0x31, 0x2E, 0x31, 0x2E, 0x31, 0x0],
        [0x38, 0x2E, 0x38, 0x2E, 0x38, 0x2E, 0x38, 0x0],
        [0x39, 0x2E, 0x39, 0x2E, 0x39, 0x2E, 0x39, 0x0],
        [
            0x32, 0x35, 0x35, 0x2E, 0x32, 0x35, 0x35, 0x2E,
            0x32, 0x35, 0x35, 0x2E, 0x32, 0x35, 0x35, 0x0,
        ],
        [
            0x31, 0x39, 0x32, 0x2E, 0x31, 0x36, 0x38, 0x2E,
            0x31, 0x2E, 0x31, 0x0,
        ],
        [0x31, 0x30, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31, 0x0],
        [
            0x31, 0x37, 0x32, 0x2E, 0x31, 0x36, 0x2E, 0x30, 0x2E,
            0x31, 0x0,
        ],
        [
            0x31, 0x30, 0x30, 0x2E, 0x36, 0x34, 0x2E, 0x30, 0x2E,
            0x31, 0x0,
        ],
        [
            0x32, 0x30, 0x38, 0x2E, 0x36, 0x37, 0x2E, 0x32, 0x32,
            0x32, 0x2E, 0x32, 0x32, 0x32, 0x0,
        ],
        [
            0x31, 0x38, 0x35, 0x2E, 0x31, 0x39, 0x39, 0x2E, 0x31,
            0x30, 0x38, 0x2E, 0x31, 0x35, 0x33, 0x0,
        ],
        [
            0x31, 0x35, 0x31, 0x2E, 0x31, 0x30, 0x31, 0x2E, 0x31,
            0x2E, 0x31, 0x34, 0x30, 0x0,
        ],
        [
            0x31, 0x30, 0x34, 0x2E, 0x31, 0x36, 0x2E, 0x31, 0x33,
            0x32, 0x2E, 0x32, 0x32, 0x39, 0x0,
        ],
        [
            0x31, 0x34, 0x32, 0x2E, 0x32, 0x35, 0x30, 0x2E, 0x31,
            0x38, 0x35, 0x2E, 0x37, 0x38, 0x0,
        ],
        [
            0x31, 0x33, 0x2E, 0x31, 0x30, 0x37, 0x2E, 0x34, 0x32,
            0x2E, 0x31, 0x34, 0x0,
        ],
        [
            0x32, 0x33, 0x2E, 0x31, 0x38, 0x35, 0x2E, 0x30, 0x2E,
            0x32, 0x0,
        ],
    ]

    Benchmark(
        "IPv4_Parsing_Multiple_IPs_inet_pton_6M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<6_000_000 {
            var ipv4Address = in_addr()
            let idx = Int(rng.next() % UInt64(ipv4MultipleIPs.count))
            _ = ipv4MultipleIPsInet[idx].withUnsafeBufferPointer { ptr in
                unsafe inet_pton(AF_INET, ptr.baseAddress.unsafelyUnwrapped, &ipv4Address)
            }
            blackHole(ipv4Address)
        }
    }

    Benchmark(
        "IPv4_Parsing_Multiple_IPs_inet_pton_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv4MultipleIPs.indices {
            var ipv4Address = in_addr()
            _ = ipv4MultipleIPsInet[idx].withUnsafeBufferPointer { ptr in
                unsafe inet_pton(AF_INET, ptr.baseAddress.unsafelyUnwrapped, &ipv4Address)
            }
            blackHole(ipv4Address)
        }
    }

    Benchmark(
        "IPv4_Parsing_Multiple_IPs_inet_pton_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv4MultipleIPs.indices {
            var ipv4Address = in_addr()
            _ = ipv4MultipleIPsInet[idx].withUnsafeBufferPointer { ptr in
                unsafe inet_pton(AF_INET, ptr.baseAddress.unsafelyUnwrapped, &ipv4Address)
            }
            blackHole(ipv4Address)
        }
    }
}
