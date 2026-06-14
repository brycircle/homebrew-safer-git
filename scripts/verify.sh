#!/usr/bin/env bash
# Verify safer-git end-to-end: download the upstream tarball pinned by the
# formula, apply our patch, build, and prove that git hooks are disabled by
# making a commit with a failing pre-commit hook installed.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FORMULA="$REPO_ROOT/Formula/safer-git.rb"
PATCH_FILE="$REPO_ROOT/patches/disable-hooks.patch"

[ -f "$FORMULA" ]    || { echo "missing $FORMULA" >&2;    exit 1; }
[ -f "$PATCH_FILE" ] || { echo "missing $PATCH_FILE" >&2; exit 1; }

URL=$(awk -F'"' '/^[[:space:]]*url[[:space:]]+"/    {print $2; exit}' "$FORMULA")
SHA=$(awk -F'"' '/^[[:space:]]*sha256[[:space:]]+"/ {print $2; exit}' "$FORMULA")
[ -n "$URL" ] && [ -n "$SHA" ] || { echo "could not parse url/sha256 from $FORMULA" >&2; exit 1; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "==> Downloading $URL"
TARBALL="$WORK/git.tar.xz"
curl -fsSLo "$TARBALL" "$URL"

echo "==> Verifying sha256"
GOT=$(sha256_of "$TARBALL")
if [ "$GOT" != "$SHA" ]; then
  echo "sha256 mismatch: formula expects $SHA, downloaded $GOT" >&2
  exit 1
fi

echo "==> Extracting"
SRC="$WORK/src"
mkdir -p "$SRC"
tar -xf "$TARBALL" -C "$SRC" --strip-components=1

echo "==> Applying patch"
patch -d "$SRC" -p1 -i "$PATCH_FILE"

echo "==> Building"
PREFIX="$WORK/install"
JOBS=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)
MAKE_ARGS=(
  USE_LIBPCRE2=YesPlease
  NO_PERL=1 NO_PYTHON=1 NO_TCLTK=1 NO_GETTEXT=1
  CFLAGS=-O2
  "prefix=$PREFIX"
)
make -C "$SRC" -j"$JOBS" "${MAKE_ARGS[@]}"
make -C "$SRC" "${MAKE_ARGS[@]}" install

GIT="$PREFIX/bin/git"
echo "==> Built: $("$GIT" --version)"

echo "==> Verifying hooks are disabled"
REPO="$WORK/testrepo"
"$GIT" init -q "$REPO"
cd "$REPO"
"$GIT" config user.email "test@example.com"
"$GIT" config user.name  "Test"

cat > .git/hooks/pre-commit <<'HOOK'
#!/bin/sh
touch "$PWD/.hook-ran"
exit 1
HOOK
chmod 0755 .git/hooks/pre-commit

echo hello > file.txt
"$GIT" add file.txt

if ! "$GIT" commit -q -m "test commit"; then
  echo "FAIL: pre-commit hook blocked the commit — hooks are NOT disabled" >&2
  exit 1
fi

if [ -e .hook-ran ]; then
  echo "FAIL: pre-commit hook executed (sentinel exists) — hooks are NOT disabled" >&2
  exit 1
fi

echo "PASS: build succeeded and git hooks are disabled."
