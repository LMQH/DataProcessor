#!/usr/bin/env python3
"""配置中 docx_to_md.input_dir 下 .docx 经 LibreOffice 转 PDF，再用 PyMuPDF 按页抽取文本写入 output_dir（每页 ## Page N 标题；版式会扁平化）。需 LibreOffice 与 pip install pymupdf PyYAML。"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import fitz

_REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(_REPO))
from config.paths import docx_to_md_dirs


def _soffice() -> str:
    for c in (
        "/Applications/LibreOffice.app/Contents/MacOS/soffice",
        shutil.which("soffice"),
        shutil.which("libreoffice"),
    ):
        if c and Path(c).is_file():
            return c
    sys.exit("未找到 LibreOffice（soffice），请先安装（例: brew install --cask libreoffice）")


def _run(soffice: str, user_inst: str, convert_to: str, outdir: Path, src: Path) -> None:
    subprocess.run(
        [
            soffice,
            f"-env:UserInstallation={user_inst}",
            "--headless",
            "--norestore",
            "--nologo",
            "--convert-to",
            convert_to,
            "--outdir",
            str(outdir),
            str(src),
        ],
        check=True,
    )


def _pdf_to_markdown(pdf_path: Path) -> str:
    doc = fitz.open(pdf_path)
    try:
        parts: list[str] = []
        for i, page in enumerate(doc):
            body = page.get_text("text", sort=True).strip()
            parts.append(f"## Page {i + 1}\n\n{body}" if body else f"## Page {i + 1}\n\n")
        return "\n\n".join(parts).rstrip() + "\n"
    finally:
        doc.close()


inp, out = docx_to_md_dirs()
out.mkdir(parents=True, exist_ok=True)
soffice = _soffice()

for p in sorted(inp.glob("*.docx")):
    dest = out / f"{p.stem}_libreoffice_pymupdf.md"
    try:
        with tempfile.TemporaryDirectory() as td:
            t = Path(td)
            prof = t / "lo"
            prof.mkdir()
            pdf_dir = t / "pdf"
            pdf_dir.mkdir()
            _run(soffice, prof.resolve().as_uri(), "pdf", pdf_dir, p)
            pdf = pdf_dir / f"{p.stem}.pdf"
            if not pdf.is_file():
                pdfs = list(pdf_dir.glob("*.pdf"))
                if len(pdfs) != 1:
                    raise RuntimeError(f"未找到唯一的 PDF（{pdf_dir}）")
                pdf = pdfs[0]
            dest.write_text(_pdf_to_markdown(pdf), encoding="utf-8")
        print(f"完成: {p.name} → {dest}")
    except Exception as e:
        print(f"跳过: {p.name} ({e})")
