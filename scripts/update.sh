#!/usr/bin/env bash
# update.sh [--check]
#
# Refreshes pkgs/sources.json from the release manifest that HostYourAI
# publishes next to their install script. The artifact is downloaded and hashed
# before anything is written, so a manifest that disagrees with the file it
# names aborts instead of producing a wrong pin.
#
# --check  report whether a newer release exists, write nothing, exit 1 if the
#          pin is out of date. Intended for CI.
set -euo pipefail

MANIFEST_URL="${HYAI_MANIFEST_URL:-https://hostyourai.com/cli/latest.json}"

ROOT="$(git rev-parse --show-toplevel)"
PIN="$ROOT/pkgs/sources.json"

CHECK_ONLY=0
if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=1
elif [[ -n "${1:-}" ]]; then
  echo "update: unknown argument '$1' (usage: update.sh [--check])" >&2
  exit 2
fi

for tool in curl jq sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || { echo "update: $tool is required" >&2; exit 2; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> fetching $MANIFEST_URL"
curl -fsSL "$MANIFEST_URL" -o "$TMP/latest.json"

for field in version url sha256 released; do
  value="$(jq -r --arg f "$field" '.[$f] // empty' "$TMP/latest.json")"
  [[ -n "$value" ]] || { echo "update: manifest has no '$field' field" >&2; exit 1; }
done

NEW_VERSION="$(jq -r .version "$TMP/latest.json")"
NEW_URL="$(jq -r .url "$TMP/latest.json")"
NEW_SHA="$(jq -r .sha256 "$TMP/latest.json")"

[[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "update: '$NEW_VERSION' is not a semantic version" >&2; exit 1; }
[[ "$NEW_SHA" =~ ^[0-9a-f]{64}$ ]] || {
  echo "update: '$NEW_SHA' is not a sha256 hex digest" >&2; exit 1; }
case "$NEW_URL" in
  *latest*) echo "update: refusing a moving URL as the build source: $NEW_URL" >&2; exit 1 ;;
esac

OLD_VERSION="$(jq -r .version "$PIN" 2>/dev/null || echo none)"

if [[ "$CHECK_ONLY" == 1 ]]; then
  if [[ "$NEW_VERSION" == "$OLD_VERSION" ]]; then
    echo "==> pin is current at $OLD_VERSION"
    exit 0
  fi
  echo "==> newer release available: $OLD_VERSION -> $NEW_VERSION" >&2
  exit 1
fi

echo "==> downloading $NEW_URL"
curl -fsSL "$NEW_URL" -o "$TMP/artifact.tgz"

GOT_SHA="$(sha256sum "$TMP/artifact.tgz" | cut -d' ' -f1)"
if [[ "$GOT_SHA" != "$NEW_SHA" ]]; then
  echo "update: hash mismatch, the pin was not touched" >&2
  echo "  manifest: $NEW_SHA" >&2
  echo "  artifact: $GOT_SHA" >&2
  exit 1
fi
echo "==> sha256 verified against the artifact"

TAR_VERSION="$(tar xzOf "$TMP/artifact.tgz" package/package.json | jq -r .version)"
if [[ "$TAR_VERSION" != "$NEW_VERSION" ]]; then
  echo "update: manifest says $NEW_VERSION but the tarball contains $TAR_VERSION" >&2
  echo "  the pin was not touched" >&2
  exit 1
fi
echo "==> tarball reports version $TAR_VERSION"

jq -S '{version, url, sha256, released}' "$TMP/latest.json" > "$TMP/sources.json"

if [[ -f "$PIN" ]] && cmp -s "$TMP/sources.json" "$PIN"; then
  echo "==> already up to date at $OLD_VERSION, nothing written"
  exit 0
fi

mv "$TMP/sources.json" "$PIN"
echo "==> pin updated: $OLD_VERSION -> $NEW_VERSION"
echo "    review the diff and commit $PIN"
