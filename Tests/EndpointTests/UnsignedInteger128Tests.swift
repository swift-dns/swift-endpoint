import IPAddress
import Synchronization
import Testing

@Suite
struct UnsignedInteger128Tests {
    @available(SwiftStdlib 6.0, *)
    @Test func `verify static properties against UInt128`() {
        #expect(UnsignedInteger128.bitWidth == UInt128.bitWidth)
        #expect(UnsignedInteger128.max.asUInt128 == UInt128.max)
        #expect(UnsignedInteger128.min.asUInt128 == UInt128.min)
        #expect(UnsignedInteger128.zero.asUInt128 == UInt128.zero)
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify integer literal init against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = UInt128(integerLiteral: lhs)
            let unsignedInteger128 = UnsignedInteger128(integerLiteral: lhs)
            #expect(uint128 == unsignedInteger128.asUInt128)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify instance properties against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = UInt128(lhs)
            let unsignedInteger128 = UnsignedInteger128(lhs)
            #expect(uint128.leadingZeroBitCount == unsignedInteger128.leadingZeroBitCount)
            #expect(uint128.trailingZeroBitCount == unsignedInteger128.trailingZeroBitCount)
            #expect(uint128.byteSwapped == unsignedInteger128.byteSwapped.asUInt128)
            #expect(uint128.littleEndian == unsignedInteger128.littleEndian.asUInt128)
            #expect(uint128.bigEndian == unsignedInteger128.bigEndian.asUInt128)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify init(big/littleEndian:) against UInt128`() throws {
        for lhs in generateRandomUInt128s() {
            do {
                let uint128 = UInt128(bigEndian: lhs)
                let unsignedInteger128 = UnsignedInteger128(bigEndian: UnsignedInteger128(lhs))
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                let uint128 = UInt128(littleEndian: lhs)
                let unsignedInteger128 = UnsignedInteger128(littleEndian: UnsignedInteger128(lhs))
                #expect(uint128 == unsignedInteger128.asUInt128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify integer initializer against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = UInt128(lhs)
            let unsignedInteger128 = UnsignedInteger128(lhs)
            #expect(uint128._low == unsignedInteger128._low)
            #expect(uint128._high == unsignedInteger128._high)
        }

        for lhs in generateRandomUInt128s() {
            let low = UInt64(truncatingIfNeeded: lhs)
            #expect(UnsignedInteger128(low)._low == low)
            #expect(UnsignedInteger128(low)._high == 0)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify equality-operator against UInt128`() {
        #expect(UnsignedInteger128(_low: 0, _high: 0) == UnsignedInteger128(_low: 0, _high: 0))
        #expect(
            UnsignedInteger128(_low: .max, _high: .max)
                == UnsignedInteger128(_low: .max, _high: .max)
        )
        #expect(UnsignedInteger128(_low: 19, _high: 7) == UnsignedInteger128(_low: 19, _high: 7))

        for (lhs, rhs) in generateRandomUInt128Pairs() {
            if lhs == rhs { continue }

            let unsignedLhs = UnsignedInteger128(lhs)
            let unsignedRhs = UnsignedInteger128(rhs)

            #expect(unsignedLhs == unsignedLhs)
            #expect(!(unsignedLhs != unsignedLhs))
            #expect(unsignedRhs == unsignedRhs)
            #expect(!(unsignedRhs != unsignedRhs))
            #expect(unsignedLhs != unsignedRhs)
            #expect(!(unsignedLhs == unsignedRhs))

            #expect(unsignedLhs.asUInt128 == lhs)
            #expect(unsignedRhs.asUInt128 == rhs)
            #expect(unsignedLhs.asUInt128 != rhs)
            #expect(unsignedRhs.asUInt128 != lhs)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify comparison-operators against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let unsignedLhs = UnsignedInteger128(lhs)
            let unsignedRhs = UnsignedInteger128(rhs)

            #expect(unsignedLhs <= unsignedLhs)
            #expect(!(unsignedLhs < unsignedLhs))
            #expect(unsignedRhs <= unsignedRhs)
            #expect(!(unsignedRhs < unsignedRhs))

            #expect((unsignedLhs < unsignedRhs) == (lhs < rhs))
            #expect((unsignedLhs <= unsignedRhs) == (lhs <= rhs))
            #expect((unsignedLhs > unsignedRhs) == (lhs > rhs))
            #expect((unsignedLhs >= unsignedRhs) == (lhs >= rhs))
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify not-operator against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = ~lhs
            let unsignedInteger128 = ~UnsignedInteger128(lhs)
            #expect(uint128 == unsignedInteger128.asUInt128)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify or-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs | rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) | UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                var uint128 = lhs
                uint128 |= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 |= UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128.asUInt128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify and-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs & rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) & UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                var uint128 = lhs
                uint128 &= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 &= UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128.asUInt128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify xor-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs ^ rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) ^ UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                var uint128 = lhs
                uint128 ^= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 ^= UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128.asUInt128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify left bit-shift against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs << rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) << rhs
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                let uint128 = lhs &<< rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) &<< rhs
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                var uint128 = lhs
                uint128 <<= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 <<= rhs
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                var uint128 = lhs
                uint128 &<<= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 &<<= rhs
                #expect(uint128 == unsignedInteger128.asUInt128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify right bit-shift against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs >> rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) >> rhs
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                let uint128 = lhs &>> rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) &>> rhs
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                var uint128 = lhs
                uint128 >>= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 >>= rhs
                #expect(uint128 == unsignedInteger128.asUInt128)
            }

            do {
                var uint128 = lhs
                uint128 &>>= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 &>>= rhs
                #expect(uint128 == unsignedInteger128.asUInt128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    private func generateRandomUInt128Pairs(
        range: ClosedRange<UInt128> = .min ... .max
    ) -> some Sequence<(UInt128, UInt128)> {
        typealias UInt128Pair = (UInt128, UInt128)
        let randomPairs: [UInt128Pair] = (0..<10_000).map { _ in
            (UInt128.random(in: range), UInt128.random(in: range))
        }
        let zeros1: [UInt128Pair] = (0..<100).map { _ in
            (0, UInt128.random(in: range))
        }
        let zeros2: [UInt128Pair] = (0..<100).map { _ in
            (UInt128.random(in: range), 0)
        }
        let zeros3: [UInt128Pair] = [(0, 0)]
        let edgeCases: [UInt128Pair] = [
            (0, .max), (.max, 0),
            (.max, .max),
            (.max, .max - 1), (.max - 1, .max),
            (1, .max), (.max, 1),
        ]
        let result: [UInt128Pair] =
            if range.contains(.max), range.contains(.min) {
                randomPairs + zeros1 + zeros2 + zeros3 + edgeCases
            } else {
                randomPairs + zeros1 + zeros2 + zeros3
            }
        return result
    }

    @available(SwiftStdlib 6.0, *)
    private func generateRandomUInt128s() -> some Sequence<UInt128> {
        let randomPairs: [UInt128] = (0..<10_000).map { _ in
            UInt128.random(in: .min ... .max)
        }
        let edgeCases: [UInt128] = [0, 1, .max - 1, .max]
        let result = randomPairs + edgeCases
        return result
    }
}

#if os(macOS) || os(Linux)
extension UnsignedInteger128Tests {
    @available(SwiftStdlib 6.0, *)
    @Test func `verify out-of-range integer initializer crash against UInt128`() async {
        await #expect(processExitsWith: .failure) {
            blackHole(UnsignedInteger128(noOptimize(-1 as Int)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(UInt128(noOptimize(-1 as Int)))
        }
    }
}
#endif

@available(SwiftStdlib 6.0, *)
extension UnsignedInteger128 {
    var asUInt128: UInt128 {
        UInt128(_low: self._low, _high: self._high)
    }
}
