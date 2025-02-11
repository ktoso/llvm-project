//===- APIData.h ---------------------------------------------*- C++ -*----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_TOOLING_DUMPTOOL_APIDATA_H
#define LLVM_CLANG_LIB_TOOLING_DUMPTOOL_APIDATA_H

#include <string>
#include <vector>

namespace clang {
namespace tooling {

struct ClassData {
  std::vector<std::string> ASTClassLocations;
  std::vector<std::string> ASTClassRanges;
  std::vector<std::string> TemplateParms;
  std::vector<std::string> TypeSourceInfos;
  std::vector<std::string> TypeLocs;
  // TODO: Extend this with locations available via typelocs etc.
};

} // namespace tooling
} // namespace clang

#endif
