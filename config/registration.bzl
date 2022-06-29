# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("@crt//toolchains/gcc_arm_none_eabi:repository.bzl", "gcc_arm_none_eabi_repos")
load("@crt//toolchains/lowrisc_rv32imcb:repository.bzl", "lowrisc_rv32imcb_repos")
load("@crt//toolchains/gcc_mxe_mingw64:repository.bzl", "gcc_mxe_mingw64_repos")

def crt_register_toolchains(
        arm = False,
        riscv32 = False,
        win64 = False):
    native.register_execution_platforms("@local_config_platform//:host")
    if arm:
        gcc_arm_none_eabi_repos()
        native.register_execution_platforms("@crt//platforms/arm:all")
        native.register_toolchains("@crt//toolchains/gcc_arm_none_eabi:all")

    if riscv32:
        lowrisc_rv32imcb_repos()
        native.register_execution_platforms("@crt//platforms/riscv32:all")
        native.register_toolchains("@crt//toolchains/lowrisc_rv32imcb:all")

    if win64:
        gcc_mxe_mingw64_repos()
        native.register_execution_platforms("@crt//platforms/x86_64:all")
        native.register_toolchains("@crt//toolchains/gcc_mxe_mingw64:all")
