import Testing
import Carrier_Primitives_Test_Support

@Suite
struct `Int8+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Int8+Carrier Tests`.Unit {

    @Test
    func `Int8 round-trips via underlying`() {
        let v: Int8 = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `Int8 round-trips via init from underlying`() {
        let v: Int8 = 99
        #expect(Int8(v.underlying) == 99)
    }
}

extension `Int8+Carrier Tests`.`Edge Case` {

    @Test
    func `Int8 handles min`() {
        let v: Int8 = .min
        #expect(v.underlying == .min)
    }

    @Test
    func `Int8 handles max`() {
        let v: Int8 = .max
        #expect(v.underlying == .max)
    }

    @Test
    func `Int8 handles zero`() {
        let v: Int8 = 0
        #expect(v.underlying == 0)
    }
}

extension `Int8+Carrier Tests`.Integration {

    @Test
    func `Int8 satisfies some Carrier<Int8>`() {
        #expect(Fixture.value(of: 7 as Int8) == 7)
    }
}
