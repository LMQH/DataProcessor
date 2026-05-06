"""从 config/config.yaml 读取 docx↔markdown 的输入输出目录。"""
from __future__ import annotations

import sys
from pathlib import Path

import yaml

CONFIG_DIR = Path(__file__).resolve().parent
REPO_ROOT = CONFIG_DIR.parent
CONFIG_PATH = CONFIG_DIR / "config.yaml"


def resolve_under_repo(path_str: str | Path) -> Path:
    p = Path(path_str)
    return p if p.is_absolute() else REPO_ROOT / p


def _pair(section_key: str) -> tuple[Path, Path]:
    if not CONFIG_PATH.is_file():
        sys.exit(f"未找到配置文件: {CONFIG_PATH}")
    data = yaml.safe_load(CONFIG_PATH.read_text(encoding="utf-8")) or {}
    section = data.get(section_key) or {}
    ind = section.get("input_dir")
    outd = section.get("output_dir")
    if not ind or not outd:
        sys.exit(
            f"config.yaml 需在 {section_key} 下提供 input_dir 与 output_dir（相对项目根或绝对路径）。"
        )
    return resolve_under_repo(ind), resolve_under_repo(outd)


def docx_to_md_dirs() -> tuple[Path, Path]:
    """DOCX → Markdown：默认 input/docx、output/markdown。"""
    return _pair("docx_to_md")


def md_to_docx_dirs() -> tuple[Path, Path]:
    """Markdown → DOCX：默认 input/markdown、output/docx。"""
    return _pair("md_to_docx")
