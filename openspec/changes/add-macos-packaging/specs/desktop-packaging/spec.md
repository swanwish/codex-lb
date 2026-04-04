# desktop-packaging Specification

## ADDED Requirements

### Requirement: macOS builds can be packaged as self-contained archives

The project MUST provide a supported macOS packaging flow that produces architecture-labelled release artifacts containing the `codex-lb` executable and the adjacent runtime files needed by recipients.

#### Scenario: macOS build archive is created

- **WHEN** a maintainer runs the documented macOS packaging command
- **THEN** the build outputs a macOS `codex-lb` executable
- **AND** it stages a release archive and DMG that include the executable plus adjacent runtime guidance files
- **AND** each artifact name indicates whether it targets `arm64` or `x86_64`

### Requirement: packaged macOS builds retain bundled runtime assets

The macOS packaging flow MUST bundle the dashboard static assets, bundled config data, OAuth templates, and Alembic migration files required for startup and runtime behavior.

#### Scenario: packaged binary starts without a source checkout

- **WHEN** a recipient runs the packaged macOS executable outside the repository
- **THEN** the dashboard UI still serves built static assets
- **AND** startup migrations can still locate the bundled Alembic scripts
- **AND** runtime bundled config reads still resolve without requiring repository-relative files

### Requirement: packaged macOS builds read env files from the executable directory

When the service runs from a packaged macOS executable, it MUST read `.env` and `.env.local` from the executable directory instead of the transient unpack location used by the packager.

#### Scenario: recipient configures the packaged binary with a local env file

- **WHEN** a recipient places `.env.local` next to the packaged executable
- **THEN** startup settings load those values without requiring exported shell variables

### Requirement: release automation publishes macOS artifacts for Apple Silicon and Intel Macs

The release workflow MUST build macOS release artifacts for both Apple Silicon and Intel macOS targets and attach them to the GitHub Release for that version.

#### Scenario: release workflow publishes architecture-specific macOS artifacts

- **WHEN** the release workflow runs for a tagged version
- **THEN** it publishes an `arm64` macOS artifact set
- **AND** it publishes an `x86_64` macOS artifact set
- **AND** both artifact sets are attached to the GitHub Release for that tag

### Requirement: macOS release automation supports codesigning and notarization

When the required signing and notarization credentials are configured, the macOS release workflow MUST sign the packaged executable and generated DMG, notarize the generated DMG, and staple the notarization ticket before publishing the artifact.

#### Scenario: signing credentials are configured for a release build

- **WHEN** the release workflow runs with the documented macOS signing and notarization secrets
- **THEN** the packaged executable is codesigned
- **AND** the generated DMG is codesigned
- **AND** the generated DMG is submitted for notarization
- **AND** the notarization ticket is stapled to the DMG before release publication

### Requirement: maintainers can run a macOS-only packaging workflow without a full release

The project MUST provide a manually triggered GitHub Actions workflow that builds macOS package artifacts for both Apple Silicon and Intel runners without requiring PyPI, Docker, Helm, or GitHub Release publication to complete.

#### Scenario: maintainer runs the macOS-only packaging workflow

- **WHEN** a maintainer manually dispatches the dedicated macOS packaging workflow for a branch, tag, or commit
- **THEN** it uploads an `arm64` macOS artifact set as a workflow artifact
- **AND** it uploads an `x86_64` macOS artifact set as a workflow artifact
- **AND** it can optionally sign and notarize the DMG when the documented secrets are configured
