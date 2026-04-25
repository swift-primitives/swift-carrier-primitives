extension Fixture.Unique {
    /// ~Copyable resource type used as the Underlying for
    /// `Fixture.Unique`. Minimal shape — one Int field — sufficient to
    /// exercise the ~Copyable / Escapable quadrant.
    public struct Resource: ~Copyable {
        public var raw: Int

        public init(raw: Int) {
            self.raw = raw
        }
    }
}
