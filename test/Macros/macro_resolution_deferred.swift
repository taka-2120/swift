// REQUIRES: swift_swift_parser
// REQUIRES: swift_feature_DeferredMacroResolution

// RUN: %empty-directory(%t)
// RUN: split-file %s %t
// RUN: %host-build-swift -swift-version 5 -emit-library -o %t/%target-library-name(MacroDefinition) -module-name=MacroDefinition %S/Inputs/syntax_macro_definitions.swift -g -no-toolchain-stdlib-rpath

// SE-0389 baseline: the argument of a declaration-position freestanding
// macro cannot see members introduced by an attached macro on a type
// declared in another file.
// RUN: %target-swift-frontend -typecheck -verify -verify-ignore-unrelated -primary-file %t/use_independent.swift %t/model.swift -swift-version 5 -enable-experimental-feature DeferredMacroResolution -load-plugin-library %t/%target-library-name(MacroDefinition) -module-name MacroUser -typo-correction-limit 0

// With 'resolution: deferred', the same reference resolves because name
// lookup within the macro argument is allowed to expand attached macros.
// RUN: %target-swift-frontend -typecheck -verify -verify-ignore-unrelated -primary-file %t/use_deferred.swift %t/model.swift -swift-version 5 -enable-experimental-feature DeferredMacroResolution -load-plugin-library %t/%target-library-name(MacroDefinition) -module-name MacroUser

// Attribute validation.
// RUN: %target-swift-frontend -typecheck -verify %t/attrs.swift -swift-version 5 -enable-experimental-feature DeferredMacroResolution -load-plugin-library %t/%target-library-name(MacroDefinition) -module-name MacroUser

//--- model.swift
@attached(member, names: named(Storage), named(storage), named(getStorage()), named(method), named(init))
macro addMembers() = #externalMacro(module: "MacroDefinition", type: "AddMembers")

@freestanding(declaration)
macro anonymousTypes(_: () -> String) = #externalMacro(module: "MacroDefinition", type: "DefineAnonymousTypesMacro")

@freestanding(declaration, resolution: deferred)
macro anonymousTypesDeferred(_: () -> String) = #externalMacro(module: "MacroDefinition", type: "DefineAnonymousTypesMacro")

@addMembers
struct S {}

//--- use_independent.swift
#anonymousTypes { String(describing: S.method()) }
// expected-error@-1{{type 'S' has no member 'method'}}

//--- use_deferred.swift
#anonymousTypesDeferred { String(describing: S.method()) }

//--- attrs.swift
// Deferred resolution is allowed for freestanding expression macros and
// freestanding declaration macros that introduce no names.
@freestanding(expression, resolution: deferred)
macro stringifyDeferred<T>(_ value: T) -> (T, String) = #externalMacro(module: "MacroDefinition", type: "StringifyMacro")

@freestanding(declaration, resolution: deferred)
macro emptyDeclDeferred() = #externalMacro(module: "MacroDefinition", type: "EmptyDeclarationMacro")

// The explicit default spelling is accepted anywhere.
@freestanding(expression, resolution: independent)
macro stringifyIndependent<T>(_ value: T) -> (T, String) = #externalMacro(module: "MacroDefinition", type: "StringifyMacro")

// Roles that introduce names cannot defer resolution.
@freestanding(declaration, names: named(A), resolution: deferred) // expected-error{{'resolution: deferred' can only be used with freestanding macros that do not introduce names}}
macro namedDeferred() = #externalMacro(module: "MacroDefinition", type: "DefineDeclsWithKnownNamesMacro")

@attached(peer, resolution: deferred) // expected-error{{'resolution: deferred' can only be used with freestanding macros that do not introduce names}}
macro deferredPeer() = #externalMacro(module: "MacroDefinition", type: "EmptyPeerMacro")

// Unknown resolution values are rejected.
@freestanding(expression, resolution: immediate) // expected-error{{unknown macro resolution 'immediate'; expected 'independent' or 'deferred'}}
macro unknownResolution(_ value: Int) = #externalMacro(module: "MacroDefinition", type: "StringifyMacro")
