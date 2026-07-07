extension String {
    func toCStringArray() -> [Int8] {
        [UInt8](utf8).map(Int8.init) + [0]
    }
}
