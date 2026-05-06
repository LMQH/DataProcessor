# Data Process（文档转换）

在本地将 **Word（`.docx`）** 与 **Markdown（`.md`）** 互转：支持按 `config/config.yaml` 配置的批量目录处理、供脚本与 macOS 应用调用的单文件命令行，以及可选的 SwiftUI 桌面端与 DMG 安装包。

## 功能概览

- **DOCX → Markdown**：多种引擎，可按文档特点选择（见 `backend/docx_to_md_engines.py`）：
  - `mammoth` — 纯 Python，无需 LibreOffice
  - `python-docx` — 偏段落与样式结构的抽取
  - `pandoc` — 需本机 Pandoc（`pypandoc-binary` 或自行安装）
  - `libreoffice-html` / `libreoffice-pdf` — 需安装 [LibreOffice](https://www.libreoffice.org/)（`soffice`）
- **Markdown → DOCX**：基于 `python-docx`，支持常见行内格式（粗体、斜体、行内代码）及标题、列表等（细节见 `scripts/md_to_docx/md_to_docx_python_docx.py`）。
- **批量模式**：把文件放入配置好的输入目录，在仓库根目录执行对应 `scripts/` 下的脚本即可。
- **macOS 应用**（`macos_app/DataProcessApp/`）：SwiftUI 界面，通过调用 Python CLI 完成转换；可选 **DMG** 构建会将 `convert_cli` 打成 PyInstaller 单文件并打进应用包。详见 [macos_app/DataProcessApp/README_zh.md](macos_app/DataProcessApp/README_zh.md)。

## 环境依赖

- **Python 3.10+**（参考开发环境使用 3.12）。
- 在**项目根目录**安装运行依赖：

```bash
python3 -m pip install -r requirements.txt
```

可选系统组件：

- **Pandoc** — 使用 `--engine pandoc` 时需要。
- **LibreOffice** — 使用 `libreoffice-html` / `libreoffice-pdf` 时需要（macOS 示例：`brew install --cask libreoffice`）。

## 配置

编辑 `config/config.yaml`，设置批量任务的输入、输出目录（相对项目根目录，也可写绝对路径）：

```yaml
docx_to_md:
  input_dir: data_input/docx
  output_dir: data_output/markdown

md_to_docx:
  input_dir: data_input/markdown
  output_dir: data_output/docx
```

`config/paths.py` 会读取上述配置，供各批量脚本使用。

## 单文件命令行（CLI）

在**项目根目录**执行（保证 `backend`、`scripts` 等包路径正确）：

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

`--engine` 仅在 `docx-to-md` 模式下有效。可选值：`mammoth`、`python-docx`、`pandoc`、`libreoffice-html`、`libreoffice-pdf`。

成功时 CLI 会在标准输出打印一行 JSON；失败时向标准错误输出信息并以非零退出码结束。

## 批量脚本

修改好 `config/config.yaml` 后，在仓库根目录运行，例如：

```bash
python3 scripts/docx_to_md/docx_to_md_mammoth.py
python3 scripts/md_to_docx/md_to_docx_python_docx.py
```

其他 DOCX→MD 变体位于 `scripts/docx_to_md/`（LibreOffice、Pandoc、`python-docx` 等），同样读取配置中的目录。

## macOS DMG 构建（可选）

需要已安装 PyInstaller 与 Xcode 命令行环境。在项目根目录：

```bash
python3 -m pip install -r requirements-build.txt
./scripts/build_dmg.sh
```

默认 `build_dmg.sh` 使用 `.conda/bin/python3.12` 作为解释器路径；若你的环境不同，请修改脚本中的 `PYTHON` 变量。产物路径：`dist/DataProcess.dmg`。当前流程为**临时签名**，便于本机安装测试，**非** Developer ID 公证分发流程。

## 仓库结构

| 路径 | 说明 |
|------|------|
| `backend/convert_cli.py` | 单文件转换 CLI（macOS 应用调用） |
| `backend/docx_to_md_engines.py` | DOCX→Markdown 引擎注册表 |
| `config/` | `config.yaml` 与路径解析 |
| `scripts/docx_to_md/` | 批量 DOCX→Markdown |
| `scripts/md_to_docx/` | 批量 Markdown→DOCX |
| `scripts/build_dmg.sh` | 应用构建 + PyInstaller + DMG |
| `macos_app/DataProcessApp/` | SwiftUI Xcode 工程 |

## 许可

若仓库中未包含 `LICENSE` 文件，请按团队约定使用或自行补充许可条款。
