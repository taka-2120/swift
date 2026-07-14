//===--- MacroDeclaration.h - Swift Macro Declaration -----------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// Data structures that configure the declaration of a macro.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_AST_MACRO_DECLARATION_H
#define SWIFT_AST_MACRO_DECLARATION_H

#include "swift/AST/Identifier.h"

namespace swift {

/// Describes the syntax that is used for a macro, which affects its role.
enum class MacroSyntax: uint8_t {
  /// Freestanding macro syntax starting with an explicit '#' followed by the
  /// macro name and optional arguments.
  Freestanding,

  /// Attached macro syntax written as an attribute with a leading `@` followed
  /// by the macro name an optional arguments.
  Attached,
};

/// Describes how references within the arguments of a macro expansion are
/// resolved relative to other macro expansions in the same scope.
enum class MacroResolution : uint8_t {
  /// The default behavior specified by SE-0389: the macro's arguments are
  /// type-checked as if all macros in the same scope expand simultaneously,
  /// so names introduced by other macro expansions are not visible.
  Independent,

  /// The macro has explicitly opted out of the simultaneous-expansion model:
  /// type-checking its arguments may trigger and observe the expansion of
  /// attached macros in the same scope. Only permitted for freestanding
  /// expression macros, which introduce no names of their own.
  Deferred,
};

/// Retrieve the string form of the given macro resolution, as written in
/// the 'resolution:' argument of the corresponding attribute.
StringRef getMacroResolutionString(MacroResolution resolution);

enum class MacroRoleBits: uint8_t {
#define MACRO_ROLE(Name, Description) Name,
#include "swift/Basic/MacroRoles.def"
};

/// The context in which a macro can be used, which determines the syntax it
/// uses.
enum class MacroRole: uint32_t {
#define MACRO_ROLE(Name, Description) \
    Name = 1 << static_cast<uint8_t>(MacroRoleBits::Name),
#include "swift/Basic/MacroRoles.def"
};

/// Returns an enumeratable list of all macro roles.
std::vector<MacroRole> getAllMacroRoles();

/// The contexts in which a particular macro declaration can be used.
using MacroRoles = OptionSet<MacroRole>;

void simple_display(llvm::raw_ostream &out, MacroRoles roles);
bool operator==(MacroRoles lhs, MacroRoles rhs);
llvm::hash_code hash_value(MacroRoles roles);

/// Retrieve the string form of the given macro role, as written on the
/// corresponding attribute.
StringRef getMacroRoleString(MacroRole role);

/// Whether a macro with the given set of macro contexts is freestanding, i.e.,
/// written in the source code with the `#` syntax.
bool isFreestandingMacro(MacroRoles contexts);

MacroRoles getFreestandingMacroRoles();

/// Whether a macro with the given set of macro contexts is attached, i.e.,
/// written in the source code as an attribute with the `@` syntax.
bool isAttachedMacro(MacroRoles contexts);

MacroRoles getAttachedMacroRoles();

/// Checks if the macro is supported or guarded behind an experimental flag.
bool isMacroSupported(MacroRole role, ASTContext &ctx);

enum class MacroIntroducedDeclNameKind {
  Named,
  Overloaded,
  Prefixed,
  Suffixed,
  Arbitrary,

  // NOTE: When adding a new name kind, also add it to
  // `getAllMacroIntroducedDeclNameKinds`.
};

/// Returns an enumeratable list of all macro introduced decl name kinds.
std::vector<MacroIntroducedDeclNameKind> getAllMacroIntroducedDeclNameKinds();

/// Whether a macro-introduced name of this kind requires an argument.
bool macroIntroducedNameRequiresArgument(MacroIntroducedDeclNameKind kind);

StringRef getMacroIntroducedDeclNameString(
    MacroIntroducedDeclNameKind kind);

class CustomAttr;

class MacroIntroducedDeclName {
public:
  using Kind = MacroIntroducedDeclNameKind;

private:
  Kind kind;
  DeclName name;

public:
  MacroIntroducedDeclName(Kind kind, DeclName name = DeclName())
      : kind(kind), name(name) {};

  static MacroIntroducedDeclName getNamed(DeclName name) {
    return MacroIntroducedDeclName(Kind::Named, name);
  }

  static MacroIntroducedDeclName getOverloaded() {
    return MacroIntroducedDeclName(Kind::Overloaded);
  }

  static MacroIntroducedDeclName getPrefixed(Identifier prefix) {
    return MacroIntroducedDeclName(Kind::Prefixed, prefix);
  }

  static MacroIntroducedDeclName getSuffixed(Identifier suffix) {
    return MacroIntroducedDeclName(Kind::Suffixed, suffix);
  }

  static MacroIntroducedDeclName getArbitrary() {
    return MacroIntroducedDeclName(Kind::Arbitrary);
  }

  Kind getKind() const { return kind; }
  DeclName getName() const { return name; }
};

}

#endif // SWIFT_AST_MACRO_DECLARATION_H
