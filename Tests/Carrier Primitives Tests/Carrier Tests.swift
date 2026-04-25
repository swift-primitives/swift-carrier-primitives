import Testing
import Carrier_Primitives_Test_Support

// Carrier<Underlying> is a generic protocol — per [SWIFT-TEST-003] the
// test suite uses the parallel namespace pattern (a non-generic
// top-level struct).
//
// This file scopes only the protocol-level surface (generic dispatch,
// associated-type defaults, parameterized constraint). Per-quadrant
// fixture conformance assertions live in the dedicated
// `Fixture.{Plain,Unique,Scoped} Tests.swift` files.

@Suite("Carrier")
struct CarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
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
        // the caller spelling it out, and (b) confirm Never satisfies
        // the ~Copyable & ~Escapable constraint on the associated type.
        let c = Fixture.Plain(42)
        let d = Fixture.domainDescription(c)
        #expect(d == "Never")
    }
}
