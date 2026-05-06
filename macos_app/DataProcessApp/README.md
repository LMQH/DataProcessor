# DataProcessApp

SwiftUI macOS development app for the local document conversion backend.

## Run in Xcode

1. Open `DataProcessApp.xcodeproj` in Xcode.
2. Select the `DataProcessApp` scheme.
3. Use `My Mac` as the run destination.
4. Run the app.

The development app calls the Python backend in the project root:

```text
.conda/bin/python3.12 backend/convert_cli.py
```

## Command-line Checks

From this directory:

```bash
swift build
xcodebuild -project DataProcessApp.xcodeproj \
  -scheme DataProcessApp \
  -destination 'platform=macOS' \
  build
```

To produce a Release `.app` in a known temporary location:

```bash
xcodebuild -project DataProcessApp.xcodeproj \
  -scheme DataProcessApp \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/DataProcessAppDerivedData \
  build
```

The generated app will be:

```text
/tmp/DataProcessAppDerivedData/Build/Products/Release/DataProcess.app
```

From the project root:

```bash
.conda/bin/python3.12 backend/convert_cli.py \
  --mode docx-to-md \
  --engine mammoth \
  --input input/docx/核价流程自动化方案.docx \
  --output /tmp/data_process_check.md
```

## DOCX→Markdown engines (`--engine`)

For `docx-to-md`, the app passes `--engine` (default `mammoth`):

- `mammoth` — no LibreOffice required.
- `python-docx` — paragraph/style oriented extraction.
- `pandoc` — requires pandoc (bundled PyInstaller build collects `pypandoc` data files).
- `libreoffice-html`, `libreoffice-pdf` — require a local LibreOffice install (`soffice`).

Example:

```bash
.conda/bin/python3.12 backend/convert_cli.py \
  --mode docx-to-md \
  --engine pandoc \
  --input input/docx/核价流程自动化方案.docx \
  --output /tmp/data_process_check.md
```

## Current Packaging Limit

The app first looks for a bundled backend at:

```text
DataProcess.app/Contents/Resources/python-backend/convert_cli
```

If the bundled backend is not present, it falls back to the project development
backend:

```text
.conda/bin/python3.12 backend/convert_cli.py
```

## DMG Build

From the project root:

```bash
.conda/bin/python3.12 -m pip install -r requirements-build.txt
./scripts/build_dmg.sh
```

The generated installer image will be:

```text
dist/DataProcess.dmg
```

This build does not enable App Sandbox. It uses ad-hoc signing for local install
and testing, not Developer ID notarization.
