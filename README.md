::: {align="center"}
# TrollGram

**A community-built Telegram client for iOS, based on Swiftgram.**

Privacy controls, local message history and an exteraGram-compatible
Python plugin layer --- brought together in one experimental build.

[Русская версия](docs/README.ru.md) · [Contributing](CONTRIBUTING.md) ·
[Report a bug](https://github.com/vnikolas2009/TrollGram/issues)
:::

------------------------------------------------------------------------

> \[!WARNING\] TrollGram is an **unofficial, experimental third-party
> client**. It is not developed, endorsed or supported by Telegram or
> the Swiftgram team. Builds may be unsigned and installation depends on
> your device, iOS version and signing method. Use at your own
> discretion.

## What is TrollGram?

TrollGram is a personal fork of
[Swiftgram](https://github.com/Swiftgram/Telegram-iOS), itself based on
Telegram's open-source iOS client. The project adds a set of local
privacy controls and an experimental Python plugin environment designed
to work with parts of the exteraGram plugin API.

The goal is not to replace Telegram's infrastructure or promise
impossible privacy guarantees. TrollGram changes selected client-side
behaviours and adds tools that can be inspected in the source code.

## Features

### Privacy controls

The **Settings → PRIVACY** section contains the following options:

  -----------------------------------------------------------------------------
  Feature                             Behaviour
  ----------------------------------- -----------------------------------------
  **Anti-Delete**                     Keeps a local copy of deleted messages in
                                      `Documents/TrollArchive/messages.json`.

  **Edit History**                    Stores previous versions of edited
                                      messages.

  **Ghost Mode**                      Master control for presence and
                                      activity-hiding options.

  **Hide Online**                     Prevents the client from sending the
                                      online presence update covered by this
                                      implementation.

  **Hide Read Receipts**              Suppresses supported read-state updates
                                      for private chats, groups, channels and
                                      secret chats.

  **Hide Typing**                     Suppresses supported typing and recording
                                      activity updates.

  **Hide Uploading**                  Suppresses supported media-upload
                                      activity updates.

  **View Once Media**                 Changes the local handling of supported
                                      view-once media.

  **Copy Protected**                  Changes client-side copy/forward
                                      restrictions for supported protected
                                      chats.

  **Remove Sponsored**                Filters sponsored channel posts in the
                                      client.
  -----------------------------------------------------------------------------

These options are implemented in the client and its networking layer.
They are **not a guarantee** that a remote service, another client, a
recipient or a server-side feature cannot reveal an action. Behaviour
may change when Telegram changes its API.

Privacy flags are stored locally in `UserDefaults` under
`app.trollgram.ios.privacy` and loaded into the runtime during
application startup.

### exteraGram-compatible plugins

TrollGram includes an embedded **CPython 3.11** runtime and an
experimental `.py` plugin host.

Current pieces include:

-   Plugin management under **Settings → PRIVACY → Plugins**.
-   Importing `.py` files through the iOS Files picker.
-   Enabling and disabling installed plugins.
-   A plugin log.
-   A compatibility layer in `Swiftgram/PythonPlugins/stdlib`, including
    `base_plugin`, `ui.settings`, `client_utils`, `android_utils`,
    `hook_utils` and `trollgram_bridge`.
-   A message-send hook exposed through `ChatController.sendMessages`;
    returning `HookResult.CANCELLED` (`2`) cancels the send operation.

The compatibility layer is a work in progress. It does not mean that
every exteraGram plugin will run unchanged on iOS.

#### Installing a plugin

1.  Open TrollGram.
2.  Go to **Settings → PRIVACY → Plugins**.
3.  Choose **Import .py File** and select a plugin from Files.
4.  Enable it in the plugin list.
5.  Check the plugin log if it does not load as expected.

The app's plugin directory is `Documents/Plugins`. The plugin bridge
stores its data under `Documents/PluginsData`.

> \[!CAUTION\] A Python plugin is executable code. It may read or modify
> data available to the app, make network requests, or behave
> unexpectedly. Install plugins only from sources you trust. Review the
> source before importing it; a `.py` extension does not make a plugin
> safe.

## Installation

TrollGram does not currently provide an App Store distribution.
Installable builds, when available, are published in the repository's
[GitHub Releases](https://github.com/vnikolas2009/TrollGram/releases).

The build workflow produces:

  -----------------------------------------------------------------------
  File                                Purpose
  ----------------------------------- -----------------------------------
  `TrollGram.ipa`                     Unsigned IPA. Intended for a
                                      compatible TrollStore installation.

  `TrollGram-signed.ipa`              Optional IPA signed with the
                                      certificate and provisioning
                                      profile configured by the
                                      repository owner. Intended for
                                      compatible sideloading tools such
                                      as Sideloadly or AltStore.
  -----------------------------------------------------------------------

Availability of a signed file depends on repository secrets being
configured. An IPA being downloadable does not mean it will install on
every device or iOS release. Check the release notes and your
installation tool's requirements.

## Building from source

### Requirements

-   macOS with the Xcode version listed in
    [`versions.json`](versions.json).
-   Python 3.
-   Git, with support for recursive submodules.
-   Enough free disk space for the iOS toolchain and Bazel build cache.
-   Your own valid Telegram API credentials and signing configuration
    where required by the build setup.

The repository pins toolchain versions in `versions.json`. If a build
fails after an Xcode update, check that file and the Actions log before
changing build settings.

### Clone the repository

``` bash
git clone --recursive https://github.com/vnikolas2009/TrollGram.git
cd TrollGram
```

If you already cloned it without submodules:

``` bash
git submodule update --init --recursive
```

### Prepare the Python runtime

``` bash
python3 build-system/setup_python.py
```

This prepares the CPython runtime and standard library used by the
plugin host.

### Build an unsigned release IPA

The repository's current build configuration can be invoked with:

``` bash
python3 build-system/Make/Make.py \
  --cacheDir="$HOME/bazel-cache" \
  --bazelUserRoot="$HOME/bazel-trollgram" \
  build \
  --configurationPath=build-system/appstore-configuration.json \
  --codesigningInformationPath=build-system/fake-codesigning \
  --configuration=release_arm64 \
  --buildNumber=1000 \
  --skipDsym \
  --overrideXcodeVersion
```

This command follows the repository's current configuration. It is not a
universal build recipe for every Xcode or macOS version. For
reproducible results, use the versions pinned in `versions.json` and
inspect the build scripts before changing flags.

## Automated builds

The workflow lives at `.github/workflows/build-ipa.yml`.

You can start it manually:

1.  Open the repository's **Actions** tab.
2.  Select **Build and Release TrollGram IPA**.
3.  Choose **Run workflow**.
4.  Keep the default `release_arm64` configuration unless you know why
    you need another one.
5.  Download the IPA from the completed run's artifacts, or use the
    GitHub Release if one was published.

The workflow also runs when a tag matching `v*` is pushed:

``` bash
git tag v1.0.0
git push origin v1.0.0
```

### Optional IPA signing

The workflow can attempt to create `TrollGram-signed.ipa` when the
following repository Actions secrets are configured:

  Secret                     Contents
  -------------------------- ----------------------------------------------
  `P12_BASE64`               Base64-encoded signing certificate (`.p12`).
  `P12_PASSWORD`             Password for the `.p12` file.
  `MOBILEPROVISION_BASE64`   Base64-encoded provisioning profile.

Keep signing credentials private. Never commit certificates,
provisioning profiles, passwords or their unencoded contents to the
repository. Signing is optional; a signing failure does not necessarily
prevent the unsigned IPA from being published.

## Project layout

The main TrollGram-specific code is grouped around these areas:

``` text
Swiftgram/
  SGTrollPrivacy/       Privacy settings and local flags
  SGTrollPrivacyCore/   Runtime integration with TelegramCore
  PythonPlugins/        Python plugin host and compatibility layer
  SGTrollPluginsUI/     Plugin management interface
  SGSettingsUI/         Privacy settings interface

submodules/TelegramCore/Sources/
  TrollPrivacyRuntime.swift
  TrollMessageArchive.swift

third-party/python/     Generated Python runtime artifacts
.github/workflows/     Build and release automation
```

This is a guide to the main additions, not a complete map of the
upstream codebase.

## Security and responsible use

-   Do not use TrollGram to access accounts or data that are not yours.
-   Do not assume that client-side privacy options override server-side
    behaviour, recipient devices, screenshots or other copies of a
    message.
-   Treat imported plugins as software you are executing, not as
    harmless configuration files.
-   Do not publish logs, archives, session data, API credentials or
    personal information in bug reports.
-   If you find a security issue, avoid posting exploitable details in a
    public issue. Contact the maintainer privately through a channel
    listed in the repository profile or README.

## Contributing

Contributions are welcome, especially focused bug fixes, compatibility
improvements, documentation and reproducible build reports.

Before opening a pull request, read [CONTRIBUTING.md](CONTRIBUTING.md).
For changes that affect privacy or message handling, include a clear
explanation of what is changed, what is not changed, and how the
behaviour was verified.

## Acknowledgements

TrollGram builds on the work of the Telegram iOS and Swiftgram projects,
as well as the maintainers of the libraries and tools listed in the
repository and its submodules. Please retain upstream notices and follow
the licence terms that apply to each component.

-   [Telegram iOS](https://github.com/TelegramMessenger/Telegram-iOS)
-   [Swiftgram](https://github.com/Swiftgram/Telegram-iOS)
-   [exteraGram](https://github.com/exteraSquad)

## Disclaimer

TrollGram is an independent community project. Telegram, Telegram logos
and related marks belong to their respective owners. The project is not
affiliated with, sponsored by or endorsed by Telegram or Swiftgram.

The software is provided without warranty. Features can be incomplete,
break after upstream changes or behave differently across devices and
iOS versions. You are responsible for deciding whether to install and
use it.

## Licence

The Telegram iOS codebase is identified by Telegram as GNU GPL version 2
or later. TrollGram's derivative code is distributed under the terms
described in [`LICENSE`](LICENSE), while third-party components and
submodules may have their own licences and notices. Read those notices
before redistributing a build.
