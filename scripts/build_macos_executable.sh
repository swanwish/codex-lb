#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="codex-lb"
ARCHIVE_PREFIX="${APP_NAME}-macos"
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
  --sign              Codesign the staged executable using CODEX_LB_MACOS_CODESIGN_IDENTITY.
  --notarize          Submit the DMG with notarytool and staple the result (implies --sign).
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

codesign_path() {
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

create_dmg() {
  local source_dir="$1"
  local dmg_path="$2"
  local volume_name="$3"

  echo "Creating DMG ${dmg_path}..."
  hdiutil create \
    -volname "${volume_name}" \
    -srcfolder "${source_dir}" \
    -ov \
    -format UDZO \
    "${dmg_path}" \
    >/dev/null
}

notarize_dmg() {
  local dmg_path="$1"

  require_env_var CODEX_LB_MACOS_NOTARY_APPLE_ID
  require_env_var CODEX_LB_MACOS_NOTARY_TEAM_ID
  require_env_var CODEX_LB_MACOS_NOTARY_APP_PASSWORD

  echo "Submitting ${dmg_path} for notarization..."
  xcrun notarytool submit "${dmg_path}" \
    --apple-id "${CODEX_LB_MACOS_NOTARY_APPLE_ID}" \
    --team-id "${CODEX_LB_MACOS_NOTARY_TEAM_ID}" \
    --password "${CODEX_LB_MACOS_NOTARY_APP_PASSWORD}" \
    --wait

  echo "Stapling notarization ticket to ${dmg_path}..."
  xcrun stapler staple "${dmg_path}"
  xcrun stapler validate "${dmg_path}"
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
PYI_DIST_DIR="${ROOT_DIR}/dist/pyinstaller/${PLATFORM_ID}"
PYI_WORK_DIR="${ROOT_DIR}/build/pyinstaller/${PLATFORM_ID}"
RELEASE_DIR="${ROOT_DIR}/dist/${ARCHIVE_PREFIX}-${ARCH}"
ARCHIVE_PATH="${ROOT_DIR}/dist/${ARCHIVE_PREFIX}-${ARCH}.tar.gz"
DMG_PATH="${ROOT_DIR}/dist/${ARCHIVE_PREFIX}-${ARCH}.dmg"
CHECKSUM_PATH="${ROOT_DIR}/dist/${ARCHIVE_PREFIX}-${ARCH}.sha256"

rm -rf "${PYI_DIST_DIR}" "${PYI_WORK_DIR}" "${RELEASE_DIR}" "${ARCHIVE_PATH}" "${DMG_PATH}" "${CHECKSUM_PATH}"
mkdir -p "${PYI_DIST_DIR}" "${PYI_WORK_DIR}" "${RELEASE_DIR}"

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

BINARY_PATH="${PYI_DIST_DIR}/${APP_NAME}"
if [[ ! -x "${BINARY_PATH}" ]]; then
  echo "PyInstaller did not produce ${BINARY_PATH}" >&2
  exit 1
fi

cp "${BINARY_PATH}" "${RELEASE_DIR}/${APP_NAME}"
cp "${ROOT_DIR}/.env.example" "${RELEASE_DIR}/.env.example"
cp "${ROOT_DIR}/packaging/macos/README.txt" "${RELEASE_DIR}/README.txt"
chmod +x "${RELEASE_DIR}/${APP_NAME}"

if [[ "${SIGN_ARTIFACTS}" == "true" ]]; then
  codesign_path "${RELEASE_DIR}/${APP_NAME}"
fi

tar -C "${ROOT_DIR}/dist" -czf "${ARCHIVE_PATH}" "$(basename "${RELEASE_DIR}")"
create_dmg "${RELEASE_DIR}" "${DMG_PATH}" "${APP_NAME}-${ARCH}"

if [[ "${NOTARIZE_ARTIFACTS}" == "true" ]]; then
  notarize_dmg "${DMG_PATH}"
fi

pushd "${ROOT_DIR}/dist" >/dev/null
shasum -a 256 "$(basename "${ARCHIVE_PATH}")" "$(basename "${DMG_PATH}")" > "$(basename "${CHECKSUM_PATH}")"
popd >/dev/null

echo
echo "Build complete:"
echo "  Binary:  ${RELEASE_DIR}/${APP_NAME}"
echo "  Archive: ${ARCHIVE_PATH}"
echo "  DMG:     ${DMG_PATH}"
echo "  SHA256:  ${CHECKSUM_PATH}"
