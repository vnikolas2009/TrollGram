
# Contributing to TrollGram

Contributions, bug reports and suggestions are welcome.

Before submitting changes, please take a moment to read these guidelines.

## Before you start

- Check existing issues and pull requests.
- Make sure your change is relevant to the project.
- For large changes, open an issue first to discuss the approach.

## Development setup

Clone the repository with its submodules:

```bash
git clone --recursive https://github.com/vnikolas2009/TrollGram.git
cd TrollGram
git submodule update --init --recursive
```

Prepare the build environment:

```bash
python3 build-system/setup_python.py
```

See the [README](README.md) for build instructions.

## Making changes

A few guidelines help keep the codebase consistent:

- Keep changes focused on one problem or feature.
- Follow the existing code style.
- Avoid unrelated formatting changes.
- Do not include generated files unless necessary.
- Test your changes before opening a pull request.

## Privacy features

Changes to privacy-related functionality should be tested carefully.

When submitting such changes, explain:

- What the feature does.
- Whether it affects message handling or network requests.
- Any known limitations.
- How you tested it.

Do not describe client-side privacy features as providing complete anonymity.

## Python plugins

Changes to the plugin system should preserve compatibility with
the existing plugin structure.

Please document changes to the plugin API and avoid introducing
unnecessary permissions or access to user data.

## Pull requests

When opening a pull request:

1. Describe the problem or feature.
2. Explain what you changed.
3. Include relevant screenshots or logs when useful.
4. Mention the tests you performed.
5. Reference related issues, if any.

Keep pull requests focused and avoid combining unrelated changes.

## Commit messages

Use short and descriptive commit messages.

Examples:

```text
fix: correct plugin loading
feat: add privacy setting
docs: update installation instructions
refactor: simplify plugin manager
```

## Reporting bugs

When reporting a bug, include:

- iOS version.
- Device model.
- TrollGram version or commit.
- Steps to reproduce the issue.
- Expected and actual behavior.
- Relevant logs or screenshots.

Do not include passwords, certificates, tokens or private messages.

## Security issues

Do not publish details of an unpatched security vulnerability
in a public issue.

Contact the project maintainers privately before disclosing it.

## License

By submitting a contribution, you agree that it may be distributed
under the project's applicable license.
