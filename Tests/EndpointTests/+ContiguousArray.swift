extension ContiguousArray<UInt8> {
    init(copying span: Span<UInt8>) {
        self.init()
        self.reserveCapacity(span.count)
        for index in span.indices {
            self.append(span[index])
        }
    }
}
