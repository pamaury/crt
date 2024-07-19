# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")
load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")
load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")

def bazel_deps():
    rules_foreign_cc_dependencies()
    rules_pkg_dependencies()
    py_repositories()
    if not native.existing_rule("python3"):
        python_register_toolchains(
            name = "python3",
            python_version = "3.9",
        )
