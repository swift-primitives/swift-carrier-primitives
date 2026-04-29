import Testing
import Carrier_Primitives_Test_Support

@Suite
struct `Int16+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Int16+Carrier Tests`.Unit {

    @Test
    func `Int16 round-trips via underlying`() {
        let v: Int16 = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `Int16 round-trips via init from underlying`() {
        let v: Int16 = 99
        #expect(Int16(v.underlying) == 99)
    }
}

extension `Int16+Carrier Tests`.`Edge Case` {

    @Test
    func `Int16 handles min`() {
        let v: Int16 = .min
        #expect(v.underlying == .min)
    }

    @Test
    func `Int16 handles max`() {
        let v: Int16 = .max
        #expect(v.underlying == .max)
    }

    @Test
    func `Int16 handles zero`() {
        let v: Int16 = 0
        #expect(v.underlying == 0)
    }
}

extension `Int16+Carrier Tests`.Integration {

    @Test
    func `Int16 satisfies some Carrier<Int16>`() {
        #expect(Fixture.value(of: 7 as Int16) == 7)
    }
}
