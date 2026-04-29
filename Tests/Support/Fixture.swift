/// Namespace for test fixtures — concrete Carrier conformers covering
/// the four Copyable × Escapable quadrants plus generic helper methods
/// used by both test targets in this package.
///
/// Fixtures live in Test Support so that both `Carrier Primitives Tests`
/// (protocol-level tests) and `Carrier Primitives Standard Library
/// Integration Tests` (stdlib-conformance tests) can consume them
/// through a single import per [TEST-010] / [TEST-019].
///
/// Fixtures are placed in a separate file from `@Test` declarations
/// because generic file-scope helpers alongside `@Test` functions
/// trigger Swift 6.3.1 "global variable must be a compile-time constant
/// to use @section attribute" errors on the test metadata globals.
public enum Fixture {}
