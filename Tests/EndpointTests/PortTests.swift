import Endpoint
import Testing

@Suite
struct PortTests {
    @Test func port() {
        /// Use non-literal `Int`s so the `init(_ value: Int)` overload is exercised
        /// instead of `init(integerLiteral:)`.
        let low = 0
        let high = 65535
        #expect(Port(low) == Port(canonicalValue: 0))
        #expect(Port(high) == Port(canonicalValue: 65535))
        #expect(Port(low).value == 0)
        #expect(Port(high).value == 65535)
        #expect(Port(canonicalValue: 443).value == 443)
    }

    @Test(
        arguments: [(port: Port, expected: [UInt8])]([
            (port: Port(canonicalValue: 0), expected: [0x00, 0x00]),
            (port: Port(canonicalValue: 1), expected: [0x00, 0x01]),
            (port: Port(canonicalValue: 2), expected: [0x00, 0x02]),
            (port: Port(canonicalValue: 7936), expected: [0x1F, 0x00]),
            (port: Port(canonicalValue: 8080), expected: [0x1F, 0x90]),
            (port: Port(canonicalValue: 8081), expected: [0x1F, 0x91]),
            (port: Port(canonicalValue: 8082), expected: [0x1F, 0x92]),
            (port: Port(canonicalValue: 8083), expected: [0x1F, 0x93]),
            (port: Port(canonicalValue: 8084), expected: [0x1F, 0x94]),
            (port: Port(canonicalValue: 8085), expected: [0x1F, 0x95]),
            (port: Port(canonicalValue: 65534), expected: [0xFF, 0xFE]),
            (port: Port(canonicalValue: 65535), expected: [0xFF, 0xFF]),
        ])
    )
    func `Port serialize parse happy-path with span works correctly`(
        port: Port,
        expected: [UInt8]
    ) throws {
        let bufferPointer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 20)
        defer { unsafe bufferPointer.deallocate() }
        var outputSpan = unsafe OutputSpan(buffer: bufferPointer, initializedCount: 0)

        let didSerialize = port.serialize(into: &outputSpan)

        #expect(didSerialize)
        #expect(outputSpan.capacity == 20)
        #expect(outputSpan.freeCapacity == 18)
        #expect(outputSpan.count == 2)
        outputSpan.span.withUnsafeBytes { ptr in
            let data = unsafe [UInt8](ptr)
            #expect(data == expected)
        }

        let _parsedPort = Port(parsing: outputSpan.span)
        let parsedPort = try #require(_parsedPort)
        #expect(parsedPort == port)
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `Port span parsing and serialization reject spans that are too small`() {
        let bytes: [UInt8] = [0x1F]
        #expect(Port(parsing: bytes.span) == nil)

        let bufferPointer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 1)
        defer { unsafe bufferPointer.deallocate() }
        var outputSpan = unsafe OutputSpan(buffer: bufferPointer, initializedCount: 0)
        let didSerialize = Port(canonicalValue: 8080).serialize(into: &outputSpan)
        #expect(!didSerialize)
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `Port description and parsing work as expected`() {
        for number in UInt16.min...UInt16.max {
            let port = Port(canonicalValue: number)
            let description = port.description
            #expect(port.description == description)
            #expect(Port(description) == port)
            #expect(Port(Substring(description)) == port)
            #expect(Port(textualRepresentation: description.utf8Span) == port)
            #expect(Port(textualRepresentation: description.utf8Span.span) == port)
            description.withCString { #expect(unsafe Port(cString: $0) == port) }

            let produced = port.withCString { span in
                #expect(span.count == description.utf8.count + 1)
                return span.withUnsafeBufferPointer {
                    unsafe String(cString: $0.baseAddress!)
                }
            }
            #expect(produced == description)
        }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: [String]([
            "",
            " ",
            "-1",
            "+1",
            "65536",
            "99999",
            "123456",
            "000000",
            "0x10",
            "80 ",
            " 80",
            "8_0",
            "8.0",
            "٨٠",
        ])
    )
    func `Port rejects invalid textual representations`(description: String) {
        #expect(Port(description) == nil)
        #expect(Port(Substring(description)) == nil)
        #expect(Port(textualRepresentation: description.utf8Span) == nil)
        #expect(Port(textualRepresentation: description.utf8Span.span) == nil)
        description.withCString { #expect(unsafe Port(cString: $0) == nil) }
    }

    @available(SwiftStdlib 6.2, *)
    @Test(
        arguments: [(description: String, port: Port?)]([
            (description: "0", port: 0),
            (description: "00", port: 0),
            (description: "000", port: 0),
            (description: "0000", port: 0),
            (description: "00000", port: 0),
            (description: "01", port: 1),
            (description: "080", port: 80),
            (description: "00080", port: 80),
            (description: "00443", port: 443),
            (description: "065535", port: nil),
            (description: "000000", port: nil),
            (description: "0065535", port: nil),
        ])
    )
    func `Port tolerates leading zeros up to 5 digits`(description: String, port: Port?) {
        #expect(Port(description) == port)
        #expect(Port(Substring(description)) == port)
        #expect(Port(textualRepresentation: description.utf8Span) == port)
        #expect(Port(textualRepresentation: description.utf8Span.span) == port)
        description.withCString { #expect(unsafe Port(cString: $0) == port) }
    }

    @Test func `IANA service ports have the registered values`() {
        #expect(Port.discard == 9)
        #expect(Port.`ftp-data` == 20)
        #expect(Port.ftp == 21)
        #expect(Port.ssh == 22)
        #expect(Port.telnet == 23)
        #expect(Port.http == 80)
        #expect(Port.kerberos == 88)
        #expect(Port.ntp == 123)
        #expect(Port.imap == 143)
        #expect(Port.https == 443)
        #expect(Port.submissions == 465)
        #expect(Port.syslog == 514)
        #expect(Port.submission == 587)
        #expect(Port.ipp == 631)
        #expect(Port.epp == 700)
        #expect(Port.`domain-s` == 853)
        #expect(Port.imaps == 993)
        #expect(Port.pop3s == 995)
        #expect(Port.nfs == 2049)
        #expect(Port.stun == 3478)
        #expect(Port.sip == 5060)
        #expect(Port.mdns == 5353)
        #expect(Port.coap == 5683)
    }

    /// Distinct IANA services sharing one port each get their own property.
    @Test func `IANA services sharing a port each have their own property`() {
        #expect(Port.http == 80)
        #expect(Port.www == 80)
        #expect(Port.https == 443)
        #expect(Port.ipp == 631)
        #expect(Port.ipps == 631)
        #expect(Port.stun == 3478)
        #expect(Port.turn == 3478)
        #expect(Port.`stun-behavior` == 3478)
    }

    @available(SwiftStdlib 6.2, *)
    @Test func `Port description and serialization round-trip exhaustively`() {
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 2)
        defer { unsafe buffer.deallocate() }

        for canonicalValue in UInt16.min...UInt16.max {
            let port = Port(canonicalValue: canonicalValue)

            let description = port.description
            #expect(description == String(canonicalValue))
            #expect(Port(description) == port)

            let viaCString = port.withCString { span in
                span.withUnsafeBufferPointer { unsafe Port(cString: $0.baseAddress!) }
            }
            #expect(viaCString == port)

            var outputSpan = unsafe OutputSpan(buffer: buffer, initializedCount: 0)
            let didSerialize = port.serialize(into: &outputSpan)
            #expect(didSerialize)
            #expect(Port(parsing: outputSpan.span) == port)
        }
    }
}

#if os(macOS) || os(Linux)
extension PortTests {
    @Test func `Port initializer crashes when the value is out of bounds`() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Port(noOptimize(-1)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Port(noOptimize(65536)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Port(noOptimize(Int.min)))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Port(noOptimize(Int.max)))
        }
    }
}
#endif
