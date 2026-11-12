load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SGTrollPrivacy",
    module_name = "SGTrollPrivacy",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Swiftgram/SGSimpleSettings:SGSimpleSettings",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramUIPreferences:TelegramUIPreferences",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramUI/Components/UndoUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
