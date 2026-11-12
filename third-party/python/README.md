# Python.xcframework (Python 3.11, iOS device + simulator)
#
# The prebuilt static framework is not tracked in git (about 100 MB of binaries).
# Place it at `third-party/python/Python.xcframework/` before building, e.g.:
#
#   cd third-party/python
#   curl -L -o python.zip https://github.com/beeware/Python-Apple-support/releases/download/3.11-b8/Python-3.11-iOS-support.b8.tar.gz
#   tar -xzf python.zip && mv Python.xcframework .
#
# Bazel target: //third-party/python:Python
