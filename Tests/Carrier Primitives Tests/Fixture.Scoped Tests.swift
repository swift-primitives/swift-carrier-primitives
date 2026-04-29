import Testing
import Carrier_Primitives_Test_Support

// Q4 (~Copyable & ~Escapable Underlying) fixture — both suppressions
// apply. `@_lifetime` annotations on the getter and init are required
// (unlike Q1/Q2, where Escapable Underlying rejects them). `_read`
// yields the ~Copyable stored value by borrow with its lifetime
// scoped to self.

@Suite
struct `Fixture.Scoped Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Fixture.Scoped Tests`.Unit {

    @Test
    func `Scoped conforms with noncopyable nonescapable underlying`() {
        let c = Fixture.Scoped(Fixture.Scoped.Resource(raw: 77))
        let raw = c.underlying.raw
        #expect(raw == 77)
    }
}

extension `Fixture.Scoped Tests`.`Edge Case` {

    @Test
    func `Scoped handles raw zero`() {
        let c = Fixture.Scoped(Fixture.Scoped.Resource(raw: 0))
        #expect(c.underlying.raw == 0)
    }

    @Test
    func `Scoped handles negative raw`() {
        let c = Fixture.Scoped(Fixture.Scoped.Resource(raw: -42))
        #expect(c.underlying.raw == -42)
    }
}

extension `Fixture.Scoped Tests`.Integration {

    @Test
    func `Scoped satisfies generic Carrier reflection`() {
        let c = Fixture.Scoped(Fixture.Scoped.Resource(raw: 5))
        let desc = Fixture.describe(c)
        #expect(desc == "Carrier<Resource> with Domain Never")
    }
}
