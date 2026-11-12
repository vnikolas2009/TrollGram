load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# exteraGram-compatible plugin host. The Python runtime itself is optional
# (see //third-party/python) — without it the module builds in stub mode.
swift_library(
    name = "PythonPlugins",
    module_name = "PythonPlugins",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)

filegroup(
    name = "PythonStdlib",
    srcs = glob(["stdlib/**/*.py"]),
    visibility = ["//visibility:public"],
)
