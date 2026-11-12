load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_xcframework_import",
)

# Python 3.11 runtime for the exteraGram-compatible plugin engine.
#
# Slices are fetched by `build-system/setup_python.py` (device + simulator,
# static Python.framework). Bazel also accepts the headers at
# `include/python3.11`, which makes `import Python` work in Swift.
apple_static_xcframework_import(
    name = "Python",
    xcframework_imports = glob(["Python.xcframework/**"]),
    visibility = [
        "//visibility:public",
    ],
)

# Stdlib copied into the app bundle (resolved through PYTHONHOME/python3.11).
filegroup(
    name = "PythonStdlib",
    srcs = glob(["python3.11/**"], allow_empty = True),
    visibility = [
        "//visibility:public",
    ],
)
