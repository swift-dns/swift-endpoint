import IPAddress
import Testing

@Suite
struct UnsignedInt128Tests {
    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify static properties against UInt128`() {
        #expect(UnsignedInt128.bitWidth == UInt128.bitWidth)
        #expect(UnsignedInt128.max == UInt128.max)
        #expect(UnsignedInt128.min == UInt128.min)
        #expect(UnsignedInt128.zero == UInt128.zero)
        #expect(UnsignedInt128.isSigned == UInt128.isSigned)
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify addition against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.addingReportingOverflow(rhs)
            let unsignedInt128 = UnsignedInt128(lhs).addingReportingOverflow(UnsignedInt128(rhs))
            #expect(uint128.partialValue == unsignedInt128.partialValue)
            #expect(uint128.overflow == unsignedInt128.overflow)

            do {
                let uint128 = lhs &+ rhs
                let unsignedInt128 = UnsignedInt128(lhs) &+ UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &+= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &+= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            if !uint128.overflow, !unsignedInt128.overflow {
                do {
                    let uint128 = lhs + rhs
                    let unsignedInt128 = UnsignedInt128(lhs) + UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }

                do {
                    var uint128 = lhs
                    uint128 += rhs
                    var unsignedInt128 = UnsignedInt128(lhs)
                    unsignedInt128 += UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify subtraction against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.subtractingReportingOverflow(rhs)
            let unsignedInt128 = UnsignedInt128(lhs).subtractingReportingOverflow(
                UnsignedInt128(rhs)
            )
            #expect(uint128.partialValue == unsignedInt128.partialValue)
            #expect(uint128.overflow == unsignedInt128.overflow)

            do {
                let uint128 = lhs &- rhs
                let unsignedInt128 = UnsignedInt128(lhs) &- UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &-= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &-= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            if !uint128.overflow, !unsignedInt128.overflow {
                do {
                    let uint128 = lhs - rhs
                    let unsignedInt128 = UnsignedInt128(lhs) - UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }

                do {
                    var uint128 = lhs
                    uint128 -= rhs
                    var unsignedInt128 = UnsignedInt128(lhs)
                    unsignedInt128 -= UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify multiplication against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.multipliedReportingOverflow(by: rhs)
            let unsignedInt128 = UnsignedInt128(lhs).multipliedReportingOverflow(
                by: UnsignedInt128(rhs)
            )
            #expect(uint128.partialValue == unsignedInt128.partialValue)
            #expect(uint128.overflow == unsignedInt128.overflow)

            do {
                let uint128 = lhs &* rhs
                let unsignedInt128 = UnsignedInt128(lhs) &* UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &*= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &*= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            if !uint128.overflow, !unsignedInt128.overflow {
                do {
                    let uint128 = lhs * rhs
                    let unsignedInt128 = UnsignedInt128(lhs) * UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }

                do {
                    var uint128 = lhs
                    uint128 *= rhs
                    var unsignedInt128 = UnsignedInt128(lhs)
                    unsignedInt128 *= UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify division against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.dividedReportingOverflow(by: rhs)
            let unsignedInt128 = UnsignedInt128(lhs).dividedReportingOverflow(
                by: UnsignedInt128(rhs)
            )
            #expect(uint128.partialValue == unsignedInt128.partialValue)
            #expect(uint128.overflow == unsignedInt128.overflow)

            if !uint128.overflow, !unsignedInt128.overflow {
                do {
                    let uint128 = lhs / rhs
                    let unsignedInt128 = UnsignedInt128(lhs) / UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }

                do {
                    var uint128 = lhs
                    uint128 /= rhs
                    var unsignedInt128 = UnsignedInt128(lhs)
                    unsignedInt128 /= UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify not-operator against UInt128`() {
        for (lhs, _) in generateRandomUInt128Pairs() {
            let uint128 = ~lhs
            let unsignedInt128 = ~UnsignedInt128(lhs)
            #expect(uint128 == unsignedInt128)
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify or-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs | rhs
                let unsignedInt128 = UnsignedInt128(lhs) | UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 |= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 |= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify and-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs & rhs
                let unsignedInt128 = UnsignedInt128(lhs) & UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify xor-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs ^ rhs
                let unsignedInt128 = UnsignedInt128(lhs) ^ UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 ^= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 ^= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify left bit-shift against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs << rhs
                let unsignedInt128 = UnsignedInt128(lhs) << UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                let uint128 = lhs << rhs
                let unsignedInt128 = UnsignedInt128(lhs) << UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 <<= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 <<= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &<<= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &<<= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify right bit-shift against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs >> rhs
                let unsignedInt128 = UnsignedInt128(lhs) >> UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                let uint128 = lhs >> rhs
                let unsignedInt128 = UnsignedInt128(lhs) >> UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 >>= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 >>= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &>>= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &>>= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test bitWidth against UInt128`(lhs: UInt128, _: UInt128) {
    //     let uint128 = lhs.bitWidth
    //     let unsignedInt128 = UnsignedInt128(lhs).bitWidth
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test trailingZeroBitCount against UInt128`(lhs: UInt128, _: UInt128) {
    //     let uint128 = lhs.trailingZeroBitCount
    //     let unsignedInt128 = UnsignedInt128(lhs).trailingZeroBitCount
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test / against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     let uint128 = lhs / rhs
    //     let unsignedInt128 = UnsignedInt128(lhs) / UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test % against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     let uint128 = lhs % rhs
    //     let unsignedInt128 = UnsignedInt128(lhs) % UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test %= against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     var uint128 = lhs
    //     uint128 %= rhs
    //     var unsignedInt128 = UnsignedInt128(lhs)
    //     unsignedInt128 %= UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test * against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     let uint128 = lhs % rhs
    //     let unsignedInt128 = UnsignedInt128(lhs) % UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test &= against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     let uint128 = lhs % rhs
    //     let unsignedInt128 = UnsignedInt128(lhs) % UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test |= against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     var uint128 = lhs
    //     uint128 |= rhs
    //     var unsignedInt128 = UnsignedInt128(lhs)
    //     unsignedInt128 |= UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test ^= against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     var uint128 = lhs
    //     uint128 ^= rhs
    //     var unsignedInt128 = UnsignedInt128(lhs)
    //     unsignedInt128 ^= UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test magnitude against UInt128`(lhs: UInt128, _: UInt128) {
    //     let uint128 = lhs.magnitude
    //     let unsignedInt128 = UnsignedInt128(lhs).magnitude
    //     #expect(uint128 == unsignedInt128)
    // }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify init(_ description: String) against UInt128`() throws {
        for (lhs, _) in generateRandomUInt128Pairs() {
            let uint128 = try #require(UInt128(lhs.description))
            let unsignedInt128 = try #require(UnsignedInt128(lhs.description))
            #expect(uint128 == unsignedInt128)
            #expect(uint128 == lhs)
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    private func generateRandomUInt128Pairs() -> some Sequence<(UInt128, UInt128)> {
        (0..<100_000).map { _ in
            (UInt128.random(in: .min ... .max), UInt128.random(in: .min ... .max))
        }[0...10]
    }
}
