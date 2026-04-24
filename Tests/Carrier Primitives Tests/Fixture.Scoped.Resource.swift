extension Fixture.Scoped {
    /// ~Copyable & ~Escapable resource type used as the Underlying for
    /// `Fixture.Scoped`. Exercises the quadrant where both suppressions
    /// apply.
    struct Resource: ~Copyable, ~Escapable {
        var raw: Int
    }
}
