load("@bazel_skylib//lib:new_sets.bzl", "sets")
load("//third_party/qemu:repos.bzl", "qemu_src_repos", "qemu_binary_repos")
load("//third_party/mxe:repos.bzl", "mxe_src_repos")
load("//third_party/cc65:repos.bzl", "cc65_src_repos")
load("//toolchains/gcc_arm_none_eabi:repository.bzl", "gcc_arm_none_eabi_repos")
load("//toolchains/lowrisc_rv32imcb:repository.bzl", "lowrisc_rv32imcb_repos")
load("//toolchains/gcc_mxe_mingw32:repository.bzl", "gcc_mxe_mingw32_repos")
load("//toolchains/gcc_mxe_mingw64:repository.bzl", "gcc_mxe_mingw64_repos")
load("//toolchains/cc65:repository.bzl", "cc65_repos")


def _sources_impl(_):
    qemu_src_repos()
    mxe_src_repos()
    cc65_src_repos()

sources = module_extension(
    implementation = _sources_impl,
)

tools = module_extension(
    implementation = lambda ctx: qemu_binary_repos(),
)

def _crt_impl(ctx):
    toolchains = sets.make()

    for mod in ctx.modules:
        for tag in mod.tags.toolchains:
            enabled = [toolchain for toolchain in dir(tag) if getattr(tag, toolchain)]
            toolchains = sets.union(toolchains, sets.make(enabled))

    if sets.contains(toolchains, "arm"):
        gcc_arm_none_eabi_repos()

    if sets.contains(toolchains, "m6502"):
        cc65_repos()

    if sets.contains(toolchains, "riscv32"):
        lowrisc_rv32imcb_repos()

    if sets.contains(toolchains, "win32"):
        gcc_mxe_mingw32_repos()

    if sets.contains(toolchains, "win64"):
        gcc_mxe_mingw64_repos()

    # TODO: call `toolchain_hub(name = "crt_toolchains")` to create a repo
    # containing all the above toolchains.

crt = module_extension(
    implementation = _crt_impl,
    tag_classes = {
        "toolchains": tag_class(attrs = {
            "arm": attr.bool(),
            "m6502": attr.bool(),
            "riscv32": attr.bool(),
            "win32": attr.bool(),
            "win64": attr.bool(),
        }),
    },
)

# Attempt to create repo containing the selected toolchains by aliasing them.
# TODO: this is unfinished and doesn't work. I'm not sure if you can have
# aliases cross repositories like this.

_build_file_alias_template = """
alias(
    name = "{name}",
    actual = "{actual}",
)  
"""

def BUILD_for_aliases(aliases):
    return "\n".join([_build_file_alias_template.format(
        name = label.name,
        actual = label,
    ) for label in aliases])

def _toolchain_hub_impl(ctx):
    toolchains = BUILD_for_aliases(ctx.attr.toolchains)
    execution_platforms = BUILD_for_aliases(ctx.attr.execution_platforms)

    ctx.file("//toolchains/BUILD.bazel", content=toolchains)
    ctx.file("//platforms/BUILD.bazel", content=execution_platforms)

toolchain_hub = repository_rule(
    implementation = _toolchain_hub_impl,
    attrs = {
        "execution_platforms": attr.label_list(),
        "toolchains": attr.label_list(),
    },
)
