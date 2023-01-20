#include "swift/extractor/translators/TypeMangler.h"
#include <swift/AST/Types.h>
#include <swift/AST/Module.h>

using namespace codeql;

std::string TypeMangler::mangleType(const swift::ProtocolType& type) {
  return type.getString();
}

std::string TypeMangler::mangleType(const swift::ModuleType& type) {
  swift::ModuleDecl* decl = type.getModule();
  auto key = decl->getRealName().str().str();
  if (decl->isNonSwiftModule()) {
    key += "|clang";
  }
  return key;
}
