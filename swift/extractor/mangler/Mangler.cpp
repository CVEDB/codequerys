#include "Mangler.h"
#include <swift/AST/Types.h>
#include <swift/AST/Module.h>

using namespace codeql;

static std::string mangleModule(const swift::ModuleDecl* decl) {
  assert(decl);
  auto key = decl->getRealName().str().str();
  if (decl->isNonSwiftModule()) {
    key += "|clang";
  }
  return key;
}
//
// std::string Mangler::mangleType(const swift::StructType& type) {
////  type.getString("")
////  if (type.hasTypeVariable()) {
//    type.print(llvm::errs()); llvm::errs() << "\n";
////  }
////  type.dump(llvm::errs()); llvm::errs() << "\n";
//
////  type.getParent().print(llvm::errs()); llvm::errs() << "\n";
//  //  type.getParent().print(llvm::errs()); llvm::errs() << "\n";
////  llvm::errs() << mangleModule(type.getDecl()->getParentModule()) << "\n";
////  type.getDecl()->getName().
//  return type.getString();
//}

// std::string Mangler::mangleType(const swift::ProtocolType& type) {
////  llvm::errs() << type.getString() << "\n";
////  type.print(llvm::errs()); llvm::errs() << "\n";
//////  type.getParent().print(llvm::errs()); llvm::errs() << "\n";
////   llvm::errs() << mangleModule(type.getDecl()->getParentModule()) << "\n";
////  type.getCanonicalType().
//  return type.getString();
//}

std::string Mangler::mangleType(const swift::ModuleType& type) {
  return mangleModule(type.getModule());
}
