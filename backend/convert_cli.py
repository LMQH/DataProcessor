#!/usr/bin/env python3
"""Single-file conversion CLI for the macOS development app."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

_REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_REPO))

from backend.docx_to_md_engines import ENGINE_FUNCS
from scripts.md_to_docx.md_to_docx_python_docx import markdown_to_docx


def convert_docx_to_md(input_path: Path, output_path: Path, engine: str) -> Path:
    fn = ENGINE_FUNCS.get(engine)
    if fn is None:
        raise ValueError(f"不支持的引擎: {engine}")
    return fn(input_path, output_path)


def convert_md_to_docx(input_path: Path, output_path: Path) -> Path:
    text = input_path.read_text(encoding="utf-8")
    doc = markdown_to_docx(text)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    doc.save(output_path)
    return output_path.resolve()


def _validate(args: argparse.Namespace) -> tuple[str, Path, Path]:
    mode = args.mode
    input_path = Path(args.input).expanduser()
    output_path = Path(args.output).expanduser()

    if not input_path.is_file():
        raise ValueError(f"输入文件不存在: {input_path}")

    if mode == "docx-to-md":
        if input_path.suffix.lower() != ".docx":
            raise ValueError("docx-to-md 模式要求输入文件为 .docx")
        if output_path.suffix.lower() != ".md":
            raise ValueError("docx-to-md 模式要求输出文件为 .md")
    elif mode == "md-to-docx":
        if input_path.suffix.lower() != ".md":
            raise ValueError("md-to-docx 模式要求输入文件为 .md")
        if output_path.suffix.lower() != ".docx":
            raise ValueError("md-to-docx 模式要求输出文件为 .docx")
    else:
        raise ValueError(f"不支持的转换模式: {mode}")

    return mode, input_path, output_path


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert one DOCX/Markdown file.")
    parser.add_argument("--mode", required=True, choices=("docx-to-md", "md-to-docx"))
    parser.add_argument(
        "--engine",
        default="mammoth",
        choices=tuple(ENGINE_FUNCS.keys()),
        help="DOCX→Markdown 转换引擎（仅 docx-to-md 生效）。",
    )
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    try:
        mode, input_path, output_path = _validate(args)
        if mode == "docx-to-md":
            converted = convert_docx_to_md(input_path, output_path, args.engine)
        else:
            converted = convert_md_to_docx(input_path, output_path)
        print(json.dumps({"ok": True, "output": str(converted)}, ensure_ascii=False))
        return 0
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
