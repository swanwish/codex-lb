from __future__ import annotations

import importlib
import sys

import pytest

import app.core.config.settings as settings_module

pytestmark = pytest.mark.unit


def test_packaged_runtime_reads_env_file_from_executable_directory(tmp_path) -> None:
    executable_dir = tmp_path / "release"
    executable_dir.mkdir()
    (executable_dir / ".env.local").write_text("CODEX_LB_LOG_FORMAT=json\n", encoding="utf-8")

    with pytest.MonkeyPatch.context() as monkeypatch:
        monkeypatch.setattr(sys, "frozen", True, raising=False)
        monkeypatch.setattr(sys, "executable", str(executable_dir / "codex-lb"), raising=False)
        monkeypatch.delenv("CODEX_LB_LOG_FORMAT", raising=False)

        reloaded = importlib.reload(settings_module)
        settings = reloaded.Settings()

        assert reloaded.BASE_DIR == executable_dir
        assert settings.log_format == "json"

    importlib.reload(settings_module)


def test_source_runtime_keeps_repo_base_dir() -> None:
    reloaded = importlib.reload(settings_module)

    assert reloaded.BASE_DIR == reloaded.Path(__file__).resolve().parents[2]
