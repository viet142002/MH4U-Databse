#!/bin/bash
# mh4u_app dev helper scripts
# Usage: ./scripts.sh <command>

set -e

CMD=${1:-help}

case "$CMD" in
  setup)
    echo "📦 Installing dependencies..."
    flutter pub get
    echo "⚙️  Running code generation..."
    dart run build_runner build --delete-conflicting-outputs
    echo "✅ Setup complete! Run: flutter run"
    ;;

  gen)
    echo "⚙️  Running code generation..."
    dart run build_runner build --delete-conflicting-outputs
    ;;

  gen-watch)
    echo "👀 Watching for changes..."
    dart run build_runner watch --delete-conflicting-outputs
    ;;

  clean-gen)
    echo "🗑  Cleaning generated files..."
    find lib -name "*.g.dart" -delete
    find lib -name "*.freezed.dart" -delete
    echo "⚙️  Regenerating..."
    dart run build_runner build --delete-conflicting-outputs
    ;;

  run)
    flutter run --flavor development
    ;;

  run-release)
    flutter run --release
    ;;

  build-apk)
    echo "🔨 Building APK..."
    flutter build apk --release
    echo "📱 APK: build/app/outputs/flutter-apk/app-release.apk"
    ;;

  build-aab)
    echo "🔨 Building App Bundle..."
    flutter build appbundle --release
    ;;

  test)
    flutter test
    ;;

  analyze)
    flutter analyze
    ;;

  format)
    dart format lib/ --line-length 100
    ;;

  help|*)
    echo ""
    echo "🐉 MH4U Database - Dev Scripts"
    echo "================================"
    echo ""
    echo "Usage: ./scripts.sh <command>"
    echo ""
    echo "Commands:"
    echo "  setup        Install deps + run code generation (first time setup)"
    echo "  gen          Run build_runner once"
    echo "  gen-watch    Watch and auto-regenerate on file changes"
    echo "  clean-gen    Delete all .g.dart files and regenerate from scratch"
    echo "  run          Run app in debug mode"
    echo "  run-release  Run app in release mode"
    echo "  build-apk    Build release APK"
    echo "  build-aab    Build release App Bundle (Play Store)"
    echo "  test         Run all tests"
    echo "  analyze      Run flutter analyze"
    echo "  format       Format all Dart files"
    echo ""
    ;;
esac
