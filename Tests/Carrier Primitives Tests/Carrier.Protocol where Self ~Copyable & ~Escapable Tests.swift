import Carrier_Primitives_Test_Support
import Testing

// Tests focused on the `Carrier where Self ~Copyable & ~Escapable`
// default extension shipped in `Sources/Carrier Primitives/Carrier where Self ~Copyable & ~Escapable.swift`.
//
// V5 design property: the throwing init takes a closure that validates
// the underlying value before construction. When validation passes, the
// init delegates to the existing non-throwing `init(_ underlying:)`
// requirement. When validation fails, the closure's error type is
// propagated through typed throws — `E == Never` for the no-validation
// case is REFUTED (see Experiments/generic-throws-init H2).
//
// Coverage shape:
//   • Unit — validation-pass path on Plain, Unique, Scoped fixtures
//     (one per quadrant covered by the suppressed-protocol constraint).
//   • Edge Case — typed throws preserves the closure's E across
//     fixtures.
//   • Integration — none here; cross-fixture dispatch is handled in
//     `Carrier Tests.swift`.

@Suite
struct `Carrier.Protocol where Self ~Copyable & ~Escapable Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

enum Validation: Swift.Error, Sendable {
    case rejected
}

extension `Carrier.Protocol where Self ~Copyable & ~Escapable Tests`.Unit {

    @Test
    func `Q1 validation-pass constructs Plain via default throwing init`() throws(Validation) {
        let c = try Fixture.Plain(42) { v in
            #expect(v == 42)
        }
        #expect(c.underlying == 42)
    }

    @Test
    func `Q2 validation-pass constructs Unique via default throwing init`() throws(Validation) {
        let resource = Fixture.Unique.Resource(raw: 7)
        let u = try Fixture.Unique(resource) { _ in
            // Validation closure takes a borrow; cannot copy ~Copyable here.
        }
        #expect(u.underlying.raw == 7)
    }

    @Test
    func `Q4 validation-pass constructs Scoped via default throwing init`() throws(Validation) {
        let resource = Fixture.Scoped.Resource(raw: 11)
        let s = try Fixture.Scoped(resource) { _ in }
        #expect(s.underlying.raw == 11)
    }
}

extension `Carrier.Protocol where Self ~Copyable & ~Escapable Tests`.`Edge Case` {

    @Test
    func `Q1 validation-fail throws closure's typed error`() {
        #expect(throws: Validation.rejected) {
            try Fixture.Plain(0) { v throws(Validation) in
                if v == 0 { throw .rejected }
            }
        }
    }

    @Test
    func `Q2 validation-fail throws closure's typed error`() {
        #expect(throws: Validation.rejected) {
            let resource = Fixture.Unique.Resource(raw: 0)
            _ = try Fixture.Unique(resource) { (v: borrowing Fixture.Unique.Resource) throws(Validation) in
                if v.raw == 0 { throw .rejected }
            }
        }
    }

    @Test
    func `Q4 validation-fail throws closure's typed error`() {
        #expect(throws: Validation.rejected) {
            let resource = Fixture.Scoped.Resource(raw: 0)
            _ = try Fixture.Scoped(resource) { (v: borrowing Fixture.Scoped.Resource) throws(Validation) in
                if v.raw == 0 { throw .rejected }
            }
        }
    }
}
