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
        "IPv4_Serializing_Zero_30M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv4Zero
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<30_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                    let written = unsafe addressPointer.pointee
                        .writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: - IPv4_Serializing_Localhost

    let ipv4Localhost = IPv4Address(127, 0, 0, 1)
    Benchmark(
        "IPv4_Serializing_Localhost_30M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv4Localhost
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<30_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                    let written = unsafe addressPointer.pointee
                        .writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: - IPv4_Serializing_Local_Broadcast

    let ipv4LocalBroadcast = IPv4Address(255, 255, 255, 255)
    Benchmark(
        "IPv4_Serializing_Local_Broadcast_30M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv4LocalBroadcast
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<30_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                    let written = unsafe addressPointer.pointee
                        .writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
                    unsafe blackHole(buffer)
                    blackHole(written)
                }
            }
        }
    }

    // MARK: - IPv4_Serializing_Mixed

    let ipv4Mixed = IPv4Address(23, 185, 0, 2)
    Benchmark(
        "IPv4_Serializing_Mixed_30M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv4Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<30_000_000 {
                withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                    let written = unsafe addressPointer.pointee
                        .writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
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
                    .writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
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
                    .writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
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
    let ipv4MultipleIPs: [32 of IPv4Address] = [
        0x7f_00_00_01,
        0x01_01_01_01,
        0x08_08_08_08,
        0x09_09_09_09,
        0xff_ff_ff_ff,
        0xc0_a8_01_01,
        0x0a_00_00_01,
        0xac_10_00_01,
        0x64_40_00_01,
        0xd0_43_de_de,
        0xb9_c7_6c_99,
        0x97_65_01_8c,
        0x68_10_84_e5,
        0x8e_fa_b9_4e,
        0x0d_6b_2a_0e,
        0x17_b9_00_02,
        0x00_00_00_00,
        0xe0_00_00_01,
        0xa9_fe_a9_fe,
        0x08_08_04_04,
        0x01_00_00_01,
        0x95_70_70_70,
        0xd0_43_dc_dc,
        0xac_d9_10_8e,
        0x8c_52_79_04,
        0xc6_29_00_04,
        0xc0_21_04_0c,
        0xc1_00_0e_81,
        0xc7_07_53_2a,
        0x5d_b8_d7_0e,
        0x14_be_a0_0e,
        0x22_6b_dd_52,
    ]

    Benchmark(
        "IPv4_Serializing_Multiple_IPs_20M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<20_000_000 {
            let idx = Int(rng.next() % UInt64(ipv4MultipleIPs.count))
            withUnsafeTemporaryAllocation(byteCount: 15, alignment: 1) { buffer in
                let written = unsafe ipv4MultipleIPs[idx]
                    .writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
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
                    .writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
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
                    .writeTextualRepresentation_Requiring2HeadroomBytes(into: buffer)
                unsafe blackHole(buffer)
                blackHole(written)
            }
        }
    }

    // MARK: IPv4_Serializing_Multiple_IPs_inet_ntop

    /// Same as ipv4MultipleIPs.map(\.address.bigEndian) but inlined
    var ipv4MultipleIPsInetNtop: [32 of UInt32] = [
        0x01_00_00_7f,
        0x01_01_01_01,
        0x08_08_08_08,
        0x09_09_09_09,
        0xff_ff_ff_ff,
        0x01_01_a8_c0,
        0x01_00_00_0a,
        0x01_00_10_ac,
        0x01_00_40_64,
        0xde_de_43_d0,
        0x99_6c_c7_b9,
        0x8c_01_65_97,
        0xe5_84_10_68,
        0x4e_b9_fa_8e,
        0x0e_2a_6b_0d,
        0x02_00_b9_17,
        0x00_00_00_00,
        0x01_00_00_e0,
        0xfe_a9_fe_a9,
        0x04_04_08_08,
        0x01_00_00_01,
        0x70_70_70_95,
        0xdc_dc_43_d0,
        0x8e_10_d9_ac,
        0x04_79_52_8c,
        0x04_00_29_c6,
        0x0c_04_21_c0,
        0x81_0e_00_c1,
        0x2a_53_07_c7,
        0x0e_d7_b8_5d,
        0x0e_a0_be_14,
        0x52_dd_6b_22,
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
