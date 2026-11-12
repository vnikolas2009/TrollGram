load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_xcframework_import",
)

# Python 3.11 runtime used by the exteraGram-compatible plugin engine.
#
# Drop the prebuilt `Python.xcframework` (PYTHON.xcframework release, device +
# simulator slices, iOS min 13.0) into this directory. Until the binary is
# present the target exports no sources and `PythonPluginManager` falls back
# to its stub mode, so the app still builds.
_PYTHON_SLICES = glob(["Python.xcframework/**"])

apple_static_xcframework_import(
    name = "Python",
    xcframework_imports = _PYTHON_SLICES,
    visibility = [
        "//visibility:public",
    ],
)

filegroup(
    name = "PythonStdlib",
    srcs = glob(["stdlib/**"], allow_empty = True),
    visibility = [
        "//visibility:public",
    ],
)
