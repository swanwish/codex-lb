#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="codex-lb"
ARCHIVE_PREFIX="${APP_NAME}-macos"
REBUILD_FRONTEND="false"
SKIP_FRONTEND="false"

usage() {
  cat <<'EOF'
Usage: scripts/build_macos_executable.sh [--rebuild-frontend] [--skip-frontend]

Build a self-contained macOS executable with PyInstaller and stage a release tarball.

Options:
  --rebuild-frontend  Rebuild app/static before packaging.
  --skip-frontend     Skip frontend build and require app/static to already exist.
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

rm -rf "${PYI_DIST_DIR}" "${PYI_WORK_DIR}" "${RELEASE_DIR}" "${ARCHIVE_PATH}"
mkdir -p "${PYI_DIST_DIR}" "${PYI_WORK_DIR}" "${RELEASE_DIR}"

echo "Packaging ${APP_NAME} for ${PLATFORM_ID}..."
pushd "${ROOT_DIR}" >/dev/null
CODEX_LB_PYINSTALLER_APP_NAME="${APP_NAME}" \
CODEX_LB_PROJECT_ROOT="${ROOT_DIR}" \
uv run --extra metrics --extra tracing --with pyinstaller==6.16.0 \
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

tar -C "${ROOT_DIR}/dist" -czf "${ARCHIVE_PATH}" "$(basename "${RELEASE_DIR}")"

echo
echo "Build complete:"
echo "  Binary:  ${RELEASE_DIR}/${APP_NAME}"
echo "  Archive: ${ARCHIVE_PATH}"
