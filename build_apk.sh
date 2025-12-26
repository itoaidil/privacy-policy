#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_ROOT=${SCRIPT_DIR}
VARIANT="release"
AUTO_INSTALL=false

log() { echo "[build-apk] $1"; }
fail() { echo "[build-apk][ERROR] $1" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) VARIANT="debug"; shift ;;
    --release) VARIANT="release"; shift ;;
    --install) AUTO_INSTALL=true; shift ;;
    *) fail "Unknown option: $1" ;;
  esac
done

SSD_GRADLE_CACHE="/Volumes/SSD_FITRO/android-development/gradle-cache"
if [[ -d "$SSD_GRADLE_CACHE" ]]; then
  export GRADLE_USER_HOME="$SSD_GRADLE_CACHE"
  log "Using GRADLE_USER_HOME=$GRADLE_USER_HOME"
fi

command -v flutter >/dev/null 2>&1 || fail "flutter not found in PATH"
pushd "$PROJECT_ROOT" >/dev/null
log "flutter pub get"
flutter pub get >/dev/null

pushd android >/dev/null
TASK="assembleRelease"; [[ "$VARIANT" == "debug" ]] && TASK="assembleDebug"
log "./gradlew ${TASK}"
./gradlew ${TASK}
popd >/dev/null

log "Locating APK"
APK=$(find android/app/build/outputs -type f \( -name "app-${VARIANT}.apk" -o -name "app-${VARIANT}*.apk" -o -name "*-${VARIANT}.apk" \) -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -n1 || true)
if [[ -z "${APK}" || ! -f "${APK}" ]]; then
  APK=$(find android -type f -name "*.apk" -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -n1 || true)
fi
[[ -z "${APK}" || ! -f "${APK}" ]] && fail "APK not found after build"

TS=$(date +%Y%m%d_%H%M%S)
DEST="$HOME/Desktop/travel_app_${VARIANT}_${TS}.apk"
cp -f "$APK" "$DEST"
log "Copied: $DEST"

if $AUTO_INSTALL; then
  ANDROID_HOME_DEFAULT="/Volumes/SSD_FITRO/android-development/sdk"
  if [[ -z "${ANDROID_HOME:-}" && -d "$ANDROID_HOME_DEFAULT" ]]; then
    export ANDROID_HOME="$ANDROID_HOME_DEFAULT"
  fi
  ADB_BIN="${ANDROID_HOME:-}/platform-tools/adb"
  if [[ -x "$ADB_BIN" ]]; then
    DEV_COUNT=$($ADB_BIN devices | awk 'NR>1 && $2=="device" {c++} END{print c+0}')
    if [[ "$DEV_COUNT" -ge 1 ]]; then
      log "Installing via ADB"
      $ADB_BIN install -r -d "$DEST" || fail "ADB install failed"
      log "Install success"
    else
      log "No ADB device; skipped install"
    fi
  else
    log "ADB not found; skipped install"
  fi
fi

popd >/dev/null
log "Done"
