import Carrier_Primitives

/// Namespace for test fixtures — concrete Carrier conformers covering
/// the four Copyable × Escapable quadrants plus generic helper methods
/// used by the test suite.
///
/// Fixtures are placed in a separate file from @Test declarations
/// because generic file-scope helpers alongside @Test functions trigger
/// Swift 6.3.1 "global variable must be a compile-time constant to use
/// @section attribute" errors on the test metadata globals.
enum Fixture {}
