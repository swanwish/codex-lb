## Why

The project already ships clean Docker and wheel artifacts, but there is no supported path to hand a non-Python macOS user a self-contained build. That blocks the simplest desktop-style evaluation flow for operators who only want to run one binary locally.

## What Changes

- Add a macOS packaging flow based on PyInstaller that produces a self-contained executable archive.
- Ensure packaged builds include the dashboard static assets, Alembic migration files, and bundled config data required at runtime.
- Make packaged binaries load `.env` and `.env.local` from the executable directory so recipients can configure the app without a source checkout.

## Capabilities

### New Capabilities

- `desktop-packaging`
