import Benchmark

struct FastRNG {
    var state: UInt64 = 0x9E37_79B9_7F4A_7C15

    mutating func next() -> UInt64 {
        self.state ^= self.state &<< 13
        self.state ^= self.state &>> 7
        self.state ^= self.state &<< 17
        return self.state
    }
}

let fastRNGBenchmarks: @Sendable () -> Void = {
    Benchmark(
        "FastRNG_100M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        var rng = FastRNG()
        for _ in 0..<100_000_000 {
            let result = rng.next()
            blackHole(result)
        }
    }
}
