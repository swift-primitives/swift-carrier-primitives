// Carrier.swift
// The Carrier namespace. The protocol itself lives at module scope as
// `_CarrierProtocol` (Swift does not allow protocols nested inside
// types); this typealias exposes the user-facing path
// `Carrier.`Protocol``. The convenience alias `Carrying` is in
// Carrying.swift.

/// Namespace for the Carrier abstraction.
///
/// The conformance contract is `Carrier.`Protocol`` (or the alias
/// `Carrying`). Conformers write:
///
/// ```swift
/// extension Cardinal: Carrier.`Protocol` {
///     typealias Underlying = Cardinal
/// }
/// ```
public enum Carrier {
    /// The Carrier conformance contract. Hoisted to module scope as
    /// `_CarrierProtocol` for Swift's protocol-nesting limitation;
    /// access the contract via this typealias.
    public typealias `Protocol` = _CarrierProtocol
}
