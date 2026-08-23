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

    let ipv6Compact: IPv6Address = 0x2620_00fe_0000_0000_0000_0000_0000_00fe
    Benchmark(
        "IPv6_Serializing_Compact_8M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv6Compact
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<8_000_000 {
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
            warmupIterations: 100,
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
            warmupIterations: 100,
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
        "IPv6_Serializing_Max_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv6Max
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

    // MARK: - IPv6_Serializing_Mixed

    let ipv6Mixed: IPv6Address = 0x2001_41d0_0302_2200_0000_0000_0000_0180
    Benchmark(
        "IPv6_Serializing_Mixed_6M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv6Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<6_000_000 {
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
            warmupIterations: 100,
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

    // MARK: - IPv6_Serializing_Mixed_Enclosed_In_Square_Brackets

    let ipv6MixedBracketOptions: IPv6Address.DescriptionOptions = [
        .standardOptions, .encloseInSquareBrackets,
    ]

    Benchmark(
        "IPv6_Serializing_Mixed_Enclosed_In_Square_Brackets_6M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var address = ipv6Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            for _ in 0..<6_000_000 {
                unsafe addressPointer.pointee.makeDescription(
                    options: ipv6MixedBracketOptions
                ) {
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
        "IPv6_Serializing_Mixed_Enclosed_In_Square_Brackets_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var address = ipv6Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            unsafe addressPointer.pointee.makeDescription(options: ipv6MixedBracketOptions) {
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
        "IPv6_Serializing_Mixed_Enclosed_In_Square_Brackets_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        var address = ipv6Mixed
        withUnsafeMutablePointer(to: &address) { addressPointer in
            unsafe blackHole(addressPointer)
            unsafe addressPointer.pointee.makeDescription(options: ipv6MixedBracketOptions) {
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
            warmupIterations: 100,
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

    // [
    //     "::1",
    //     "::",
    //     "2606:4700:4700::1111",
    //     "2606:4700:4700::1001",
    //     "2001:4860:4860::8888",
    //     "2001:4860:4860:0:0:0:0:8844",
    //     "2620:FE::FE",
    //     "2620:119:35::35",
    //     "2620:0:ccc::2",
    //     "2a03:2880:f177:185:face:b00c:0:25de",
    //     "2a03:2880:f177:185::",
    //     "2600:9000:2241:5800:0001:5a21:7c40:93a1",
    //     "2600:9000:2241:5800::",
    //     "::ffff:151.101.1.140",
    //     "64:ff9b::8.8.8.8",
    //     "2606:4700::6810:84e5",
    //     "2400:cb00:2049:1::a29f:1804",
    //     "2606:2800:220:1:248:1893:25c8:1946",
    //     "2001:0500:0002:0000:0000:0000:0000:000c",
    //     "2001:503:ba3e::2:30",
    //     "2001:7fd::1",
    //     "FE80::1FF:FE23:4567:890A",
    //     "fe80::200:5eff:fe00:5213",
    //     "fe80::",
    //     "ff02::1",
    //     "ff02::1:ff00:1",
    //     "ff05:0:0:0:0:0:1:3",
    //     "2001:41d0:302:2200::180",
    //     "2A01:4F8:C010:D56::1",
    //     "2a01:4f8:c010:d56::",
    //     "2a00:1450:4001:c15::8a",
    //     "fd00:ec2:0:0:0:0:0:254",
    // ]
    let ipv6MultipleIPs: [32 of IPv6Address] = [
        0x0000_0000_0000_0000_0000_0000_0000_0001,
        0x0000_0000_0000_0000_0000_0000_0000_0000,
        0x2606_4700_4700_0000_0000_0000_0000_1111,
        0x2606_4700_4700_0000_0000_0000_0000_1001,
        0x2001_4860_4860_0000_0000_0000_0000_8888,
        0x2001_4860_4860_0000_0000_0000_0000_8844,
        0x2620_00fe_0000_0000_0000_0000_0000_00fe,
        0x2620_0119_0035_0000_0000_0000_0000_0035,
        0x2620_0000_0ccc_0000_0000_0000_0000_0002,
        0x2a03_2880_f177_0185_face_b00c_0000_25de,
        0x2a03_2880_f177_0185_0000_0000_0000_0000,
        0x2600_9000_2241_5800_0001_5a21_7c40_93a1,
        0x2600_9000_2241_5800_0000_0000_0000_0000,
        0x0000_0000_0000_0000_0000_ffff_9765_018c,
        0x0064_ff9b_0000_0000_0000_0000_0808_0808,
        0x2606_4700_0000_0000_0000_0000_6810_84e5,
        0x2400_cb00_2049_0001_0000_0000_a29f_1804,
        0x2606_2800_0220_0001_0248_1893_25c8_1946,
        0x2001_0500_0002_0000_0000_0000_0000_000c,
        0x2001_0503_ba3e_0000_0000_0000_0002_0030,
        0x2001_07fd_0000_0000_0000_0000_0000_0001,
        0xfe80_0000_0000_0000_01ff_fe23_4567_890a,
        0xfe80_0000_0000_0000_0200_5eff_fe00_5213,
        0xfe80_0000_0000_0000_0000_0000_0000_0000,
        0xff02_0000_0000_0000_0000_0000_0000_0001,
        0xff02_0000_0000_0000_0000_0001_ff00_0001,
        0xff05_0000_0000_0000_0000_0000_0001_0003,
        0x2001_41d0_0302_2200_0000_0000_0000_0180,
        0x2a01_04f8_c010_0d56_0000_0000_0000_0001,
        0x2a01_04f8_c010_0d56_0000_0000_0000_0000,
        0x2a00_1450_4001_0c15_0000_0000_0000_008a,
        0xfd00_0ec2_0000_0000_0000_0000_0000_0254,
    ]

    /// Mirrors the 6 bracketed inputs of the IPv6_Parsing_Multiple_IPs set,
    /// at the same indices.
    let ipv6MultipleIPsOptions: [32 of IPv6Address.DescriptionOptions] = [
        [.standardOptions, .encloseInSquareBrackets],
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        [.standardOptions, .encloseInSquareBrackets],
        [.standardOptions, .encloseInSquareBrackets],
        .standardOptions,
        .standardOptions,
        [.standardOptions, .encloseInSquareBrackets],
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        .standardOptions,
        [.standardOptions, .encloseInSquareBrackets],
        .standardOptions,
        [.standardOptions, .encloseInSquareBrackets],
        .standardOptions,
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
            unsafe ipv6MultipleIPs[idx].makeDescription(options: ipv6MultipleIPsOptions[idx]) {
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
            unsafe ipv6MultipleIPs[idx].makeDescription(options: ipv6MultipleIPsOptions[idx]) {
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
            warmupIterations: 100,
            maxIterations: 10
        )
    ) { benchmark in
        for idx in ipv6MultipleIPs.indices {
            unsafe ipv6MultipleIPs[idx].makeDescription(options: ipv6MultipleIPsOptions[idx]) {
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
    var ipv6MultipleIPsInetNtop: [32 of UInt128] = [
        0x0100_0000_0000_0000_0000_0000_0000_0000,
        0x0000_0000_0000_0000_0000_0000_0000_0000,
        0x1111_0000_0000_0000_0000_0047_0047_0626,
        0x0110_0000_0000_0000_0000_0047_0047_0626,
        0x8888_0000_0000_0000_0000_6048_6048_0120,
        0x4488_0000_0000_0000_0000_6048_6048_0120,
        0xfe00_0000_0000_0000_0000_0000_fe00_2026,
        0x3500_0000_0000_0000_0000_3500_1901_2026,
        0x0200_0000_0000_0000_0000_cc0c_0000_2026,
        0xde25_0000_0cb0_cefa_8501_77f1_8028_032a,
        0x0000_0000_0000_0000_8501_77f1_8028_032a,
        0xa193_407c_215a_0100_0058_4122_0090_0026,
        0x0000_0000_0000_0000_0058_4122_0090_0026,
        0x8c01_6597_ffff_0000_0000_0000_0000_0000,
        0x0808_0808_0000_0000_0000_0000_9bff_6400,
        0xe584_1068_0000_0000_0000_0000_0047_0626,
        0x0418_9fa2_0000_0000_0100_4920_00cb_0024,
        0x4619_c825_9318_4802_0100_2002_0028_0626,
        0x0c00_0000_0000_0000_0000_0200_0005_0120,
        0x3000_0200_0000_0000_0000_3eba_0305_0120,
        0x0100_0000_0000_0000_0000_0000_fd07_0120,
        0x0a89_6745_23fe_ff01_0000_0000_0000_80fe,
        0x1352_00fe_ff5e_0002_0000_0000_0000_80fe,
        0x0000_0000_0000_0000_0000_0000_0000_80fe,
        0x0100_0000_0000_0000_0000_0000_0000_02ff,
        0x0100_00ff_0100_0000_0000_0000_0000_02ff,
        0x0300_0100_0000_0000_0000_0000_0000_05ff,
        0x8001_0000_0000_0000_0022_0203_d041_0120,
        0x0100_0000_0000_0000_560d_10c0_f804_012a,
        0x0000_0000_0000_0000_560d_10c0_f804_012a,
        0x8a00_0000_0000_0000_150c_0140_5014_002a,
        0x5402_0000_0000_0000_0000_0000_c20e_00fd,
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
            warmupIterations: 100,
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
