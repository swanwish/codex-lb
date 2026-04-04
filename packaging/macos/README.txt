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
- This package is architecture-specific. Use the matching arm64 or x86_64 build for your Mac.
- GitHub Releases may also include a DMG for the same architecture. Prefer the DMG if you want the notarized distribution artifact.
- Recipients do not need a local Python installation.
- Default data directory remains ~/.codex-lb/
- Unsigned archives downloaded from the internet may require:
  xattr -dr com.apple.quarantine ./codex-lb
