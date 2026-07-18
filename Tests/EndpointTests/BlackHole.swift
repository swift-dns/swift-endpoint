/// Foils optimizations that would otherwise discard the value passed in.
/// `@_optimize(none)` keeps the call opaque so the caller must materialize the argument, which
/// preserves precondition/overflow traps that release builds would otherwise fold away.
/// Borrowed from swift-collections benchmark, as used by ordo-one/package-benchmark.
@_optimize(none)
func blackHole(_: some Any) {}
