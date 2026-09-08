#!/usr/bin/env bash
# Cuts a release in two steps, so the link gets tested before anything goes live.
#
#   make publish VERSION=0.15.0 NOTES="..."   bump control, build, upload to catbox, write the site's
#                                             content/release.json, print the link. Nothing is committed.
#   make push                                 commit and push both repos once the link is tested;
#                                             Coolify rebuilds spoti.pw from that push.
#
# The IPA never touches git: it goes to catbox and only its URL lands in release.json, next to the
# mod version, Spotify's version and build (read off the built IPA), size, date and notes.
# CATBOX_USERHASH uploads under your catbox account instead of anonymously (files then show up in
# its manager and can be deleted). WEB points at the site checkout, default ../custom_spotify_web.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="${WEB:-$ROOT/../custom_spotify_web}"
RELEASE="$WEB/content/release.json"
CONTROL="$ROOT/tweak/control"

die() { echo "$*" >&2; exit 1; }
control_version() { sed -n 's/^Version: //p' "$CONTROL"; }
release_field() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$RELEASE" "$1"; }

stage() {
  local ipa="$1" version="$2" notes="$3"
  [ -f "$ipa" ] || die "no IPA: put a decrypted Spotify .ipa in ipa/, or pass one (make publish IPA=path.ipa ...)"
  [[ "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]] || die "VERSION must look like 0.15.0, got '${version:-nothing}'"
  [ -n "$notes" ] || die "NOTES is empty: say what changed, it is the changelog on the site and in the app"
  [ -d "$WEB/content" ] || die "no site checkout at $WEB (set WEB=...)"
  [ "$version" = "$(control_version)" ] && echo "note: control already says $version" >&2

  sed -i '' "s/^Version: .*/Version: $version/" "$CONTROL"

  local out
  out="$("$ROOT/scripts/pipeline.sh" "$ipa" --no-flex | tee /dev/stderr | sed -n 's/^==> done: //p')"
  [ -f "$out" ] || die "pipeline did not report a built IPA"

  local app_dir plist
  app_dir="$(unzip -Z1 "$out" | grep -oE '^Payload/[^/]+\.app/' | sort -u | head -1)"
  plist="$(mktemp)"
  unzip -p "$out" "${app_dir}Info.plist" > "$plist"
  local spotify build bundle min_os
  spotify="$(plutil -extract CFBundleShortVersionString raw -o - "$plist")"
  build="$(plutil -extract CFBundleVersion raw -o - "$plist")"
  bundle="$(plutil -extract CFBundleIdentifier raw -o - "$plist")"
  min_os="$(plutil -extract MinimumOSVersion raw -o - "$plist")"
  rm -f "$plist"

  echo "==> uploading $(du -h "$out" | cut -f1) to catbox"
  local url
  url="$(curl -fsS -F reqtype=fileupload ${CATBOX_USERHASH:+-F "userhash=$CATBOX_USERHASH"} \
              -F "fileToUpload=@$out" https://catbox.moe/user/api.php)"
  [[ "$url" == https://files.catbox.moe/* ]] || die "catbox did not return a link: $url"

  python3 - "$RELEASE" "$version" "$spotify" "$build" "$bundle" "$min_os" "$(stat -f %z "$out")" "$url" "$notes" <<'PY'
import json, sys
from datetime import date
path, mod, spotify, build, bundle, min_os, size, url, notes = sys.argv[1:]
json.dump({
    "mod": mod, "version": spotify, "buildVersion": build, "bundleId": bundle, "minOS": min_os,
    "bytes": int(size), "date": date.today().isoformat(), "ipaUrl": url, "notes": notes,
}, open(path, "w"), indent=2)
open(path, "a").write("\n")
PY

  cat <<MSG

==> staged $version on Spotify $spotify
    $url
    $RELEASE
Sign and install that link, check the About row says $version, then: make push
MSG
}

push() {
  local mod
  mod="$(release_field mod)"
  [ "$mod" = "$(control_version)" ] || die "release.json says $mod but control says $(control_version); run make publish"
  [ -n "$(git -C "$WEB" status --porcelain -- content/release.json)" ] || die "release.json is unchanged; run make publish first"

  git -C "$WEB" add content/release.json
  git -C "$WEB" commit -m "release: $mod"
  git -C "$WEB" push
  git -C "$ROOT" add tweak/control
  git -C "$ROOT" commit -m "release: $mod"
  git -C "$ROOT" push
  echo "==> $mod is live once Coolify finishes: $(release_field ipaUrl)"
}

case "${1:-}" in
  stage) stage "$2" "$3" "$4" ;;
  push) push ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
