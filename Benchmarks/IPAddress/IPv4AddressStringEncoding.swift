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
#error("The IPv4AddressStringEncoding benchmarks module was unable to identify your C library.")
#endif

let ipv4AddressToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_String_Encoding_Zero

    let ipv4Zero = IPv4Address(0, 0, 0, 0)
    Benchmark(
        "IPv4_String_Encoding_Zero_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4Zero.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_String_Encoding_Localhost

    let ipv4Localhost = IPv4Address(127, 0, 0, 1)
    Benchmark(
        "IPv4_String_Encoding_Localhost_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4Localhost.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_String_Encoding_Local_Broadcast

    let ipv4LocalBroadcast = IPv4Address(255, 255, 255, 255)
    Benchmark(
        "IPv4_String_Encoding_Local_Broadcast_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4LocalBroadcast.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_String_Encoding_Mixed

    let ipv4Mixed = IPv4Address(123, 45, 6, 0)
    Benchmark(
        "IPv4_String_Encoding_Mixed_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4Mixed.description
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_String_Encoding_Mixed_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let description = ipv4Mixed.description
        blackHole(description)
    }

    Benchmark(
        "IPv4_String_Encoding_Mixed_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let description = ipv4Mixed.description
        blackHole(description)
    }

    // MARK: IPv4_String_Encoding_Mixed_inet_ntop

    var ipv4MixedInetNtop = ipv4Mixed.address

    /// inet_ntop expects the reverse byte-order but we don't account for that here.

    Benchmark(
        "IPv4_String_Encoding_Mixed_inet_ntop_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            let ptr = UnsafeMutableRawPointer.allocate(byteCount: 15, alignment: 1).bindMemory(
                to: Int8.self,
                capacity: 15
            )
            inet_ntop(
                AF_INET,
                &ipv4MixedInetNtop,
                ptr,
                15
            )
            let description = String(cString: ptr)
            ptr.deinitialize(count: 15).deallocate()
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_String_Encoding_Mixed_inet_ntop_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var addressBytes: [Int8] = [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]
        let description = addressBytes.withUnsafeMutableBufferPointer {
            (addressBytesPtr: inout UnsafeMutableBufferPointer<Int8>) -> String in
            inet_ntop(
                AF_INET,
                &ipv4MixedInetNtop,
                addressBytesPtr.baseAddress!,
                15
            )
            return addressBytesPtr.baseAddress!.withMemoryRebound(
                to: UInt8.self,
                capacity: 15
            ) {
                String(cString: $0)
            }
        }
        blackHole(description)
    }

    Benchmark(
        "IPv4_String_Encoding_Mixed_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var addressBytes: [Int8] = [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]
        let description = addressBytes.withUnsafeMutableBufferPointer {
            (addressBytesPtr: inout UnsafeMutableBufferPointer<Int8>) -> String in
            inet_ntop(
                AF_INET,
                &ipv4MixedInetNtop,
                addressBytesPtr.baseAddress!,
                15
            )
            return addressBytesPtr.baseAddress!.withMemoryRebound(
                to: UInt8.self,
                capacity: 15
            ) {
                String(cString: $0)
            }
        }
        blackHole(description)
    }

    // MARK: - IPv4_String_Encoding_Multiple_IPs

    let ipv4MultipleIPs = [
        IPv4Address(127, 0, 0, 1),
        IPv4Address(1, 1, 1, 1),
        IPv4Address(8, 8, 8, 8),
        IPv4Address(9, 9, 9, 9),
        IPv4Address(255, 255, 255, 255),
        IPv4Address(192, 168, 1, 1),
        IPv4Address(10, 0, 0, 1),
        IPv4Address(172, 16, 0, 1),
        IPv4Address(100, 64, 0, 1),
        IPv4Address(208, 67, 222, 222),
        IPv4Address(185, 199, 108, 153),
        IPv4Address(151, 101, 1, 140),
        IPv4Address(104, 16, 132, 229),
        IPv4Address(142, 250, 185, 78),
        IPv4Address(13, 107, 42, 14),
        IPv4Address(23, 185, 0, 2),
    ]

    Benchmark(
        "IPv4_String_Encoding_Multiple_IPs_8M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<8_000_000 {
            let idx = Int(rng.next() % 16)
            let description = ipv4MultipleIPs[idx].description
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_String_Encoding_Multiple_IPs_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for ip in ipv4MultipleIPs {
            let description = ip.description
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_String_Encoding_Multiple_IPs_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        for ip in ipv4MultipleIPs {
            let description = ip.description
            blackHole(description)
        }
    }

    // MARK: IPv4_String_Encoding_Multiple_IPs_inet_ntop

    let ipv4MultipleIPsInetNtop = ipv4MultipleIPs.map(\.address)

    /// inet_ntop expects the reverse byte-order but we don't account for that here.

    Benchmark(
        "IPv4_String_Encoding_Multiple_IPs_inet_ntop_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<1_000_000 {
            let idx = Int(rng.next() % 16)
            var address = ipv4MultipleIPsInetNtop[idx]
            let ptr = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 1).bindMemory(
                to: Int8.self,
                capacity: 16
            )
            inet_ntop(
                AF_INET,
                &address,
                ptr,
                16
            )
            let description = String(cString: ptr)
            ptr.deinitialize(count: 16).deallocate()
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_String_Encoding_Multiple_IPs_inet_ntop_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var addressBytes: [Int8] = [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]
        addressBytes.withUnsafeMutableBufferPointer {
            (addressBytesPtr: inout UnsafeMutableBufferPointer<Int8>) in
            for var address in ipv4MultipleIPsInetNtop {
                inet_ntop(
                    AF_INET,
                    &address,
                    addressBytesPtr.baseAddress!,
                    16
                )
                let description = addressBytesPtr.baseAddress!.withMemoryRebound(
                    to: UInt8.self,
                    capacity: 16
                ) {
                    String(cString: $0)
                }
                blackHole(description)
            }
        }
    }

    Benchmark(
        "IPv4_String_Encoding_Multiple_IPs_inet_ntop_Instructions",
        configuration: .init(
            metrics: [.instructions],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var addressBytes: [Int8] = [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]
        addressBytes.withUnsafeMutableBufferPointer {
            (addressBytesPtr: inout UnsafeMutableBufferPointer<Int8>) in
            for var address in ipv4MultipleIPsInetNtop {
                inet_ntop(
                    AF_INET,
                    &address,
                    addressBytesPtr.baseAddress!,
                    16
                )
                let description = addressBytesPtr.baseAddress!.withMemoryRebound(
                    to: UInt8.self,
                    capacity: 16
                ) {
                    String(cString: $0)
                }
                blackHole(description)
            }
        }
    }
}
