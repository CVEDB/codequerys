#pragma once

#include <swift/AST/Types.h>
#include <string>

namespace codeql {
class Mangler {
 public:
  template <typename T>
  std::string mangleType(const T& type) {
    return type.getString();
  }

  //  std::string mangleType(const swift::ProtocolType& type);
  std::string mangleType(const swift::ModuleType& type);
  //  std::string mangleType(const swift::StructType& type);
};
}  // namespace codeql
