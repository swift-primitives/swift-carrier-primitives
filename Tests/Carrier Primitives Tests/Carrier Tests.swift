import Testing
import Carrier_Primitives_Test_Support

// Carrier<Underlying> is a generic protocol — per [SWIFT-TEST-003] the
// test suite uses the parallel namespace pattern (a non-generic
// top-level struct).

@Suite("Carrier")
struct CarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit
//
// Per-quadrant exercises of the protocol's witness shape via the
// fixtures shipped in Carrier Primitives Test Support.

extension CarrierTests.Unit {

    @Test
    func `Q1 Plain stores and reads Int underlying`() {
        let c = Fixture.Plain(42)
        #expect(c.underlying == 42)
    }

    @Test
    func `Q1 Plain round-trips via init from underlying`() {
        let a = Fixture.Plain(100)
        let b = Fixture.Plain(a.underlying)
        #expect(a.underlying == b.underlying)
    }

    @Test
    func `Q2 Unique reads underlying via borrow`() {
        let c = Fixture.Unique(Fixture.Unique.Resource(raw: 99))
        let raw = c.underlying.raw
        #expect(raw == 99)
    }

    @Test
    func `Q4 Scoped conforms with noncopyable nonescapable underlying`() {
        let c = Fixture.Scoped(Fixture.Scoped.Resource(raw: 77))
        let raw = c.underlying.raw
        #expect(raw == 77)
    }
}

// MARK: - Integration
//
// Generic-dispatch tests exercising the parameterized super-protocol
// surface across multiple fixtures.

extension CarrierTests.Integration {

    @Test
    func `describe reflects Underlying and Domain at type level`() {
        let c = Fixture.Plain(7)
        let desc = Fixture.describe(c)
        #expect(desc == "Carrier<Int> with Domain Never")
    }

    @Test
    func `value accepts Plain via parameterized constraint`() {
        let c = Fixture.Plain(55)
        #expect(Fixture.value(of: c) == 55)
    }

    @Test
    func `Domain-constrained generic resolves Never for default-Domain conformer`() {
        // Exercises `where C.Domain: ~Copyable & ~Escapable` against a
        // conformer that uses the `Domain = Never` default. The generic
        // substitution machinery must (a) bind C.Domain to Never without
        // the caller spelling it out, and (b) confirm Never satisfies the
        // ~Copyable & ~Escapable constraint on the associated type.
        let c = Fixture.Plain(42)
        let d = Fixture.domainDescription(c)
        #expect(d == "Never")
    }
}
