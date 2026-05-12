# -*- mode: python ; coding: utf-8 -*-
from __future__ import annotations

import os
from pathlib import Path

from PyInstaller.utils.hooks import collect_data_files, collect_submodules

ROOT = Path(os.environ.get("CODEX_LB_PROJECT_ROOT", Path.cwd())).resolve()
APP_NAME = os.environ.get("CODEX_LB_PYINSTALLER_APP_NAME", "codex-lb")


def _data_tree(directory: Path) -> list[tuple[str, str]]:
    entries: list[tuple[str, str]] = []
    for path in directory.rglob("*"):
        if path.is_file():
            entries.append((str(path), str(path.relative_to(ROOT).parent)))
    return entries


datas = [
    *collect_data_files(
        "app",
        includes=[
            "static/**/*",
            "modules/oauth/templates/**/*",
        ],
    ),
    *collect_data_files("config", includes=["*.json"]),
    *_data_tree(ROOT / "app" / "db" / "alembic"),
]

hiddenimports = sorted(
    {
        *collect_submodules("app"),
        "aiosqlite",
        "asyncpg",
        "greenlet",
        "psycopg",
        "opentelemetry.exporter.otlp.proto.grpc.trace_exporter",
        "opentelemetry.instrumentation.aiohttp_client",
        "opentelemetry.instrumentation.fastapi",
        "opentelemetry.instrumentation.sqlalchemy",
        "opentelemetry.sdk.resources",
        "opentelemetry.sdk.trace",
        "opentelemetry.sdk.trace.export",
        "opentelemetry.trace",
        "prometheus_client",
        "prometheus_client.multiprocess",
    }
)

a = Analysis(
    [str(ROOT / "app" / "cli.py")],
    pathex=[str(ROOT)],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=["tests"],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    name=APP_NAME,
    exclude_binaries=True,
    console=True,
    strip=False,
    upx=False,
    bootloader_ignore_signals=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    name=APP_NAME,
)
