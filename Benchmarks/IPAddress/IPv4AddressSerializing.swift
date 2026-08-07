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
        var address = ipv4Zero
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<15_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                    let written = unsafe addressPointer.pointee
                        .writeTextualRepresentation_RequiringMinimumCapacityOf15(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
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
        var address = ipv4Localhost
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<15_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                    let written = unsafe addressPointer.pointee
                        .writeTextualRepresentation_RequiringMinimumCapacityOf15(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
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
        var address = ipv4LocalBroadcast
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<15_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                    let written = unsafe addressPointer.pointee
                        .writeTextualRepresentation_RequiringMinimumCapacityOf15(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: - IPv4_Serializing_Mixed

    let ipv4Mixed = IPv4Address(23, 185, 0, 2)
    Benchmark(
        "IPv4_Serializing_Mixed_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv4Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<15_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                    let written = unsafe addressPointer.pointee
                        .writeTextualRepresentation_RequiringMinimumCapacityOf15(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
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
        var address = ipv4Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                let written = unsafe addressPointer.pointee
                    .writeTextualRepresentation_RequiringMinimumCapacityOf15(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    Benchmark(
        "IPv4_Serializing_Mixed_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 10,
            maxIterations: 10
        )
    ) { benchmark in
        var address = ipv4Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                let written = unsafe addressPointer.pointee
                    .writeTextualRepresentation_RequiringMinimumCapacityOf15(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: IPv4_Serializing_Mixed_inet_ntop

    var ipv4MixedInetNtop = ipv4Mixed.address.bigEndian

    Benchmark(
        "IPv4_Serializing_Mixed_inet_ntop_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
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
            warmupIterations: 10,
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

    let ipv4MultipleIPs: [16 of IPv4Address] = [
        0x7F_00_00_01, 0x01_01_01_01, 0x08_08_08_08, 0x09_09_09_09,
        0xFF_FF_FF_FF, 0xC0_A8_01_01, 0x0A_00_00_01, 0xAC_10_00_01,
        0x64_40_00_01, 0xD0_43_DE_DE, 0xB9_C7_6C_99, 0x97_65_01_8C,
        0x68_10_84_E5, 0x8E_FA_B9_4E, 0x0D_6B_2A_0E, 0x17_B9_00_02,
    ]

    Benchmark(
        "IPv4_Serializing_Multiple_IPs_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<10_000_000 {
            let idx = Int(rng.next() % UInt64(ipv4MultipleIPs.count))
            withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                let written = unsafe ipv4MultipleIPs[idx]
                    .writeTextualRepresentation_RequiringMinimumCapacityOf15(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
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
        for idx in ipv4MultipleIPs.indices {
            withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                let written = unsafe ipv4MultipleIPs[idx]
                    .writeTextualRepresentation_RequiringMinimumCapacityOf15(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    Benchmark(
        "IPv4_Serializing_Multiple_IPs_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 10,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv4MultipleIPs.indices {
            withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                let written = unsafe ipv4MultipleIPs[idx]
                    .writeTextualRepresentation_RequiringMinimumCapacityOf15(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: IPv4_Serializing_Multiple_IPs_inet_ntop

    /// Same as ipv4MultipleIPs.map(\.address.bigEndian) but inlined
    var ipv4MultipleIPsInetNtop: [16 of UInt32] = [
        0x01_00_00_7F, 0x01_01_01_01, 0x08_08_08_08, 0x09_09_09_09,
        0xFF_FF_FF_FF, 0x01_01_A8_C0, 0x01_00_00_0A, 0x01_00_10_AC,
        0x01_00_40_64, 0xDE_DE_43_D0, 0x99_6C_C7_B9, 0x8C_01_65_97,
        0xE5_84_10_68, 0x4E_B9_FA_8E, 0x0E_2A_6B_0D, 0x02_00_B9_17,
    ]

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
            let idx = Int(rng.next() % UInt64(ipv4MultipleIPs.count))
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
        for idx in ipv4MultipleIPs.indices {
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
            warmupIterations: 10,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv4MultipleIPs.indices {
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
