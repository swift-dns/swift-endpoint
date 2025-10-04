import struct NIOCore.ByteBuffer


#if canImport(FoundationEssentials)
import FoundationEssentials
#else
/// We're in tests so should be fine
import Foundation
#endif

enum Resources: String {
    case topDomains = "top-domains.csv"

    func buffer() -> ByteBuffer {
        ByteBuffer(bytes: self.data())
    }

    func data() -> Data {
        FileManager.default.contents(
            atPath: self.qualifiedPath()
        )!
    }

    private func qualifiedPath() -> String {
        var components = URL(fileURLWithPath: #filePath).pathComponents

        while components.last != "swift-endpoint" {
            components.removeLast()
        }

        components.append(contentsOf: ["Tests", "Resources", self.rawValue])

        return components.joined(separator: "/")
    }
}
