// Carrier.swift
// The `Carrier.\`Protocol\`` typealias — hoisted protocol path.
//
// The `Carrier` namespace itself lives in the `Carrier Namespace` target.
// The conformance contract is `Carrier.\`Protocol\`` (typealias here, points
// to the module-scope hoisted `_CarrierProtocol`). The convenience alias
// `Carrying` is in Carrying.swift.

public import Carrier_Primitive

extension Carrier {
    /// The Carrier conformance contract.
    ///
    /// Hoisted to module scope as `_CarrierProtocol` for Swift's
    /// protocol-nesting limitation; access the contract via this typealias.
    public typealias `Protocol` = _CarrierProtocol
}
