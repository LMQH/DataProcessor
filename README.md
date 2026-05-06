# Data Process

Local tooling to convert **Word (`.docx`)** and **Markdown (`.md`)** in both directions: batch jobs driven by `config/config.yaml`, a single-file CLI for scripting and the macOS app, and an optional SwiftUI desktop wrapper with DMG packaging.

## Features

- **DOCX → Markdown** via several backends (pick the one that fits your documents):
  - `mammoth` — pure Python, no LibreOffice
  - `python-docx` — paragraph/style-oriented extraction
  - `pandoc` — needs a Pandoc binary (`pypandoc-binary` or system install)
  - `libreoffice-html` / `libreoffice-pdf` — need [LibreOffice](https://www.libreoffice.org/) (`soffice`)
- **Markdown → DOCX** using `python-docx`, with basic inline markup (bold, italic, inline code) and heading/list support (see `scripts/md_to_docx/md_to_docx_python_docx.py` for details).
- **Batch mode**: drop files into configured folders and run the corresponding script under `scripts/`.
- **macOS app** (`macos_app/DataProcessApp/`): SwiftUI UI that shells out to the Python CLI; optional **DMG** build bundles a PyInstaller binary of `convert_cli`. See [macos_app/DataProcessApp/README.md](macos_app/DataProcessApp/README.md).

## Requirements

- **Python 3.10+** (3.12 is used in the reference dev setup).
- Install runtime dependencies from the repository root:

```bash
python3 -m pip install -r requirements.txt
```

Optional system tools:

- **Pandoc** — for `--engine pandoc`.
- **LibreOffice** — for `--engine libreoffice-html` or `libreoffice-pdf` (e.g. macOS: `brew install --cask libreoffice`).

## Configuration

Edit `config/config.yaml` to set batch input/output directories (paths are relative to the repo root unless absolute):

```yaml
docx_to_md:
  input_dir: data_input/docx
  output_dir: data_output/markdown

md_to_docx:
  input_dir: data_input/markdown
  output_dir: data_output/docx
```

`config/paths.py` loads these values for the batch scripts.

## Single-file CLI

From the repository root (so `backend` and `scripts` resolve correctly):

```bash
python3 backend/convert_cli.py \
  --mode docx-to-md \
  --engine mammoth \
  --input path/to/file.docx \
  --output path/to/out.md
```

```bash
python3 backend/convert_cli.py \
  --mode md-to-docx \
  --input path/to/file.md \
  --output path/to/out.docx
```

`--engine` applies only to `docx-to-md`. Valid engines: `mammoth`, `python-docx`, `pandoc`, `libreoffice-html`, `libreoffice-pdf` (see `backend/docx_to_md_engines.py`).

On success the CLI prints a small JSON line to stdout; errors go to stderr with a non-zero exit code.

## Batch scripts

After updating `config/config.yaml`, run a script from the repo root, for example:

```bash
python3 scripts/docx_to_md/docx_to_md_mammoth.py
python3 scripts/md_to_docx/md_to_docx_python_docx.py
```

Other DOCX→MD variants live under `scripts/docx_to_md/` (LibreOffice, Pandoc, `python-docx`, etc.) and follow the same config-driven directories.

## macOS DMG (optional)

Requires PyInstaller and Xcode command-line tooling. From the repo root:

```bash
python3 -m pip install -r requirements-build.txt
./scripts/build_dmg.sh
```

The default script expects a Python interpreter at `.conda/bin/python3.12`; adjust `PYTHON` in `scripts/build_dmg.sh` if your layout differs. Output: `dist/DataProcess.dmg`. The build uses ad-hoc signing for local testing, not Developer ID notarization.

## Repository layout

| Path | Role |
|------|------|
| `backend/convert_cli.py` | Single-file conversion CLI (used by the macOS app) |
| `backend/docx_to_md_engines.py` | Engine registry for DOCX→Markdown |
| `config/` | `config.yaml` + path helpers |
| `scripts/docx_to_md/` | Batch DOCX→Markdown scripts |
| `scripts/md_to_docx/` | Batch Markdown→DOCX |
| `scripts/build_dmg.sh` | App + PyInstaller + DMG pipeline |
| `macos_app/DataProcessApp/` | SwiftUI Xcode project |

## License

If the repository does not include a `LICENSE` file, treat usage as internal or add a license as appropriate for your organization.
