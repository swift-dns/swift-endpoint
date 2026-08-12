struct FastRNG {
    var state: UInt64 = 0x9E37_79B9_7F4A_7C15

    mutating func next() -> UInt64 {
        self.state ^= self.state &<< 13
        self.state ^= self.state &>> 7
        self.state ^= self.state &<< 17
        return self.state
    }
}
