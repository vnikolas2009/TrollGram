
<div align="center">

# TrollGram

**An unofficial Telegram client for iOS**

Built on Telegram iOS and Swiftgram, with additional privacy controls
and experimental Python plugin support.

[Features](#features) · [Installation](#installation) · [Building](#building) · [Contributing](CONTRIBUTING.md)

</div>

---

## About

TrollGram is an iOS Telegram client based on the Telegram iOS codebase.

The project combines selected Swiftgram features, additional privacy
controls and an experimental Python plugin system.

The goal is to provide useful client-side features while keeping the
project open to modification and community contributions.

## Features

### Privacy controls

- Anti-Delete
- Edit History
- Ghost Mode
- Hide Online Status
- Hide Read Receipts
- Hide Typing Status
- Hide Uploading Status
- View Once Media
- Copy Protected Media
- Remove Sponsored Messages

These features operate on the client side. They do not guarantee
complete anonymity or protection from Telegram's servers.

### Python plugins

TrollGram includes experimental support for Python 3.11 plugins.

- Import Python `.py` files.
- Enable or disable individual plugins.
- View plugin logs.
- Store plugin data separately.

Default directories:

| Purpose | Path |
| --- | --- |
| Plugins | `Documents/Plugins` |
| Plugin data | `Documents/PluginsData` |

Only install plugins from sources you trust. Python plugins execute
code within the application environment and may access available data.

### Compatibility

The project includes selected features and compatibility components
from exteraGram.

Not every feature from other Telegram clients is available in TrollGram.

## Installation

The recommended way to install TrollGram is to use the IPA files
published in [GitHub Releases](../../releases).

Installation requirements depend on the signing method and the
iOS version of your device.

## Building

### Requirements

- macOS
- Xcode
- Python 3
- Git
- Git submodules initialized

### Clone the repository

```bash
git clone --recursive https://github.com/vnikolas2009/TrollGram.git
cd TrollGram
git submodule update --init --recursive
```

### Prepare the build environment

```bash
python3 build-system/setup_python.py
```

### Build

```bash
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

The build configuration may need to be adjusted for your environment.

## GitHub Actions

The repository includes a workflow for building the application:

`.github/workflows/build-ipa.yml`

Depending on the workflow configuration, signing may require these
GitHub Actions secrets:

- `P12_BASE64`
- `P12_PASSWORD`
- `MOBILEPROVISION_BASE64`

Do not publish certificates, provisioning profiles or passwords
in the repository.

## Project structure

| Path | Description |
| --- | --- |
| `Swiftgram/SGTrollPrivacy` | Privacy-related interface and features |
| `SGTrollPrivacyCore` | Privacy feature implementation |
| `PythonPlugins` | Python plugin support |
| `SGTrollPluginsUI` | Plugin management interface |
| `SGSettingsUI` | Application settings |
| `submodules/TelegramCore` | Telegram Core components |

## Credits

TrollGram builds on the work of several open-source projects:

- [Telegram iOS](https://github.com/TelegramMessenger/Telegram-iOS)
- [Swiftgram](https://github.com/Swiftgram/Telegram-iOS)
- [exteraGram](https://github.com/exteraSquad/exteraGram)

Thanks to their developers and contributors.

## Disclaimer

TrollGram is an unofficial third-party project.

It is not affiliated with, endorsed by or sponsored by Telegram
or any of the projects listed above.

Telegram is a trademark of its respective owner.

## License

TrollGram is distributed under the GNU General Public License,
version 2 or, at your option, any later version.

Some third-party components may be distributed under different
licenses. See their respective license files.

