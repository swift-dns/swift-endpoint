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
#error("The IPv4AddressStringDecoding benchmarks module was unable to identify your C library.")
#endif

let ipv4AddressFromStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_String_Decoding_Zero

    Benchmark(
        "IPv4_String_Decoding_Zero_15M",
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

    // MARK: - IPv4_String_Decoding_Localhost

    Benchmark(
        "IPv4_String_Decoding_Localhost_15M",
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

    // MARK: - IPv4_String_Decoding_Local_Broadcast

    Benchmark(
        "IPv4_String_Decoding_Local_Broadcast_15M",
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
        "IPv4_String_Decoding_Local_Broadcast_Malloc",
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
        "IPv4_String_Decoding_Local_Broadcast_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = unsafe IPv4Address("255.255.255.255").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: IPv4_String_Decoding_Broadcast_inet_pton

    Benchmark(
        "IPv4_String_Decoding_Local_Broadcast_inet_pton_8M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<8_000_000 {
            var ipv4Address = in_addr()
            _ = "255.255.255.255".withCString { p in
                unsafe inet_pton(AF_INET, p, &ipv4Address)
            }
            blackHole(ipv4Address)
        }
    }

    Benchmark(
        "IPv4_String_Decoding_Local_Broadcast_inet_pton_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var ipv4Address = in_addr()
        _ = "255.255.255.255".withCString { p in
            unsafe inet_pton(AF_INET, p, &ipv4Address)
        }
        blackHole(ipv4Address)
    }

    Benchmark(
        "IPv4_String_Decoding_Local_Broadcast_inet_pton_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var ipv4Address = in_addr()
        _ = "255.255.255.255".withCString { p in
            unsafe inet_pton(AF_INET, p, &ipv4Address)
        }
        blackHole(ipv4Address)
    }

    // MARK: - IPv4_String_Decoding_Multiple_IPs

    let ipv4MultipleIPs = [
        "127.0.0.1",
        "1.1.1.1",
        "8.8.8.8",
        "9.9.9.9",
        "255.255.255.255",
        "192.168.1.1",
        "10.0.0.1",
        "172.16.0.1",
        "100.64.0.1",
        "208.67.222.222",
        "185.199.108.153",
        "151.101.1.140",
        "104.16.132.229",
        "142.250.185.78",
        "13.107.42.14",
        "23.185.0.2",
    ]

    Benchmark(
        "IPv4_String_Decoding_Multiple_IPs_6M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<6_000_000 {
            let idx = Int(rng.next() % 16)
            let ip = unsafe IPv4Address(ipv4MultipleIPs[idx]).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_String_Decoding_Multiple_IPs_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for ipString in ipv4MultipleIPs {
            let ip = unsafe IPv4Address(ipString).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_String_Decoding_Multiple_IPs_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for ipString in ipv4MultipleIPs {
            let ip = unsafe IPv4Address(ipString).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: IPv4_String_Decoding_Multiple_IPs_inet_pton

    Benchmark(
        "IPv4_String_Decoding_Multiple_IPs_inet_pton_6M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<6_000_000 {
            var ipv4Address = in_addr()
            let idx = Int(rng.next() % 16)
            _ = ipv4MultipleIPs[idx].withCString { p in
                unsafe inet_pton(AF_INET, p, &ipv4Address)
            }
            blackHole(ipv4Address)
        }
    }

    Benchmark(
        "IPv4_String_Decoding_Multiple_IPs_inet_pton_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for ipString in ipv4MultipleIPs {
            var ipv4Address = in_addr()
            _ = ipString.withCString { p in
                unsafe inet_pton(AF_INET, p, &ipv4Address)
            }
            blackHole(ipv4Address)
        }
    }

    Benchmark(
        "IPv4_String_Decoding_Multiple_IPs_inet_pton_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for ipString in ipv4MultipleIPs {
            var ipv4Address = in_addr()
            _ = ipString.withCString { p in
                unsafe inet_pton(AF_INET, p, &ipv4Address)
            }
            blackHole(ipv4Address)
        }
    }
}
