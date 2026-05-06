# DataProcessApp

这是一个 SwiftUI macOS 开发版应用，用于调用本地文档转换 Python 后端。

## 在 Xcode 中运行

1. 使用 Xcode 打开 `DataProcessApp.xcodeproj`。
2. 选择 `DataProcessApp` scheme。
3. 运行目标选择 `My Mac`。
4. 运行应用。

开发版应用会调用项目根目录下的 Python 后端：

```text
.conda/bin/python3.12 backend/convert_cli.py
```

## 命令行检查

在当前目录执行：

```bash
swift build
xcodebuild -project DataProcessApp.xcodeproj \
  -scheme DataProcessApp \
  -destination 'platform=macOS' \
  build
```

如果需要在固定临时目录生成 Release `.app`：

```bash
xcodebuild -project DataProcessApp.xcodeproj \
  -scheme DataProcessApp \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/DataProcessAppDerivedData \
  build
```

生成的应用路径为：

```text
/tmp/DataProcessAppDerivedData/Build/Products/Release/DataProcess.app
```

在项目根目录执行 Python 后端检查：

```bash
.conda/bin/python3.12 backend/convert_cli.py \
  --mode docx-to-md \
  --engine mammoth \
  --input input/docx/核价流程自动化方案.docx \
  --output /tmp/data_process_check.md
```

## DOCX→Markdown 转换方法（`--engine`）

主界面在「DOCX -> Markdown」下可通过「转换方法」选择引擎；命令行对应 `--engine`：

- `mammoth`（默认）：不依赖 LibreOffice。
- `python-docx`：按段落与样式解析。
- `pandoc`：依赖 pandoc（仓库使用 `pypandoc` / `pypandoc-binary`；DMG 内置后端已通过 PyInstaller 收集 pandoc 数据）。
- `libreoffice-html`、`libreoffice-pdf`：需本机安装 LibreOffice（`soffice`）。

示例（任选其一 `--engine`）：

```bash
.conda/bin/python3.12 backend/convert_cli.py \
  --mode docx-to-md \
  --engine pandoc \
  --input input/docx/核价流程自动化方案.docx \
  --output /tmp/data_process_check.md
```

## 当前打包行为

应用会优先查找内置后端：

```text
DataProcess.app/Contents/Resources/python-backend/convert_cli
```

如果没有找到内置后端，则回退到项目开发后端：

```text
.conda/bin/python3.12 backend/convert_cli.py
```

## 构建 DMG

在项目根目录执行：

```bash
.conda/bin/python3.12 -m pip install -r requirements-build.txt
./scripts/build_dmg.sh
```

生成的安装镜像路径为：

```text
dist/DataProcess.dmg
```

当前构建不启用 App Sandbox。它使用 ad-hoc 签名，适合本机安装和测试，不是 Developer ID 公证版本。

## LibreOffice（macOS）

首次打开应用时会检测本机是否已安装 LibreOffice（`/Applications` 与 `~/Applications` 下的 `LibreOffice.app`）。若未检测到，会提示并可一键打开官网下载页。DMG 本身不包含静默安装步骤；与 Windows Inno 安装后的行为对齐的是「首次启动时的检测与引导」。

主界面中 Mammoth / python-docx / Pandoc 不依赖 LibreOffice；选择 LibreOffice→HTML / LibreOffice→PDF 时需本机安装 LibreOffice。仓库内 `scripts/docx_to_md/` 等批处理脚本同样可能依赖 LibreOffice 或配置目录。

## Windows 打包与安装程序

在 Windows 上，于仓库根目录打开 PowerShell：

1. 安装 [Inno Setup 6](https://jrsoftware.org/isinfo.php)（若需要编译 `.iss` 安装包）。
2. 安装与仓库中 `requirements-build.txt` 兼容的 Python（或使用仓库内 `.conda`，与 macOS 一致）。
3. 仅生成 `convert_cli.exe` 并复制到 Inno 输入目录：

   ```powershell
   .\scripts\build_windows.ps1
   ```

4. 同时编译安装包（需已安装 Inno Setup 6）：

   ```powershell
   .\scripts\build_windows.ps1 -CompileInstaller
   ```

安装程序脚本位于 `installer/windows/DataProcess.iss`，产物输出到 `dist\DataProcess_Setup.exe`（与 `.gitignore` 中的 `dist/` 一致）。

安装结束时若系统未检测到 LibreOffice（标准安装路径或 `PATH` 中的 `soffice.exe`），会由 `installer/windows/ensure_libreoffice.ps1` 从 TDF 下载固定版本的 MSI 并静默安装到系统默认位置。升级 LibreOffice 版本时请编辑该脚本顶部的版本号与说明中的镜像说明。
