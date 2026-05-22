// Carrier.swift
// The Carrier namespace. Lives in the Carrier Namespace target so consumers
// extending Carrier with sub-namespaces (e.g. Numeric.Decimal.Carrier,
// Text.Case.Carrier) can import only the namespace without pulling in
// the protocol declaration or stdlib integration.

/// Namespace for the Carrier abstraction.
///
/// The conformance contract is `Carrier.\`Protocol\`` (or the alias
/// `Carrying`). Conformers write:
///
/// ```swift
/// extension Cardinal: Carrier.`Protocol` {
///     typealias Underlying = Cardinal
/// }
/// ```
///
/// The `Carrier.\`Protocol\`` typealias and its conditional-extension
/// default implementations live in the `Carrier Protocol` target.
public enum Carrier {}
