#!/bin/bash
set -e

echo "🧹 Cleaning Flutter project and caches..."
flutter clean || true
rm -rf .dart_tool build pubspec.lock

echo "🧽 Repairing Flutter pub cache..."
flutter pub cache repair

echo "📦 Pre-caching Flutter artifacts..."
flutter precache

echo "🩺 Checking Flutter environment..."
flutter doctor -v

echo "📥 Fetching dependencies..."
flutter pub get

echo "🔍 Checking for Dart SDK in package_config.json..."
if cat .dart_tool/package_config.json | grep -q sdk; then
  echo "✅ Dart SDK linked successfully!"
else
  echo "⚠️ Dart SDK not found — forcing Flutter upgrade..."
  flutter upgrade --force
  flutter pub get
  echo "🔁 Re-checking..."
  cat .dart_tool/package_config.json | grep sdk || echo "❌ Still no SDK — please restart terminal and 
retry."
fi

echo "🎉 Done! Try running:"
echo "   flutter run --debug"

