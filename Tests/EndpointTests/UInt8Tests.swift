import IPAddress
import Testing

@Suite
struct UInt8Tests {
    @Test func `UInt8 asDecimal works correctly`() {
        for number in (UInt8(0)...UInt8(255)) {
            withUnsafeTemporaryAllocation(byteCount: 4, alignment: 1) { buffer in
                let (paddedBytes, count) = number.asDecimal()
                unsafe buffer.storeBytes(of: paddedBytes, toByteOffset: 0, as: UInt32.self)
                let string = unsafe String(decoding: buffer[1...count], as: UTF8.self)
                #expect(string == String(number))
            }
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `UInt8 from-decimal-span initializer works for numbers 0...255`() {
        for number in (UInt8(0)...UInt8(255)) {
            let string = String(number)
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == number)
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `UInt8 from-decimal-span initializer fails for negative numbers -255...-0`() {
        for number in (UInt8(0)...UInt8(255)) {
            let string = "-" + String(number)
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == nil)
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `UInt8 from-decimal-span initializer fails for numbers 256...309`() {
        for number in 256..<310 {
            let string = String(number)
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == nil)
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `UInt8 from-decimal-span initializer fails for numbers 1000...1233`() {
        for number in 1000..<1234 {
            let string = String(number)
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == nil)
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `UInt8 from-decimal-span initializer fails for invalid strings`() {
        for string in ["hello", "hi there", "新华网.中国", "中国"] {
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == nil)
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `mapHexadecimalByteToUInt8 works correctly`() {
        for byte in (UInt8(0)...UInt8(255)) {
            let expected: UInt8?
            switch byte {
            case UInt8(ascii: "0")...UInt8(ascii: "9"):
                expected = byte &- UInt8(ascii: "0")
            case UInt8(ascii: "a")...UInt8(ascii: "f"):
                expected = byte &- UInt8(ascii: "a") &+ 10
            case UInt8(ascii: "A")...UInt8(ascii: "F"):
                expected = byte &- UInt8(ascii: "A") &+ 10
            default:
                expected = nil
            }

            #expect(UInt8.mapHexadecimalByteToUInt8(byte) == expected)
        }
    }
}
