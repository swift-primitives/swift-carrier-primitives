import Testing
import Carrier_Primitives_Test_Support

@Suite("Int8+Carrier")
struct Int8CarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension Int8CarrierTests.Unit {

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

extension Int8CarrierTests.`Edge Case` {

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

extension Int8CarrierTests.Integration {

    @Test
    func `Int8 satisfies some Carrier<Int8>`() {
        #expect(Fixture.value(of: 7 as Int8) == 7)
    }
}
