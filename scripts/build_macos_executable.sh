#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="codex-lb"
ARCHIVE_PREFIX="${APP_NAME}-macos"
PACKAGE_IDENTIFIER="io.github.codex-lb"
INSTALL_ROOT="/Library/Application Support/${APP_NAME}"
INSTALL_BIN="/usr/local/bin/${APP_NAME}"
REBUILD_FRONTEND="false"
SKIP_FRONTEND="false"
SIGN_ARTIFACTS="false"
NOTARIZE_ARTIFACTS="false"

usage() {
  cat <<'EOF'
Usage: scripts/build_macos_executable.sh [--rebuild-frontend] [--skip-frontend] [--sign] [--notarize]

Build a self-contained macOS executable with PyInstaller and stage release artifacts.

Options:
  --rebuild-frontend  Rebuild app/static before packaging.
  --skip-frontend     Skip frontend build and require app/static to already exist.
  --sign              Codesign the staged executable and sign the generated PKG.
  --notarize          Submit the PKG with notarytool and staple the result (implies --sign).

Required env vars for --sign:
  CODEX_LB_MACOS_CODESIGN_IDENTITY
  CODEX_LB_MACOS_INSTALLER_SIGN_IDENTITY

Required env vars for --notarize:
  CODEX_LB_MACOS_NOTARY_APPLE_ID
  CODEX_LB_MACOS_NOTARY_TEAM_ID
  CODEX_LB_MACOS_NOTARY_APP_PASSWORD
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild-frontend)
      REBUILD_FRONTEND="true"
      shift
      ;;
    --skip-frontend)
      SKIP_FRONTEND="true"
      shift
      ;;
    --sign)
      SIGN_ARTIFACTS="true"
      shift
      ;;
    --notarize)
      SIGN_ARTIFACTS="true"
      NOTARIZE_ARTIFACTS="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This packaging script only supports macOS builders." >&2
  exit 1
fi

require_env_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
}

detect_frontend_pm() {
  if command -v bun >/dev/null 2>&1; then
    echo "bun"
  elif command -v npm >/dev/null 2>&1; then
    echo "npm"
  elif command -v pnpm >/dev/null 2>&1; then
    echo "pnpm"
  else
    echo "missing"
  fi
}

build_frontend() {
  local pm
  pm="$(detect_frontend_pm)"
  if [[ "${pm}" == "missing" ]]; then
    echo "Frontend rebuild requested but no bun/npm/pnpm was found." >&2
    exit 1
  fi

  echo "Building frontend with ${pm}..."
  pushd "${ROOT_DIR}/frontend" >/dev/null
  case "${pm}" in
    bun)
      bun install --frozen-lockfile
      bun run build
      ;;
    npm)
      npm install --no-package-lock --legacy-peer-deps
      npm run build
      ;;
    pnpm)
      pnpm install --no-frozen-lockfile
      pnpm run build
      ;;
  esac
  popd >/dev/null
}

project_version() {
  python3 - <<'PY'
import tomllib
from pathlib import Path

data = tomllib.loads(Path("pyproject.toml").read_text(encoding="utf-8"))
print(data["project"]["version"])
PY
}

codesign_executable() {
  local path="$1"

  require_env_var CODEX_LB_MACOS_CODESIGN_IDENTITY

  echo "Codesigning ${path}..."
  codesign \
    --force \
    --timestamp \
    --options runtime \
    --sign "${CODEX_LB_MACOS_CODESIGN_IDENTITY}" \
    "${path}"
  codesign --verify --strict --verbose=2 "${path}"
}

create_pkg() {
  local pkg_root="$1"
  local pkg_path="$2"
  local version="$3"
  local -a args=(
    --root "${pkg_root}"
    --identifier "${PACKAGE_IDENTIFIER}"
    --version "${version}"
    --install-location /
  )

  if [[ "${SIGN_ARTIFACTS}" == "true" ]]; then
    require_env_var CODEX_LB_MACOS_INSTALLER_SIGN_IDENTITY
    args+=(--sign "${CODEX_LB_MACOS_INSTALLER_SIGN_IDENTITY}")
  fi

  args+=("${pkg_path}")

  echo "Creating PKG ${pkg_path}..."
  pkgbuild "${args[@]}" >/dev/null

  if [[ "${SIGN_ARTIFACTS}" == "true" ]]; then
    pkgutil --check-signature "${pkg_path}"
  fi
}

notarize_pkg() {
  local pkg_path="$1"

  require_env_var CODEX_LB_MACOS_NOTARY_APPLE_ID
  require_env_var CODEX_LB_MACOS_NOTARY_TEAM_ID
  require_env_var CODEX_LB_MACOS_NOTARY_APP_PASSWORD

  echo "Submitting ${pkg_path} for notarization..."
  xcrun notarytool submit "${pkg_path}" \
    --apple-id "${CODEX_LB_MACOS_NOTARY_APPLE_ID}" \
    --team-id "${CODEX_LB_MACOS_NOTARY_TEAM_ID}" \
    --password "${CODEX_LB_MACOS_NOTARY_APP_PASSWORD}" \
    --wait

  echo "Stapling notarization ticket to ${pkg_path}..."
  xcrun stapler staple "${pkg_path}"
  xcrun stapler validate "${pkg_path}"
}

STATIC_INDEX="${ROOT_DIR}/app/static/index.html"
if [[ "${SKIP_FRONTEND}" == "true" ]]; then
  if [[ ! -f "${STATIC_INDEX}" ]]; then
    echo "app/static is missing; remove --skip-frontend or build frontend assets first." >&2
    exit 1
  fi
elif [[ "${REBUILD_FRONTEND}" == "true" || ! -f "${STATIC_INDEX}" ]]; then
  build_frontend
else
  echo "Using existing frontend assets in app/static/"
fi

ARCH="$(uname -m)"
PLATFORM_ID="macos-${ARCH}"
VERSION="$(cd "${ROOT_DIR}" && project_version)"
WRAPPER_TEMPLATE="${ROOT_DIR}/packaging/macos/bin/${APP_NAME}"
ENV_TEMPLATE="${ROOT_DIR}/packaging/macos/.env.example"
PYI_DIST_DIR="${ROOT_DIR}/dist/pyinstaller/${PLATFORM_ID}"
PYI_BUNDLE_DIR="${PYI_DIST_DIR}/${APP_NAME}"
PYI_WORK_DIR="${ROOT_DIR}/build/pyinstaller/${PLATFORM_ID}"
PKG_ROOT="${ROOT_DIR}/build/pkgroot/${PLATFORM_ID}"
RELEASE_DIR="${ROOT_DIR}/dist/${ARCHIVE_PREFIX}-${ARCH}"
ARCHIVE_PATH="${ROOT_DIR}/dist/${ARCHIVE_PREFIX}-${ARCH}.tar.gz"
PKG_PATH="${ROOT_DIR}/dist/${ARCHIVE_PREFIX}-${ARCH}.pkg"
CHECKSUM_PATH="${ROOT_DIR}/dist/${ARCHIVE_PREFIX}-${ARCH}.sha256"
LEGACY_DMG_PATH="${ROOT_DIR}/dist/${ARCHIVE_PREFIX}-${ARCH}.dmg"

rm -rf "${PYI_DIST_DIR}" "${PYI_WORK_DIR}" "${PKG_ROOT}" "${RELEASE_DIR}" "${ARCHIVE_PATH}" "${PKG_PATH}" "${CHECKSUM_PATH}" "${LEGACY_DMG_PATH}"
mkdir -p "${PYI_DIST_DIR}" "${PYI_WORK_DIR}" "${PKG_ROOT}${INSTALL_ROOT}" "${PKG_ROOT}/usr/local/bin" "${RELEASE_DIR}"

echo "Packaging ${APP_NAME} for ${PLATFORM_ID}..."
pushd "${ROOT_DIR}" >/dev/null
CODEX_LB_PYINSTALLER_APP_NAME="${APP_NAME}" \
CODEX_LB_PROJECT_ROOT="${ROOT_DIR}" \
uv run --extra metrics --extra tracing --with pyinstaller==6.16.0 \
  --frozen \
  pyinstaller \
  --clean \
  --noconfirm \
  --distpath "${PYI_DIST_DIR}" \
  --workpath "${PYI_WORK_DIR}" \
  packaging/pyinstaller/macos.spec
popd >/dev/null

BINARY_PATH="${PYI_BUNDLE_DIR}/${APP_NAME}"
if [[ ! -x "${BINARY_PATH}" ]]; then
  echo "PyInstaller did not produce ${BINARY_PATH}" >&2
  exit 1
fi

cp -R "${PYI_BUNDLE_DIR}/." "${RELEASE_DIR}/"
cp "${ENV_TEMPLATE}" "${RELEASE_DIR}/.env.example"
cp "${ROOT_DIR}/packaging/macos/README.txt" "${RELEASE_DIR}/README.txt"
chmod +x "${RELEASE_DIR}/${APP_NAME}"

if [[ "${SIGN_ARTIFACTS}" == "true" ]]; then
  codesign_executable "${RELEASE_DIR}/${APP_NAME}"
fi

cp -R "${RELEASE_DIR}/." "${PKG_ROOT}${INSTALL_ROOT}/"
install -m 755 "${WRAPPER_TEMPLATE}" "${PKG_ROOT}${INSTALL_BIN}"

tar -C "${ROOT_DIR}/dist" -czf "${ARCHIVE_PATH}" "$(basename "${RELEASE_DIR}")"
create_pkg "${PKG_ROOT}" "${PKG_PATH}" "${VERSION}"

if [[ "${NOTARIZE_ARTIFACTS}" == "true" ]]; then
  notarize_pkg "${PKG_PATH}"
fi

pushd "${ROOT_DIR}/dist" >/dev/null
shasum -a 256 "$(basename "${ARCHIVE_PATH}")" "$(basename "${PKG_PATH}")" > "$(basename "${CHECKSUM_PATH}")"
popd >/dev/null

echo
echo "Build complete:"
echo "  Binary:  ${RELEASE_DIR}/${APP_NAME}"
echo "  Archive: ${ARCHIVE_PATH}"
echo "  PKG:     ${PKG_PATH}"
echo "  SHA256:  ${CHECKSUM_PATH}"
