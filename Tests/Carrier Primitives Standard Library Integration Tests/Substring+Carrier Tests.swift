import Testing
import Carrier_Primitives_Test_Support

@Suite("Substring+Carrier")
struct SubstringCarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension SubstringCarrierTests.Unit {

    @Test
    func `Substring round-trips via underlying`() {
        let full = "hello world"
        let v: Substring = full.prefix(5)
        #expect(v.underlying == "hello")
    }
}

extension SubstringCarrierTests.`Edge Case` {

    @Test
    func `Substring handles empty slice`() {
        let full = "hello"
        let v: Substring = full.prefix(0)
        #expect(v.underlying == "")
    }

    @Test
    func `Substring handles full-string slice`() {
        let full = "hello"
        let v: Substring = full[...]
        #expect(v.underlying == "hello")
    }

    @Test
    func `Substring handles unicode boundary`() {
        let full = "héllo 🌍"
        let v: Substring = full.dropLast()
        #expect(v.underlying == "héllo ")
    }
}

extension SubstringCarrierTests.Integration {

    @Test
    func `Substring satisfies some Carrier<Substring>`() {
        let v: Substring = "hello".prefix(3)
        #expect(Fixture.value(of: v) == "hel")
    }
}
