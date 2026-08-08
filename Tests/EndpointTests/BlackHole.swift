/// Foils optimizations that would otherwise discard the value passed in.
/// `@_optimize(none)` keeps the call opaque so the caller must materialize the argument, which
/// preserves precondition/overflow traps that release builds would otherwise fold away.
/// Borrowed from swift-collections benchmark, as used by ordo-one/package-benchmark.
@_optimize(none)
func blackHole(_: some Any) {}

/// Returns its argument unchanged while staying opaque to the optimizer.
/// `@_optimize(none)` prevents inlining, so callers can't see the value is a constant. This keeps
/// crash-path operands runtime-opaque, which avoids compile-time diagnostics (e.g. literal
/// division by zero) and stops release builds from constant-folding a trap away.
/// Borrowed from swift-collections benchmark, as used by ordo-one/package-benchmark.
@_optimize(none)
func noOptimize<T>(_ value: T) -> T {
    value
}
