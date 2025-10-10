@available(swiftEndpointApplePlatforms 13, *)
extension String {
    mutating func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        if #available(swiftEndpointApplePlatforms 26, *) {
            return try body(self.utf8Span.span)
        }
        return try self.withSpan_macOSUnder26(body)
    }

    mutating func withSpan_macOSUnder26<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        do {
            return try self.withUTF8 { buffer in
                try body(buffer.span)
            }
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unexpected error: \(String(reflecting: error))")
        }
    }
}

@available(swiftEndpointApplePlatforms 13, *)
extension Substring {
    mutating func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        if #available(swiftEndpointApplePlatforms 26, *) {
            return try body(self.utf8Span.span)
        }
        return try self.withSpan_macOSUnder26(body)
    }

    mutating func withSpan_macOSUnder26<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        do {
            return try self.withUTF8 { buffer in
                try body(buffer.span)
            }
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unexpected error: \(String(reflecting: error))")
        }
    }
}
