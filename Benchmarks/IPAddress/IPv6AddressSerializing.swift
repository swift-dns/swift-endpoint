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
        "IPv6_Serializing_Zero_8M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<8_000_000 {
            let description = ipv6Zero.description
            blackHole(description)
        }
    }

    // MARK: - IPv6_Serializing_Localhost

    let ipv6Localhost: IPv6Address = 0x0000_0000_0000_0000_0000_0000_0000_0001
    Benchmark(
        "IPv6_Serializing_Localhost_8M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<8_000_000 {
            let description = ipv6Localhost.description
            blackHole(description)
        }
    }

    // MARK: - IPv6_Serializing_Compact

    let ipv6Compact: IPv6Address = 0x0001_0002_0000_0000_0000_0000_0003_0000
    Benchmark(
        "IPv6_Serializing_Compact_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<5_000_000 {
            let description = ipv6Compact.description
            blackHole(description)
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
        let description = ipv6Compact.description
        blackHole(description)
    }

    Benchmark(
        "IPv6_Serializing_Compact_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let description = ipv6Compact.description
        blackHole(description)
    }

    // MARK: IPv6_Serializing_Compact_inet_ntop

    var ipv6CompactInetNtop = ipv6Compact.address

    /// inet_ntop expects the reverse byte-order but we don't account for that here.

    Benchmark(
        "IPv6_Serializing_Compact_inet_ntop_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            let ptr = unsafe UnsafeMutableRawPointer.allocate(
                byteCount: 64,
                alignment: 1
            ).bindMemory(
                to: Int8.self,
                capacity: 64
            )
            unsafe inet_ntop(
                AF_INET6,
                &ipv6CompactInetNtop,
                ptr,
                64
            )
            let description = unsafe String(cString: ptr)
            unsafe ptr.deinitialize(count: 64).deallocate()
            blackHole(description)
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
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) {
            (addressBytesPtr: UnsafeMutableBufferPointer<Int8>) in
            unsafe inet_ntop(
                AF_INET6,
                &ipv6CompactInetNtop,
                addressBytesPtr.baseAddress!,
                50
            )
            blackHole(addressBytesPtr)
        }
    }

    Benchmark(
        "IPv6_Serializing_Compact_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) {
            (addressBytesPtr: UnsafeMutableBufferPointer<Int8>) in
            unsafe inet_ntop(
                AF_INET6,
                &ipv6CompactInetNtop,
                addressBytesPtr.baseAddress!,
                50
            )
            blackHole(addressBytesPtr)
        }
    }

    // MARK: - IPv6_Serializing_Max

    let ipv6Max: IPv6Address = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
    Benchmark(
        "IPv6_Serializing_Max_3M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<3_000_000 {
            let description = ipv6Max.description
            blackHole(description)
        }
    }

    // MARK: - IPv6_Serializing_Mixed

    let ipv6Mixed: IPv6Address = 0x85a0_850a_8500_0000_0000_00af_805a_085a
    Benchmark(
        "IPv6_Serializing_Mixed_3M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<3_000_000 {
            let description = ipv6Mixed.description
            blackHole(description)
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
        let description = ipv6Mixed.description
        blackHole(description)
    }

    Benchmark(
        "IPv6_Serializing_Mixed_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let description = ipv6Mixed.description
        blackHole(description)
    }

    // MARK: IPv6_Serializing_Mixed_inet_ntop

    var ipv6MixedInetNtop = ipv6Mixed.address

    /// inet_ntop expects the reverse byte-order but we don't account for that here.

    Benchmark(
        "IPv6_Serializing_Mixed_inet_ntop_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            let ptr = unsafe UnsafeMutableRawPointer.allocate(
                byteCount: 64,
                alignment: 1
            ).bindMemory(
                to: Int8.self,
                capacity: 64
            )
            unsafe inet_ntop(
                AF_INET6,
                &ipv6MixedInetNtop,
                ptr,
                64
            )
            let description = unsafe String(cString: ptr)
            unsafe ptr.deinitialize(count: 64).deallocate()
            blackHole(description)
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
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) {
            (addressBytesPtr: UnsafeMutableBufferPointer<Int8>) in
            unsafe inet_ntop(
                AF_INET6,
                &ipv6MixedInetNtop,
                addressBytesPtr.baseAddress!,
                50
            )
            blackHole(addressBytesPtr)
        }
    }

    Benchmark(
        "IPv6_Serializing_Mixed_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) {
            (addressBytesPtr: UnsafeMutableBufferPointer<Int8>) in
            unsafe inet_ntop(
                AF_INET6,
                &ipv6MixedInetNtop,
                addressBytesPtr.baseAddress!,
                50
            )
            blackHole(addressBytesPtr)
        }
    }

    // MARK: - IPv6_Serializing_Multiple_IPs

    let ipv6MultipleIPs: [IPv6Address] = [
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
        "IPv6_Serializing_Multiple_IPs_3M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<3_000_000 {
            let idx = Int(rng.next() % 16)
            let description = ipv6MultipleIPs[idx].description
            blackHole(description)
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
        for ip in ipv6MultipleIPs {
            let description = ip.description
            blackHole(description)
        }
    }

    Benchmark(
        "IPv6_Serializing_Multiple_IPs_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for ip in ipv6MultipleIPs {
            let description = ip.description
            blackHole(description)
        }
    }

    // MARK: IPv6_Serializing_Multiple_IPs_inet_ntop

    let ipv6MultipleIPsInetNtop = ipv6MultipleIPs.map(\.address)

    /// inet_ntop expects the reverse byte-order but we don't account for that here.

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
            let idx = Int(rng.next() % 16)
            var address = ipv6MultipleIPsInetNtop[idx]
            let ptr = unsafe UnsafeMutableRawPointer.allocate(
                byteCount: 64,
                alignment: 1
            ).bindMemory(
                to: Int8.self,
                capacity: 64
            )
            unsafe inet_ntop(
                AF_INET6,
                &address,
                ptr,
                64
            )
            let description = unsafe String(cString: ptr)
            unsafe ptr.deinitialize(count: 64).deallocate()
            blackHole(description)
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
        for var address in ipv6MultipleIPsInetNtop {
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) {
                (addressBytesPtr: UnsafeMutableBufferPointer<Int8>) in
                unsafe inet_ntop(
                    AF_INET6,
                    &address,
                    addressBytesPtr.baseAddress!,
                    50
                )
                blackHole(addressBytesPtr)
            }
        }
    }

    Benchmark(
        "IPv6_Serializing_Multiple_IPs_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for var address in ipv6MultipleIPsInetNtop {
            withUnsafeTemporaryAllocation(of: Int8.self, capacity: 50) {
                (addressBytesPtr: UnsafeMutableBufferPointer<Int8>) in
                unsafe inet_ntop(
                    AF_INET6,
                    &address,
                    addressBytesPtr.baseAddress!,
                    50
                )
                blackHole(addressBytesPtr)
            }
        }
    }
}
