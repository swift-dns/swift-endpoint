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
#error("The PortParsing benchmarks module was unable to identify your C library.")
#endif

let portFromStringBenchmarks: @Sendable () -> Void = {
    // MARK: - Port_Parsing_HTTPS

    Benchmark(
        "Port_Parsing_HTTPS_12M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<12_000_000 {
            let port = unsafe Port("443").unsafelyUnwrapped
            blackHole(port)
        }
    }

    Benchmark(
        "Port_Parsing_HTTPS_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let port = unsafe Port("443").unsafelyUnwrapped
        blackHole(port)
    }

    Benchmark(
        "Port_Parsing_HTTPS_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        let port = unsafe Port("443").unsafelyUnwrapped
        blackHole(port)
    }

    // MARK: - Port_Parsing_Multiple_Ports

    // [
    //     "9", "21", "22", "23", "25", "53", "80", "110",
    //     "123", "143", "179", "389", "443", "514", "587", "853",
    //     "993", "995", "1194", "1433", "2049", "3306", "3389", "5060",
    //     "5353", "5432", "6379", "8080", "8443", "11211", "27017", "33435",
    // ]
    let portMultiplePorts: [32 of [UInt8]] = [
        [0x39],
        [0x32, 0x31],
        [0x32, 0x32],
        [0x32, 0x33],
        [0x32, 0x35],
        [0x35, 0x33],
        [0x38, 0x30],
        [0x31, 0x31, 0x30],
        [0x31, 0x32, 0x33],
        [0x31, 0x34, 0x33],
        [0x31, 0x37, 0x39],
        [0x33, 0x38, 0x39],
        [0x34, 0x34, 0x33],
        [0x35, 0x31, 0x34],
        [0x35, 0x38, 0x37],
        [0x38, 0x35, 0x33],
        [0x39, 0x39, 0x33],
        [0x39, 0x39, 0x35],
        [0x31, 0x31, 0x39, 0x34],
        [0x31, 0x34, 0x33, 0x33],
        [0x32, 0x30, 0x34, 0x39],
        [0x33, 0x33, 0x30, 0x36],
        [0x33, 0x33, 0x38, 0x39],
        [0x35, 0x30, 0x36, 0x30],
        [0x35, 0x33, 0x35, 0x33],
        [0x35, 0x34, 0x33, 0x32],
        [0x36, 0x33, 0x37, 0x39],
        [0x38, 0x30, 0x38, 0x30],
        [0x38, 0x34, 0x34, 0x33],
        [0x31, 0x31, 0x32, 0x31, 0x31],
        [0x32, 0x37, 0x30, 0x31, 0x37],
        [0x33, 0x33, 0x34, 0x33, 0x35],
    ]

    Benchmark(
        "Port_Parsing_Multiple_Ports_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<15_000_000 {
            let idx = Int(rng.next() % UInt64(portMultiplePorts.count))
            let port = unsafe Port(
                textualRepresentation: portMultiplePorts[idx].span
            ).unsafelyUnwrapped
            blackHole(port)
        }
    }

    Benchmark(
        "Port_Parsing_Multiple_Ports_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePorts.indices {
            let port = unsafe Port(
                textualRepresentation: portMultiplePorts[idx].span
            ).unsafelyUnwrapped
            blackHole(port)
        }
    }

    Benchmark(
        "Port_Parsing_Multiple_Ports_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePorts.indices {
            let port = unsafe Port(
                textualRepresentation: portMultiplePorts[idx].span
            ).unsafelyUnwrapped
            blackHole(port)
        }
    }

    // MARK: Port_Parsing_Multiple_Ports_strtoul

    /// Null-terminated so `strtoul` can read them.
    let portMultiplePortsStrtoul: [32 of [CChar]] = [
        [0x39, 0x00],
        [0x32, 0x31, 0x00],
        [0x32, 0x32, 0x00],
        [0x32, 0x33, 0x00],
        [0x32, 0x35, 0x00],
        [0x35, 0x33, 0x00],
        [0x38, 0x30, 0x00],
        [0x31, 0x31, 0x30, 0x00],
        [0x31, 0x32, 0x33, 0x00],
        [0x31, 0x34, 0x33, 0x00],
        [0x31, 0x37, 0x39, 0x00],
        [0x33, 0x38, 0x39, 0x00],
        [0x34, 0x34, 0x33, 0x00],
        [0x35, 0x31, 0x34, 0x00],
        [0x35, 0x38, 0x37, 0x00],
        [0x38, 0x35, 0x33, 0x00],
        [0x39, 0x39, 0x33, 0x00],
        [0x39, 0x39, 0x35, 0x00],
        [0x31, 0x31, 0x39, 0x34, 0x00],
        [0x31, 0x34, 0x33, 0x33, 0x00],
        [0x32, 0x30, 0x34, 0x39, 0x00],
        [0x33, 0x33, 0x30, 0x36, 0x00],
        [0x33, 0x33, 0x38, 0x39, 0x00],
        [0x35, 0x30, 0x36, 0x30, 0x00],
        [0x35, 0x33, 0x35, 0x33, 0x00],
        [0x35, 0x34, 0x33, 0x32, 0x00],
        [0x36, 0x33, 0x37, 0x39, 0x00],
        [0x38, 0x30, 0x38, 0x30, 0x00],
        [0x38, 0x34, 0x34, 0x33, 0x00],
        [0x31, 0x31, 0x32, 0x31, 0x31, 0x00],
        [0x32, 0x37, 0x30, 0x31, 0x37, 0x00],
        [0x33, 0x33, 0x34, 0x33, 0x35, 0x00],
    ]

    Benchmark(
        "Port_Parsing_Multiple_Ports_strtoul_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<10_000_000 {
            let idx = Int(rng.next() % UInt64(portMultiplePortsStrtoul.count))
            let port = portMultiplePortsStrtoul[idx].span.withUnsafeBufferPointer {
                unsafe strtoul($0.baseAddress.unsafelyUnwrapped, nil, 10)
            }
            blackHole(port)
        }
    }

    Benchmark(
        "Port_Parsing_Multiple_Ports_strtoul_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsStrtoul.indices {
            let port = portMultiplePortsStrtoul[idx].span.withUnsafeBufferPointer {
                unsafe strtoul($0.baseAddress.unsafelyUnwrapped, nil, 10)
            }
            blackHole(port)
        }
    }

    Benchmark(
        "Port_Parsing_Multiple_Ports_strtoul_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsStrtoul.indices {
            let port = portMultiplePortsStrtoul[idx].span.withUnsafeBufferPointer {
                unsafe strtoul($0.baseAddress.unsafelyUnwrapped, nil, 10)
            }
            blackHole(port)
        }
    }

    // MARK: Port_Parsing_Multiple_Ports_String

    /// The `String`-consuming counterpart of the span benchmarks above, so it can be compared
    /// against the stdlib's `UInt16(String)` on equal terms.
    let portMultiplePortsString: [32 of String] = [
        "9", "21", "22", "23", "25", "53", "80", "110",
        "123", "143", "179", "389", "443", "514", "587", "853",
        "993", "995", "1194", "1433", "2049", "3306", "3389", "5060",
        "5353", "5432", "6379", "8080", "8443", "11211", "27017", "33435",
    ]

    Benchmark(
        "Port_Parsing_Multiple_Ports_String_7M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<7_000_000 {
            let idx = Int(rng.next() % UInt64(portMultiplePortsString.count))
            let port = unsafe Port(portMultiplePortsString[idx]).unsafelyUnwrapped
            blackHole(port)
        }
    }

    Benchmark(
        "Port_Parsing_Multiple_Ports_String_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsString.indices {
            let port = unsafe Port(portMultiplePortsString[idx]).unsafelyUnwrapped
            blackHole(port)
        }
    }

    Benchmark(
        "Port_Parsing_Multiple_Ports_String_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsString.indices {
            let port = unsafe Port(portMultiplePortsString[idx]).unsafelyUnwrapped
            blackHole(port)
        }
    }

    // MARK: Port_Parsing_Multiple_Ports_UInt16

    Benchmark(
        "Port_Parsing_Multiple_Ports_UInt16_12M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<12_000_000 {
            let idx = Int(rng.next() % UInt64(portMultiplePortsString.count))
            let port = unsafe UInt16(portMultiplePortsString[idx]).unsafelyUnwrapped
            blackHole(port)
        }
    }

    Benchmark(
        "Port_Parsing_Multiple_Ports_UInt16_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsString.indices {
            let port = unsafe UInt16(portMultiplePortsString[idx]).unsafelyUnwrapped
            blackHole(port)
        }
    }

    Benchmark(
        "Port_Parsing_Multiple_Ports_UInt16_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsString.indices {
            let port = unsafe UInt16(portMultiplePortsString[idx]).unsafelyUnwrapped
            blackHole(port)
        }
    }
}
