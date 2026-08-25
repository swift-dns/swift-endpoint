import Benchmark
import CBenchSupport
import IPAddress

let portToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - Port_Serializing_SSH

    let portSSH = Port(rawValue: 22)
    Benchmark(
        "Port_Serializing_SSH_30M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<30_000_000 {
            withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                let written = unsafe portSSH.writeTextualRepresentation_RequiringMinimumCapacityOf8(
                    into: buffer
                )
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: - Port_Serializing_HTTPS

    let portHTTPS = Port(rawValue: 443)
    Benchmark(
        "Port_Serializing_HTTPS_30M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<30_000_000 {
            withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                let written =
                    unsafe portHTTPS.writeTextualRepresentation_RequiringMinimumCapacityOf8(
                        into: buffer
                    )
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: - Port_Serializing_HTTP_Alt

    let portHTTPAlt = Port(rawValue: 8080)
    Benchmark(
        "Port_Serializing_HTTP_Alt_30M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<30_000_000 {
            withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                let written =
                    unsafe portHTTPAlt.writeTextualRepresentation_RequiringMinimumCapacityOf8(
                        into: buffer
                    )
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: - Port_Serializing_Ephemeral

    let portEphemeral = Port(rawValue: 33435)
    Benchmark(
        "Port_Serializing_Ephemeral_30M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<30_000_000 {
            withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
                let written =
                    unsafe portEphemeral.writeTextualRepresentation_RequiringMinimumCapacityOf8(
                        into: buffer
                    )
                unsafe blackHole(buffer)
                blackHole(written)
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
        withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
            let written =
                unsafe portEphemeral.writeTextualRepresentation_RequiringMinimumCapacityOf8(
                    into: buffer
                )
            unsafe blackHole(buffer)
            blackHole(written)
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
        withUnsafeTemporaryAllocation(byteCount: 8, alignment: 1) { buffer in
            let written =
                unsafe portEphemeral.writeTextualRepresentation_RequiringMinimumCapacityOf8(
                    into: buffer
                )
            unsafe blackHole(buffer)
            blackHole(written)
        }
    }

    // MARK: - Port_Serializing_Multiple_Ports

    // [
    //     9, 21, 22, 23, 25, 53, 80, 110,
    //     123, 143, 179, 389, 443, 514, 587, 853,
    //     993, 995, 1194, 1433, 2049, 3306, 3389, 5060,
    //     5353, 5432, 6379, 8080, 8443, 11211, 27017, 33435,
    // ]
    let portMultiplePorts: [32 of Port] = [
        9, 21, 22, 23, 25, 53, 80, 110,
        123, 143, 179, 389, 443, 514, 587, 853,
        993, 995, 1194, 1433, 2049, 3306, 3389, 5060,
        5353, 5432, 6379, 8080, 8443, 11211, 27017, 33435,
    ]

    Benchmark(
        "Port_Serializing_Multiple_Ports_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<15_000_000 {
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

    // MARK: Port_Serializing_Multiple_Ports_snprintf

    /// Same as portMultiplePorts.map(\.rawValue) but inlined.
    let portMultiplePortsSnprintf: [32 of UInt32] = [
        9, 21, 22, 23, 25, 53, 80, 110,
        123, 143, 179, 389, 443, 514, 587, 853,
        993, 995, 1194, 1433, 2049, 3306, 3389, 5060,
        5353, 5432, 6379, 8080, 8443, 11211, 27017, 33435,
    ]

    Benchmark(
        "Port_Serializing_Multiple_Ports_snprintf_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<2_000_000 {
            let idx = Int(rng.next() % UInt64(portMultiplePortsSnprintf.count))
            withUnsafeTemporaryAllocation(byteCount: 6, alignment: 1) { buffer in
                let base = unsafe buffer.baseAddress.unsafelyUnwrapped
                    .assumingMemoryBound(to: CChar.self)
                let written = unsafe cbench_snprintf_u32(base, 6, portMultiplePortsSnprintf[idx])
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_snprintf_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsSnprintf.indices {
            withUnsafeTemporaryAllocation(byteCount: 6, alignment: 1) { buffer in
                let base = unsafe buffer.baseAddress.unsafelyUnwrapped
                    .assumingMemoryBound(to: CChar.self)
                let written = unsafe cbench_snprintf_u32(base, 6, portMultiplePortsSnprintf[idx])
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    Benchmark(
        "Port_Serializing_Multiple_Ports_snprintf_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in portMultiplePortsSnprintf.indices {
            withUnsafeTemporaryAllocation(byteCount: 6, alignment: 1) { buffer in
                let base = unsafe buffer.baseAddress.unsafelyUnwrapped
                    .assumingMemoryBound(to: CChar.self)
                let written = unsafe cbench_snprintf_u32(base, 6, portMultiplePortsSnprintf[idx])
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: Port_Serializing_Multiple_Ports_description

    /// The String-producing counterpart of the writer benchmarks above, so it can be compared
    /// against the stdlib's `String(UInt16)` on equal terms.

    Benchmark(
        "Port_Serializing_Multiple_Ports_description_6M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<6_000_000 {
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
        "Port_Serializing_Multiple_Ports_String_6M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<6_000_000 {
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
