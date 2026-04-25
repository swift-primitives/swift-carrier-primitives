import Testing
import Carrier_Primitives_Test_Support

@Suite("Int+Carrier")
struct IntCarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension IntCarrierTests.Unit {

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

extension IntCarrierTests.`Edge Case` {

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

extension IntCarrierTests.Integration {

    @Test
    func `Int satisfies some Carrier<Int>`() {
        #expect(Fixture.value(of: 77 as Int) == 77)
    }
}
