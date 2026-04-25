import Testing
import Carrier_Primitives_Test_Support

@Suite("Bool+Carrier")
struct BoolCarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension BoolCarrierTests.Unit {

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

extension BoolCarrierTests.`Edge Case` {

    @Test
    func `Bool false round-trips via underlying`() {
        let v: Bool = false
        #expect(v.underlying == false)
    }
}

extension BoolCarrierTests.Integration {

    @Test
    func `Bool satisfies some Carrier<Bool>`() {
        #expect(Fixture.value(of: true) == true)
    }
}
