#!/usr/bin/env bash
# Build the Noor Qur'an web app and deploy it to Vercel, bundling the Android APK
# so downloads are served same-origin (GitHub release CDN stalls on mobile browsers).
set -euo pipefail
cd "$(dirname "$0")"

export PATH="$PATH:/c/Users/USER/flutter/bin"

APK_SRC="dist/NoorQuran-1.0.0-arm64-v8a.apk"
APK_DEST_NAME="noor-quran-latest.apk"

echo "==> Building web release"
flutter build web --release --no-tree-shake-icons

echo "==> Bundling APK into the build output (post-build, so the service worker ignores it)"
mkdir -p build/web/download
cp "$APK_SRC" "build/web/download/$APK_DEST_NAME"
cp "$APK_SRC" "build/web/download/noor-quran-1.0.0-arm64-v8a.apk"

# vercel.json must travel with the deployment root.
cp vercel.json build/web/vercel.json

echo "==> Deploying to Vercel (production)"
cd build/web
export PATH="$PATH:/c/Users/USER/AppData/Roaming/npm"
vercel deploy --prod --yes --name noor-quran

echo "==> Done"
