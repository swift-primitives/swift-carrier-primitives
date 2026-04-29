import Carrier_Primitives_Test_Support
import Testing

@Suite
struct `Int+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Int+Carrier Tests`.Unit {

    @Test
    func `Int round-trips via underlying`() {
        let v: Int = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `Int round-trips via init from underlying`() {
        let v: Int = 99
        #expect(Int(v.underlying) == 99)
    }
}

extension `Int+Carrier Tests`.`Edge Case` {

    @Test
    func `Int handles min`() {
        let v: Int = .min
        #expect(v.underlying == .min)
    }

    @Test
    func `Int handles max`() {
        let v: Int = .max
        #expect(v.underlying == .max)
    }

    @Test
    func `Int handles zero`() {
        let v: Int = 0
        #expect(v.underlying == 0)
    }
}

extension `Int+Carrier Tests`.Integration {

    @Test
    func `Int satisfies some Carrier<Int>`() {
        #expect(Fixture.value(of: 77 as Int) == 77)
    }
}
