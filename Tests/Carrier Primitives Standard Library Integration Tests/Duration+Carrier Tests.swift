import Testing
import Carrier_Primitives_Test_Support

@Suite
struct `Duration+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Duration+Carrier Tests`.Unit {

    @Test
    func `Duration round-trips via underlying`() {
        let v: Duration = .milliseconds(500)
        #expect(v.underlying == .milliseconds(500))
    }
}

extension `Duration+Carrier Tests`.`Edge Case` {

    @Test
    func `Duration handles zero`() {
        let v: Duration = .zero
        #expect(v.underlying == .zero)
    }

    @Test
    func `Duration handles negative`() {
        let v: Duration = .milliseconds(-1)
        #expect(v.underlying == .milliseconds(-1))
    }

    @Test
    func `Duration handles nanosecond resolution`() {
        let v: Duration = .nanoseconds(1)
        #expect(v.underlying == .nanoseconds(1))
    }

    @Test
    func `Duration handles large values`() {
        let v: Duration = .seconds(86_400)
        #expect(v.underlying == .seconds(86_400))
    }
}

extension `Duration+Carrier Tests`.Integration {

    @Test
    func `Duration satisfies some Carrier<Duration>`() {
        let v: Duration = .seconds(2)
        #expect(Fixture.value(of: v) == .seconds(2))
    }
}
