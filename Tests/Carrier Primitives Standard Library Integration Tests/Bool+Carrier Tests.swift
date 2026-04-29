import Testing
import Carrier_Primitives_Test_Support

@Suite
struct `Bool+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Bool+Carrier Tests`.Unit {

    @Test
    func `Bool true round-trips via underlying`() {
        let v: Bool = true
        #expect(v.underlying == true)
    }

    @Test
    func `Bool round-trips via init from underlying`() {
        let v: Bool = true
        #expect(Bool(v.underlying) == true)
    }
}

extension `Bool+Carrier Tests`.`Edge Case` {

    @Test
    func `Bool false round-trips via underlying`() {
        let v: Bool = false
        #expect(v.underlying == false)
    }
}

extension `Bool+Carrier Tests`.Integration {

    @Test
    func `Bool satisfies some Carrier<Bool>`() {
        #expect(Fixture.value(of: true) == true)
    }
}
