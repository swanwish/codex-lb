## Why

The project already ships clean Docker and wheel artifacts, but there is no supported path to hand a non-Python macOS user a self-contained build. That blocks the simplest desktop-style evaluation flow for operators who only want to run one binary locally.

## What Changes

- Add a macOS packaging flow based on PyInstaller that produces a self-contained archive plus PKG installer with a direct Terminal launcher.
- Ensure packaged builds include the dashboard static assets, Alembic migration files, and bundled config data required at runtime.
- Stage packaged runtime assets in a durable onedir layout so long-running services do not depend on PyInstaller's transient onefile extraction directory.
- Make packaged binaries load `.env` and `.env.local` from the executable directory so recipients can configure the app without a source checkout.
- Publish architecture-specific macOS release artifacts for both Apple Silicon and Intel Macs from GitHub Actions.
- Add optional codesigning and notarization support for the macOS release PKG when release secrets are configured.

## Capabilities

### New Capabilities

- `desktop-packaging`
