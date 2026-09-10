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
        try! Data(contentsOf: self.qualifiedURL())
    }

    private func qualifiedURL() -> URL {
        let testsDirectory: URL

        if let projectRootForTesting = ProcessInfo.processInfo
            .environment["PROJECT_ROOT_FOR_TESTING"],
            !projectRootForTesting.isEmpty
        {
            testsDirectory = URL(fileURLWithPath: projectRootForTesting)
                .appendingPathComponent("Tests")
        } else {
            /// `#filePath` is `<Tests>/EndpointTests/Resources.swift`, so dropping the file name
            /// and the test target's directory leaves the `Tests` directory itself.
            testsDirectory = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
        }

        let resourcesDirectory = testsDirectory.appendingPathComponent("Resources")
        return resourcesDirectory.appendingPathComponent(self.rawValue)
    }
}
