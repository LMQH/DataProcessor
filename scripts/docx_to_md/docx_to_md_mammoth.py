#!/usr/bin/env python3
"""将配置中 docx_to_md.input_dir 下所有 .docx 转为 Markdown 写入 output_dir（见 config/config.yaml）。
依赖: pip install mammoth PyYAML
"""
import sys
from pathlib import Path

import mammoth

_REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(_REPO))
from config.paths import docx_to_md_dirs

inp, out = docx_to_md_dirs()
out.mkdir(parents=True, exist_ok=True)
for p in sorted(inp.glob("*.docx")):
    dest = out / f"{p.stem}_mammoth.md"
    try:
        with p.open("rb") as f:
            r = mammoth.convert_to_markdown(f)
        dest.write_text(r.value, encoding="utf-8")
        print(f"完成: {p.name} → {dest}")
    except Exception as e:
        print(f"跳过: {p.name} ({e})")
