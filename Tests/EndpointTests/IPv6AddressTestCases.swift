import Endpoint

extension IPTestCase where IPAddressType == IPv6Address {
    @available(SwiftStdlib 6.0, *)
    static var stringAndAddress: [Self] {
        [
            IPTestCase(
                "1111:2222:3333:4444:5555:6666:7777:8888",
                address: 0x1111_2222_3333_4444_5555_6666_7777_8888,
                canonicalDescription: "[1111:2222:3333:4444:5555:6666:7777:8888]"
            ),
            IPTestCase(
                "[FF::]",
                address: 0x00FF_0000_0000_0000_0000_0000_0000_0000,
                canonicalDescription: "[ff::]"
            ),
            IPTestCase(
                "[::FF]",
                address: 0x0000_0000_0000_0000_0000_0000_0000_00FF,
                canonicalDescription: "[::ff]"
            ),
            IPTestCase(
                "[0:FF::]",
                address: 0x0000_00FF_0000_0000_0000_0000_0000_0000,
                canonicalDescription: "[0:ff::]"
            ),
            IPTestCase(
                "[2001:db8:85a3::100]",
                address: 0x2001_0DB8_85A3_0000_0000_0000_0000_0100,
                canonicalDescription: "[2001:db8:85a3::100]"
            ),
            IPTestCase(
                "2001:db8:85a3::100",
                address: 0x2001_0DB8_85A3_0000_0000_0000_0000_0100,
                canonicalDescription: "[2001:db8:85a3::100]"
            ),
            IPTestCase(
                "[2001:db8:85a0::100]",
                address: 0x2001_0DB8_85A0_0000_0000_0000_0000_0100,
                canonicalDescription: "[2001:db8:85a0::100]"
            ),
            IPTestCase(
                "[2001:db8:8503::100]",
                address: 0x2001_0DB8_8503_0000_0000_0000_0000_0100,
                canonicalDescription: "[2001:db8:8503::100]"
            ),
            IPTestCase(
                "[2001:db8:80a3::100]",
                address: 0x2001_0DB8_80A3_0000_0000_0000_0000_0100,
                canonicalDescription: "[2001:db8:80a3::100]"
            ),
            IPTestCase(
                "[2001:db8::1:0:0:2]",
                address: 0x2001_0DB8_0000_0000_0001_0000_0000_0002,
                canonicalDescription: "[2001:db8::1:0:0:2]"
            ),
            IPTestCase(
                "[2001:db8:1111:2222:3333:4444::]",
                address: 0x2001_0DB8_1111_2222_3333_4444_0000_0000,
                canonicalDescription: "[2001:db8:1111:2222:3333:4444::]"
            ),
            IPTestCase(
                "[2001:db8:1111:2222:3333:4444:5555:6666]",
                address: 0x2001_0DB8_1111_2222_3333_4444_5555_6666,
                canonicalDescription: "[2001:db8:1111:2222:3333:4444:5555:6666]"
            ),
            IPTestCase(
                "[2001:db8:1111:2222:3333:4444:5555:0]",
                address: 0x2001_0DB8_1111_2222_3333_4444_5555_0000,
                canonicalDescription: "[2001:db8:1111:2222:3333:4444:5555:0]"
            ),
            IPTestCase(
                "[2001:DB8:1111:2222:0:3333:4444:5555]",
                address: 0x2001_0DB8_1111_2222_0000_3333_4444_5555,
                canonicalDescription: "[2001:db8:1111:2222:0:3333:4444:5555]"
            ),
            IPTestCase(
                "[2001::1:0:0:2]",
                address: 0x2001_0000_0000_0000_0001_0000_0000_0002,
                canonicalDescription: "[2001::1:0:0:2]"
            ),
            IPTestCase(
                "2001::1:0:0:2",
                address: 0x2001_0000_0000_0000_0001_0000_0000_0002,
                canonicalDescription: "[2001::1:0:0:2]"
            ),
            IPTestCase(
                "[2001:0:0:1::2]",
                address: 0x2001_0000_0000_0001_0000_0000_0000_0002,
                canonicalDescription: "[2001:0:0:1::2]"
            ),
            IPTestCase(
                "[2001:db8:aaaa:bbbb:cccc:DDDD:eeee:1]",
                address: 0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001,
                canonicalDescription: "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]"
            ),
            IPTestCase(
                "2001:db8:aaaa:BBBB:cccc:dddd:eeee:1",
                address: 0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001,
                canonicalDescription: "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]"
            ),
            IPTestCase(
                "01:db8:a0a:bb:cc0:0dd0:ee:1",
                address: 0x0001_0DB8_0A0A_00BB_0CC0_0DD0_00EE_0001,
                canonicalDescription: "[1:db8:a0a:bb:cc0:dd0:ee:1]"
            ),
            IPTestCase(
                "[2001:db8::1:0:0:2]",
                address: 0x2001_0DB8_0000_0000_0001_0000_0000_0002,
                canonicalDescription: "[2001:db8::1:0:0:2]"
            ),
            IPTestCase(
                "[::]",
                address: 0x0000_0000_0000_0000_0000_0000_0000_0000,
                canonicalDescription: "[::]"
            ),
            IPTestCase(
                "::",
                address: 0x0000_0000_0000_0000_0000_0000_0000_0000,
                canonicalDescription: "[::]"
            ),
            IPTestCase(
                "[2001:0:0:1::]",
                address: 0x2001_0000_0000_0001_0000_0000_0000_0000,
                canonicalDescription: "[2001:0:0:1::]"
            ),
            IPTestCase(
                "[::1:0:0:2]",
                address: 0x0000_0000_0000_0000_0001_0000_0000_0002,
                canonicalDescription: "[::1:0:0:2]"
            ),
            IPTestCase(
                "[::1:2:3:0:4:5]",
                address: 0x0000_0000_0001_0002_0003_0000_0004_0005,
                canonicalDescription: "[::1:2:3:0:4:5]"
            ),
            IPTestCase(
                "[::1:0:0:1:0:0]",
                address: 0x0000_0000_0001_0000_0000_0001_0000_0000,
                canonicalDescription: "[::1:0:0:1:0:0]"
            ),
            IPTestCase(
                "[1:0:1::1:0]",
                address: 0x0001_0000_0001_0000_0000_0000_0001_0000,
                canonicalDescription: "[1:0:1::1:0]"
            ),
            IPTestCase(
                "[0:1:2:3:4:0:5:6]",
                address: 0x0000_0001_0002_0003_0004_0000_0005_0006,
                canonicalDescription: "[0:1:2:3:4:0:5:6]"
            ),
            IPTestCase(
                "[0:1:2:3:4:0:5:f]",
                address: 0x0000_0001_0002_0003_0004_0000_0005_000F,
                canonicalDescription: "[0:1:2:3:4:0:5:f]"
            ),
            IPTestCase(
                "0:1:2:3:4:0:5:6",
                address: 0x0000_0001_0002_0003_0004_0000_0005_0006,
                canonicalDescription: "[0:1:2:3:4:0:5:6]"
            ),
            IPTestCase(
                "[::1]",
                address: 0x0000_0000_0000_0000_0000_0000_0000_0001,
                canonicalDescription: "[::1]"
            ),
            IPTestCase(
                "::1",
                address: 0x0000_0000_0000_0000_0000_0000_0000_0001,
                canonicalDescription: "[::1]"
            ),
            IPTestCase(
                "::FFFF:204.152.189.116",
                address: 0x0000_0000_0000_0000_0000_FFFF_CC98_BD74,
                canonicalDescription: "[::ffff:cc98:bd74]"
            ),
            IPTestCase(
                "::FFFF:255.255.255.255",
                address: 0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF,
                canonicalDescription: "[::ffff:ffff:ffff]"
            ),
            IPTestCase(
                "::FFFF:1.1.1.1",
                address: 0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                canonicalDescription: "[::ffff:101:101]"
            ),
            IPTestCase(
                "[::ffff:1.1.1.1]",
                address: 0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                canonicalDescription: "[::ffff:101:101]"
            ),
            IPTestCase(
                "64:ff9b::192.0.2.33",
                address: 0x0064_FF9B_0000_0000_0000_0000_C000_0221,
                canonicalDescription: "[64:ff9b::c000:221]"
            ),
            IPTestCase(
                "[64:ff9b::192.0.2.33]",
                address: 0x0064_FF9B_0000_0000_0000_0000_C000_0221,
                canonicalDescription: "[64:ff9b::c000:221]"
            ),
            IPTestCase(
                "2001:db8:122:344::192.0.2.33",
                address: 0x2001_0DB8_0122_0344_0000_0000_C000_0221,
                canonicalDescription: "[2001:db8:122:344::c000:221]"
            ),
            IPTestCase(
                "::13.1.68.3",
                address: 0x0000_0000_0000_0000_0000_0000_0D01_4403,
                canonicalDescription: "[::d01:4403]"
            ),
            IPTestCase(
                "0:0:1:0:0:FFFF:204.152.189.116",
                address: 0x0000_0000_0001_0000_0000_FFFF_CC98_BD74,
                canonicalDescription: "[::1:0:0:ffff:cc98:bd74]"
            ),
            IPTestCase(
                "0:0:0:0:0:FFFF:204.152.189.116",
                address: 0x0000_0000_0000_0000_0000_FFFF_CC98_BD74,
                canonicalDescription: "[::ffff:cc98:bd74]"
            ),
            IPTestCase(
                "0:0:0:0:0:ffff:255.255.255.255",
                address: 0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF,
                canonicalDescription: "[::ffff:ffff:ffff]"
            ),
            IPTestCase(
                "[0000:0000:0000:0000:0000:FFFF:255.255.255.255]",
                address: 0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF,
                canonicalDescription: "[::ffff:ffff:ffff]"
            ),
            IPTestCase(
                "0:0:0:0:0:FFFF:1.1.1.1",
                address: 0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                canonicalDescription: "[::ffff:101:101]"
            ),
            IPTestCase(
                "0::0:FFFF:1.1.1.1",
                address: 0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                canonicalDescription: "[::ffff:101:101]"
            ),
            IPTestCase(
                "0:0::0:FFFF:1.1.1.1",
                address: 0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                canonicalDescription: "[::ffff:101:101]"
            ),
            IPTestCase("0:0:0:0:0:0:FFFF:1.1.1.1", address: nil),
            IPTestCase("0:0:0:0:FFFF:1.1.1.1:FFFF", address: nil),
            IPTestCase("0:0:0:0:0:1.1.1.1:FFFF", address: nil),
            IPTestCase("::FFFF:1.1.1.1:FFFF", address: nil),
            IPTestCase("::1.1.1.1:FFFF", address: nil),
            IPTestCase(":FFFF:1.1.1.1", address: nil),
            IPTestCase("::FFFF:1.", address: nil),
            IPTestCase("::FFFF:1.1", address: nil),
            IPTestCase("::FFFF:1.1.", address: nil),
            IPTestCase("::FFFF:1.1.1", address: nil),
            IPTestCase("::FFFF:1.1.1.", address: nil),
            IPTestCase(
                "::1.1.1.1",
                address: 0x0000_0000_0000_0000_0000_0000_0101_0101,
                canonicalDescription: "[::101:101]"
            ),
            IPTestCase(".1.1.1.1", address: nil),
            IPTestCase("::FFFF:256.152.189.116", address: nil),
            IPTestCase("[0000:0000:0000:0000:0000:FFFF:255.255.255.1111]", address: nil),
            IPTestCase("::FFFF:204.152.189.116.", address: nil),
            IPTestCase("::FFFF:.204.152.189.116", address: nil),
            IPTestCase("::FFFF::204.152.189.116", address: nil),
            IPTestCase("::FFFF:204.152.189", address: nil),
            IPTestCase("::FFFF:204.152.189.", address: nil),
            IPTestCase("::FFFF:.204.152.189", address: nil),
            IPTestCase("", address: nil),
            IPTestCase(" ", address: nil),
            IPTestCase("    ", address: nil),
            IPTestCase(".", address: nil),
            IPTestCase("..", address: nil),
            IPTestCase("...", address: nil),
            IPTestCase("....", address: nil),
            IPTestCase(".....", address: nil),
            IPTestCase("::FFFF:", address: nil),
            IPTestCase("::FFFF: ", address: nil),
            IPTestCase("::FFFF:    ", address: nil),
            IPTestCase("::FFFF:.", address: nil),
            IPTestCase("::FFFF:..", address: nil),
            IPTestCase("::FFFF:...", address: nil),
            IPTestCase("::FFFF:....", address: nil),
            IPTestCase("::FFFF:.....", address: nil),
            IPTestCase(":", address: nil),
            IPTestCase("[:]", address: nil),
            IPTestCase(":::", address: nil),
            IPTestCase("[:::]", address: nil),
            IPTestCase("::::", address: nil),
            IPTestCase(":::::", address: nil),
            IPTestCase("::::::", address: nil),
            IPTestCase(":::::::", address: nil),
            IPTestCase("[:::::::]", address: nil),
            IPTestCase("::::::::", address: nil),
            IPTestCase(":::::::::", address: nil),
            IPTestCase("::::::::::", address: nil),
            IPTestCase("[::::::::::]", address: nil),
            IPTestCase("[2001:0:0:1:::]", address: nil),
            IPTestCase("[:::2001:0:0:1]", address: nil),
            IPTestCase("[2001:0:0:1::2", address: nil),
            IPTestCase("2001:0:0:1::2]", address: nil),
            IPTestCase("[1::2::]", address: nil),
            IPTestCase("[1::2::3]", address: nil),
            IPTestCase("[:0:1:2:3:4:0:5:6]", address: nil),
            IPTestCase("[0:1:2:3:4:0:5:6:]", address: nil),
            IPTestCase("[0:1:2:3:4:0:5:6:]", address: nil),
            IPTestCase("[::0:1:2:3:4:5:6:7]", address: nil),
            IPTestCase("[0:1:2:3:4:5:6:7::]", address: nil),
            IPTestCase("[0:1:2:3:4:0:5]", address: nil),
            IPTestCase("[1:2:3:4:5:6:7]", address: nil),
            IPTestCase("[1:2:3:4:5:6:7:8:9]", address: nil),
            IPTestCase("[1:2:3]", address: nil),
            IPTestCase("[1:2:3:]", address: nil),
            IPTestCase("[:1:2:3]", address: nil),
            IPTestCase("[0:1:2:3:4:0:5:6:7]", address: nil),
            IPTestCase("[0:1:2:3:4:0:5:-6]", address: nil),
            IPTestCase("[0:1:2:3:4:0:5:g]", address: nil),
            IPTestCase("[0:11111:2:3:4:0:5:6]", address: nil),
            IPTestCase("[0:11111::]", address: nil),
            IPTestCase("[::11111:0]", address: nil),
            IPTestCase("[11111::]", address: nil),
            IPTestCase("[::11111]", address: nil),
            IPTestCase("m.a.h.d", address: nil),
            IPTestCase("m:a:h:d::", address: nil),
            IPTestCase(" ::1", address: nil),
            IPTestCase("::1 ", address: nil),
            IPTestCase("::1\n", address: nil),
            IPTestCase("::1\t", address: nil),
            IPTestCase("::FFFF:1.2.3.4 ", address: nil),
            IPTestCase("fe80::1%eth0", address: nil),
            IPTestCase("::ffff:1.2.3.4.5", address: nil),
            IPTestCase("::ffff:1.2.3.4:", address: nil),
            IPTestCase("::ffff:1.2.3", address: nil),
            IPTestCase("::ffff:0x1.2.3.4", address: nil),
            IPTestCase("::ffff:999.1.1.1", address: nil),
            IPTestCase("1::2:3:4:5:6:7:8", address: nil),
            IPTestCase("0:00:000:0000:0:0:0:0", address: 0, canonicalDescription: "[::]"),
            IPTestCase(
                "0000:0000:0000:0000:0000:0000:0000:0001",
                address: 1,
                canonicalDescription: "[::1]"
            ),
            IPTestCase("[0:00:000:0000:0:0:0:1]", address: 1, canonicalDescription: "[::1]"),
            IPTestCase("192.168.1.255", address: nil, isValidAsOtherIPVersion: true),
            /// Imported from glibc `resolv/tst-inet_pton.c`.
            IPTestCase(".:", address: nil),
            IPTestCase("0.:", address: nil),
            IPTestCase("00", address: nil),
            IPTestCase("0000000", address: nil),
            IPTestCase("00000000000000000", address: nil),
            IPTestCase("092.", address: nil),
            IPTestCase("10.0.301.2", address: nil),
            IPTestCase("19..", address: nil),
            IPTestCase("192.0.2.-1", address: nil),
            IPTestCase("192.0.2.1.", address: nil),
            IPTestCase("192.0.2.1192.", address: nil),
            IPTestCase("192.0.2.256", address: nil),
            IPTestCase("192.0.201.", address: nil),
            IPTestCase("192.0.261.", address: nil),
            IPTestCase("192.062.", address: nil),
            IPTestCase("192.192.00n2.1.", address: nil),
            IPTestCase("192.192.2.190.", address: nil),
            IPTestCase("192.255.255.2555", address: nil),
            IPTestCase(
                "1:1::1:1",
                address: 0x0001_0001_0000_0000_0000_0000_0001_0001,
                canonicalDescription: "[1:1::1:1]"
            ),
            IPTestCase("2", address: nil),
            IPTestCase("2.", address: nil),
            IPTestCase("2001:db8:00001::f", address: nil),
            IPTestCase("2001:db8:10000::f", address: nil),
            IPTestCase(
                "2001:db8:1234:5678:abcd:ef01:2345:67",
                address: 0x2001_0db8_1234_5678_abcd_ef01_2345_0067,
                canonicalDescription: "[2001:db8:1234:5678:abcd:ef01:2345:67]"
            ),
            IPTestCase("2001:db8:1234:5678:abcd:ef01:2345:6789:1", address: nil),
            IPTestCase("2001:db8:1234:5678:abcd:ef01:2345::6789", address: nil),
            IPTestCase(
                "2001:db8::0",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0000,
                canonicalDescription: "[2001:db8::]"
            ),
            IPTestCase(
                "2001:db8::00",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0000,
                canonicalDescription: "[2001:db8::]"
            ),
            IPTestCase(
                "2001:db8::1",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0001,
                canonicalDescription: "[2001:db8::1]"
            ),
            IPTestCase(
                "2001:db8::10",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0010,
                canonicalDescription: "[2001:db8::10]"
            ),
            IPTestCase(
                "2001:db8::19",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0019,
                canonicalDescription: "[2001:db8::19]"
            ),
            IPTestCase(
                "2001:db8::2",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0002,
                canonicalDescription: "[2001:db8::2]"
            ),
            IPTestCase(
                "2001:db8::3",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0003,
                canonicalDescription: "[2001:db8::3]"
            ),
            IPTestCase(
                "2001:db8::4",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0004,
                canonicalDescription: "[2001:db8::4]"
            ),
            IPTestCase(
                "2001:db8::5",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0005,
                canonicalDescription: "[2001:db8::5]"
            ),
            IPTestCase(
                "2001:db8::6",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0006,
                canonicalDescription: "[2001:db8::6]"
            ),
            IPTestCase(
                "2001:db8::7",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0007,
                canonicalDescription: "[2001:db8::7]"
            ),
            IPTestCase(
                "2001:db8::8",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0008,
                canonicalDescription: "[2001:db8::8]"
            ),
            IPTestCase(
                "2001:db8::9",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_0009,
                canonicalDescription: "[2001:db8::9]"
            ),
            IPTestCase(
                "2001:db8::A",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000a,
                canonicalDescription: "[2001:db8::a]"
            ),
            IPTestCase(
                "2001:db8::B",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000b,
                canonicalDescription: "[2001:db8::b]"
            ),
            IPTestCase(
                "2001:db8::C",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000c,
                canonicalDescription: "[2001:db8::c]"
            ),
            IPTestCase(
                "2001:db8::D",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000d,
                canonicalDescription: "[2001:db8::d]"
            ),
            IPTestCase(
                "2001:db8::E",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000e,
                canonicalDescription: "[2001:db8::e]"
            ),
            IPTestCase(
                "2001:db8::F",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000f,
                canonicalDescription: "[2001:db8::f]"
            ),
            IPTestCase(
                "2001:db8::a",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000a,
                canonicalDescription: "[2001:db8::a]"
            ),
            IPTestCase(
                "2001:db8::b",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000b,
                canonicalDescription: "[2001:db8::b]"
            ),
            IPTestCase(
                "2001:db8::c",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000c,
                canonicalDescription: "[2001:db8::c]"
            ),
            IPTestCase(
                "2001:db8::d",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000d,
                canonicalDescription: "[2001:db8::d]"
            ),
            IPTestCase(
                "2001:db8::e",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000e,
                canonicalDescription: "[2001:db8::e]"
            ),
            IPTestCase(
                "2001:db8::f",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_000f,
                canonicalDescription: "[2001:db8::f]"
            ),
            IPTestCase(
                "2001:db8::ff",
                address: 0x2001_0db8_0000_0000_0000_0000_0000_00ff,
                canonicalDescription: "[2001:db8::ff]"
            ),
            IPTestCase("22", address: nil),
            IPTestCase("2222@", address: nil),
            IPTestCase("255.255.255.25555", address: nil),
            IPTestCase("2:", address: nil),
            IPTestCase("2:ff:1:1:7:ff:1:1:7.", address: nil),
            IPTestCase(
                "2f:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000G01",
                address: nil
            ),
            IPTestCase("429495", address: nil),
            IPTestCase("5::5::", address: nil),
            IPTestCase("6.6.", address: nil),
            IPTestCase("992.", address: nil),
            IPTestCase("::00001", address: nil),
            IPTestCase("::10000", address: nil),
            IPTestCase(
                "::1:1",
                address: 0x0000_0000_0000_0000_0000_0000_0001_0001,
                canonicalDescription: "[::1:1]"
            ),
            IPTestCase(
                "::ff:1:1:7.0.0.1",
                address: 0x0000_0000_0000_00ff_0001_0001_0700_0001,
                canonicalDescription: "[::ff:1:1:700:1]"
            ),
            IPTestCase("::ff:1:1:7:ff:1:1:7.", address: nil),
            IPTestCase("::ff:1:1:7ff:1:8:7.0.0.1", address: nil),
            IPTestCase("::ff:1:1:7ff:1:8f:1:1:71", address: nil),
            IPTestCase("::ffff:02fff:127.0.S1", address: nil),
            IPTestCase(
                "::ffff:127.0.0.1",
                address: 0x0000_0000_0000_0000_0000_ffff_7f00_0001,
                canonicalDescription: "[::ffff:7f00:1]"
            ),
            IPTestCase(
                "::ffff:1:7.0.0.1",
                address: 0x0000_0000_0000_0000_ffff_0001_0700_0001,
                canonicalDescription: "[::ffff:1:700:1]"
            ),
            IPTestCase("A:f:ff:1:1:D:ff:1:1::7.", address: nil),
            IPTestCase("AAAAA.", address: nil),
            IPTestCase("D:::", address: nil),
            IPTestCase("DF8F", address: nil),
            IPTestCase(
                "F::",
                address: 0x000f_0000_0000_0000_0000_0000_0000_0000,
                canonicalDescription: "[f::]"
            ),
            IPTestCase(
                "F:ff:100:7ff:1:8:7.0.10.1",
                address: 0x000f_00ff_0100_07ff_0001_0008_0700_0a01,
                canonicalDescription: "[f:ff:100:7ff:1:8:700:a01]"
            ),
            IPTestCase("d92.", address: nil),
            IPTestCase(
                "ff:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001",
                address: nil
            ),
            IPTestCase(
                "fff2:2::ff2:2:f7",
                address: 0xfff2_0002_0000_0000_0000_0ff2_0002_00f7,
                canonicalDescription: "[fff2:2::ff2:2:f7]"
            ),
            IPTestCase("ffff:ff:ff:fff:ff:ff:ff:", address: nil),
        ] + Self.boundaryCharacters
    }

    @available(SwiftStdlib 6.0, *)
    static var idnaStringAndAddress: [Self] {
        [
            /// Contains weird characters that are mapped to the correct characters in IDNA
            /// These all should work based on IDNA.
            /// For example, the weird `1`s in the ip address below is:
            /// 2081          ; mapped     ; 0031          # 1.1  SUBSCRIPT ONE
            ///
            /// Some ignored IDNA unicode scalars that are used below:
            /// U+00AD ( ­ ) SOFT HYPHEN
            /// U+200B ( ​ ) ZERO WIDTH SPACE
            /// U+2064 ( ⁤ ) INVISIBLE PLUS
            ///
            /// Would parse to 1111:2222:3333:4444:5555:6666:7777:8888 assuming IDNA-compliant parsing
            IPTestCase(
                "₁₁₁₁:2222:3333:4444:5555:₆6₆6:7777:8888",
                address: 0x1111_2222_3333_4444_5555_6666_7777_8888
            ),
            /// Would parse to 1111:2222:3333:4444:5555:6666:7777:8888 assuming IDNA-compliant parsing
            IPTestCase(
                "\u{AD}1\u{AD}111:2222︓\u{AD}3333:4444︓55\u{200B}\u{2064}55:₆6₆6:7777:8888\u{200B}",
                address: 0x1111_2222_3333_4444_5555_6666_7777_8888
            ),
            /// Would parse to 2001:0DB8:85A3:F109:197A:8A2E:0370:7334 assuming IDNA-compliant parsing
            IPTestCase(
                "\u{200B}﹇₂₀\u{AD}\u{200B}₀₁︓\u{2064}₀ⒹⒷ₈︓₈₅Ⓐ₃\u{2064}︓Ⓕ₁₀₉︓₁₉₇Ⓐ︓₈Ⓐ₂Ⓔ︓₀₃₇₀︓₇₃₃₄﹈\u{2064}",
                address: 0x2001_0DB8_85A3_F109_197A_8A2E_0370_7334
            ),
            IPTestCase("\u{AD}", address: nil),
            IPTestCase("\u{AD}\u{200B}\u{2064}", address: nil),
            IPTestCase("[\u{AD}]", address: nil),
            IPTestCase("[\u{AD}\u{200B}\u{2064}]", address: nil),
            /// We should support parsing these next 4 as valid if we were to support IDNA-compliant parsing,
            /// but we can skip them if necessary for performance.
            /// If you remove the IDNA-ignored unicode scalars, it becomes clear they are valid.
            IPTestCase("[\u{AD}::]", address: 0x0000_0000_0000_0000_0000_0000_0000_0000),
            IPTestCase("[::\u{AD}]", address: 0x0000_0000_0000_0000_0000_0000_0000_0000),
            IPTestCase("[1:\u{AD}:1]", address: 0x0001_0000_0000_0000_0000_0000_0000_0001),
            IPTestCase("[1:\u{AD}\u{200B}:1]", address: 0x0001_0000_0000_0000_0000_0000_0000_0001),
        ]
    }

    private static var boundaryCharacters: [Self] {
        let boundaryBytes: [UInt8] = [
            UInt8(ascii: ":") + 1,
            UInt8(ascii: "0") - 1, UInt8(ascii: "9") + 1,
            UInt8(ascii: "a") - 1, UInt8(ascii: "f") + 1,
            UInt8(ascii: "A") - 1, UInt8(ascii: "F") + 1,
            UInt8(ascii: ".") - 1, UInt8(ascii: ".") + 1,
        ]
        return boundaryBytes.map { utf8Byte in
            let char = String(UnicodeScalar(utf8Byte))
            return IPTestCase("::1:\(char):1", address: nil)
        }
    }
}

extension IPPropertyTestCase where IPAddressType == IPv6Address {
    static var all: [Self] {
        [
            IPPropertyTestCase(IPv6Address("::1")!, "isLoopback", \.isLoopback),
            IPPropertyTestCase(
                IPv6Address("::1:1")!,
                "!isLoopback",
                { @Sendable in !$0.isLoopback }
            ),
            IPPropertyTestCase(IPv6Address("FF00::")!, "isMulticast", \.isMulticast),
            IPPropertyTestCase(IPv6Address("FF92::")!, "isMulticast", \.isMulticast),
            IPPropertyTestCase(IPv6Address("FFFF:998A::1")!, "isMulticast", \.isMulticast),
            IPPropertyTestCase(
                IPv6Address("FF::")!,
                "!isMulticast",
                { @Sendable in !$0.isMulticast }
            ),
            IPPropertyTestCase(
                IPv6Address("00FF::")!,
                "!isMulticast",
                { @Sendable in !$0.isMulticast }
            ),
            IPPropertyTestCase(
                IPv6Address("FAFF::")!,
                "!isMulticast",
                { @Sendable in !$0.isMulticast }
            ),
            IPPropertyTestCase(IPv6Address("FE80::")!, "isLinkLocalUnicast", \.isLinkLocalUnicast),
            IPPropertyTestCase(IPv6Address("FE90::")!, "isLinkLocalUnicast", \.isLinkLocalUnicast),
            IPPropertyTestCase(IPv6Address("FEBF::")!, "isLinkLocalUnicast", \.isLinkLocalUnicast),
            IPPropertyTestCase(
                IPv6Address("FEAA:9876:1928::9")!,
                "isLinkLocalUnicast",
                \.isLinkLocalUnicast
            ),
            IPPropertyTestCase(
                IPv6Address("FE70::")!,
                "!isLinkLocalUnicast",
                { @Sendable in !$0.isLinkLocalUnicast }
            ),
        ]
    }
}

extension IPv4MappedIPv6TestCase {
    static var all: [Self] {
        [
            IPv4MappedIPv6TestCase("::ffff:c000:0280", IPv4Address(192, 0, 2, 128)),
            IPv4MappedIPv6TestCase("::ffff:1234:5678", IPv4Address(18, 52, 86, 120)),
            IPv4MappedIPv6TestCase("::ffff:abcd:ef01", IPv4Address(171, 205, 239, 1)),
            IPv4MappedIPv6TestCase("::ffff:7f00:0001", IPv4Address(127, 0, 0, 1)),
            IPv4MappedIPv6TestCase("0:0:1:0:0:ffff:abcd:ef01"),
            IPv4MappedIPv6TestCase("ffff:ffff:ffff:ffff:ffff:ffff:abcd:ef01"),
        ]
    }
}

// 16 means no compression sign.
// Each Element is a pair of (lowerBound, upperBound) of range of segments that should be compressed.
// Each index of each element is the bitmap of the segments that are all-zero (1) or not (0).
// For example the element at index 0b0011_1000 is `(3, 5)`, meaning segments 3, 4, 5 should be compressed.
let compressionRangeTable: [(Int, Int)] = {
    var table = [(Int, Int)]()
    table.reserveCapacity(256)

    for index in 0..<256 {
        let mask = UInt8(index)

        var bestStart = -1
        var bestLength = 0
        var segment = 0
        while segment < 8 {
            if (mask >> segment) & 1 == 1 {
                var runEnd = segment
                while runEnd < 8 && (mask >> runEnd) & 1 == 1 {
                    runEnd += 1
                }
                let length = runEnd - segment
                if length > bestLength {
                    bestLength = length
                    bestStart = segment
                }
                segment = runEnd
            }
            segment += 1
        }

        let expected: (Int, Int)
        if bestLength >= 2 {
            expected = (bestStart, bestStart + bestLength - 1)
        } else {
            expected = (16, 16)
        }
        table.append(expected)
    }

    return table
}()
