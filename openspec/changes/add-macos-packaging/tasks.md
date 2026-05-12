## 1. Specs

- [x] 1.1 Add the macOS desktop packaging requirements.
- [ ] 1.2 Validate OpenSpec changes.

## 2. Tests

- [x] 2.1 Add unit coverage for packaged-runtime env file loading.
- [x] 2.2 Add regression coverage that macOS packaging stages a durable PyInstaller onedir bundle.

## 3. Implementation

- [x] 3.1 Add a PyInstaller spec that bundles runtime assets and dynamically loaded database drivers.
- [x] 3.2 Add a macOS build script that stages a releasable archive.
- [x] 3.3 Document the macOS packaging and runtime workflow.
- [x] 3.4 Add release automation that publishes macOS arm64 and x86_64 artifacts to GitHub Releases.
- [x] 3.5 Extend the macOS packaging flow to emit PKGs and optional signing/notarization outputs.
- [x] 3.6 Document the Intel Mac distribution path and required signing/notarization secrets.
- [x] 3.7 Add a manually triggered macOS-only GitHub Actions workflow that uploads arm64 and x86_64 package artifacts.
- [x] 3.8 Document how to configure and run the macOS-only workflow without the full release pipeline.
- [x] 3.9 Install a `codex-lb` Terminal launcher from the macOS PKG so recipients can start the service without copying the package contents.
- [x] 3.10 Load packaged runtime overrides from the macOS user data directory for PKG-based installs while keeping `~/.codex-lb` upgrade compatibility.
- [x] 3.11 Add a lightweight `codex-lb init` command that prepares the user override file after installation.
- [x] 3.12 Stage the entire PyInstaller onedir bundle in macOS archive and PKG artifacts.
