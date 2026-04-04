# desktop-packaging Specification

## ADDED Requirements

### Requirement: macOS builds can be packaged as self-contained archives

The project MUST provide a supported macOS packaging flow that produces a self-contained archive containing the `codex-lb` executable and the adjacent runtime files needed by recipients.

#### Scenario: macOS build archive is created

- **WHEN** a maintainer runs the documented macOS packaging command
- **THEN** the build outputs a macOS `codex-lb` executable
- **AND** it stages a release archive that includes the executable plus adjacent runtime guidance files

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
