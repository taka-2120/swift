// REQUIRES: swift_swift_parser
// REQUIRES: swift_feature_DeferredMacroResolution

// RUN: %empty-directory(%t)
// RUN: split-file %s %t
// RUN: %host-build-swift -swift-version 5 -emit-library -o %t/%target-library-name(MacroDefinition) -module-name=MacroDefinition %S/Inputs/syntax_macro_definitions.swift -g -no-toolchain-stdlib-rpath

// Build a library declaring a deferred-resolution macro, exercising
// serialization of the 'resolution:' argument.
// RUN: %target-swift-frontend -swift-version 5 -emit-module -o %t/macro_library.swiftmodule %t/macro_library.swift -module-name macro_library -load-plugin-library %t/%target-library-name(MacroDefinition) -enable-experimental-feature DeferredMacroResolution

// The deserialized independent macro still follows SE-0389.
// RUN: %target-swift-frontend -typecheck -verify -verify-ignore-unrelated -primary-file %t/use_independent.swift %t/model.swift -I %t -swift-version 5 -enable-experimental-feature DeferredMacroResolution -load-plugin-library %t/%target-library-name(MacroDefinition) -module-name MacroUser -typo-correction-limit 0

// The deserialized deferred macro can see the attached macro expansion.
// RUN: %target-swift-frontend -typecheck -verify -verify-ignore-unrelated -primary-file %t/use_deferred.swift %t/model.swift -I %t -swift-version 5 -enable-experimental-feature DeferredMacroResolution -load-plugin-library %t/%target-library-name(MacroDefinition) -module-name MacroUser

//--- macro_library.swift
@attached(member, names: named(Storage), named(storage), named(getStorage()), named(method), named(init))
public macro AddMembers() = #externalMacro(module: "MacroDefinition", type: "AddMembers")

@freestanding(declaration)
public macro anonymousTypes(_: () -> String) = #externalMacro(module: "MacroDefinition", type: "DefineAnonymousTypesMacro")

@freestanding(declaration, resolution: deferred)
public macro anonymousTypesDeferred(_: () -> String) = #externalMacro(module: "MacroDefinition", type: "DefineAnonymousTypesMacro")

//--- model.swift
import macro_library

@AddMembers
struct S {}

//--- use_independent.swift
import macro_library

#anonymousTypes { String(describing: S.method()) }
// expected-error@-1{{type 'S' has no member 'method'}}

//--- use_deferred.swift
import macro_library

#anonymousTypesDeferred { String(describing: S.method()) }
