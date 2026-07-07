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
#error("The IPv4AddressSerializing benchmarks module was unable to identify your C library.")
#endif

let ipv4AddressToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_Serializing_Zero

    let ipv4Zero = IPv4Address(0, 0, 0, 0)
    Benchmark(
        "IPv4_Serializing_Zero_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4Zero.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_Serializing_Localhost

    let ipv4Localhost = IPv4Address(127, 0, 0, 1)
    Benchmark(
        "IPv4_Serializing_Localhost_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4Localhost.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_Serializing_Local_Broadcast

    let ipv4LocalBroadcast = IPv4Address(255, 255, 255, 255)
    Benchmark(
        "IPv4_Serializing_Local_Broadcast_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4LocalBroadcast.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_Serializing_Mixed

    let ipv4Mixed = IPv4Address(123, 45, 6, 0)
    Benchmark(
        "IPv4_Serializing_Mixed_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4Mixed.description
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_Serializing_Mixed_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let description = ipv4Mixed.description
        blackHole(description)
    }

    Benchmark(
        "IPv4_Serializing_Mixed_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let description = ipv4Mixed.description
        blackHole(description)
    }

    // MARK: IPv4_Serializing_Mixed_inet_ntop

    var ipv4MixedInetNtop = ipv4Mixed.address.bigEndian

    Benchmark(
        "IPv4_Serializing_Mixed_inet_ntop_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 16) { ptr in
                unsafe inet_ntop(
                    AF_INET,
                    &ipv4MixedInetNtop,
                    ptr.baseAddress.unsafelyUnwrapped,
                    16
                )
                unsafe blackHole(ptr)
            }
        }
    }

    Benchmark(
        "IPv4_Serializing_Mixed_inet_ntop_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 16) { ptr in
            unsafe inet_ntop(
                AF_INET,
                &ipv4MixedInetNtop,
                ptr.baseAddress.unsafelyUnwrapped,
                16
            )
            unsafe blackHole(ptr)
        }
    }

    Benchmark(
        "IPv4_Serializing_Mixed_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 16) { ptr in
            unsafe inet_ntop(
                AF_INET,
                &ipv4MixedInetNtop,
                ptr.baseAddress.unsafelyUnwrapped,
                16
            )
            unsafe blackHole(ptr)
        }
    }

    // MARK: - IPv4_Serializing_Multiple_IPs

    let ipv4MultipleIPs = [
        IPv4Address(127, 0, 0, 1),
        IPv4Address(1, 1, 1, 1),
        IPv4Address(8, 8, 8, 8),
        IPv4Address(9, 9, 9, 9),
        IPv4Address(255, 255, 255, 255),
        IPv4Address(192, 168, 1, 1),
        IPv4Address(10, 0, 0, 1),
        IPv4Address(172, 16, 0, 1),
        IPv4Address(100, 64, 0, 1),
        IPv4Address(208, 67, 222, 222),
        IPv4Address(185, 199, 108, 153),
        IPv4Address(151, 101, 1, 140),
        IPv4Address(104, 16, 132, 229),
        IPv4Address(142, 250, 185, 78),
        IPv4Address(13, 107, 42, 14),
        IPv4Address(23, 185, 0, 2),
    ]

    Benchmark(
        "IPv4_Serializing_Multiple_IPs_8M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<8_000_000 {
            let idx = Int(rng.next() % 16)
            let description = ipv4MultipleIPs[idx].description
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_Serializing_Multiple_IPs_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for ip in ipv4MultipleIPs {
            let description = ip.description
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_Serializing_Multiple_IPs_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for ip in ipv4MultipleIPs {
            let description = ip.description
            blackHole(description)
        }
    }

    // MARK: IPv4_Serializing_Multiple_IPs_inet_ntop

    var ipv4MultipleIPsInetNtop = ipv4MultipleIPs.map(\.address.bigEndian)

    Benchmark(
        "IPv4_Serializing_Multiple_IPs_inet_ntop_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<1_000_000 {
            let idx = Int(rng.next() % 16)
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 16) { ptr in
                unsafe inet_ntop(
                    AF_INET,
                    &ipv4MultipleIPsInetNtop[idx],
                    ptr.baseAddress.unsafelyUnwrapped,
                    16
                )
                unsafe blackHole(ptr)
            }
        }
    }

    Benchmark(
        "IPv4_Serializing_Multiple_IPs_inet_ntop_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in 0..<16 {
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 16) { ptr in
                unsafe inet_ntop(
                    AF_INET,
                    &ipv4MultipleIPsInetNtop[idx],
                    ptr.baseAddress.unsafelyUnwrapped,
                    16
                )
                unsafe blackHole(ptr)
            }
        }
    }

    Benchmark(
        "IPv4_Serializing_Multiple_IPs_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in 0..<16 {
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 16) { ptr in
                unsafe inet_ntop(
                    AF_INET,
                    &ipv4MultipleIPsInetNtop[idx],
                    ptr.baseAddress.unsafelyUnwrapped,
                    16
                )
                unsafe blackHole(ptr)
            }
        }
    }
}
