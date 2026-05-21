// exports.swift
// Umbrella re-export of the Carrier namespace + protocol surface.
//
// Per [MOD-005] this is the umbrella target's sole content: zero
// implementation, only `@_exported public import` of the sub-namespace
// targets. Consumers importing `Carrier_Primitives` get the full
// surface (namespace + protocol + conditional defaults) via this
// re-export chain.

@_exported public import Carrier_Namespace
@_exported public import Carrier_Protocol
