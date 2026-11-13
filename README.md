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

TrollGram includes a collection of optional privacy-related settings:

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

Plugins can be managed from the application interface.

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
