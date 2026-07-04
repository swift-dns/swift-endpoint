import Endpoint

extension IPTestCase where IPAddressType == IPv4Address {
    static var stringAndAddress: [Self] {
        [
            IPTestCase(
                "127.0.0.1",
                ip: (IPv4Address(127, 0, 0, 1), "127.0.0.1")
            ),
            IPTestCase(
                "0.0.0.0",
                ip: (IPv4Address(0, 0, 0, 0), "0.0.0.0")
            ),
            IPTestCase(
                "0.0.0.1",
                ip: (IPv4Address(0, 0, 0, 1), "0.0.0.1")
            ),
            IPTestCase(
                "0.0.1.0",
                ip: (IPv4Address(0, 0, 1, 0), "0.0.1.0")
            ),
            IPTestCase(
                "0.1.0.0",
                ip: (IPv4Address(0, 1, 0, 0), "0.1.0.0")
            ),
            IPTestCase(
                "1.0.0.0",
                ip: (IPv4Address(1, 0, 0, 0), "1.0.0.0")
            ),
            IPTestCase(
                "1.1.1.1",
                ip: (IPv4Address(1, 1, 1, 1), "1.1.1.1")
            ),
            IPTestCase(
                "123.251.98.234",
                ip: (IPv4Address(123, 251, 98, 234), "123.251.98.234")
            ),
            IPTestCase(
                "255.255.255.255",
                ip: (IPv4Address(255, 255, 255, 255), "255.255.255.255")
            ),
            IPTestCase(
                "192.168.1.98",
                ip: (IPv4Address(192, 168, 1, 98), "192.168.1.98")
            ),
            IPTestCase(
                "120.102.12.100",
                ip: (IPv4Address(120, 102, 12, 100), "120.102.12.100")
            ),
            IPTestCase("192.168.1.256", ip: nil),
            IPTestCase("192.168.1.", ip: nil),
            IPTestCase("1111.168.1.1", ip: nil),
            IPTestCase("192.168.1.2.3", ip: nil),
            IPTestCase("192.168.1", ip: nil),
            IPTestCase(".168.1.123", ip: nil),
            IPTestCase("168.1.123", ip: nil),
            IPTestCase("-1.168.1.123", ip: nil),
            IPTestCase("1.-168.1.123", ip: nil),
            IPTestCase("1.-168.1.0xaa", ip: nil),
            IPTestCase("1.-168.1.aa", ip: nil),
            IPTestCase("9", ip: nil),
            IPTestCase("9.87", ip: nil),
            IPTestCase("", ip: nil),
            IPTestCase(" ", ip: nil),
            IPTestCase("    ", ip: nil),
            IPTestCase(".", ip: nil),
            IPTestCase("..", ip: nil),
            IPTestCase("...", ip: nil),
            IPTestCase("....", ip: nil),
            IPTestCase(".....", ip: nil),
            IPTestCase("m.a.h.d", ip: nil),
            IPTestCase("m:a:h:d::", ip: nil),
            IPTestCase(" 1.2.3.4", ip: nil),
            IPTestCase("1.2.3.4 ", ip: nil),
            IPTestCase("1.2.3.4\n", ip: nil),
            IPTestCase("1.2.3.4\t", ip: nil),
            IPTestCase("1.2 .3.4", ip: nil),
            IPTestCase("0x7f.0.0.1", ip: nil),
            IPTestCase("0xff.0xff.0xff.0xff", ip: nil),
            IPTestCase("+1.2.3.4", ip: nil),
            IPTestCase("1.2.3.+4", ip: nil),
            IPTestCase("1.2.3.-4", ip: nil),
            IPTestCase("999.999.999.999", ip: nil),
            IPTestCase("1..2.3", ip: nil),
            IPTestCase(
                "1111:2222:3333:4444:5555:6666:7777:8888",
                ip: nil,
                isValidAsOtherIPVersion: true
            ),
            IPTestCase("::1", ip: nil, isValidAsOtherIPVersion: true),
            /// Imported from glibc `resolv/tst-inet_pton.c` and Darwin Libc `tests/inet_pton.c`.
            /// `192.0.2.01`: glibc rejects the leading zero; this library and Apple `inet_pton`
            /// accept it as decimal per RFC 6943. Controversial across libcs.
            IPTestCase(
                "192.0.2.01",
                ip: (IPv4Address(192, 0, 2, 1), "192.0.2.1")
            ),
            IPTestCase(
                "192.0.2.27",
                ip: (IPv4Address(192, 0, 2, 27), "192.0.2.27")
            ),
            IPTestCase(
                "10.20.30.40",
                ip: (IPv4Address(10, 20, 30, 40), "10.20.30.40")
            ),
            IPTestCase(
                "010.020.030.040",
                ip: (IPv4Address(10, 20, 30, 40), "10.20.30.40")
            ),
        ] + Self.boundaryCharacters
    }

    static var idnaStringAndAddress: [Self] {
        [
            /// These all should work based on IDNA.
            /// For example, the weird `1`s in the ip address below is:
            /// 2081          ; mapped     ; 0031          # 1.1  SUBSCRIPT ONE
            ///
            /// IDNA label separators other than U+002E ( . ) FULL STOP, are:
            /// U+FF0E ( ． ) FULLWIDTH FULL STOP
            /// U+3002 ( 。 ) IDEOGRAPHIC FULL STOP
            /// U+FF61 ( ｡ ) HALFWIDTH IDEOGRAPHIC FULL STOP
            ///
            /// Some ignored IDNA unicode scalars that are used below:
            /// U+00AD ( ­ ) SOFT HYPHEN
            /// U+200B ( ​ ) ZERO WIDTH SPACE
            /// U+2064 ( ⁤ ) INVISIBLE PLUS
            ///
            /// Would parse to 192.168.1.98 assuming IDNA-compliant parsing
            IPTestCase(
                "\u{AD}1\u{AD}92.₁₆\u{2064}\u{200B}\u{AD}₈.₁.98\u{AD}",
                ip: (IPv4Address(192, 168, 1, 98), "192.168.1.98")
            ),
            /// Would parse to 192.168.1.98 assuming IDNA-compliant parsing
            IPTestCase(
                "192．168。1｡\u{AD}98",
                ip: (IPv4Address(192, 168, 1, 98), "192.168.1.98")
            ),
            IPTestCase("192.\u{AD}.166.9", ip: nil),
        ]
    }

    private static var boundaryCharacters: [Self] {
        let boundaryBytes: [UInt8] = [
            UInt8(ascii: ".") - 1, UInt8(ascii: ".") + 1,
            UInt8(ascii: "0") - 1, UInt8(ascii: "9") + 1,
        ]
        return boundaryBytes.map { utf8Byte in
            let char = String(UnicodeScalar(utf8Byte))
            return IPTestCase("127.0.\(char).1", ip: nil)
        }
    }
}

extension IPPropertyTestCase where IPAddressType == IPv4Address {
    static var all: [Self] {
        [
            IPPropertyTestCase(IPv4Address(127, 0, 0, 0), "isLoopback", \.isLoopback),
            IPPropertyTestCase(IPv4Address(127, 0, 0, 1), "isLoopback", \.isLoopback),
            IPPropertyTestCase(IPv4Address(127, 128, 9, 22), "isLoopback", \.isLoopback),
            IPPropertyTestCase(IPv4Address(127, 255, 255, 255), "isLoopback", \.isLoopback),
            IPPropertyTestCase(
                IPv4Address(126, 0, 0, 0),
                "!isLoopback",
                { @Sendable in !$0.isLoopback }
            ),
            IPPropertyTestCase(
                IPv4Address(128, 0, 0, 0),
                "!isLoopback",
                { @Sendable in !$0.isLoopback }
            ),
            IPPropertyTestCase(IPv4Address(224, 0, 0, 0), "isMulticast", \.isMulticast),
            IPPropertyTestCase(IPv4Address(239, 255, 255, 255), "isMulticast", \.isMulticast),
            IPPropertyTestCase(IPv4Address(229, 28, 192, 233), "isMulticast", \.isMulticast),
            IPPropertyTestCase(
                IPv4Address(244, 0, 0, 0),
                "!isMulticast",
                { @Sendable in !$0.isMulticast }
            ),
            IPPropertyTestCase(IPv4Address(169, 254, 0, 0), "isLinkLocal", \.isLinkLocal),
            IPPropertyTestCase(IPv4Address(169, 254, 222, 138), "isLinkLocal", \.isLinkLocal),
            IPPropertyTestCase(IPv4Address(169, 254, 255, 255), "isLinkLocal", \.isLinkLocal),
            IPPropertyTestCase(
                IPv4Address(169, 253, 0, 0),
                "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
            IPPropertyTestCase(
                IPv4Address(169, 255, 0, 0),
                "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
            IPPropertyTestCase(
                IPv4Address(168, 254, 0, 0),
                "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
            IPPropertyTestCase(
                IPv4Address(170, 254, 0, 0),
                "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
        ]
    }
}
