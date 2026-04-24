extension Fixture.Unique {
    /// ~Copyable resource type used as the Underlying for
    /// `Fixture.Unique`. Minimal shape — one Int field — sufficient to
    /// exercise the ~Copyable / Escapable quadrant.
    struct Resource: ~Copyable {
        var raw: Int
    }
}
