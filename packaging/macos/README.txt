codex-lb macOS package

This package contains:
- codex-lb: standalone executable for this macOS architecture
- .env.example: sample configuration file

Before you start:
- Use the arm64 build on Apple Silicon Macs
- Use the x86_64 build on Intel Macs
- You do not need Python, uv, Bun, or the source repository

Quick start:
1. Copy this package to a writable local directory, for example ~/Applications/codex-lb/
2. Optional: copy .env.example to .env.local
3. Run:
   ./codex-lb --host 127.0.0.1 --port 2455
4. Open:
   http://127.0.0.1:2455

Configuration:
- The executable reads .env and .env.local from the same directory
- Default database: ~/.codex-lb/store.db
- Default local service port: 2455
- Default OAuth callback port: 1455
- Do not change the OAuth callback port unless your maintainer told you to

Client endpoints:
- Codex CLI:
  http://127.0.0.1:2455/backend-api/codex
- OpenAI-compatible clients:
  http://127.0.0.1:2455/v1

Notes:
- Prefer the DMG if you want the signed and notarized distribution artifact
- Unsigned archives downloaded from the internet may require:
  xattr -dr com.apple.quarantine ./codex-lb
- Health check:
  http://127.0.0.1:2455/health
