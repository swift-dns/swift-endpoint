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
        "IPv4_Parsing_Zero_25M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<25_000_000 {
            let ip = unsafe IPv4Address("0.0.0.0" as String).unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv4_Parsing_Localhost

    Benchmark(
        "IPv4_Parsing_Localhost_25M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<25_000_000 {
            let ip = unsafe IPv4Address("127.0.0.1" as String).unsafelyUnwrapped
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
            let ip = unsafe IPv4Address("255.255.255.255" as String).unsafelyUnwrapped
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
        let ip = unsafe IPv4Address("255.255.255.255" as String).unsafelyUnwrapped
        blackHole(ip)
    }

    Benchmark(
        "IPv4_Parsing_Local_Broadcast_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = unsafe IPv4Address("255.255.255.255" as String).unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: IPv4_Parsing_Broadcast_inet_pton

    let cStringBroadcastIP = "255.255.255.255".utf8CString

    Benchmark(
        "IPv4_Parsing_Local_Broadcast_inet_pton_6M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<6_000_000 {
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
            warmupIterations: 100,
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
    //     "0.0.0.0",
    //     "224.0.0.1",
    //     "169.254.169.254",
    //     "8.8.4.4",
    //     "1.0.0.1",
    //     "149.112.112.112",
    //     "208.67.220.220",
    //     "172.217.16.142",
    //     "140.82.121.4",
    //     "198.41.0.4",
    //     "192.33.4.12",
    //     "193.0.14.129",
    //     "199.7.83.42",
    //     "93.184.215.14",
    //     "20.190.160.14",
    //     "34.107.221.82",
    // ]
    let ipv4MultipleIPs: [32 of [UInt8]] = [
        [0x31, 0x32, 0x37, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31],
        [0x31, 0x2E, 0x31, 0x2E, 0x31, 0x2E, 0x31],
        [0x38, 0x2E, 0x38, 0x2E, 0x38, 0x2E, 0x38],
        [0x39, 0x2E, 0x39, 0x2E, 0x39, 0x2E, 0x39],
        [0x32, 0x35, 0x35, 0x2E, 0x32, 0x35, 0x35, 0x2E, 0x32, 0x35, 0x35, 0x2E, 0x32, 0x35, 0x35],
        [0x31, 0x39, 0x32, 0x2E, 0x31, 0x36, 0x38, 0x2E, 0x31, 0x2E, 0x31],
        [0x31, 0x30, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31],
        [0x31, 0x37, 0x32, 0x2E, 0x31, 0x36, 0x2E, 0x30, 0x2E, 0x31],
        [0x31, 0x30, 0x30, 0x2E, 0x36, 0x34, 0x2E, 0x30, 0x2E, 0x31],
        [0x32, 0x30, 0x38, 0x2E, 0x36, 0x37, 0x2E, 0x32, 0x32, 0x32, 0x2E, 0x32, 0x32, 0x32],
        [0x31, 0x38, 0x35, 0x2E, 0x31, 0x39, 0x39, 0x2E, 0x31, 0x30, 0x38, 0x2E, 0x31, 0x35, 0x33],
        [0x31, 0x35, 0x31, 0x2E, 0x31, 0x30, 0x31, 0x2E, 0x31, 0x2E, 0x31, 0x34, 0x30],
        [0x31, 0x30, 0x34, 0x2E, 0x31, 0x36, 0x2E, 0x31, 0x33, 0x32, 0x2E, 0x32, 0x32, 0x39],
        [0x31, 0x34, 0x32, 0x2E, 0x32, 0x35, 0x30, 0x2E, 0x31, 0x38, 0x35, 0x2E, 0x37, 0x38],
        [0x31, 0x33, 0x2E, 0x31, 0x30, 0x37, 0x2E, 0x34, 0x32, 0x2E, 0x31, 0x34],
        [0x32, 0x33, 0x2E, 0x31, 0x38, 0x35, 0x2E, 0x30, 0x2E, 0x32],
        [0x30, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x30],
        [0x32, 0x32, 0x34, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31],
        [0x31, 0x36, 0x39, 0x2E, 0x32, 0x35, 0x34, 0x2E, 0x31, 0x36, 0x39, 0x2E, 0x32, 0x35, 0x34],
        [0x38, 0x2E, 0x38, 0x2E, 0x34, 0x2E, 0x34],
        [0x31, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31],
        [0x31, 0x34, 0x39, 0x2E, 0x31, 0x31, 0x32, 0x2E, 0x31, 0x31, 0x32, 0x2E, 0x31, 0x31, 0x32],
        [0x32, 0x30, 0x38, 0x2E, 0x36, 0x37, 0x2E, 0x32, 0x32, 0x30, 0x2E, 0x32, 0x32, 0x30],
        [0x31, 0x37, 0x32, 0x2E, 0x32, 0x31, 0x37, 0x2E, 0x31, 0x36, 0x2E, 0x31, 0x34, 0x32],
        [0x31, 0x34, 0x30, 0x2E, 0x38, 0x32, 0x2E, 0x31, 0x32, 0x31, 0x2E, 0x34],
        [0x31, 0x39, 0x38, 0x2E, 0x34, 0x31, 0x2E, 0x30, 0x2E, 0x34],
        [0x31, 0x39, 0x32, 0x2E, 0x33, 0x33, 0x2E, 0x34, 0x2E, 0x31, 0x32],
        [0x31, 0x39, 0x33, 0x2E, 0x30, 0x2E, 0x31, 0x34, 0x2E, 0x31, 0x32, 0x39],
        [0x31, 0x39, 0x39, 0x2E, 0x37, 0x2E, 0x38, 0x33, 0x2E, 0x34, 0x32],
        [0x39, 0x33, 0x2E, 0x31, 0x38, 0x34, 0x2E, 0x32, 0x31, 0x35, 0x2E, 0x31, 0x34],
        [0x32, 0x30, 0x2E, 0x31, 0x39, 0x30, 0x2E, 0x31, 0x36, 0x30, 0x2E, 0x31, 0x34],
        [0x33, 0x34, 0x2E, 0x31, 0x30, 0x37, 0x2E, 0x32, 0x32, 0x31, 0x2E, 0x38, 0x32],
    ]

    Benchmark(
        "IPv4_Parsing_Multiple_IPs_8M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<8_000_000 {
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
            warmupIterations: 100,
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
    let ipv4MultipleIPsInet: [32 of [Int8]] = [
        [0x31, 0x32, 0x37, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31, 0x00],
        [0x31, 0x2E, 0x31, 0x2E, 0x31, 0x2E, 0x31, 0x00],
        [0x38, 0x2E, 0x38, 0x2E, 0x38, 0x2E, 0x38, 0x00],
        [0x39, 0x2E, 0x39, 0x2E, 0x39, 0x2E, 0x39, 0x00],
        [
            0x32, 0x35, 0x35, 0x2E, 0x32, 0x35, 0x35, 0x2E, 0x32,
            0x35, 0x35, 0x2E, 0x32, 0x35, 0x35, 0x00,
        ],
        [0x31, 0x39, 0x32, 0x2E, 0x31, 0x36, 0x38, 0x2E, 0x31, 0x2E, 0x31, 0x00],
        [0x31, 0x30, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31, 0x00],
        [0x31, 0x37, 0x32, 0x2E, 0x31, 0x36, 0x2E, 0x30, 0x2E, 0x31, 0x00],
        [0x31, 0x30, 0x30, 0x2E, 0x36, 0x34, 0x2E, 0x30, 0x2E, 0x31, 0x00],
        [0x32, 0x30, 0x38, 0x2E, 0x36, 0x37, 0x2E, 0x32, 0x32, 0x32, 0x2E, 0x32, 0x32, 0x32, 0x00],
        [
            0x31, 0x38, 0x35, 0x2E, 0x31, 0x39, 0x39, 0x2E, 0x31,
            0x30, 0x38, 0x2E, 0x31, 0x35, 0x33, 0x00,
        ],
        [0x31, 0x35, 0x31, 0x2E, 0x31, 0x30, 0x31, 0x2E, 0x31, 0x2E, 0x31, 0x34, 0x30, 0x00],
        [0x31, 0x30, 0x34, 0x2E, 0x31, 0x36, 0x2E, 0x31, 0x33, 0x32, 0x2E, 0x32, 0x32, 0x39, 0x00],
        [0x31, 0x34, 0x32, 0x2E, 0x32, 0x35, 0x30, 0x2E, 0x31, 0x38, 0x35, 0x2E, 0x37, 0x38, 0x00],
        [0x31, 0x33, 0x2E, 0x31, 0x30, 0x37, 0x2E, 0x34, 0x32, 0x2E, 0x31, 0x34, 0x00],
        [0x32, 0x33, 0x2E, 0x31, 0x38, 0x35, 0x2E, 0x30, 0x2E, 0x32, 0x00],
        [0x30, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x30, 0x00],
        [0x32, 0x32, 0x34, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31, 0x00],
        [
            0x31, 0x36, 0x39, 0x2E, 0x32, 0x35, 0x34, 0x2E, 0x31,
            0x36, 0x39, 0x2E, 0x32, 0x35, 0x34, 0x00,
        ],
        [0x38, 0x2E, 0x38, 0x2E, 0x34, 0x2E, 0x34, 0x00],
        [0x31, 0x2E, 0x30, 0x2E, 0x30, 0x2E, 0x31, 0x00],
        [
            0x31, 0x34, 0x39, 0x2E, 0x31, 0x31, 0x32, 0x2E, 0x31,
            0x31, 0x32, 0x2E, 0x31, 0x31, 0x32, 0x00,
        ],
        [0x32, 0x30, 0x38, 0x2E, 0x36, 0x37, 0x2E, 0x32, 0x32, 0x30, 0x2E, 0x32, 0x32, 0x30, 0x00],
        [0x31, 0x37, 0x32, 0x2E, 0x32, 0x31, 0x37, 0x2E, 0x31, 0x36, 0x2E, 0x31, 0x34, 0x32, 0x00],
        [0x31, 0x34, 0x30, 0x2E, 0x38, 0x32, 0x2E, 0x31, 0x32, 0x31, 0x2E, 0x34, 0x00],
        [0x31, 0x39, 0x38, 0x2E, 0x34, 0x31, 0x2E, 0x30, 0x2E, 0x34, 0x00],
        [0x31, 0x39, 0x32, 0x2E, 0x33, 0x33, 0x2E, 0x34, 0x2E, 0x31, 0x32, 0x00],
        [0x31, 0x39, 0x33, 0x2E, 0x30, 0x2E, 0x31, 0x34, 0x2E, 0x31, 0x32, 0x39, 0x00],
        [0x31, 0x39, 0x39, 0x2E, 0x37, 0x2E, 0x38, 0x33, 0x2E, 0x34, 0x32, 0x00],
        [0x39, 0x33, 0x2E, 0x31, 0x38, 0x34, 0x2E, 0x32, 0x31, 0x35, 0x2E, 0x31, 0x34, 0x00],
        [0x32, 0x30, 0x2E, 0x31, 0x39, 0x30, 0x2E, 0x31, 0x36, 0x30, 0x2E, 0x31, 0x34, 0x00],
        [0x33, 0x34, 0x2E, 0x31, 0x30, 0x37, 0x2E, 0x32, 0x32, 0x31, 0x2E, 0x38, 0x32, 0x00],
    ]

    Benchmark(
        "IPv4_Parsing_Multiple_IPs_inet_pton_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<5_000_000 {
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
            warmupIterations: 100,
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

    // MARK: IPv4_Parsing_Multiple_IPs_StaticString

    /// Every call site here is a `StaticString` literal, so the whole parse is expected to be
    /// folded into a constant at compile time and the only work left is `blackHole`.
    /// The instruction count is the assertion; a `cpuUser` benchmark would measure nothing.
    Benchmark(
        "IPv4_Parsing_Multiple_IPs_StaticString_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        blackHole("127.0.0.1" as IPv4Address)
        blackHole("1.1.1.1" as IPv4Address)
        blackHole("8.8.8.8" as IPv4Address)
        blackHole("9.9.9.9" as IPv4Address)
        blackHole("255.255.255.255" as IPv4Address)
        blackHole("192.168.1.1" as IPv4Address)
        blackHole("10.0.0.1" as IPv4Address)
        blackHole("172.16.0.1" as IPv4Address)
        blackHole("100.64.0.1" as IPv4Address)
        blackHole("208.67.222.222" as IPv4Address)
        blackHole("185.199.108.153" as IPv4Address)
        blackHole("151.101.1.140" as IPv4Address)
        blackHole("104.16.132.229" as IPv4Address)
        blackHole("142.250.185.78" as IPv4Address)
        blackHole("13.107.42.14" as IPv4Address)
        blackHole("23.185.0.2" as IPv4Address)
        blackHole("0.0.0.0" as IPv4Address)
        blackHole("224.0.0.1" as IPv4Address)
        blackHole("169.254.169.254" as IPv4Address)
        blackHole("8.8.4.4" as IPv4Address)
        blackHole("1.0.0.1" as IPv4Address)
        blackHole("149.112.112.112" as IPv4Address)
        blackHole("208.67.220.220" as IPv4Address)
        blackHole("172.217.16.142" as IPv4Address)
        blackHole("140.82.121.4" as IPv4Address)
        blackHole("198.41.0.4" as IPv4Address)
        blackHole("192.33.4.12" as IPv4Address)
        blackHole("193.0.14.129" as IPv4Address)
        blackHole("199.7.83.42" as IPv4Address)
        blackHole("93.184.215.14" as IPv4Address)
        blackHole("20.190.160.14" as IPv4Address)
        blackHole("34.107.221.82" as IPv4Address)
    }

    // MARK: IPv4_Parsing_Multiple_IPs_StaticString_64_IPs

    /// Headroom tripwire. `IPv4Address` folds through the Swift inliner, so past a certain number
    /// of literals in one function the caller-size budget runs out and every site degrades to a
    /// guarded parse. Double the size of the one above, to keep that one clear of the cliff.

    Benchmark(
        "IPv4_Parsing_Multiple_IPs_StaticString_64_IPs_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        blackHole("127.0.0.1" as IPv4Address)
        blackHole("1.1.1.1" as IPv4Address)
        blackHole("8.8.8.8" as IPv4Address)
        blackHole("9.9.9.9" as IPv4Address)
        blackHole("255.255.255.255" as IPv4Address)
        blackHole("192.168.1.1" as IPv4Address)
        blackHole("10.0.0.1" as IPv4Address)
        blackHole("172.16.0.1" as IPv4Address)
        blackHole("100.64.0.1" as IPv4Address)
        blackHole("208.67.222.222" as IPv4Address)
        blackHole("185.199.108.153" as IPv4Address)
        blackHole("151.101.1.140" as IPv4Address)
        blackHole("104.16.132.229" as IPv4Address)
        blackHole("142.250.185.78" as IPv4Address)
        blackHole("13.107.42.14" as IPv4Address)
        blackHole("23.185.0.2" as IPv4Address)
        blackHole("0.0.0.0" as IPv4Address)
        blackHole("224.0.0.1" as IPv4Address)
        blackHole("169.254.169.254" as IPv4Address)
        blackHole("8.8.4.4" as IPv4Address)
        blackHole("1.0.0.1" as IPv4Address)
        blackHole("149.112.112.112" as IPv4Address)
        blackHole("208.67.220.220" as IPv4Address)
        blackHole("172.217.16.142" as IPv4Address)
        blackHole("140.82.121.4" as IPv4Address)
        blackHole("198.41.0.4" as IPv4Address)
        blackHole("192.33.4.12" as IPv4Address)
        blackHole("193.0.14.129" as IPv4Address)
        blackHole("199.7.83.42" as IPv4Address)
        blackHole("93.184.215.14" as IPv4Address)
        blackHole("20.190.160.14" as IPv4Address)
        blackHole("34.107.221.82" as IPv4Address)
        blackHole("1.0.0.3" as IPv4Address)
        blackHole("9.9.9.10" as IPv4Address)
        blackHole("9.9.9.11" as IPv4Address)
        blackHole("76.76.2.0" as IPv4Address)
        blackHole("76.76.10.0" as IPv4Address)
        blackHole("94.140.14.14" as IPv4Address)
        blackHole("94.140.15.15" as IPv4Address)
        blackHole("45.90.28.0" as IPv4Address)
        blackHole("45.90.30.0" as IPv4Address)
        blackHole("156.154.70.1" as IPv4Address)
        blackHole("156.154.71.1" as IPv4Address)
        blackHole("8.26.56.26" as IPv4Address)
        blackHole("8.20.247.20" as IPv4Address)
        blackHole("195.46.39.39" as IPv4Address)
        blackHole("195.46.39.40" as IPv4Address)
        blackHole("77.88.8.8" as IPv4Address)
        blackHole("77.88.8.1" as IPv4Address)
        blackHole("185.228.168.9" as IPv4Address)
        blackHole("185.228.169.9" as IPv4Address)
        blackHole("176.103.130.130" as IPv4Address)
        blackHole("176.103.130.131" as IPv4Address)
        blackHole("216.239.32.10" as IPv4Address)
        blackHole("216.239.34.10" as IPv4Address)
        blackHole("205.251.192.47" as IPv4Address)
        blackHole("199.9.14.201" as IPv4Address)
        blackHole("192.203.230.10" as IPv4Address)
        blackHole("192.5.5.241" as IPv4Address)
        blackHole("192.112.36.4" as IPv4Address)
        blackHole("198.97.190.53" as IPv4Address)
        blackHole("192.36.148.17" as IPv4Address)
        blackHole("192.58.128.30" as IPv4Address)
        blackHole("202.12.27.33" as IPv4Address)
    }

}
