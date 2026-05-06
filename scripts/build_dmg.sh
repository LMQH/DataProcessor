#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/macos_app/DataProcessApp"
PYTHON="$ROOT_DIR/.conda/bin/python3.12"
DERIVED_DATA="/tmp/DataProcessAppDerivedData"
DIST_DIR="$ROOT_DIR/dist"
PYINSTALLER_WORK="$ROOT_DIR/build/pyinstaller"
PYINSTALLER_DIST="$ROOT_DIR/build/python-backend"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Release/DataProcess.app"
BACKEND_DEST="$APP_BUNDLE/Contents/Resources/python-backend"
DMG_ROOT="$ROOT_DIR/build/dmg-root"
DMG_PATH="$DIST_DIR/DataProcess.dmg"

if [[ ! -x "$PYTHON" ]]; then
  echo "未找到 Python 运行环境: $PYTHON" >&2
  exit 1
fi

if ! "$PYTHON" -m PyInstaller --version >/dev/null 2>&1; then
  echo "未安装 PyInstaller。请先执行: $PYTHON -m pip install -r requirements-build.txt" >&2
  exit 1
fi

cd "$ROOT_DIR"

rm -rf "$PYINSTALLER_WORK" "$PYINSTALLER_DIST" "$DERIVED_DATA" "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DIST_DIR" "$PYINSTALLER_WORK" "$PYINSTALLER_DIST"
xattr -cr "$APP_DIR" "$ROOT_DIR/backend" "$ROOT_DIR/scripts" 2>/dev/null || true

"$PYTHON" -m PyInstaller \
  --clean \
  --noconfirm \
  --onefile \
  --name convert_cli \
  --distpath "$PYINSTALLER_DIST" \
  --workpath "$PYINSTALLER_WORK" \
  --specpath "$PYINSTALLER_WORK" \
  --hidden-import pypandoc \
  --hidden-import html2text \
  --hidden-import fitz \
  --hidden-import scripts.docx_to_md.docx_to_md_python_docx \
  --collect-data pypandoc \
  "$ROOT_DIR/backend/convert_cli.py"

COPYFILE_DISABLE=1 xcodebuild \
  -project "$APP_DIR/DataProcessApp.xcodeproj" \
  -scheme DataProcessApp \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  build

mkdir -p "$BACKEND_DEST"
cp "$PYINSTALLER_DIST/convert_cli" "$BACKEND_DEST/convert_cli"
chmod 755 "$BACKEND_DEST/convert_cli"

codesign --force --deep --sign - "$APP_BUNDLE"

mkdir -p "$DMG_ROOT"
cp -R "$APP_BUNDLE" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "DataProcess" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "已生成: $DMG_PATH"
