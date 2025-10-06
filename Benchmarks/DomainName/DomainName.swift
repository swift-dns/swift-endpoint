import Benchmark
import Domain

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    let google = "google.com"
    Benchmark(
        "google_dot_com_String_Parsing_CPU_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000,
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let domainName = try! DomainName(google)
            blackHole(domainName)
        }
    }

    Benchmark(
        "google_dot_com_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        let domainName = try! DomainName(google)
        blackHole(domainName)
    }

    let appAnalyticsServices = "app-analytics-services.com"
    Benchmark(
        "app-analytics-services_dot_com_String_Parsing_CPU_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000,
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let domainName = try! DomainName(appAnalyticsServices)
            blackHole(domainName)
        }
    }

    Benchmark(
        "app-analytics-services_dot_com_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        let domainName = try! DomainName(appAnalyticsServices)
        blackHole(domainName)
    }

    let name1 = try! DomainName("google.com.")
    let name2 = try! DomainName("google.com.")
    Benchmark(
        "Equality_Check_CPU_20M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 100_000_000,
        )
    ) { benchmark in
        for _ in 0..<20_000_000 {
            blackHole(name1 == name2)
        }
    }

    Benchmark(
        "Equality_Check_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        blackHole(name1 == name2)
    }
}
