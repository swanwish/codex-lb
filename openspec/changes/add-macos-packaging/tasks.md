## 1. Specs

- [x] 1.1 Add the macOS desktop packaging requirements.
- [ ] 1.2 Validate OpenSpec changes.

## 2. Tests

- [x] 2.1 Add unit coverage for packaged-runtime env file loading.

## 3. Implementation

- [x] 3.1 Add a PyInstaller spec that bundles runtime assets and dynamically loaded database drivers.
- [x] 3.2 Add a macOS build script that stages a releasable archive.
- [x] 3.3 Document the macOS packaging and runtime workflow.
- [x] 3.4 Add release automation that publishes macOS arm64 and x86_64 artifacts to GitHub Releases.
- [x] 3.5 Extend the macOS packaging flow to emit DMGs and optional signing/notarization outputs.
- [x] 3.6 Document the Intel Mac distribution path and required signing/notarization secrets.
