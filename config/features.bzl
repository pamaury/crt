# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "FeatureInfo",
    __feature = "feature",
    __flag_group = "flag_group",
    __flag_set = "flag_set",
    __with_feature_set = "with_feature_set",
    __env_set = "env_set",
    __env_entry = "env_entry",
)
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_skylib//lib:structs.bzl", "structs")

with_feature_set = __with_feature_set

CPP_ALL_COMPILE_ACTIONS = [
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.lto_backend,
    ACTION_NAMES.clif_match,
]

C_ALL_COMPILE_ACTIONS = [
    ACTION_NAMES.assemble,
    ACTION_NAMES.c_compile,
]

LD_ALL_ACTIONS = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

ALL_ACTIONS = structs.to_dict(ACTION_NAMES).values()

FeatureSetInfo = provider(fields = ["features", "subst"])

# Apply substitutions: they are applied "recursively", meaning that
# the content of a previous substitution is itself subject to substitution.
def apply_subst(array, subst):
    # We cannot make a while loop but we know that for a well-formed set
    # of substitutions, the longest chain of substitution possible is len(subst)
    # so we just iterate that many times and stop as soon as nothing changes anymore.
    for _ in range(1, len(subst)):
        array2 = []
        for f in array:
            if f in subst:
                if f.startswith("[") and f.endswith("]"):
                    array2.extend(subst[f].split("|"))
            else:
                for k, v in subst.items():
                    f = f.replace(k, v)
                array2.append(f)
        if array == array2:
            break
        array = array2
    return array

def reify_flag_group(
        flags = [],
        flag_groups = [],
        iterate_over = None,
        expand_if_available = None,
        expand_if_not_available = None,
        expand_if_true = None,
        expand_if_false = None,
        expand_if_equal = None,
        type_name = None,
        subst = {}):

    return __flag_group(
        apply_subst(flags, subst),
        flag_groups,
        iterate_over,
        expand_if_available,
        expand_if_not_available,
        expand_if_true,
        expand_if_false,
        expand_if_equal,
    )

def reify_with_features_set(
        features,
        not_features,
        type_name):
    if type_name != "with_feature_set":
        fail("the argument to with_features must be an array of values created by with_feature_set")
    return with_feature_set(
        features,
        not_features
    )

def reify_flag_set(
        actions = [],
        with_features = [],
        flag_groups = [],
        type_name = None):
    return __flag_set(
        actions,
        with_features =[reify_with_features_set(**v) for v in with_features],
        flag_groups = [reify_flag_group(**v) for v in flag_groups],
    )

def subst_env_entry(key, value, subst):
    for k, v in subst.items():
        value = value.replace(k, v)
    return __env_entry(key, value)

def feature_set_subst(fs, **kwargs):
    subst = dict(fs.subst)
    subst.update(kwargs)
    features = {}
    for name, feature in fs.features.items():
        flag_sets = [
            __flag_set(
                f.actions,
                f.with_features,
                [
                    reify_flag_group(
                        g.flags,
                        g.flag_groups,
                        g.iterate_over,
                        g.expand_if_available,
                        g.expand_if_not_available,
                        g.expand_if_true,
                        g.expand_if_false,
                        g.expand_if_equal,
                        subst = subst,
                    )
                    for g in f.flag_groups
                ],
            )
            for f in feature.flag_sets
        ]
        env_sets = [
            __env_set(
                s.actions,
                [
                    subst_env_entry(e.key, e.value, subst)
                    for e in s.env_entries
                ],
                s.with_features,
            )
            for s in feature.env_sets
        ]
        features[name] = __feature(
            name = feature.name,
            enabled = feature.enabled,
            flag_sets = flag_sets,
            requires = feature.requires,
            implies = feature.implies,
            provides = feature.provides,
            env_sets = env_sets,
        )
    return features

def flag_group(
        flags = [],
        flag_groups = [],
        iterate_over = None,
        expand_if_available = None,
        expand_if_not_available = None,
        expand_if_true = None,
        expand_if_false = None,
        expand_if_equal = None):
    return {
        "flags": flags,
        "flag_groups": flag_groups,
        "iterate_over": iterate_over,
        "expand_if_available": expand_if_available,
        "expand_if_not_available": expand_if_not_available,
        "expand_if_true": expand_if_true,
        "expand_if_false": expand_if_false,
        "expand_if_equal": expand_if_equal,
    }

def flag_set(
        actions = [],
        with_features = [],
        flag_groups = []):
    return json.encode({
        "actions": actions,
        "with_features": with_features,
        "flag_groups": flag_groups,
    })

def reify_env_entry(key, value):
    return __env_entry(
        key,
        value,
    )

def env_entry(key, value):
    return {
        "key": key,
        "value": value,
    }

def reify_env_set(
        actions = [],
        env_entries = [],
        with_features = []):
    return __env_set(
        actions,
        env_entries = [reify_env_entry(**v) for v in env_entries],
        with_features = [reify_with_features_set(**v) for v in with_features],
    )

def env_set(
        actions,
        env_entries = [],
        with_features = []):
    return json.encode({
        "actions": actions,
        "with_features": with_features,
        "env_entries": env_entries,
    })

def _feature_impl(ctx):
    return [
        __feature(
            name = ctx.attr.name,
            enabled = ctx.attr.enabled,
            flag_sets = [reify_flag_set(**json.decode(v)) for v in ctx.attr.flag_sets],
            requires = ctx.attr.requires,
            implies = ctx.attr.implies,
            provides = ctx.attr.provides,
            env_sets = [reify_env_set(**json.decode(v)) for v in ctx.attr.env_sets],
        ),
    ]

feature = rule(
    implementation = _feature_impl,
    attrs = {
        "enabled": attr.bool(mandatory = True, doc = "Whether the feature is enabled."),
        "flag_sets": attr.string_list(default = [], doc = "Flag sets for this feature."),
        "requires": attr.string_list(default = [], doc = "A list of feature sets defining when this feature is supported by the toolchain."),
        "implies": attr.string_list(default = [], doc = "A string list of features or action configs that are automatically enabled when this feature is enabled."),
        "provides": attr.string_list(default = [], doc = "A list of names this feature conflicts with."),
        "env_sets": attr.string_list(default = [], doc = "A list of env_set this feature will apply if enabled."),
    },
    provides = [FeatureInfo],
)

def feature_single_flag_c_cpp(name, flag, enabled = True):
    """This macro produces a C/C++ feature() that enables a single flag."""
    feature(
        name = name,
        enabled = enabled,
        flag_sets = [
            flag_set(
                actions = CPP_ALL_COMPILE_ACTIONS + C_ALL_COMPILE_ACTIONS,
                flag_groups = [
                    flag_group(
                        flags = [flag],
                    ),
                ],
            ),
        ],
    )

def _feature_set_impl(ctx):
    features = {}
    subst = {}
    for base in ctx.attr.base:
        features.update(base[FeatureSetInfo].features)
        subst.update(base[FeatureSetInfo].subst)
    for feature in ctx.attr.feature:
        f = feature[FeatureInfo]
        features[f.name] = f
    subst.update(ctx.attr.substitutions)

    #print(json.encode_indent(features))
    return [
        FeatureSetInfo(features = features, subst = subst),
    ]

feature_set = rule(
    implementation = _feature_set_impl,
    attrs = {
        "base": attr.label_list(default = [], providers = [FeatureSetInfo], doc = "A base feature set to derive a new set"),
        "feature": attr.label_list(mandatory = True, providers = [FeatureInfo], doc = "A list of features in this set"),
        # Substitutions apply until nothing changes (fixed point). For example if
        #   substitutions = {"X": "a", "Y": "Xb"}
        # then the result of "Y" will be "ab".
        "substitutions": attr.string_dict(doc = "Substitutions to apply to features"),
    },
    provides = [FeatureSetInfo],
)
