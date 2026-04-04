codex-lb macOS package

Contents
- codex-lb: self-contained executable built for this macOS architecture
- .env.example: sample configuration file

Usage
1. Copy .env.example to .env.local if you need to override defaults.
2. Edit .env.local in the same directory as the executable.
3. Run ./codex-lb --host 127.0.0.1 --port 2455
4. Open http://127.0.0.1:2455

Notes
- Recipients do not need a local Python installation.
- Default data directory remains ~/.codex-lb/
- Unsigned binaries downloaded from the internet may require:
  xattr -dr com.apple.quarantine ./codex-lb
