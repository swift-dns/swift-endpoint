import Endpoint

extension IPv6AddressTestCase {
    @available(SwiftStdlib 6.0, *)
    static let stringAndAddress: [Self] =
        Self.hardcodedStringAndAddress + Self.boundaryCharacters + Self.ipv4Embedded

    @available(SwiftStdlib 6.0, *)
    private static let hardcodedStringAndAddress: [Self] = [
        IPv6AddressTestCase(
            "1111:2222:3333:4444:5555:6666:7777:8888",
            ip: IP(
                0x1111_2222_3333_4444_5555_6666_7777_8888,
                "1111:2222:3333:4444:5555:6666:7777:8888",
                "1111:2222:3333:4444:5555:6666:119.119.136.136"
            )
        ),
        IPv6AddressTestCase(
            "[FF::]",
            ip: IP(0x00FF_0000_0000_0000_0000_0000_0000_0000, "ff::", "ff::0.0.0.0")
        ),
        IPv6AddressTestCase(
            "[::FF]",
            ip: IP(0x0000_0000_0000_0000_0000_0000_0000_00FF, "::ff", "::0.0.0.255")
        ),
        IPv6AddressTestCase(
            "[0:FF::]",
            ip: IP(0x0000_00FF_0000_0000_0000_0000_0000_0000, "0:ff::", "0:ff::0.0.0.0")
        ),
        IPv6AddressTestCase(
            "[2001:db8:85a3::100]",
            ip: IP(
                0x2001_0DB8_85A3_0000_0000_0000_0000_0100,
                "2001:db8:85a3::100",
                "2001:db8:85a3::0.0.1.0"
            )
        ),
        IPv6AddressTestCase(
            "2001:db8:85a3::100",
            ip: IP(
                0x2001_0DB8_85A3_0000_0000_0000_0000_0100,
                "2001:db8:85a3::100",
                "2001:db8:85a3::0.0.1.0"
            )
        ),
        IPv6AddressTestCase(
            "[2001:db8:85a0::100]",
            ip: IP(
                0x2001_0DB8_85A0_0000_0000_0000_0000_0100,
                "2001:db8:85a0::100",
                "2001:db8:85a0::0.0.1.0"
            )
        ),
        IPv6AddressTestCase(
            "[2001:db8:8503::100]",
            ip: IP(
                0x2001_0DB8_8503_0000_0000_0000_0000_0100,
                "2001:db8:8503::100",
                "2001:db8:8503::0.0.1.0"
            )
        ),
        IPv6AddressTestCase(
            "[2001:db8:80a3::100]",
            ip: IP(
                0x2001_0DB8_80A3_0000_0000_0000_0000_0100,
                "2001:db8:80a3::100",
                "2001:db8:80a3::0.0.1.0"
            )
        ),
        IPv6AddressTestCase(
            "[2001:db8::1:0:0:2]",
            ip: IP(
                0x2001_0DB8_0000_0000_0001_0000_0000_0002,
                "2001:db8::1:0:0:2",
                "2001:db8::1:0:0.0.0.2"
            )
        ),
        IPv6AddressTestCase(
            "[2001:db8:1111:2222:3333:4444::]",
            ip: IP(
                0x2001_0DB8_1111_2222_3333_4444_0000_0000,
                "2001:db8:1111:2222:3333:4444::",
                "2001:db8:1111:2222:3333:4444:0.0.0.0"
            )
        ),
        IPv6AddressTestCase(
            "[2001:db8:1111:2222:3333:4444:5555:6666]",
            ip: IP(
                0x2001_0DB8_1111_2222_3333_4444_5555_6666,
                "2001:db8:1111:2222:3333:4444:5555:6666",
                "2001:db8:1111:2222:3333:4444:85.85.102.102"
            )
        ),
        IPv6AddressTestCase(
            "[2001:db8:1111:2222:3333:4444:5555:0]",
            ip: IP(
                0x2001_0DB8_1111_2222_3333_4444_5555_0000,
                "2001:db8:1111:2222:3333:4444:5555:0",
                "2001:db8:1111:2222:3333:4444:85.85.0.0"
            )
        ),
        IPv6AddressTestCase(
            "[2001:DB8:1111:2222:0:3333:4444:5555]",
            ip: IP(
                0x2001_0DB8_1111_2222_0000_3333_4444_5555,
                "2001:db8:1111:2222:0:3333:4444:5555",
                "2001:db8:1111:2222:0:3333:68.68.85.85"
            )
        ),
        IPv6AddressTestCase(
            "[2001::1:0:0:2]",
            ip: IP(0x2001_0000_0000_0000_0001_0000_0000_0002, "2001::1:0:0:2", "2001::1:0:0.0.0.2")
        ),
        IPv6AddressTestCase(
            "2001::1:0:0:2",
            ip: IP(0x2001_0000_0000_0000_0001_0000_0000_0002, "2001::1:0:0:2", "2001::1:0:0.0.0.2")
        ),
        IPv6AddressTestCase(
            "[2001:0:0:1::2]",
            ip: IP(
                0x2001_0000_0000_0001_0000_0000_0000_0002,
                "2001:0:0:1::2",
                "2001::1:0:0:0.0.0.2"
            )
        ),
        IPv6AddressTestCase(
            "[2001:db8:aaaa:bbbb:cccc:DDDD:eeee:1]",
            ip: IP(
                0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001,
                "2001:db8:aaaa:bbbb:cccc:dddd:eeee:1",
                "2001:db8:aaaa:bbbb:cccc:dddd:238.238.0.1"
            )
        ),
        IPv6AddressTestCase(
            "2001:db8:aaaa:BBBB:cccc:dddd:eeee:1",
            ip: IP(
                0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001,
                "2001:db8:aaaa:bbbb:cccc:dddd:eeee:1",
                "2001:db8:aaaa:bbbb:cccc:dddd:238.238.0.1"
            )
        ),
        IPv6AddressTestCase(
            "01:db8:a0a:bb:cc0:0dd0:ee:1",
            ip: IP(
                0x0001_0DB8_0A0A_00BB_0CC0_0DD0_00EE_0001,
                "1:db8:a0a:bb:cc0:dd0:ee:1",
                "1:db8:a0a:bb:cc0:dd0:0.238.0.1"
            )
        ),
        IPv6AddressTestCase(
            "[2001:db8::1:0:0:2]",
            ip: IP(
                0x2001_0DB8_0000_0000_0001_0000_0000_0002,
                "2001:db8::1:0:0:2",
                "2001:db8::1:0:0.0.0.2"
            )
        ),
        IPv6AddressTestCase(
            "[::]",
            ip: IP(0x0000_0000_0000_0000_0000_0000_0000_0000, "::", "::0.0.0.0")
        ),
        IPv6AddressTestCase(
            "::",
            ip: IP(0x0000_0000_0000_0000_0000_0000_0000_0000, "::", "::0.0.0.0")
        ),
        IPv6AddressTestCase(
            "[2001:0:0:1::]",
            ip: IP(0x2001_0000_0000_0001_0000_0000_0000_0000, "2001:0:0:1::", "2001::1:0:0:0.0.0.0")
        ),
        IPv6AddressTestCase(
            "[::1:0:0:2]",
            ip: IP(0x0000_0000_0000_0000_0001_0000_0000_0002, "::1:0:0:2", "::1:0:0.0.0.2")
        ),
        IPv6AddressTestCase(
            "[::1:2:3:0:4:5]",
            ip: IP(0x0000_0000_0001_0002_0003_0000_0004_0005, "::1:2:3:0:4:5", "::1:2:3:0:0.4.0.5")
        ),
        IPv6AddressTestCase(
            "[::1:0:0:1:0:0]",
            ip: IP(0x0000_0000_0001_0000_0000_0001_0000_0000, "::1:0:0:1:0:0", "::1:0:0:1:0.0.0.0")
        ),
        IPv6AddressTestCase(
            "[1:0:1::1:0]",
            ip: IP(0x0001_0000_0001_0000_0000_0000_0001_0000, "1:0:1::1:0", "1:0:1::0.1.0.0")
        ),
        IPv6AddressTestCase(
            "[0:1:2:3:4:0:5:6]",
            ip: IP(
                0x0000_0001_0002_0003_0004_0000_0005_0006,
                "0:1:2:3:4:0:5:6",
                "0:1:2:3:4:0:0.5.0.6"
            )
        ),
        IPv6AddressTestCase(
            "[0:1:2:3:4:0:5:f]",
            ip: IP(
                0x0000_0001_0002_0003_0004_0000_0005_000F,
                "0:1:2:3:4:0:5:f",
                "0:1:2:3:4:0:0.5.0.15"
            )
        ),
        IPv6AddressTestCase(
            "0:1:2:3:4:0:5:6",
            ip: IP(
                0x0000_0001_0002_0003_0004_0000_0005_0006,
                "0:1:2:3:4:0:5:6",
                "0:1:2:3:4:0:0.5.0.6"
            )
        ),
        IPv6AddressTestCase(
            "1:2:3:4:5::",
            ip: IP(0x0001_0002_0003_0004_0005_0000_0000_0000, "1:2:3:4:5::", "1:2:3:4:5:0:0.0.0.0")
        ),
        IPv6AddressTestCase(
            "1:2:3:4::5",
            ip: IP(0x0001_0002_0003_0004_0000_0000_0000_0005, "1:2:3:4::5", "1:2:3:4::0.0.0.5")
        ),
        IPv6AddressTestCase(
            "1:0:0:2::",
            ip: IP(0x0001_0000_0000_0002_0000_0000_0000_0000, "1:0:0:2::", "1::2:0:0:0.0.0.0")
        ),
        IPv6AddressTestCase(
            "1:2:3:4:5:6:0:7",
            ip: IP(
                0x0001_0002_0003_0004_0005_0006_0000_0007,
                "1:2:3:4:5:6:0:7",
                "1:2:3:4:5:6:0.0.0.7"
            )
        ),
        IPv6AddressTestCase(
            "[::1]",
            ip: IP(0x0000_0000_0000_0000_0000_0000_0000_0001, "::1", "::0.0.0.1")
        ),
        IPv6AddressTestCase(
            "::1",
            ip: IP(0x0000_0000_0000_0000_0000_0000_0000_0001, "::1", "::0.0.0.1")
        ),
        IPv6AddressTestCase(
            "::FFFF:204.152.189.116",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_CC98_BD74,
                "::ffff:cc98:bd74",
                "::ffff:204.152.189.116"
            )
        ),
        IPv6AddressTestCase(
            "::FFFF:255.255.255.255",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF,
                "::ffff:ffff:ffff",
                "::ffff:255.255.255.255"
            )
        ),
        IPv6AddressTestCase(
            "::FFFF:1.1.1.1",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                "::ffff:101:101",
                "::ffff:1.1.1.1"
            )
        ),
        IPv6AddressTestCase(
            "[::ffff:1.1.1.1]",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                "::ffff:101:101",
                "::ffff:1.1.1.1"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:0:0",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0000_0000,
                "::ffff:0:0",
                "::ffff:0.0.0.0"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:0.0.0.0",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0000_0000,
                "::ffff:0:0",
                "::ffff:0.0.0.0"
            )
        ),
        IPv6AddressTestCase(
            "64:ff9b::0.0.0.0",
            ip: IP(0x0064_FF9B_0000_0000_0000_0000_0000_0000, "64:ff9b::", "64:ff9b::0.0.0.0")
        ),
        IPv6AddressTestCase(
            "64:ff9b::192.0.2.33",
            ip: IP(
                0x0064_FF9B_0000_0000_0000_0000_C000_0221,
                "64:ff9b::c000:221",
                "64:ff9b::192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "[64:ff9b::192.0.2.33]",
            ip: IP(
                0x0064_FF9B_0000_0000_0000_0000_C000_0221,
                "64:ff9b::c000:221",
                "64:ff9b::192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "64:FF9B:0:0:0:0:C000:0221",
            ip: IP(
                0x0064_FF9B_0000_0000_0000_0000_C000_0221,
                "64:ff9b::c000:221",
                "64:ff9b::192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "64:ff9b::",
            ip: IP(0x0064_FF9B_0000_0000_0000_0000_0000_0000, "64:ff9b::", "64:ff9b::0.0.0.0")
        ),
        IPv6AddressTestCase(
            "64:ff9b::1",
            ip: IP(0x0064_FF9B_0000_0000_0000_0000_0000_0001, "64:ff9b::1", "64:ff9b::0.0.0.1")
        ),
        IPv6AddressTestCase(
            "[64:ff9b::255.255.255.255]",
            ip: IP(
                0x0064_FF9B_0000_0000_0000_0000_FFFF_FFFF,
                "64:ff9b::ffff:ffff",
                "64:ff9b::255.255.255.255"
            )
        ),
        IPv6AddressTestCase(
            "64:ff9b::0.1.2.0",
            ip: IP(0x0064_FF9B_0000_0000_0000_0000_0001_0200, "64:ff9b::1:200", "64:ff9b::0.1.2.0")
        ),
        IPv6AddressTestCase(
            "64:ff9b::255.255.0.0",
            ip: IP(
                0x0064_FF9B_0000_0000_0000_0000_FFFF_0000,
                "64:ff9b::ffff:0",
                "64:ff9b::255.255.0.0"
            )
        ),
        IPv6AddressTestCase(
            "64:ff9b:0:0:0:1:c000:221",
            ip: IP(
                0x0064_FF9B_0000_0000_0000_0001_C000_0221,
                "64:ff9b::1:c000:221",
                "64:ff9b::1:192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "64:ff9c::192.0.2.33",
            ip: IP(
                0x0064_FF9C_0000_0000_0000_0000_C000_0221,
                "64:ff9c::c000:221",
                "64:ff9c::192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "65:ff9b::192.0.2.33",
            ip: IP(
                0x0065_FF9B_0000_0000_0000_0000_C000_0221,
                "65:ff9b::c000:221",
                "65:ff9b::192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "0:64:ff9b::192.0.2.33",
            ip: IP(
                0x0000_0064_FF9B_0000_0000_0000_C000_0221,
                "0:64:ff9b::c000:221",
                "0:64:ff9b::192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "2001:db8:122:344::192.0.2.33",
            ip: IP(
                0x2001_0DB8_0122_0344_0000_0000_C000_0221,
                "2001:db8:122:344::c000:221",
                "2001:db8:122:344::192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "::13.1.68.3",
            ip: IP(0x0000_0000_0000_0000_0000_0000_0D01_4403, "::d01:4403", "::13.1.68.3")
        ),
        IPv6AddressTestCase(
            "0:0:1:0:0:FFFF:204.152.189.116",
            ip: IP(
                0x0000_0000_0001_0000_0000_FFFF_CC98_BD74,
                "::1:0:0:ffff:cc98:bd74",
                "::1:0:0:ffff:204.152.189.116"
            )
        ),
        IPv6AddressTestCase(
            "0:0:0:0:0:FFFF:204.152.189.116",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_CC98_BD74,
                "::ffff:cc98:bd74",
                "::ffff:204.152.189.116"
            )
        ),
        IPv6AddressTestCase(
            "0:0:0:0:0:ffff:255.255.255.255",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF,
                "::ffff:ffff:ffff",
                "::ffff:255.255.255.255"
            )
        ),
        IPv6AddressTestCase(
            "[0000:0000:0000:0000:0000:FFFF:255.255.255.255]",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF,
                "::ffff:ffff:ffff",
                "::ffff:255.255.255.255"
            )
        ),
        IPv6AddressTestCase(
            "0:0:0:0:0:FFFF:1.1.1.1",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                "::ffff:101:101",
                "::ffff:1.1.1.1"
            )
        ),
        IPv6AddressTestCase(
            "0::0:FFFF:1.1.1.1",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                "::ffff:101:101",
                "::ffff:1.1.1.1"
            )
        ),
        IPv6AddressTestCase(
            "0:0::0:FFFF:1.1.1.1",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0101_0101,
                "::ffff:101:101",
                "::ffff:1.1.1.1"
            )
        ),
        IPv6AddressTestCase(
            "::1.1.1.1",
            ip: IP(0x0000_0000_0000_0000_0000_0000_0101_0101, "::101:101", "::1.1.1.1")
        ),
        IPv6AddressTestCase(
            "::ffff:0.0.0.1",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0000_0001,
                "::ffff:0:1",
                "::ffff:0.0.0.1"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:0.0.1.0",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0000_0100,
                "::ffff:0:100",
                "::ffff:0.0.1.0"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:0.0.1.2",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0000_0102,
                "::ffff:0:102",
                "::ffff:0.0.1.2"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:0.1.0.0",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0001_0000,
                "::ffff:1:0",
                "::ffff:0.1.0.0"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:0.1.2.0",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0001_0200,
                "::ffff:1:200",
                "::ffff:0.1.2.0"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:255.255.0.0",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_FFFF_0000,
                "::ffff:ffff:0",
                "::ffff:255.255.0.0"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:255.0.0.0",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_FF00_0000,
                "::ffff:ff00:0",
                "::ffff:255.0.0.0"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:0.0.255.255",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0000_FFFF,
                "::ffff:0:ffff",
                "::ffff:0.0.255.255"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:9.8.7.6",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_0908_0706,
                "::ffff:908:706",
                "::ffff:9.8.7.6"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:192.0.2.128",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFF_C000_0280,
                "::ffff:c000:280",
                "::ffff:192.0.2.128"
            )
        ),
        IPv6AddressTestCase(
            "::fffe:255.255.255.255",
            ip: IP(
                0x0000_0000_0000_0000_0000_FFFE_FFFF_FFFF,
                "::fffe:ffff:ffff",
                "::fffe:255.255.255.255"
            )
        ),
        IPv6AddressTestCase(
            "::1:ffff:1.1.1.1",
            ip: IP(
                0x0000_0000_0000_0000_0001_FFFF_0101_0101,
                "::1:ffff:101:101",
                "::1:ffff:1.1.1.1"
            )
        ),
        IPv6AddressTestCase(
            "1::ffff:1.1.1.1",
            ip: IP(0x0001_0000_0000_0000_0000_FFFF_0101_0101, "1::ffff:101:101", "1::ffff:1.1.1.1")
        ),
        IPv6AddressTestCase(
            "0:0:0:0:ffff:0:1.1.1.1",
            ip: IP(
                0x0000_0000_0000_0000_FFFF_0000_0101_0101,
                "::ffff:0:101:101",
                "::ffff:0:1.1.1.1"
            )
        ),
        IPv6AddressTestCase(
            "64:ff9b:1::192.0.2.33",
            ip: IP(
                0x0064_FF9B_0001_0000_0000_0000_C000_0221,
                "64:ff9b:1::c000:221",
                "64:ff9b:1::192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "fe80::5efe:192.0.2.33",
            ip: IP(
                0xFE80_0000_0000_0000_0000_5EFE_C000_0221,
                "fe80::5efe:c000:221",
                "fe80::5efe:192.0.2.33"
            )
        ),
        IPv6AddressTestCase(
            "2002:c000:221::1",
            ip: IP(
                0x2002_C000_0221_0000_0000_0000_0000_0001,
                "2002:c000:221::1",
                "2002:c000:221::0.0.0.1"
            )
        ),
        IPv6AddressTestCase(
            "::1:2:3:4:5:6:7",
            ip: IP(
                0x0000_0001_0002_0003_0004_0005_0006_0007,
                "0:1:2:3:4:5:6:7",
                "0:1:2:3:4:5:0.6.0.7"
            )
        ),
        IPv6AddressTestCase(
            "1:2:3:4:5:6:7::",
            ip: IP(
                0x0001_0002_0003_0004_0005_0006_0007_0000,
                "1:2:3:4:5:6:7:0",
                "1:2:3:4:5:6:0.7.0.0"
            )
        ),
        IPv6AddressTestCase(
            "1:2:3::4:5:6:7",
            ip: IP(
                0x0001_0002_0003_0000_0004_0005_0006_0007,
                "1:2:3:0:4:5:6:7",
                "1:2:3:0:4:5:0.6.0.7"
            )
        ),
        IPv6AddressTestCase("0:00:000:0000:0:0:0:0", ip: IP(0, "::", "::0.0.0.0")),
        IPv6AddressTestCase(
            "0000:0000:0000:0000:0000:0000:0000:0001",
            ip: IP(1, "::1", "::0.0.0.1")
        ),
        IPv6AddressTestCase("[0:00:000:0000:0:0:0:1]", ip: IP(1, "::1", "::0.0.0.1")),
        IPv6AddressTestCase(
            "0001:0002:0003:0004:0005:0006:0007:0008",
            ip: IP(
                0x0001_0002_0003_0004_0005_0006_0007_0008,
                "1:2:3:4:5:6:7:8",
                "1:2:3:4:5:6:0.7.0.8"
            )
        ),
        IPv6AddressTestCase(
            "[0000:0001::0000:0002]",
            ip: IP(0x0000_0001_0000_0000_0000_0000_0000_0002, "0:1::2", "0:1::0.0.0.2")
        ),
        IPv6AddressTestCase(
            "[0000:0000:0000:0000:0000:00ff:0000:0001]",
            ip: IP(0x0000_0000_0000_0000_0000_00FF_0000_0001, "::ff:0:1", "::ff:0.0.0.1")
        ),
        IPv6AddressTestCase(
            "00ff::00ff",
            ip: IP(0x00FF_0000_0000_0000_0000_0000_0000_00FF, "ff::ff", "ff::0.0.0.255")
        ),
        IPv6AddressTestCase("::0000", ip: IP(0, "::", "::0.0.0.0")),
        IPv6AddressTestCase("0000::", ip: IP(0, "::", "::0.0.0.0")),
        IPv6AddressTestCase("::0000:0000", ip: IP(0, "::", "::0.0.0.0")),
        IPv6AddressTestCase("0:0000::00", ip: IP(0, "::", "::0.0.0.0")),
        IPv6AddressTestCase("::00000", ip: nil),
        IPv6AddressTestCase("00000::", ip: nil),
        IPv6AddressTestCase("00001::", ip: nil),
        IPv6AddressTestCase("0:0:0:0:0:0:0:00000", ip: nil),
        IPv6AddressTestCase("1:2:3:4:5:6:7:00008", ip: nil),
        IPv6AddressTestCase("[00000:0:0:0:0:0:0:0]", ip: nil),
        IPv6AddressTestCase("::ffff:0000.0.0.1", ip: nil),
        IPv6AddressTestCase("::ffff:1.2.3.0000", ip: nil),
        IPv6AddressTestCase("::0000.1.2.3", ip: nil),
        IPv6AddressTestCase("2001:db8::1.2.3.0000", ip: nil),
        IPv6AddressTestCase("[0000:0000:0000:0000:0000:FFFF:0255.255.255.255]", ip: nil),
        IPv6AddressTestCase("192.168.1.255", ip: nil, isValidAsOtherIPVersion: true),
        IPv6AddressTestCase("0:0:0:0:0:0:FFFF:1.1.1.1", ip: nil),
        IPv6AddressTestCase("0:0:0:0:FFFF:1.1.1.1:FFFF", ip: nil),
        IPv6AddressTestCase("0:0:0:0:0:1.1.1.1:FFFF", ip: nil),
        IPv6AddressTestCase("::FFFF:1.1.1.1:FFFF", ip: nil),
        IPv6AddressTestCase("::1.1.1.1:FFFF", ip: nil),
        IPv6AddressTestCase(":FFFF:1.1.1.1", ip: nil),
        IPv6AddressTestCase("::FFFF:1.", ip: nil),
        IPv6AddressTestCase("::FFFF:1.1", ip: nil),
        IPv6AddressTestCase("::FFFF:1.1.", ip: nil),
        IPv6AddressTestCase("::FFFF:1.1.1", ip: nil),
        IPv6AddressTestCase("::FFFF:1.1.1.", ip: nil),
        IPv6AddressTestCase(".1.1.1.1", ip: nil),
        IPv6AddressTestCase("::FFFF:256.152.189.116", ip: nil),
        IPv6AddressTestCase("[0000:0000:0000:0000:0000:FFFF:255.255.255.1111]", ip: nil),
        IPv6AddressTestCase("::FFFF:204.152.189.116.", ip: nil),
        IPv6AddressTestCase("::FFFF:.204.152.189.116", ip: nil),
        IPv6AddressTestCase("::FFFF::204.152.189.116", ip: nil),
        IPv6AddressTestCase("::FFFF:204.152.189", ip: nil),
        IPv6AddressTestCase("::FFFF:204.152.189.", ip: nil),
        IPv6AddressTestCase("::FFFF:.204.152.189", ip: nil),
        IPv6AddressTestCase("", ip: nil),
        IPv6AddressTestCase(" ", ip: nil),
        IPv6AddressTestCase("    ", ip: nil),
        IPv6AddressTestCase(".", ip: nil),
        IPv6AddressTestCase("..", ip: nil),
        IPv6AddressTestCase("...", ip: nil),
        IPv6AddressTestCase("....", ip: nil),
        IPv6AddressTestCase(".....", ip: nil),
        IPv6AddressTestCase("::FFFF:", ip: nil),
        IPv6AddressTestCase("::FFFF: ", ip: nil),
        IPv6AddressTestCase("::FFFF:    ", ip: nil),
        IPv6AddressTestCase("::FFFF:.", ip: nil),
        IPv6AddressTestCase("::FFFF:..", ip: nil),
        IPv6AddressTestCase("::FFFF:...", ip: nil),
        IPv6AddressTestCase("::FFFF:....", ip: nil),
        IPv6AddressTestCase("::FFFF:.....", ip: nil),
        IPv6AddressTestCase(":", ip: nil),
        IPv6AddressTestCase("[:]", ip: nil),
        IPv6AddressTestCase(":::", ip: nil),
        IPv6AddressTestCase("[:::]", ip: nil),
        IPv6AddressTestCase("::::", ip: nil),
        IPv6AddressTestCase(":::::", ip: nil),
        IPv6AddressTestCase("::::::", ip: nil),
        IPv6AddressTestCase(":::::::", ip: nil),
        IPv6AddressTestCase("[:::::::]", ip: nil),
        IPv6AddressTestCase("::::::::", ip: nil),
        IPv6AddressTestCase(":::::::::", ip: nil),
        IPv6AddressTestCase("::::::::::", ip: nil),
        IPv6AddressTestCase("[::::::::::]", ip: nil),
        IPv6AddressTestCase("[2001:0:0:1:::]", ip: nil),
        IPv6AddressTestCase("[:::2001:0:0:1]", ip: nil),
        IPv6AddressTestCase("[2001:0:0:1::2", ip: nil),
        IPv6AddressTestCase("2001:0:0:1::2]", ip: nil),
        IPv6AddressTestCase("[1::2::]", ip: nil),
        IPv6AddressTestCase("[1::2::3]", ip: nil),
        IPv6AddressTestCase("[:0:1:2:3:4:0:5:6]", ip: nil),
        IPv6AddressTestCase("[0:1:2:3:4:0:5:6:]", ip: nil),
        IPv6AddressTestCase("[0:1:2:3:4:0:5:6:]", ip: nil),
        IPv6AddressTestCase("[::0:1:2:3:4:5:6:7]", ip: nil),
        IPv6AddressTestCase("[0:1:2:3:4:5:6:7::]", ip: nil),
        IPv6AddressTestCase("[0:1:2:3:4:0:5]", ip: nil),
        IPv6AddressTestCase("[1:2:3:4:5:6:7]", ip: nil),
        IPv6AddressTestCase("[1:2:3:4:5:6:7:8:9]", ip: nil),
        IPv6AddressTestCase("[1:2:3]", ip: nil),
        IPv6AddressTestCase("[1:2:3:]", ip: nil),
        IPv6AddressTestCase("[:1:2:3]", ip: nil),
        IPv6AddressTestCase("[0:1:2:3:4:0:5:6:7]", ip: nil),
        IPv6AddressTestCase("[0:1:2:3:4:0:5:-6]", ip: nil),
        IPv6AddressTestCase("[0:1:2:3:4:0:5:g]", ip: nil),
        IPv6AddressTestCase("[0:11111:2:3:4:0:5:6]", ip: nil),
        IPv6AddressTestCase("[0:11111::]", ip: nil),
        IPv6AddressTestCase("[::11111:0]", ip: nil),
        IPv6AddressTestCase("[11111::]", ip: nil),
        IPv6AddressTestCase("[::11111]", ip: nil),
        IPv6AddressTestCase("m.a.h.d", ip: nil),
        IPv6AddressTestCase("m:a:h:d::", ip: nil),
        IPv6AddressTestCase(" ::1", ip: nil),
        IPv6AddressTestCase("::1 ", ip: nil),
        IPv6AddressTestCase("::1\n", ip: nil),
        IPv6AddressTestCase("::1\t", ip: nil),
        IPv6AddressTestCase("::FFFF:1.2.3.4 ", ip: nil),
        IPv6AddressTestCase("fe80::1%eth0", ip: nil),
        IPv6AddressTestCase("::ffff:1.2.3.4.5", ip: nil),
        IPv6AddressTestCase("::ffff:1.2.3.4:", ip: nil),
        IPv6AddressTestCase("::ffff:1.2.3", ip: nil),
        IPv6AddressTestCase("::ffff:0x1.2.3.4", ip: nil),
        IPv6AddressTestCase("::ffff:999.1.1.1", ip: nil),
        IPv6AddressTestCase("1::2:3:4:5:6:7:8", ip: nil),
        /// Imported from glibc `resolv/tst-inet_pton.c`.
        IPv6AddressTestCase(
            "1:1::1:1",
            ip: IP(0x0001_0001_0000_0000_0000_0000_0001_0001, "1:1::1:1", "1:1::0.1.0.1")
        ),
        IPv6AddressTestCase(
            "2001:db8:1234:5678:abcd:ef01:2345:67",
            ip: IP(
                0x2001_0db8_1234_5678_abcd_ef01_2345_0067,
                "2001:db8:1234:5678:abcd:ef01:2345:67",
                "2001:db8:1234:5678:abcd:ef01:35.69.0.103"
            )
        ),
        IPv6AddressTestCase(
            "2001:db8::0",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0000, "2001:db8::", "2001:db8::0.0.0.0")
        ),
        IPv6AddressTestCase(
            "2001:db8::00",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0000, "2001:db8::", "2001:db8::0.0.0.0")
        ),
        IPv6AddressTestCase(
            "2001:db8::1",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0001, "2001:db8::1", "2001:db8::0.0.0.1")
        ),
        IPv6AddressTestCase(
            "2001:db8::10",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0010, "2001:db8::10", "2001:db8::0.0.0.16")
        ),
        IPv6AddressTestCase(
            "2001:db8::19",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0019, "2001:db8::19", "2001:db8::0.0.0.25")
        ),
        IPv6AddressTestCase(
            "2001:db8::2",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0002, "2001:db8::2", "2001:db8::0.0.0.2")
        ),
        IPv6AddressTestCase(
            "2001:db8::3",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0003, "2001:db8::3", "2001:db8::0.0.0.3")
        ),
        IPv6AddressTestCase(
            "2001:db8::4",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0004, "2001:db8::4", "2001:db8::0.0.0.4")
        ),
        IPv6AddressTestCase(
            "2001:db8::5",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0005, "2001:db8::5", "2001:db8::0.0.0.5")
        ),
        IPv6AddressTestCase(
            "2001:db8::6",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0006, "2001:db8::6", "2001:db8::0.0.0.6")
        ),
        IPv6AddressTestCase(
            "2001:db8::7",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0007, "2001:db8::7", "2001:db8::0.0.0.7")
        ),
        IPv6AddressTestCase(
            "2001:db8::8",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0008, "2001:db8::8", "2001:db8::0.0.0.8")
        ),
        IPv6AddressTestCase(
            "2001:db8::9",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_0009, "2001:db8::9", "2001:db8::0.0.0.9")
        ),
        IPv6AddressTestCase(
            "2001:db8::A",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000a, "2001:db8::a", "2001:db8::0.0.0.10")
        ),
        IPv6AddressTestCase(
            "2001:db8::B",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000b, "2001:db8::b", "2001:db8::0.0.0.11")
        ),
        IPv6AddressTestCase(
            "2001:db8::C",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000c, "2001:db8::c", "2001:db8::0.0.0.12")
        ),
        IPv6AddressTestCase(
            "2001:db8::D",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000d, "2001:db8::d", "2001:db8::0.0.0.13")
        ),
        IPv6AddressTestCase(
            "2001:db8::E",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000e, "2001:db8::e", "2001:db8::0.0.0.14")
        ),
        IPv6AddressTestCase(
            "2001:db8::F",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000f, "2001:db8::f", "2001:db8::0.0.0.15")
        ),
        IPv6AddressTestCase(
            "2001:db8::a",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000a, "2001:db8::a", "2001:db8::0.0.0.10")
        ),
        IPv6AddressTestCase(
            "2001:db8::b",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000b, "2001:db8::b", "2001:db8::0.0.0.11")
        ),
        IPv6AddressTestCase(
            "2001:db8::c",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000c, "2001:db8::c", "2001:db8::0.0.0.12")
        ),
        IPv6AddressTestCase(
            "2001:db8::d",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000d, "2001:db8::d", "2001:db8::0.0.0.13")
        ),
        IPv6AddressTestCase(
            "2001:db8::e",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000e, "2001:db8::e", "2001:db8::0.0.0.14")
        ),
        IPv6AddressTestCase(
            "2001:db8::f",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_000f, "2001:db8::f", "2001:db8::0.0.0.15")
        ),
        IPv6AddressTestCase(
            "2001:db8::ff",
            ip: IP(0x2001_0db8_0000_0000_0000_0000_0000_00ff, "2001:db8::ff", "2001:db8::0.0.0.255")
        ),
        IPv6AddressTestCase(".:", ip: nil),
        IPv6AddressTestCase("0.:", ip: nil),
        IPv6AddressTestCase("00", ip: nil),
        IPv6AddressTestCase("0000000", ip: nil),
        IPv6AddressTestCase("00000000000000000", ip: nil),
        IPv6AddressTestCase("092.", ip: nil),
        IPv6AddressTestCase("10.0.301.2", ip: nil),
        IPv6AddressTestCase("19..", ip: nil),
        IPv6AddressTestCase("192.0.2.-1", ip: nil),
        IPv6AddressTestCase("192.0.2.1.", ip: nil),
        IPv6AddressTestCase("192.0.2.1192.", ip: nil),
        IPv6AddressTestCase("192.0.2.256", ip: nil),
        IPv6AddressTestCase("192.0.201.", ip: nil),
        IPv6AddressTestCase("192.0.261.", ip: nil),
        IPv6AddressTestCase("192.062.", ip: nil),
        IPv6AddressTestCase("192.192.00n2.1.", ip: nil),
        IPv6AddressTestCase("192.192.2.190.", ip: nil),
        IPv6AddressTestCase("192.255.255.2555", ip: nil),
        IPv6AddressTestCase("2", ip: nil),
        IPv6AddressTestCase("2.", ip: nil),
        IPv6AddressTestCase("2001:db8:00001::f", ip: nil),
        IPv6AddressTestCase("2001:db8:10000::f", ip: nil),
        IPv6AddressTestCase("2001:db8:1234:5678:abcd:ef01:2345:6789:1", ip: nil),
        IPv6AddressTestCase("2001:db8:1234:5678:abcd:ef01:2345::6789", ip: nil),
        IPv6AddressTestCase("22", ip: nil),
        IPv6AddressTestCase("2222@", ip: nil),
        IPv6AddressTestCase("255.255.255.25555", ip: nil),
        IPv6AddressTestCase("2:", ip: nil),
        IPv6AddressTestCase("2:ff:1:1:7:ff:1:1:7.", ip: nil),
        IPv6AddressTestCase(
            "2f:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000G01",
            ip: nil
        ),
        IPv6AddressTestCase("429495", ip: nil),
        IPv6AddressTestCase("5::5::", ip: nil),
        IPv6AddressTestCase("6.6.", ip: nil),
        IPv6AddressTestCase("992.", ip: nil),
        IPv6AddressTestCase("::00001", ip: nil),
        IPv6AddressTestCase("::10000", ip: nil),
        IPv6AddressTestCase(
            "::1:1",
            ip: IP(0x0000_0000_0000_0000_0000_0000_0001_0001, "::1:1", "::0.1.0.1")
        ),
        IPv6AddressTestCase(
            "::ff:1:1:7.0.0.1",
            ip: IP(0x0000_0000_0000_00ff_0001_0001_0700_0001, "::ff:1:1:700:1", "::ff:1:1:7.0.0.1")
        ),
        IPv6AddressTestCase("::ff:1:1:7:ff:1:1:7.", ip: nil),
        IPv6AddressTestCase("::ff:1:1:7ff:1:8:7.0.0.1", ip: nil),
        IPv6AddressTestCase("::ff:1:1:7ff:1:8f:1:1:71", ip: nil),
        IPv6AddressTestCase("::ffff:02fff:127.0.S1", ip: nil),
        IPv6AddressTestCase(
            "::ffff:127.0.0.1",
            ip: IP(
                0x0000_0000_0000_0000_0000_ffff_7f00_0001,
                "::ffff:7f00:1",
                "::ffff:127.0.0.1"
            )
        ),
        IPv6AddressTestCase(
            "::ffff:1:7.0.0.1",
            ip: IP(0x0000_0000_0000_0000_ffff_0001_0700_0001, "::ffff:1:700:1", "::ffff:1:7.0.0.1")
        ),
        IPv6AddressTestCase("A:f:ff:1:1:D:ff:1:1::7.", ip: nil),
        IPv6AddressTestCase("AAAAA.", ip: nil),
        IPv6AddressTestCase("D:::", ip: nil),
        IPv6AddressTestCase("DF8F", ip: nil),
        IPv6AddressTestCase(
            "F::",
            ip: IP(0x000f_0000_0000_0000_0000_0000_0000_0000, "f::", "f::0.0.0.0")
        ),
        IPv6AddressTestCase(
            "F:ff:100:7ff:1:8:7.0.10.1",
            ip: IP(
                0x000f_00ff_0100_07ff_0001_0008_0700_0a01,
                "f:ff:100:7ff:1:8:700:a01",
                "f:ff:100:7ff:1:8:7.0.10.1"
            )
        ),
        IPv6AddressTestCase("d92.", ip: nil),
        IPv6AddressTestCase(
            "ff:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001",
            ip: nil
        ),
        IPv6AddressTestCase(
            "fff2:2::ff2:2:f7",
            ip: IP(
                0xfff2_0002_0000_0000_0000_0ff2_0002_00f7,
                "fff2:2::ff2:2:f7",
                "fff2:2::ff2:0.2.0.247"
            )
        ),
        IPv6AddressTestCase("ffff:ff:ff:fff:ff:ff:ff:", ip: nil),
    ]

    @available(SwiftStdlib 6.0, *)
    static let idnaStringAndAddress: [Self] = [
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
        IPv6AddressTestCase(
            "₁₁₁₁:2222:3333:4444:5555:₆6₆6:7777:8888",
            ip: IP(
                0x1111_2222_3333_4444_5555_6666_7777_8888,
                "1111:2222:3333:4444:5555:6666:7777:8888",
                "1111:2222:3333:4444:5555:6666:119.119.136.136"
            )
        ),
        /// Would parse to 1111:2222:3333:4444:5555:6666:7777:8888 assuming IDNA-compliant parsing
        IPv6AddressTestCase(
            "\u{AD}1\u{AD}111:2222︓\u{AD}3333:4444︓55\u{200B}\u{2064}55:₆6₆6:7777:8888\u{200B}",
            ip: IP(
                0x1111_2222_3333_4444_5555_6666_7777_8888,
                "1111:2222:3333:4444:5555:6666:7777:8888",
                "1111:2222:3333:4444:5555:6666:119.119.136.136"
            )
        ),
        /// Would parse to 2001:0DB8:85A3:F109:197A:8A2E:0370:7334 assuming IDNA-compliant parsing
        IPv6AddressTestCase(
            "\u{200B}﹇₂₀\u{AD}\u{200B}₀₁︓\u{2064}₀ⒹⒷ₈︓₈₅Ⓐ₃\u{2064}︓Ⓕ₁₀₉︓₁₉₇Ⓐ︓₈Ⓐ₂Ⓔ︓₀₃₇₀︓₇₃₃₄﹈\u{2064}",
            ip: IP(
                0x2001_0DB8_85A3_F109_197A_8A2E_0370_7334,
                "2001:db8:85a3:f109:197a:8a2e:370:7334",
                "2001:db8:85a3:f109:197a:8a2e:3.112.115.52"
            )
        ),
        IPv6AddressTestCase("\u{AD}", ip: nil),
        IPv6AddressTestCase("\u{AD}\u{200B}\u{2064}", ip: nil),
        IPv6AddressTestCase("[\u{AD}]", ip: nil),
        IPv6AddressTestCase("[\u{AD}\u{200B}\u{2064}]", ip: nil),
        /// We should support parsing these next 4 as valid if we were to support IDNA-compliant parsing,
        /// but we can skip them if necessary for performance.
        /// If you remove the IDNA-ignored unicode scalars, it becomes clear they are valid.
        IPv6AddressTestCase("[\u{AD}::]", ip: IP(0, "::", "::0.0.0.0")),
        IPv6AddressTestCase("[::\u{AD}]", ip: IP(0, "::", "::0.0.0.0")),
        IPv6AddressTestCase(
            "[1:\u{AD}:1]",
            ip: IP(0x0001_0000_0000_0000_0000_0000_0000_0001, "1::1", "1::0.0.0.1")
        ),
        IPv6AddressTestCase(
            "[1:\u{AD}\u{200B}:1]",
            ip: IP(0x0001_0000_0000_0000_0000_0000_0000_0001, "1::1", "1::0.0.0.1")
        ),
    ]

    /// Derived from the exhaustive IPv4 octet cases, so the IPv4-embedded forms are hardcoded
    /// in exactly one place. Covers the IPv4-mapped prefix, which is the only one the
    /// non-forced mixed notation applies to, plus the NAT64 well-known prefix and a compressed
    /// and an uncompressed prefix, which only the forced mixed notation applies to.
    private static let ipv4Embedded: [Self] = IPv4DecimalLengthTestCase.all.flatMap { octets in
        [
            Self(
                "::ffff:\(octets.string)",
                ip: IP(
                    octets.address.asIPv4MappedIPv6,
                    octets.ipv4MappedExpandedIPv6Description,
                    "::ffff:\(octets.description)"
                )
            ),
            Self(
                "64:ff9b::\(octets.string)",
                ip: IP(
                    octets.address.asNAT64WellKnownIPv4EmbeddedIPv6,
                    octets.nat64ExpandedIPv6Description,
                    "64:ff9b::\(octets.description)"
                )
            ),
            Self(
                "2001:db8::\(octets.string)",
                ip: IP(
                    octets.documentationEmbeddedIPv6,
                    octets.documentationEmbeddedIPv6Description,
                    "2001:db8::\(octets.description)"
                )
            ),
            Self(
                "1:2:3:4:5:6:\(octets.string)",
                ip: IP(
                    octets.uncompressedPrefixEmbeddedIPv6,
                    octets.uncompressedPrefixEmbeddedIPv6Description,
                    "1:2:3:4:5:6:\(octets.description)"
                )
            ),
        ]
    }

    private static let boundaryCharacters: [Self] = [
        UInt8(ascii: ":") + 1,
        UInt8(ascii: "0") - 1, UInt8(ascii: "9") + 1,
        UInt8(ascii: "a") - 1, UInt8(ascii: "f") + 1,
        UInt8(ascii: "A") - 1, UInt8(ascii: "F") + 1,
        UInt8(ascii: ".") - 1, UInt8(ascii: ".") + 1,
    ].map { utf8Byte in
        let char = String(UnicodeScalar(utf8Byte))
        return IPv6AddressTestCase("::1:\(char):1", ip: nil)
    }
}

extension IPv6Address.DescriptionOptions {
    static let allCombos: [Self] = [
        Self([]),
        Self([.useMixedNotation]),
        Self([.forceMixedNotation]),
        Self([.useMixedNotation, .forceMixedNotation]),
        Self([.encloseInSquareBrackets]),
        Self([.useMixedNotation, .encloseInSquareBrackets]),
        Self([.forceMixedNotation, .encloseInSquareBrackets]),
        Self([.useMixedNotation, .forceMixedNotation, .encloseInSquareBrackets]),
    ]
}

@available(SwiftStdlib 6.0, *)
extension IPPropertyTestCase where IPAddressType == IPv6Address {
    static let all: [Self] = [
        IPPropertyTestCase(IPv6Address("::1")!, "isLoopback", \.isLoopback),
        IPPropertyTestCase(IPv6Address("::1:1")!, "!isLoopback", { @Sendable in !$0.isLoopback }),
        IPPropertyTestCase(IPv6Address("FF00::")!, "isMulticast", \.isMulticast),
        IPPropertyTestCase(IPv6Address("FF92::")!, "isMulticast", \.isMulticast),
        IPPropertyTestCase(IPv6Address("FFFF:998A::1")!, "isMulticast", \.isMulticast),
        IPPropertyTestCase(IPv6Address("FF::")!, "!isMulticast", { @Sendable in !$0.isMulticast }),
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
        IPPropertyTestCase(IPv6Address("::")!, "isUnspecified", \.isUnspecified),
        IPPropertyTestCase(
            IPv6Address("::1")!,
            "!isUnspecified",
            { @Sendable in !$0.isUnspecified }
        ),
        IPPropertyTestCase(IPv6Address("FC00::")!, "isUniqueLocal", \.isUniqueLocal),
        IPPropertyTestCase(IPv6Address("FD12:3456::1")!, "isUniqueLocal", \.isUniqueLocal),
        IPPropertyTestCase(
            IPv6Address("FDFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF")!,
            "isUniqueLocal",
            \.isUniqueLocal
        ),
        IPPropertyTestCase(
            IPv6Address("FB00::")!,
            "!isUniqueLocal",
            { @Sendable in !$0.isUniqueLocal }
        ),
        IPPropertyTestCase(
            IPv6Address("FE00::")!,
            "!isUniqueLocal",
            { @Sendable in !$0.isUniqueLocal }
        ),
        IPPropertyTestCase(IPv6Address("2001:DB8::")!, "isDocumentation", \.isDocumentation),
        IPPropertyTestCase(IPv6Address("2001:DB8:1234::1")!, "isDocumentation", \.isDocumentation),
        IPPropertyTestCase(
            IPv6Address("2001:DB8:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF")!,
            "isDocumentation",
            \.isDocumentation
        ),
        IPPropertyTestCase(
            IPv6Address("2001:DB7::")!,
            "!isDocumentation",
            { @Sendable in !$0.isDocumentation }
        ),
        IPPropertyTestCase(
            IPv6Address("2001:DB9::")!,
            "!isDocumentation",
            { @Sendable in !$0.isDocumentation }
        ),
        IPPropertyTestCase(IPv6Address("::FFFF:0:0")!, "isIPv4Mapped", \.isIPv4Mapped),
        IPPropertyTestCase(IPv6Address("::FFFF:1.2.3.4")!, "isIPv4Mapped", \.isIPv4Mapped),
        IPPropertyTestCase(IPv6Address("::FFFF:255.255.255.255")!, "isIPv4Mapped", \.isIPv4Mapped),
        IPPropertyTestCase(
            IPv6Address("::FFFE:0:0")!,
            "!isIPv4Mapped",
            { @Sendable in !$0.isIPv4Mapped }
        ),
        IPPropertyTestCase(
            IPv6Address("::1:FFFF:0:0")!,
            "!isIPv4Mapped",
            { @Sendable in !$0.isIPv4Mapped }
        ),
        IPPropertyTestCase(
            IPv6Address("::1.2.3.4")!,
            "!isIPv4Mapped",
            { @Sendable in !$0.isIPv4Mapped }
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9B::")!,
            "!isIPv4Mapped",
            { @Sendable in !$0.isIPv4Mapped }
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9B::")!,
            "isNAT64WellKnownIPv4Embedded",
            \.isNAT64WellKnownIPv4Embedded
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9B::192.0.2.33")!,
            "isNAT64WellKnownIPv4Embedded",
            \.isNAT64WellKnownIPv4Embedded
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9B::FFFF:FFFF")!,
            "isNAT64WellKnownIPv4Embedded",
            \.isNAT64WellKnownIPv4Embedded
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9B:1::")!,
            "!isNAT64WellKnownIPv4Embedded",
            { @Sendable in !$0.isNAT64WellKnownIPv4Embedded }
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9C::")!,
            "!isNAT64WellKnownIPv4Embedded",
            { @Sendable in !$0.isNAT64WellKnownIPv4Embedded }
        ),
        IPPropertyTestCase(
            IPv6Address("65:FF9B::")!,
            "!isNAT64WellKnownIPv4Embedded",
            { @Sendable in !$0.isNAT64WellKnownIPv4Embedded }
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9B:0:0:0:1::")!,
            "!isNAT64WellKnownIPv4Embedded",
            { @Sendable in !$0.isNAT64WellKnownIPv4Embedded }
        ),
        IPPropertyTestCase(
            IPv6Address("::FFFF:0:0")!,
            "!isNAT64WellKnownIPv4Embedded",
            { @Sendable in !$0.isNAT64WellKnownIPv4Embedded }
        ),
        IPPropertyTestCase(
            IPv6Address("::FFFF:1.2.3.4")!,
            "isWellKnownIPv4Embedded",
            \.isWellKnownIPv4Embedded
        ),
        IPPropertyTestCase(
            IPv6Address("::FFFF:0:0")!,
            "isWellKnownIPv4Embedded",
            \.isWellKnownIPv4Embedded
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9B::1.2.3.4")!,
            "isWellKnownIPv4Embedded",
            \.isWellKnownIPv4Embedded
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9B::")!,
            "isWellKnownIPv4Embedded",
            \.isWellKnownIPv4Embedded
        ),
        IPPropertyTestCase(
            IPv6Address("::1.2.3.4")!,
            "!isWellKnownIPv4Embedded",
            { @Sendable in !$0.isWellKnownIPv4Embedded }
        ),
        IPPropertyTestCase(
            IPv6Address("::")!,
            "!isWellKnownIPv4Embedded",
            { @Sendable in !$0.isWellKnownIPv4Embedded }
        ),
        IPPropertyTestCase(
            IPv6Address("64:FF9B:1::1.2.3.4")!,
            "!isWellKnownIPv4Embedded",
            { @Sendable in !$0.isWellKnownIPv4Embedded }
        ),
        IPPropertyTestCase(
            IPv6Address("2001:DB8::")!,
            "!isWellKnownIPv4Embedded",
            { @Sendable in !$0.isWellKnownIPv4Embedded }
        ),
        IPPropertyTestCase(IPv6Address("::")!, "isContiguous", \.isContiguous),
        IPPropertyTestCase(IPv6Address("FFFF::")!, "isContiguous", \.isContiguous),
        IPPropertyTestCase(
            IPv6Address("FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF")!,
            "isContiguous",
            \.isContiguous
        ),
        IPPropertyTestCase(
            IPv6Address("::FFFF")!,
            "!isContiguous",
            { @Sendable in !$0.isContiguous }
        ),
        IPPropertyTestCase(
            IPv6Address("FFFF::FFFF")!,
            "!isContiguous",
            { @Sendable in !$0.isContiguous }
        ),
        IPPropertyTestCase(
            IPv6Address("FEFF::")!,
            "!isContiguous",
            { @Sendable in !$0.isContiguous }
        ),
    ]
}

extension IPv6AddressTestCase {
    /// IPv6 addresses that are in neither well-known IPv4-embedding prefix, so they must not
    /// convert to an IPv4 address. The convertible counterparts are derived exhaustively from
    /// `IPv4DecimalLengthTestCase.all` instead of being hardcoded.
    static let nonIPv4EmbeddedStrings: [String] = [
        "0:0:1:0:0:ffff:abcd:ef01",
        "ffff:ffff:ffff:ffff:ffff:ffff:abcd:ef01",
        "64:ff9b:1::c000:221",
        "64:ff9c::c000:221",
        "65:ff9b::c000:221",
        "64:ff9b:0:0:0:1:c000:221",
        "::c000:221",
    ]
}
