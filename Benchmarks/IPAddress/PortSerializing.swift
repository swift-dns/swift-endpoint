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
#error("The PortSerializing benchmarks module was unable to identify your C library.")
#endif

let portToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - Port_Serializing_SSH

    let portSSH = Port(rawValue: 22)
    Benchmark(
        "Port_Serializing_SSH_60M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var port = portSSH
        withUnsafeMutablePointer(to: &port) { portPointer in
            unsafe blackHole(portPointer)
            for _ in 0..<60_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                    let written = unsafe portPointer.pointee
                        .writeTextualRepresentation_RequiringMinimumCapacityOf8(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: - Port_Serializing_HTTPS

    let portHTTPS = Port(rawValue: 443)
    Benchmark(
        "Port_Serializing_HTTPS_60M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var port = portHTTPS
        withUnsafeMutablePointer(to: &port) { portPointer in
            unsafe blackHole(portPointer)
            for _ in 0..<60_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                    let written = unsafe portPointer.pointee
                        .writeTextualRepresentation_RequiringMinimumCapacityOf8(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: - Port_Serializing_HTTP_Alt

    let portHTTPAlt = Port(rawValue: 8080)
    Benchmark(
        "Port_Serializing_HTTP_Alt_60M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var port = portHTTPAlt
        withUnsafeMutablePointer(to: &port) { portPointer in
            unsafe blackHole(portPointer)
            for _ in 0..<60_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                    let written = unsafe portPointer.pointee
                        .writeTextualRepresentation_RequiringMinimumCapacityOf8(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: - Port_Serializing_Ephemeral

    let portEphemeral = Port(rawValue: 33435)
    Benchmark(
        "Port_Serializing_Ephemeral_60M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var port = portEphemeral
        withUnsafeMutablePointer(to: &port) { portPointer in
            unsafe blackHole(portPointer)
            for _ in 0..<60_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                    let written = unsafe portPointer.pointee
                        .writeTextualRepresentation_RequiringMinimumCapacityOf8(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    Benchmark(
        "Port_Serializing_Ephemeral_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var port = portEphemeral
        withUnsafeMutablePointer(to: &port) { portPointer in
            unsafe blackHole(portPointer)
            withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                let written = unsafe portPointer.pointee
                    .writeTextualRepresentation_RequiringMinimumCapacityOf8(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    Benchmark(
        "Port_Serializing_Ephemeral_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        var port = portEphemeral
        withUnsafeMutablePointer(to: &port) { portPointer in
            unsafe blackHole(portPointer)
            withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                let written = unsafe portPointer.pointee
                    .writeTextualRepresentation_RequiringMinimumCapacityOf8(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: - Port_Serializing_Multiple_Ports

    // [
    //     7, 22, 25, 53, 80, 110, 123, 143,
    //     179, 443, 465, 514, 587, 636, 853, 993,
    //     995, 1080, 1194, 1433, 1521, 3306, 3389, 5432,
    //     5672, 6379, 8080, 8443, 9092, 11211, 27017, 33435,
    // ]
    let portMultiplePorts: [32 of Port] = [
        7, 22, 25, 53, 80, 110, 123, 143,
        179, 443, 465, 514, 587, 636, 853, 993,
        995, 1080, 1194, 1433, 1521, 3306, 3389, 5432,
        5672, 6379, 8080, 8443, 9092, 11211, 27017, 33435,
    ]

    Benchmark(
        "Port_Serializing_Multiple_Ports_25M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<25_000_000 {
            let idx = Int(rng.next() % UInt64(portMultiplePorts.count))
            withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                let written = unsafe portMultiplePorts[idx]
                    .writeTextualRepresentation_RequiringMinimumCapacityOf8(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePorts.indices {
            withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                let written = unsafe portMultiplePorts[idx]
                    .writeTextualRepresentation_RequiringMinimumCapacityOf8(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePorts.indices {
            withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                let written = unsafe portMultiplePorts[idx]
                    .writeTextualRepresentation_RequiringMinimumCapacityOf8(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: Port_Serializing_Multiple_Ports_vsnprintf

    /// Same as portMultiplePorts.map(\.rawValue) but inlined.
    /// `snprintf` is a C variadic so it is not importable; `vsnprintf` is the way to reach it.
    /// The mallocs this reports come from `withVaList` boxing the argument, not from `snprintf`.
    let portMultiplePortsVsnprintf: [32 of UInt32] = [
        7, 22, 25, 53, 80, 110, 123, 143,
        179, 443, 465, 514, 587, 636, 853, 993,
        995, 1080, 1194, 1433, 1521, 3306, 3389, 5432,
        5672, 6379, 8080, 8443, 9092, 11211, 27017, 33435,
    ]

    Benchmark(
        "Port_Serializing_Multiple_Ports_vsnprintf_500K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<500_000 {
            let idx = Int(rng.next() % UInt64(portMultiplePortsVsnprintf.count))
            withUnsafeTemporaryAllocation(byteCount: 6, alignment: 1) { buffer in
                let base = unsafe buffer.baseAddress.unsafelyUnwrapped
                    .assumingMemoryBound(to: CChar.self)
                let written = unsafe withVaList([portMultiplePortsVsnprintf[idx]]) { vaList in
                    unsafe vsnprintf(base, 6, "%u", vaList)
                }
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_vsnprintf_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsVsnprintf.indices {
            withUnsafeTemporaryAllocation(byteCount: 6, alignment: 1) { buffer in
                let base = unsafe buffer.baseAddress.unsafelyUnwrapped
                    .assumingMemoryBound(to: CChar.self)
                let written = unsafe withVaList([portMultiplePortsVsnprintf[idx]]) { vaList in
                    unsafe vsnprintf(base, 6, "%u", vaList)
                }
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_vsnprintf_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsVsnprintf.indices {
            withUnsafeTemporaryAllocation(byteCount: 6, alignment: 1) { buffer in
                let base = unsafe buffer.baseAddress.unsafelyUnwrapped
                    .assumingMemoryBound(to: CChar.self)
                let written = unsafe withVaList([portMultiplePortsVsnprintf[idx]]) { vaList in
                    unsafe vsnprintf(base, 6, "%u", vaList)
                }
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: Port_Serializing_Multiple_Ports_description

    /// The String-producing counterpart of the writer benchmarks above, so it can be compared
    /// against the stdlib's `String(UInt16)` on equal terms.

    Benchmark(
        "Port_Serializing_Multiple_Ports_description_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<15_000_000 {
            let idx = Int(rng.next() % UInt64(portMultiplePorts.count))
            let description = portMultiplePorts[idx].description
            blackHole(description)
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_description_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePorts.indices {
            let description = portMultiplePorts[idx].description
            blackHole(description)
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_description_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePorts.indices {
            let description = portMultiplePorts[idx].description
            blackHole(description)
        }
    }

    // MARK: Port_Serializing_Multiple_Ports_String

    Benchmark(
        "Port_Serializing_Multiple_Ports_String_8M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<8_000_000 {
            let idx = Int(rng.next() % UInt64(portMultiplePorts.count))
            let description = String(portMultiplePorts[idx].rawValue)
            blackHole(description)
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_String_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePorts.indices {
            let description = String(portMultiplePorts[idx].rawValue)
            blackHole(description)
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_String_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePorts.indices {
            let description = String(portMultiplePorts[idx].rawValue)
            blackHole(description)
        }
    }
}
