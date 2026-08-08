import Endpoint

extension IPv4AddressTestCase {
    static let stringAndAddress: [Self] =
        Self.hardcodedStringAndAddress + Self.boundaryCharacters

    private static let hardcodedStringAndAddress: [Self] = [
        IPv4AddressTestCase("127.0.0.1", ip: (IPv4Address(127, 0, 0, 1), "127.0.0.1")),
        IPv4AddressTestCase("0.0.0.0", ip: (IPv4Address(0, 0, 0, 0), "0.0.0.0")),
        IPv4AddressTestCase("0.0.0.1", ip: (IPv4Address(0, 0, 0, 1), "0.0.0.1")),
        IPv4AddressTestCase("0.0.1.0", ip: (IPv4Address(0, 0, 1, 0), "0.0.1.0")),
        IPv4AddressTestCase("0.1.0.0", ip: (IPv4Address(0, 1, 0, 0), "0.1.0.0")),
        IPv4AddressTestCase("1.0.0.0", ip: (IPv4Address(1, 0, 0, 0), "1.0.0.0")),
        IPv4AddressTestCase("1.1.1.1", ip: (IPv4Address(1, 1, 1, 1), "1.1.1.1")),
        IPv4AddressTestCase(
            "123.251.98.234",
            ip: (IPv4Address(123, 251, 98, 234), "123.251.98.234")
        ),
        IPv4AddressTestCase(
            "255.255.255.255",
            ip: (IPv4Address(255, 255, 255, 255), "255.255.255.255")
        ),
        IPv4AddressTestCase("192.168.1.98", ip: (IPv4Address(192, 168, 1, 98), "192.168.1.98")),
        IPv4AddressTestCase(
            "120.102.12.100",
            ip: (IPv4Address(120, 102, 12, 100), "120.102.12.100")
        ),
        IPv4AddressTestCase("192.168.1.256", ip: nil),
        IPv4AddressTestCase("192.168.1.", ip: nil),
        IPv4AddressTestCase("1111.168.1.1", ip: nil),
        IPv4AddressTestCase("192.168.1.2.3", ip: nil),
        IPv4AddressTestCase("192.168.1", ip: nil),
        IPv4AddressTestCase(".168.1.123", ip: nil),
        IPv4AddressTestCase("168.1.123", ip: nil),
        IPv4AddressTestCase("-1.168.1.123", ip: nil),
        IPv4AddressTestCase("1.-168.1.123", ip: nil),
        IPv4AddressTestCase("1.-168.1.0xaa", ip: nil),
        IPv4AddressTestCase("1.-168.1.aa", ip: nil),
        IPv4AddressTestCase("9", ip: nil),
        IPv4AddressTestCase("9.87", ip: nil),
        IPv4AddressTestCase("", ip: nil),
        IPv4AddressTestCase(" ", ip: nil),
        IPv4AddressTestCase("    ", ip: nil),
        IPv4AddressTestCase(".", ip: nil),
        IPv4AddressTestCase("..", ip: nil),
        IPv4AddressTestCase("...", ip: nil),
        IPv4AddressTestCase("....", ip: nil),
        IPv4AddressTestCase(".....", ip: nil),
        IPv4AddressTestCase("m.a.h.d", ip: nil),
        IPv4AddressTestCase("m:a:h:d::", ip: nil),
        IPv4AddressTestCase(" 1.2.3.4", ip: nil),
        IPv4AddressTestCase("1.2.3.4 ", ip: nil),
        IPv4AddressTestCase("1.2.3.4\n", ip: nil),
        IPv4AddressTestCase("1.2.3.4\t", ip: nil),
        IPv4AddressTestCase("1.2 .3.4", ip: nil),
        IPv4AddressTestCase("0x7f.0.0.1", ip: nil),
        IPv4AddressTestCase("0xff.0xff.0xff.0xff", ip: nil),
        IPv4AddressTestCase("+1.2.3.4", ip: nil),
        IPv4AddressTestCase("1.2.3.+4", ip: nil),
        IPv4AddressTestCase("1.2.3.-4", ip: nil),
        IPv4AddressTestCase("999.999.999.999", ip: nil),
        IPv4AddressTestCase("1..2.3", ip: nil),
        IPv4AddressTestCase(
            "1111:2222:3333:4444:5555:6666:7777:8888",
            ip: nil,
            isValidAsOtherIPVersion: true
        ),
        IPv4AddressTestCase("::1", ip: nil, isValidAsOtherIPVersion: true),
        /// Imported from glibc `resolv/tst-inet_pton.c` and Darwin Libc `tests/inet_pton.c`.
        /// `192.0.2.01`: glibc rejects the leading zero; this library and Apple `inet_pton`
        /// accept it as decimal per RFC 6943. Controversial across libcs.
        IPv4AddressTestCase("192.0.2.01", ip: (IPv4Address(192, 0, 2, 1), "192.0.2.1")),
        IPv4AddressTestCase("192.0.2.27", ip: (IPv4Address(192, 0, 2, 27), "192.0.2.27")),
        IPv4AddressTestCase("10.20.30.40", ip: (IPv4Address(10, 20, 30, 40), "10.20.30.40")),
        IPv4AddressTestCase("010.020.030.040", ip: (IPv4Address(10, 20, 30, 40), "10.20.30.40")),
        /// A fourth digit is rejected even when the padding digits are all zeros.
        IPv4AddressTestCase("0000.1.2.3", ip: nil),
        IPv4AddressTestCase("1.0000.2.3", ip: nil),
        IPv4AddressTestCase("1.2.0000.3", ip: nil),
        IPv4AddressTestCase("1.2.3.0000", ip: nil),
        IPv4AddressTestCase("0255.1.2.3", ip: nil),
        IPv4AddressTestCase("1.2.3.0255", ip: nil),
        IPv4AddressTestCase("0000.0000.0000.0000", ip: nil),
    ]

    static let idnaStringAndAddress: [Self] = [
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
        IPv4AddressTestCase(
            "\u{AD}1\u{AD}92.₁₆\u{2064}\u{200B}\u{AD}₈.₁.98\u{AD}",
            ip: (IPv4Address(192, 168, 1, 98), "192.168.1.98")
        ),
        /// Would parse to 192.168.1.98 assuming IDNA-compliant parsing
        IPv4AddressTestCase(
            "192．168。1｡\u{AD}98",
            ip: (IPv4Address(192, 168, 1, 98), "192.168.1.98")
        ),
        IPv4AddressTestCase("192.\u{AD}.166.9", ip: nil),
    ]

    private static let boundaryCharacters: [Self] = [
        UInt8(ascii: ".") - 1, UInt8(ascii: ".") + 1,
        UInt8(ascii: "0") - 1, UInt8(ascii: "9") + 1,
    ].map { utf8Byte in
        let char = String(UnicodeScalar(utf8Byte))
        return IPv4AddressTestCase("127.0.\(char).1", ip: nil)
    }
}

extension IPPropertyTestCase where IPAddressType == IPv4Address {
    static let all: [Self] = [
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
        IPPropertyTestCase(IPv4Address(0, 0, 0, 0), "isUnspecified", \.isUnspecified),
        IPPropertyTestCase(
            IPv4Address(0, 0, 0, 1),
            "!isUnspecified",
            { @Sendable in !$0.isUnspecified }
        ),
        IPPropertyTestCase(IPv4Address(255, 255, 255, 255), "isBroadcast", \.isBroadcast),
        IPPropertyTestCase(
            IPv4Address(255, 255, 255, 254),
            "!isBroadcast",
            { @Sendable in !$0.isBroadcast }
        ),
        IPPropertyTestCase(IPv4Address(10, 0, 0, 0), "isPrivate", \.isPrivate),
        IPPropertyTestCase(IPv4Address(10, 255, 255, 255), "isPrivate", \.isPrivate),
        IPPropertyTestCase(IPv4Address(172, 16, 0, 0), "isPrivate", \.isPrivate),
        IPPropertyTestCase(IPv4Address(172, 31, 255, 255), "isPrivate", \.isPrivate),
        IPPropertyTestCase(IPv4Address(192, 168, 0, 0), "isPrivate", \.isPrivate),
        IPPropertyTestCase(IPv4Address(192, 168, 255, 255), "isPrivate", \.isPrivate),
        IPPropertyTestCase(
            IPv4Address(9, 255, 255, 255),
            "!isPrivate",
            { @Sendable in !$0.isPrivate }
        ),
        IPPropertyTestCase(IPv4Address(11, 0, 0, 0), "!isPrivate", { @Sendable in !$0.isPrivate }),
        IPPropertyTestCase(
            IPv4Address(172, 15, 255, 255),
            "!isPrivate",
            { @Sendable in !$0.isPrivate }
        ),
        IPPropertyTestCase(
            IPv4Address(172, 32, 0, 0),
            "!isPrivate",
            { @Sendable in !$0.isPrivate }
        ),
        IPPropertyTestCase(
            IPv4Address(192, 167, 0, 0),
            "!isPrivate",
            { @Sendable in !$0.isPrivate }
        ),
        IPPropertyTestCase(
            IPv4Address(192, 169, 0, 0),
            "!isPrivate",
            { @Sendable in !$0.isPrivate }
        ),
        IPPropertyTestCase(IPv4Address(100, 64, 0, 0), "isShared", \.isShared),
        IPPropertyTestCase(IPv4Address(100, 127, 255, 255), "isShared", \.isShared),
        IPPropertyTestCase(
            IPv4Address(100, 63, 255, 255),
            "!isShared",
            { @Sendable in !$0.isShared }
        ),
        IPPropertyTestCase(IPv4Address(100, 128, 0, 0), "!isShared", { @Sendable in !$0.isShared }),
        IPPropertyTestCase(IPv4Address(192, 0, 2, 0), "isDocumentation", \.isDocumentation),
        IPPropertyTestCase(IPv4Address(192, 0, 2, 255), "isDocumentation", \.isDocumentation),
        IPPropertyTestCase(IPv4Address(198, 51, 100, 7), "isDocumentation", \.isDocumentation),
        IPPropertyTestCase(IPv4Address(203, 0, 113, 200), "isDocumentation", \.isDocumentation),
        IPPropertyTestCase(
            IPv4Address(192, 0, 3, 0),
            "!isDocumentation",
            { @Sendable in !$0.isDocumentation }
        ),
        IPPropertyTestCase(
            IPv4Address(198, 51, 101, 0),
            "!isDocumentation",
            { @Sendable in !$0.isDocumentation }
        ),
        IPPropertyTestCase(
            IPv4Address(203, 0, 112, 0),
            "!isDocumentation",
            { @Sendable in !$0.isDocumentation }
        ),
        IPPropertyTestCase(IPv4Address(0, 0, 0, 0), "isContiguous", \.isContiguous),
        IPPropertyTestCase(IPv4Address(255, 0, 0, 0), "isContiguous", \.isContiguous),
        IPPropertyTestCase(IPv4Address(255, 255, 192, 0), "isContiguous", \.isContiguous),
        IPPropertyTestCase(IPv4Address(255, 255, 255, 255), "isContiguous", \.isContiguous),
        IPPropertyTestCase(
            IPv4Address(0, 255, 0, 0),
            "!isContiguous",
            { @Sendable in !$0.isContiguous }
        ),
        IPPropertyTestCase(
            IPv4Address(255, 0, 0, 255),
            "!isContiguous",
            { @Sendable in !$0.isContiguous }
        ),
        IPPropertyTestCase(
            IPv4Address(254, 255, 0, 0),
            "!isContiguous",
            { @Sendable in !$0.isContiguous }
        ),
        IPPropertyTestCase(
            IPv4Address(0, 0, 0, 1),
            "!isContiguous",
            { @Sendable in !$0.isContiguous }
        ),
    ]
}
