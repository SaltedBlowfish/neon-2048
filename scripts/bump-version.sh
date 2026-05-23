#!/bin/bash

# Usage:
#   ./scripts/bump-version.sh <version>     Bump version (and auto-increment build)
#   ./scripts/bump-version.sh --build       Auto-increment build only (no version change)
#   ./scripts/bump-version.sh --current     Print current version+build, exit
#
# Examples:
#   ./scripts/bump-version.sh 1.0.1
#   ./scripts/bump-version.sh 2.0.0
#   ./scripts/bump-version.sh --build       (useful for rebuilding after a rejected upload)
#
# Flutter reads `version: X.Y.Z+N` from pubspec.yaml and Gradle propagates it
# into the AAB via `flutter.versionCode` and `flutter.versionName` — so pubspec
# is the only file this script touches. (Unlike RN, there's no Info.plist or
# build.gradle to keep in sync.)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"

if [ ! -f "$PUBSPEC" ]; then
    echo "Error: pubspec.yaml not found at $PUBSPEC" >&2
    exit 1
fi

# Parse current "version: X.Y.Z+N" line.
CURRENT_LINE=$(grep -m1 '^version:' "$PUBSPEC" || true)
if [ -z "$CURRENT_LINE" ]; then
    echo "Error: no 'version:' line in $PUBSPEC" >&2
    exit 1
fi

CURRENT_VERSION=$(echo "$CURRENT_LINE" | sed -E 's/^version:[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+).*/\1/')
CURRENT_BUILD=$(echo "$CURRENT_LINE"   | sed -E 's/^version:[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+).*/\2/')

if ! [[ "$CURRENT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || ! [[ "$CURRENT_BUILD" =~ ^[0-9]+$ ]]; then
    echo "Error: could not parse '$CURRENT_LINE' as 'version: X.Y.Z+N'" >&2
    exit 1
fi

ARG="${1:-}"

if [ -z "$ARG" ]; then
    echo "Usage: $0 <version>            (e.g. 1.0.1)"
    echo "       $0 --build              (increment build number only)"
    echo "       $0 --current            (print current version, exit)"
    echo ""
    echo "Current: $CURRENT_VERSION+$CURRENT_BUILD"
    exit 1
fi

if [ "$ARG" = "--current" ]; then
    echo "$CURRENT_VERSION+$CURRENT_BUILD"
    exit 0
fi

if [ "$ARG" = "--build" ]; then
    NEW_VERSION="$CURRENT_VERSION"
else
    if ! [[ "$ARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: version must be X.Y.Z (semver). Got: $ARG" >&2
        exit 1
    fi
    NEW_VERSION="$ARG"
fi

NEW_BUILD=$((CURRENT_BUILD + 1))

# Guard against accidentally lowering the version (Play rejects lower versionCode,
# and a lower versionName is almost always a typo).
if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    LOWER=$(printf '%s\n%s\n' "$CURRENT_VERSION" "$NEW_VERSION" | sort -V | head -1)
    if [ "$LOWER" = "$NEW_VERSION" ] && [ "$LOWER" != "$CURRENT_VERSION" ]; then
        echo "Error: new version $NEW_VERSION is lower than current $CURRENT_VERSION. Refusing." >&2
        exit 1
    fi
fi

echo "Version: $CURRENT_VERSION → $NEW_VERSION"
echo "Build:   $CURRENT_BUILD → $NEW_BUILD"

# macOS BSD sed needs the empty '' after -i.
sed -i '' "s/^version:[[:space:]].*/version: $NEW_VERSION+$NEW_BUILD/" "$PUBSPEC"

echo "✓ Updated $PUBSPEC → version: $NEW_VERSION+$NEW_BUILD"
echo ""
echo "Next:"
echo "  flutter build appbundle --release"
echo "  # upload build/app/outputs/bundle/release/app-release.aab to Play Console"
