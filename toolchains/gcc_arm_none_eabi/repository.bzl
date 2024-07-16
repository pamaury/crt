# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("@crt//rules:repo.bzl", "http_archive_or_local", "bzlmod_local_repository")

def gcc_arm_none_eabi_repos(local = None):
    http_archive_or_local(
        name = "gcc_arm_none_eabi_files",
        local = local,
        url = "https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2",
        strip_prefix = "gcc-arm-none-eabi-10.3-2021.10",
        build_file = Label("//toolchains:BUILD.export_all.bazel"),
        sha256 = "97dbb4f019ad1650b732faffcc881689cedc14e2b7ee863d390e0a41ef16c9a3",
    )

    bzlmod_local_repository(
        name = "gcc_arm_none_eabi_toolchains",
        path = "@crt//toolchains/gcc_arm_none_eabi:BUILD.bazel",
    )