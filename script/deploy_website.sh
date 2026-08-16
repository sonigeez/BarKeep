#!/bin/zsh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE_SOURCE="$REPO_ROOT/website"
PACKAGE_PATH="$REPO_ROOT/dist/BarKeep-1.0.0.zip"
CHECKSUM_PATH="$PACKAGE_PATH.sha256"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/barkeep-site.XXXXXX")"
CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-41c98402ec5a272c8d9cce3ccac9c7ef}"
export CLOUDFLARE_ACCOUNT_ID

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

if [[ ! -f "$PACKAGE_PATH" || ! -f "$CHECKSUM_PATH" ]]; then
  echo "Missing release package. Run ./script/build_and_run.sh --package first." >&2
  exit 1
fi

cp -R "$SITE_SOURCE/." "$STAGING_DIR/"
rm "$STAGING_DIR/README.md"
mkdir -p "$STAGING_DIR/downloads"
cp "$PACKAGE_PATH" "$CHECKSUM_PATH" "$STAGING_DIR/downloads/"

cd "$REPO_ROOT"
npx wrangler pages deploy "$STAGING_DIR" --project-name barkeep
