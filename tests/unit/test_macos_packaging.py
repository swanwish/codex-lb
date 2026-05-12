from __future__ import annotations

from pathlib import Path

import pytest

pytestmark = pytest.mark.unit

_PROJECT_ROOT = Path(__file__).resolve().parents[2]
_MACOS_SPEC = _PROJECT_ROOT / "packaging" / "pyinstaller" / "macos.spec"
_BUILD_SCRIPT = _PROJECT_ROOT / "scripts" / "build_macos_executable.sh"


def test_macos_pyinstaller_spec_builds_persistent_onedir_bundle() -> None:
    spec = _MACOS_SPEC.read_text(encoding="utf-8")

    assert "exclude_binaries=True" in spec
    assert "COLLECT(" in spec
    assert "a.binaries" in spec
    assert "a.datas" in spec
    assert "a.zipfiles" in spec
    assert "a.binaries,\n    a.zipfiles,\n    a.datas" in spec


def test_macos_packaging_stages_entire_pyinstaller_bundle() -> None:
    script = _BUILD_SCRIPT.read_text(encoding="utf-8")

    assert 'PYI_BUNDLE_DIR="${PYI_DIST_DIR}/${APP_NAME}"' in script
    assert 'BINARY_PATH="${PYI_BUNDLE_DIR}/${APP_NAME}"' in script
    assert 'cp -R "${PYI_BUNDLE_DIR}/." "${RELEASE_DIR}/"' in script
    assert 'cp -R "${RELEASE_DIR}/." "${PKG_ROOT}${INSTALL_ROOT}/"' in script
