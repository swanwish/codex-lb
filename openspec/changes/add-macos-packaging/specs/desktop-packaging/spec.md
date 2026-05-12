# desktop-packaging Specification

## ADDED Requirements

### Requirement: macOS builds can be packaged as self-contained archives

The project MUST provide a supported macOS packaging flow that produces architecture-labelled release artifacts containing the `codex-lb` executable and the adjacent runtime files needed by recipients.

#### Scenario: macOS build archive is created

- **WHEN** a maintainer runs the documented macOS packaging command
- **THEN** the build outputs a macOS `codex-lb` executable
- **AND** it stages a release archive and PKG that include the executable plus adjacent runtime guidance files
- **AND** each artifact name indicates whether it targets `arm64` or `x86_64`

### Requirement: packaged macOS builds retain bundled runtime assets

The macOS packaging flow MUST bundle the dashboard static assets, bundled config data, OAuth templates, and Alembic migration files required for startup and runtime behavior.

#### Scenario: packaged binary starts without a source checkout

- **WHEN** a recipient runs the packaged macOS executable outside the repository
- **THEN** the dashboard UI still serves built static assets
- **AND** startup migrations can still locate the bundled Alembic scripts
- **AND** runtime bundled config reads still resolve without requiring repository-relative files

#### Scenario: long-running packaged service retains dashboard assets

- **WHEN** a recipient starts the installed macOS service and leaves it running for multiple days
- **THEN** the dashboard static assets remain available from the installed runtime directory
- **AND** frontend requests do not depend on a PyInstaller onefile temporary extraction directory that macOS may clean up during runtime

### Requirement: packaged macOS builds read env files from the executable directory

When the service runs from a packaged macOS executable, it MUST read `.env` and `.env.local` from the executable directory instead of the transient unpack location used by the packager. For installed PKG builds, it MUST also support user overrides from the macOS user data directory so the installed `codex-lb` command can run without editing files inside system-owned install paths, while still honoring the legacy `~/.codex-lb` layout during upgrades.

#### Scenario: recipient configures the packaged binary with a local env file

- **WHEN** a recipient places `.env.local` next to the packaged executable
- **THEN** startup settings load those values without requiring exported shell variables

#### Scenario: recipient configures a fresh installed PKG build

- **WHEN** a recipient installs the macOS PKG and places `.env.local` under `~/Library/Application Support/codex-lb/`
- **THEN** launching `codex-lb` from Terminal loads those values without requiring edits inside the install directory

#### Scenario: recipient upgrades from the legacy home directory layout

- **WHEN** a recipient already has `.env.local` under `~/.codex-lb/` and has not created the newer macOS user data directory yet
- **THEN** launching `codex-lb` from Terminal continues to load those values

### Requirement: installed PKG builds expose a direct Terminal launcher

The macOS PKG installation flow MUST install a `codex-lb` launcher on the user's shell path so recipients can start the packaged service directly from Terminal without manually copying the app directory or `cd`-ing into the installation root.

#### Scenario: recipient starts the installed package from Terminal

- **WHEN** a recipient completes the PKG installation
- **THEN** the `codex-lb` command is available from Terminal
- **AND** running that command starts the packaged service

### Requirement: release automation publishes macOS artifacts for Apple Silicon and Intel Macs

The release workflow MUST build macOS release artifacts for both Apple Silicon and Intel macOS targets and attach them to the GitHub Release for that version.

#### Scenario: release workflow publishes architecture-specific macOS artifacts

- **WHEN** the release workflow runs for a tagged version
- **THEN** it publishes an `arm64` macOS artifact set
- **AND** it publishes an `x86_64` macOS artifact set
- **AND** both artifact sets are attached to the GitHub Release for that tag

### Requirement: macOS release automation supports codesigning and notarization

When the required signing and notarization credentials are configured, the macOS release workflow MUST sign the packaged executable, sign the generated PKG with an installer certificate, notarize the generated PKG, and staple the notarization ticket before publishing the artifact.

#### Scenario: signing credentials are configured for a release build

- **WHEN** the release workflow runs with the documented macOS signing and notarization secrets
- **THEN** the packaged executable is codesigned
- **AND** the generated PKG is signed with the installer identity
- **AND** the generated PKG is submitted for notarization
- **AND** the notarization ticket is stapled to the PKG before release publication

### Requirement: maintainers can run a macOS-only packaging workflow without a full release

The project MUST provide a manually triggered GitHub Actions workflow that builds macOS package artifacts for both Apple Silicon and Intel runners without requiring PyPI, Docker, Helm, or GitHub Release publication to complete.

#### Scenario: maintainer runs the macOS-only packaging workflow

- **WHEN** a maintainer manually dispatches the dedicated macOS packaging workflow for a branch, tag, or commit
- **THEN** it uploads an `arm64` macOS artifact set as a workflow artifact
- **AND** it uploads an `x86_64` macOS artifact set as a workflow artifact
- **AND** it can optionally sign and notarize the PKG when the documented secrets are configured
