extension Fixture.Scoped {
    /// ~Copyable & ~Escapable resource type used as the Underlying for
    /// `Fixture.Scoped`. Exercises the quadrant where both suppressions
    /// apply.
    public struct Resource: ~Copyable, ~Escapable {
        public var raw: Int

        public init(raw: Int) {
            self.raw = raw
        }
    }
}
