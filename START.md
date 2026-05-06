# 快速开始（macOS）：环境 → 打包 DMG → 安装应用

本文只覆盖：**从零准备本机环境**、**打出 `DataProcess.dmg`**、**安装并首次打开应用**。更完整的项目说明见根目录 [README_zh.md](README_zh.md)。

**若不想折腾环境与打包**：根据已有安装包（例如项目里已生成好的 `dist/DataProcess.dmg`），在 Finder 中**双击打开该 DMG**，将 **`DataProcess.app` 拖入「应用程序」** 即可完成安装，随后从启动台或「应用程序」中打开即可使用。下文从「一」起，是需要自己配环境、重新打 DMG 的步骤，适合开发者去折腾。

---

## 一、前置条件

1. **macOS**（与 Xcode 支持的版本一致即可）。
2. **Xcode**（需能编译 SwiftUI 工程；仅装 Command Line Tools 往往不够，请从 App Store 或开发者网站安装完整 Xcode，并至少打开过一次以完成许可与组件安装）。
3. **项目代码**已解压或克隆到本机，下文记为「项目根目录」。

---

## 二、准备 Python 运行环境

打包脚本 `scripts/build_dmg.sh` 默认使用项目根目录下的解释器：

```text
<项目根目录>/.conda/bin/python3.12
```

请任选一种方式对齐该路径（二选一即可）。

### 方式 A：在项目根目录建 Miniconda/Mambaforge 环境（与脚本默认一致）

在**项目根目录**执行（若已安装 `conda`）：

```bash
cd /path/to/data_process
conda create -y -p ./.conda python=3.12
conda run -p ./.conda python -m pip install -U pip
conda run -p ./.conda python -m pip install -r requirements.txt
conda run -p ./.conda python -m pip install -r requirements-build.txt
```

完成后应存在可执行文件：`.conda/bin/python3.12`，且已安装 **运行依赖**（`requirements.txt`）与 **构建依赖**（`requirements-build.txt`，含 PyInstaller）。

### 方式 B：使用已有 Python 3.12

若你使用其他位置的 `python3.12`（例如 Homebrew、`pyenv`），请**编辑** `scripts/build_dmg.sh`，将第 6 行左右的：

```bash
PYTHON="$ROOT_DIR/.conda/bin/python3.12"
```

改为你本机的解释器绝对路径，例如：

```bash
PYTHON="/opt/homebrew/bin/python3.12"
```

然后在项目根目录用该解释器安装依赖：

```bash
cd /path/to/data_process
/path/to/python3.12 -m pip install -r requirements.txt
/path/to/python3.12 -m pip install -r requirements-build.txt
```

---

## 三、打包 DMG

1. 确认 **Xcode** 已就绪（见第一节）。
2. 在终端进入项目根目录：

```bash
cd /path/to/data_process
```

3. 执行打包脚本：

```bash
chmod +x scripts/build_dmg.sh   # 仅需执行一次
./scripts/build_dmg.sh
```

脚本会依次：**用 PyInstaller 打包 `backend/convert_cli.py`** → **Release 编译 `DataProcess.app`** → **把 `convert_cli` 拷入应用包的 `Resources/python-backend/`** → **临时签名** → **生成 DMG**。

成功时终端末尾会提示类似：`已生成: .../dist/DataProcess.dmg`。

若报错「未找到 Python 运行环境」，说明 `PYTHON` 路径不对，请回到第二节检查或修改 `build_dmg.sh`。

若报错「未安装 PyInstaller」，请对**当前脚本所用的同一个 Python** 执行：

```bash
<你的PYTHON路径> -m pip install -r requirements-build.txt
```

---

## 四、安装应用

1. 在 Finder 中打开 **`dist/DataProcess.dmg`**（或在终端执行 `open dist/DataProcess.dmg`）。
2. 将窗口中的 **`DataProcess.app`** 拖入 **`Applications`**（或磁盘映像里提供的「应用程序」快捷方式）。
3. 推出磁盘映像。
4. 在「应用程序」中双击 **`DataProcess`** 启动。

### 首次打开被系统拦截时

当前构建为**临时签名**（非 Developer ID 公证），首次运行可能被 Gatekeeper 拦截：

- 可尝试：**系统设置 → 隐私与安全性** 中允许本次运行；或  
- 对 `DataProcess.app` **右键 → 打开**，在提示中选择打开。

具体文案因 macOS 版本略有差异。

---

## 五、简要对照表

| 步骤 | 你要做的事 |
|------|------------|
| 环境 | 让 `build_dmg.sh` 里的 `PYTHON` 指向带 `requirements.txt` + `requirements-build.txt` 的 Python 3.12 |
| 打包 | 在项目根目录执行 `./scripts/build_dmg.sh` |
| 产物 | `dist/DataProcess.dmg` |
| 安装 | 打开 DMG，将 `DataProcess.app` 拖到「应用程序」 |

开发阶段不打包、仅用 Xcode 跑应用时，请参考 `macos_app/DataProcessApp/README_zh.md`。
