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
#error("The IPv6AddressSerializing benchmarks module was unable to identify your C library.")
#endif

let ipv6AddressToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv6_Serializing_Zero

    let ipv6Zero: IPv6Address = 0
    Benchmark(
        "IPv6_Serializing_Zero_20M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv6Zero
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<20_000_000 {
                unsafe addressPointer.pointee.makeDescription(options: .standardOptions) {
                    (maxBytes, writeBytes) in
                    withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                        let written = unsafe writeBytes(buffer)
                        unsafe blackHole(buffer)
                        blackHole(written)
                    }
                }
            }
        }
    }

    // MARK: - IPv6_Serializing_Localhost

    let ipv6Localhost: IPv6Address = 0x0000_0000_0000_0000_0000_0000_0000_0001
    Benchmark(
        "IPv6_Serializing_Localhost_12M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv6Localhost
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<12_000_000 {
                unsafe addressPointer.pointee.makeDescription(options: .standardOptions) {
                    (maxBytes, writeBytes) in
                    withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                        let written = unsafe writeBytes(buffer)
                        unsafe blackHole(buffer)
                        blackHole(written)
                    }
                }
            }
        }
    }

    // MARK: - IPv6_Serializing_Compact

    let ipv6Compact: IPv6Address = 0x0001_0002_0000_0000_0000_0000_0003_0000
    Benchmark(
        "IPv6_Serializing_Compact_7M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv6Compact
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<7_000_000 {
                unsafe addressPointer.pointee.makeDescription(options: .standardOptions) {
                    (maxBytes, writeBytes) in
                    withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                        let written = unsafe writeBytes(buffer)
                        unsafe blackHole(buffer)
                        blackHole(written)
                    }
                }
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Compact_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var address = ipv6Compact
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            unsafe addressPointer.pointee.makeDescription(options: .standardOptions) {
                (maxBytes, writeBytes) in
                withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                    let written = unsafe writeBytes(buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Compact_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 10,
            maxIterations: 10
        )
    ) { benchmark in
        var address = ipv6Compact
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            unsafe addressPointer.pointee.makeDescription(options: .standardOptions) {
                (maxBytes, writeBytes) in
                withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                    let written = unsafe writeBytes(buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: IPv6_Serializing_Compact_inet_ntop

    var ipv6CompactInetNtop = ipv6Compact.address.bigEndian

    Benchmark(
        "IPv6_Serializing_Compact_inet_ntop_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) { ptr in
                unsafe inet_ntop(
                    AF_INET6,
                    &ipv6CompactInetNtop,
                    ptr.baseAddress.unsafelyUnwrapped,
                    50
                )
                unsafe blackHole(ptr)
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Compact_inet_ntop_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) { ptr in
            unsafe inet_ntop(
                AF_INET6,
                &ipv6CompactInetNtop,
                ptr.baseAddress.unsafelyUnwrapped,
                50
            )
            unsafe blackHole(ptr)
        }
    }

    Benchmark(
        "IPv6_Serializing_Compact_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 10,
            maxIterations: 10
        )
    ) { benchmark in
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) { ptr in
            unsafe inet_ntop(
                AF_INET6,
                &ipv6CompactInetNtop,
                ptr.baseAddress.unsafelyUnwrapped,
                50
            )
            unsafe blackHole(ptr)
        }
    }

    // MARK: - IPv6_Serializing_Max

    let ipv6Max: IPv6Address = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
    Benchmark(
        "IPv6_Serializing_Max_4M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv6Max
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<4_000_000 {
                unsafe addressPointer.pointee.makeDescription(options: .standardOptions) {
                    (maxBytes, writeBytes) in
                    withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                        let written = unsafe writeBytes(buffer)
                        unsafe blackHole(buffer)
                        blackHole(written)
                    }
                }
            }
        }
    }

    // MARK: - IPv6_Serializing_Mixed

    let ipv6Mixed: IPv6Address = 0x85a0_850a_8500_0000_0000_00af_805a_085a
    Benchmark(
        "IPv6_Serializing_Mixed_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv6Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<5_000_000 {
                unsafe addressPointer.pointee.makeDescription(options: .standardOptions) {
                    (maxBytes, writeBytes) in
                    withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                        let written = unsafe writeBytes(buffer)
                        unsafe blackHole(buffer)
                        blackHole(written)
                    }
                }
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Mixed_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var address = ipv6Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            unsafe addressPointer.pointee.makeDescription(options: .standardOptions) {
                (maxBytes, writeBytes) in
                withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                    let written = unsafe writeBytes(buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Mixed_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 10,
            maxIterations: 10
        )
    ) { benchmark in
        var address = ipv6Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            unsafe addressPointer.pointee.makeDescription(options: .standardOptions) {
                (maxBytes, writeBytes) in
                withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                    let written = unsafe writeBytes(buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: IPv6_Serializing_Mixed_inet_ntop

    var ipv6MixedInetNtop = ipv6Mixed.address.bigEndian

    Benchmark(
        "IPv6_Serializing_Mixed_inet_ntop_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) { ptr in
                unsafe inet_ntop(
                    AF_INET6,
                    &ipv6MixedInetNtop,
                    ptr.baseAddress.unsafelyUnwrapped,
                    50
                )
                unsafe blackHole(ptr)
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Mixed_inet_ntop_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) { ptr in
            unsafe inet_ntop(
                AF_INET6,
                &ipv6MixedInetNtop,
                ptr.baseAddress.unsafelyUnwrapped,
                50
            )
            unsafe blackHole(ptr)
        }
    }

    Benchmark(
        "IPv6_Serializing_Mixed_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 10,
            maxIterations: 10
        )
    ) { benchmark in
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) { ptr in
            unsafe inet_ntop(
                AF_INET6,
                &ipv6MixedInetNtop,
                ptr.baseAddress.unsafelyUnwrapped,
                50
            )
            unsafe blackHole(ptr)
        }
    }

    // MARK: - IPv6_Serializing_Multiple_IPs

    let ipv6MultipleIPs: [16 of IPv6Address] = [
        0x0000_0000_0000_0000_0000_0000_0000_0001,
        0x2606_4700_4700_0000_0000_0000_0000_1111,
        0x2001_4860_4860_0000_0000_0000_0000_8888,
        0x2620_00fe_0000_0000_0000_0000_0000_00fe,
        0x2620_0119_0035_0000_0000_0000_0000_0035,
        0x2a03_2880_f177_0185_face_b00c_0000_25de,
        0x2a00_1450_4001_0c15_0000_0000_0000_008a,
        0x2606_4700_0000_0000_0000_0000_6810_84e5,
        0x2600_9000_2241_5800_0001_5a21_7c40_93a1,
        0x2001_0db8_85a3_0000_0000_8a2e_0370_7334,
        0x0064_ff9b_0000_0000_0000_0000_0808_0808,
        0xfe80_0000_0000_0000_01ff_fe23_4567_890a,
        0xff02_0000_0000_0000_0000_0000_0000_0001,
        0x2001_41d0_0302_2200_0000_0000_0000_0180,
        0x2a01_04f8_c010_0d56_0000_0000_0000_0001,
        0x2400_cb00_2049_0001_0000_0000_a29f_1804,
    ]

    Benchmark(
        "IPv6_Serializing_Multiple_IPs_4M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<4_000_000 {
            let idx = Int(rng.next() % UInt64(ipv6MultipleIPs.count))
            unsafe ipv6MultipleIPs[idx].makeDescription(options: .standardOptions) {
                (maxBytes, writeBytes) in
                withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                    let written = unsafe writeBytes(buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Multiple_IPs_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv6MultipleIPs.indices {
            unsafe ipv6MultipleIPs[idx].makeDescription(options: .standardOptions) {
                (maxBytes, writeBytes) in
                withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                    let written = unsafe writeBytes(buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Multiple_IPs_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 10,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv6MultipleIPs.indices {
            unsafe ipv6MultipleIPs[idx].makeDescription(options: .standardOptions) {
                (maxBytes, writeBytes) in
                withUnsafeTemporaryAllocation(byteCount: maxBytes, alignment: 1) { buffer in
                    let written = unsafe writeBytes(buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: IPv6_Serializing_Multiple_IPs_inet_ntop

    /// Same as ipv6MultipleIPs.map(\.address.bigEndian) but inlined
    var ipv6MultipleIPsInetNtop: [16 of UInt128] = [
        0x0100_0000_0000_0000_0000_0000_0000_0000,
        0x1111_0000_0000_0000_0000_0047_0047_0626,
        0x8888_0000_0000_0000_0000_6048_6048_0120,
        0xFE00_0000_0000_0000_0000_0000_FE00_2026,
        0x3500_0000_0000_0000_0000_3500_1901_2026,
        0xDE25_0000_0CB0_CEFA_8501_77F1_8028_032A,
        0x8A00_0000_0000_0000_150C_0140_5014_002A,
        0xE584_1068_0000_0000_0000_0000_0047_0626,
        0xA193_407C_215A_0100_0058_4122_0090_0026,
        0x3473_7003_2E8A_0000_0000_A385_B80D_0120,
        0x0808_0808_0000_0000_0000_0000_9BFF_6400,
        0x0A89_6745_23FE_FF01_0000_0000_0000_80FE,
        0x0100_0000_0000_0000_0000_0000_0000_02FF,
        0x8001_0000_0000_0000_0022_0203_D041_0120,
        0x0100_0000_0000_0000_560D_10C0_F804_012A,
        0x0418_9FA2_0000_0000_0100_4920_00CB_0024,
    ]

    Benchmark(
        "IPv6_Serializing_Multiple_IPs_inet_ntop_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<1_000_000 {
            let idx = Int(rng.next() % UInt64(ipv6MultipleIPs.count))
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) { ptr in
                unsafe inet_ntop(
                    AF_INET6,
                    &ipv6MultipleIPsInetNtop[idx],
                    ptr.baseAddress.unsafelyUnwrapped,
                    50
                )
                unsafe blackHole(ptr)
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Multiple_IPs_inet_ntop_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv6MultipleIPs.indices {
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) { ptr in
                unsafe inet_ntop(
                    AF_INET6,
                    &ipv6MultipleIPsInetNtop[idx],
                    ptr.baseAddress.unsafelyUnwrapped,
                    50
                )
                unsafe blackHole(ptr)
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Multiple_IPs_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 10,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv6MultipleIPs.indices {
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) { ptr in
                unsafe inet_ntop(
                    AF_INET6,
                    &ipv6MultipleIPsInetNtop[idx],
                    ptr.baseAddress.unsafelyUnwrapped,
                    50
                )
                unsafe blackHole(ptr)
            }
        }
    }
}
