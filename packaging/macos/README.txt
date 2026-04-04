codex-lb macOS package

Installed paths:
- launcher command: /usr/local/bin/codex-lb
- packaged runtime: /Library/Application Support/codex-lb/
- user data and overrides (fresh installs): ~/Library/Application Support/codex-lb/
- legacy user data (upgrades): ~/.codex-lb/

After installation:
1. Open a new Terminal window
2. Optionally run:
   codex-lb init
3. Run:
   codex-lb
4. Open:
   http://127.0.0.1:2455

Configuration:
- Fresh PKG installs read user overrides from:
  ~/Library/Application Support/codex-lb/.env
  ~/Library/Application Support/codex-lb/.env.local
- Existing ~/.codex-lb installs remain supported during upgrades
- The macOS example config is installed at:
  /Library/Application Support/codex-lb/.env.example
- To create a local override file automatically:
  codex-lb init
- Or manually:
  mkdir -p ~/Library/Application\ Support/codex-lb
  cp "/Library/Application Support/codex-lb/.env.example" \
    ~/Library/Application\ Support/codex-lb/.env.local

Client endpoints:
- Codex CLI:
  http://127.0.0.1:2455/backend-api/codex
- OpenAI-compatible clients:
  http://127.0.0.1:2455/v1

Notes:
- Use the arm64 build on Apple Silicon Macs
- Use the x86_64 build on Intel Macs
- Default database path for fresh PKG installs:
  ~/Library/Application Support/codex-lb/store.db
- Default OAuth callback port:
  1455
- Health check:
  http://127.0.0.1:2455/health
