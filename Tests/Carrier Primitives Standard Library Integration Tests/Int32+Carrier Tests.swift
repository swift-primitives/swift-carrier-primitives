import Testing
import Carrier_Primitives_Test_Support

@Suite
struct `Int32+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Int32+Carrier Tests`.Unit {

    @Test
    func `Int32 round-trips via underlying`() {
        let v: Int32 = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `Int32 round-trips via init from underlying`() {
        let v: Int32 = 99
        #expect(Int32(v.underlying) == 99)
    }
}

extension `Int32+Carrier Tests`.`Edge Case` {

    @Test
    func `Int32 handles min`() {
        let v: Int32 = .min
        #expect(v.underlying == .min)
    }

    @Test
    func `Int32 handles max`() {
        let v: Int32 = .max
        #expect(v.underlying == .max)
    }

    @Test
    func `Int32 handles zero`() {
        let v: Int32 = 0
        #expect(v.underlying == 0)
    }
}

extension `Int32+Carrier Tests`.Integration {

    @Test
    func `Int32 satisfies some Carrier<Int32>`() {
        #expect(Fixture.value(of: 7 as Int32) == 7)
    }
}
