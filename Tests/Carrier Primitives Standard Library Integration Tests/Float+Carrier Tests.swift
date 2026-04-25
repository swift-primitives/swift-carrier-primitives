import Testing
import Carrier_Primitives_Test_Support

@Suite("Float+Carrier")
struct FloatCarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension FloatCarrierTests.Unit {

    @Test
    func `Float round-trips via underlying`() {
        let v: Float = 1.5
        #expect(v.underlying == 1.5)
    }

    @Test
    func `Float round-trips via init from underlying`() {
        let v: Float = 2.5
        #expect(Float(v.underlying) == 2.5)
    }
}

extension FloatCarrierTests.`Edge Case` {

    @Test
    func `Float handles zero`() {
        let v: Float = 0.0
        #expect(v.underlying == 0.0)
    }

    @Test
    func `Float handles negative zero (preserves sign)`() {
        let v: Float = -0.0
        #expect(v.underlying.bitPattern == Float(-0.0).bitPattern)
    }

    @Test
    func `Float handles infinity`() {
        let v: Float = .infinity
        #expect(v.underlying == .infinity)
    }

    @Test
    func `Float handles NaN (compared via bitPattern)`() {
        let v: Float = .nan
        #expect(v.underlying.bitPattern == Float.nan.bitPattern)
    }
}

extension FloatCarrierTests.Integration {

    @Test
    func `Float satisfies some Carrier<Float>`() {
        #expect(Fixture.value(of: 7.5 as Float) == 7.5)
    }
}
