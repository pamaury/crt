load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def cc65_src_repos():
    http_archive(
        name = "cc65_src",
        url = "https://github.com/cc65/cc65/archive/master.zip",
        build_file = Label("//third_party/cc65:BUILD.cc65_src.bazel"),
        sha256 = "c0f3c64d4ca37ce526afd469529ce4c10fbe367a0bc92ccc69e56c9fa641d2b0",
        strip_prefix = "cc65-master",
    )
