#!/usr/bin/env python3
"""将配置中 docx_to_md.input_dir 下所有 .docx 转为 Markdown 写入 output_dir（见 config/config.yaml）。

依赖 pypandoc、PyYAML。需能找到 pandoc 可执行文件：可 pip install pypandoc-binary（常见 macOS/Windows），
或自行安装 pandoc（brew / conda-forge）并保证在 PATH 中。
"""
import sys
from pathlib import Path

_REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(_REPO))
from config.paths import docx_to_md_dirs

try:
    import pypandoc
except ImportError:
    sys.exit("未安装 pypandoc，请执行: pip install pypandoc")

try:
    pypandoc.get_pandoc_path()
except OSError:
    sys.exit(
        "未找到 pandoc 可执行文件。\n"
        "请任选其一: pip install pypandoc-binary；或 brew install pandoc；"
        "或 conda install -c conda-forge pandoc"
    )

inp, out = docx_to_md_dirs()
out.mkdir(parents=True, exist_ok=True)
for p in sorted(inp.glob("*.docx")):
    dest = out / f"{p.stem}_pypandoc.md"
    try:
        pypandoc.convert_file(
            str(p),
            to="markdown",
            format="docx",
            outputfile=str(dest),
        )
        print(f"完成: {p.name} → {dest}")
    except Exception as e:
        print(f"跳过: {p.name} ({e})")
