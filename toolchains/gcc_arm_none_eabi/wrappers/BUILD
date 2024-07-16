# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Warning: with WORKSPACE, this file is executed normally, but with bzlmod
# it will be executed in its own repository so all path to the crt repository
# must be absolute and all other paths must be relative. See repository.bzl.

load("@crt//rules:template.bzl", "render_template")

package(default_visibility = ["//visibility:public"])

# Warning: with WORKSPACE, this file is executed normally, but with bzlmod
# it will be executed in its own repository, see ../BUILD.bazel.

exports_files(glob(["*"]))

filegroup(
    name = "all",
    srcs = [
        "ar",
        "cpp",
        "gcc",
        "gcov",
        "ld",
        "nm",
        "objcopy",
        "objdump",
        "strip",
    ],
)
