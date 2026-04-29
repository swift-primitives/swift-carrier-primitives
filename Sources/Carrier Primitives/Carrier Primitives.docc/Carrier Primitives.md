# ``Carrier_Primitives``

@Metadata {
    @DisplayName("Carrier Primitives")
    @TitleHeading("Swift Institute — Primitives Layer")
    @CallToAction(
        url: "doc:GettingStarted",
        purpose: link,
        label: "Get Started"
    )
}

A unified super-protocol for phantom-typed value wrappers.

## Overview

`Carrier Primitives` ships ``Carrier_Primitives/Carrier``, a parameterized protocol abstracting over types that carry a wrapped `Underlying` value with an optional phantom `Domain` tag. Cardinal, Ordinal, Hash.Value, Tagged, and similar value-carrying primitives all fit the pattern; Carrier is the canonical abstraction under which they compose.

The protocol covers all four `Copyable × Escapable` quadrants in a single declaration — both the carrier and its underlying can independently admit or suppress `Copyable` and `Escapable`. For the full technical reference, including the four-quadrant grid and the design rationale, see ``Carrier_Primitives/Carrier``. For a guided first use, follow <doc:GettingStarted>.

## Topics

### Tutorials

- <doc:GettingStarted>

### Essentials

- <doc:Understanding-Carriers>

### Conformance

- <doc:Conformance-Recipes>
- <doc:Round-trip-Semantics>

### Comparisons

- <doc:Carrier-vs-RawRepresentable>

### Core Protocol

- ``Carrier_Primitives/Carrier``
