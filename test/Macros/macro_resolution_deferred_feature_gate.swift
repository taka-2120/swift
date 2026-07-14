// REQUIRES: swift_swift_parser

// RUN: %target-typecheck-verify-swift -swift-version 5 -module-name MacrosTest

// Without the DeferredMacroResolution experimental feature, using
// 'resolution: deferred' is an error (but still parses, so that module
// interfaces remain loadable).
@freestanding(expression, resolution: deferred) // expected-error{{'@freestanding' is an experimental feature; use '-enable-experimental-feature DeferredMacroResolution'}}
macro stringifyDeferred<T>(_ value: T) -> (T, String) = #externalMacro(module: "MissingModule", type: "MissingType")
// expected-warning@-1{{external macro implementation type}}

// The default spelling remains unaffected.
@freestanding(expression, resolution: independent)
macro stringifyIndependent<T>(_ value: T) -> (T, String) = #externalMacro(module: "MissingModule", type: "MissingType")
// expected-warning@-1{{external macro implementation type}}
