// REQUIRES: clang-driver
// REQUIRES: x86-registered-target
// REQUIRES: amdgpu-registered-target

// RUN: %clang -### -target x86_64-linux-gnu \
// RUN:   -x hip \
// RUN:   --offload-arch=gfx908:xnack+:sramecc+ \
// RUN:   --offload-arch=gfx908:xnack+:sramecc- \
// RUN:   --rocm-path=%S/Inputs/rocm \
// RUN:   %s 2>&1 | FileCheck %s

// RUN: %clang -### -target x86_64-linux-gnu \
// RUN:   -x hip \
// RUN:   --offload-arch=gfx908:xnack+:sramecc+ \
// RUN:   --offload-arch=gfx908:xnack+:sramecc- \
// RUN:   --rocm-path=%S/Inputs/rocm \
// RUN:   -save-temps \
// RUN:   %s 2>&1 | FileCheck --check-prefixes=CHECK,TMP %s

// RUN: %clang -### -target x86_64-linux-gnu \
// RUN:   -x hip \
// RUN:   --offload-arch=gfx908:xnack+:sramecc+ \
// RUN:   --offload-arch=gfx908:xnack+:sramecc- \
// RUN:   --rocm-path=%S/Inputs/rocm \
// RUN:   -fgpu-rdc \
// RUN:   %s 2>&1 | FileCheck --check-prefixes=CHECK %s

// CHECK: [[CLANG:"[^"]*clang[^"]*"]] "-cc1" "-mllvm" "--amdhsa-code-object-version={{[0-9]+}}" "-triple" "amdgcn-amd-amdhsa"
// CHECK-SAME: "-target-cpu" "gfx908"
// CHECK-SAME: "-target-feature" "+sramecc"
// CHECK-SAME: "-target-feature" "+xnack"

// TMP: [[CLANG:"[^"]*clang[^"]*"]] "-cc1as" "-mllvm" "--amdhsa-code-object-version={{[0-9]+}}" "-triple" "amdgcn-amd-amdhsa"
// TMP-SAME: "-target-cpu" "gfx908"
// TMP-SAME: "-target-feature" "+sramecc"
// TMP-SAME: "-target-feature" "+xnack"

// CHECK: [[LLD:"[^"]*lld[^"]*"]] {{.*}} "-plugin-opt=mcpu=gfx908"
// CHECK-SAME: "-plugin-opt=-mattr=+sramecc,+xnack"

// CHECK: [[CLANG]] "-cc1" "-mllvm" "--amdhsa-code-object-version={{[0-9]+}}" "-triple" "amdgcn-amd-amdhsa"
// CHECK-SAME: "-target-cpu" "gfx908"
// CHECK-SAME: "-target-feature" "-sramecc"
// CHECK-SAME: "-target-feature" "+xnack"

// CHECK: [[LLD]] {{.*}} "-plugin-opt=mcpu=gfx908"
// CHECK-SAME: "-plugin-opt=-mattr=-sramecc,+xnack"

// CHECK: {{"[^"]*clang-offload-bundler[^"]*"}}
// CHECK-SAME: "-targets=host-x86_64-unknown-linux,hipv4-amdgcn-amd-amdhsa--gfx908:sramecc+:xnack+,hipv4-amdgcn-amd-amdhsa--gfx908:sramecc-:xnack+"

// Check canonicalization and repeating of target ID.

// RUN: %clang -### -target x86_64-linux-gnu \
// RUN:   -x hip \
// RUN:   --offload-arch=fiji \
// RUN:   --offload-arch=gfx803 \
// RUN:   --offload-arch=fiji \
// RUN:   --rocm-path=%S/Inputs/rocm \
// RUN:   %s 2>&1 | FileCheck -check-prefix=FIJI %s
// FIJI: "-targets=host-x86_64-unknown-linux,hipv4-amdgcn-amd-amdhsa--gfx803"

// RUN: %clang -### -target x86_64-linux-gnu \
// RUN:   -x hip \
// RUN:   --offload-arch=gfx900:xnack- \
// RUN:   --offload-arch=gfx900:xnack+ \
// RUN:   --offload-arch=gfx908:sramecc+ \
// RUN:   --offload-arch=gfx908:sramecc- \
// RUN:   --offload-arch=gfx906 \
// RUN:   --rocm-path=%S/Inputs/rocm \
// RUN:   %s 2>&1 | FileCheck -check-prefix=MULTI %s
// MULTI: "-targets=host-x86_64-unknown-linux,hipv4-amdgcn-amd-amdhsa--gfx900:xnack+,hipv4-amdgcn-amd-amdhsa--gfx900:xnack-,hipv4-amdgcn-amd-amdhsa--gfx906,hipv4-amdgcn-amd-amdhsa--gfx908:sramecc+,hipv4-amdgcn-amd-amdhsa--gfx908:sramecc-"
