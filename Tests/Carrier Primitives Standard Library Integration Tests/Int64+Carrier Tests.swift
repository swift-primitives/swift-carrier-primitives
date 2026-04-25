import Testing
import Carrier_Primitives_Test_Support

@Suite("Int64+Carrier")
struct Int64CarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension Int64CarrierTests.Unit {

    @Test
    func `Int64 round-trips via underlying`() {
        let v: Int64 = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `Int64 round-trips via init from underlying`() {
        let v: Int64 = 99
        #expect(Int64(v.underlying) == 99)
    }
}

extension Int64CarrierTests.`Edge Case` {

    @Test
    func `Int64 handles min`() {
        let v: Int64 = .min
        #expect(v.underlying == .min)
    }

    @Test
    func `Int64 handles max`() {
        let v: Int64 = .max
        #expect(v.underlying == .max)
    }

    @Test
    func `Int64 handles zero`() {
        let v: Int64 = 0
        #expect(v.underlying == 0)
    }
}

extension Int64CarrierTests.Integration {

    @Test
    func `Int64 satisfies some Carrier<Int64>`() {
        #expect(Fixture.value(of: 7 as Int64) == 7)
    }
}
