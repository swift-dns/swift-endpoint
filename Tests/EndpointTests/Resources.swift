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
        var testsDirectory: [String]

        if let projectRootForTesting = ProcessInfo.processInfo
            .environment["PROJECT_ROOT_FOR_TESTING"],
            !projectRootForTesting.isEmpty
        {
            testsDirectory = URL(fileURLWithPath: projectRootForTesting).pathComponents
            testsDirectory.append("Tests")
        } else {
            /// `#filePath` is `<Tests>/EndpointTests/Resources.swift`, so dropping the file name
            /// and the test target's directory leaves the `Tests` directory itself.
            let thisFile = URL(fileURLWithPath: #filePath).pathComponents
            testsDirectory = Array(thisFile.dropLast(2))
        }

        testsDirectory.append(contentsOf: ["Resources", self.rawValue])

        return testsDirectory.joined(separator: "/")
    }
}
