import Carrier_Primitives_Test_Support
import Testing

// Q1 (Copyable & Escapable Underlying) fixture — exercises the
// simplest carrier shape: plain storage, plain getter, plain init.
// `@_lifetime` annotations are omitted because Int is Escapable.
// `Domain` defaults to `Never`.

@Suite
struct `Fixture.Plain Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Fixture.Plain Tests`.Unit {

    @Test
    func `Plain stores and reads Int underlying`() {
        let c = Fixture.Plain(42)
        #expect(c.underlying == 42)
    }

    @Test
    func `Plain round-trips via init from underlying`() {
        let a = Fixture.Plain(100)
        let b = Fixture.Plain(a.underlying)
        #expect(a.underlying == b.underlying)
    }
}

extension `Fixture.Plain Tests`.`Edge Case` {

    @Test
    func `Plain handles Int min`() {
        let c = Fixture.Plain(.min)
        #expect(c.underlying == .min)
    }

    @Test
    func `Plain handles Int max`() {
        let c = Fixture.Plain(.max)
        #expect(c.underlying == .max)
    }

    @Test
    func `Plain handles zero`() {
        let c = Fixture.Plain(0)
        #expect(c.underlying == 0)
    }
}

extension `Fixture.Plain Tests`.Integration {

    @Test
    func `Plain satisfies some Carrier<Int>`() {
        let c = Fixture.Plain(55)
        #expect(Fixture.value(of: c) == 55)
    }

    @Test
    func `Plain reflects Underlying = Int and Domain = Never`() {
        let c = Fixture.Plain(7)
        #expect(Fixture.describe(c) == "Carrier<Int> with Domain Never")
    }
}
