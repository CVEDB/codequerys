#pragma once

#include <swift/AST/Types.h>
#include <string>

namespace codeql {
class TypeMangler {
 public:
  template <typename T>
  std::string mangleType(const T& type) {
    return "";
  }

  std::string mangleType(const swift::ProtocolType& type);
  std::string mangleType(const swift::ModuleType& type);
};
}  // namespace codeql
