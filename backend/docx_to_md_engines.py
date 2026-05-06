"""Single-file DOCX→Markdown engines for convert_cli."""
from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

import mammoth


def convert_mammoth(input_path: Path, output_path: Path) -> Path:
    with input_path.open("rb") as f:
        result = mammoth.convert_to_markdown(f)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(result.value, encoding="utf-8")
    return output_path.resolve()


def convert_python_docx(input_path: Path, output_path: Path) -> Path:
    from scripts.docx_to_md.docx_to_md_python_docx import docx_to_markdown

    body = docx_to_markdown(input_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(body, encoding="utf-8")
    return output_path.resolve()


def convert_pandoc(input_path: Path, output_path: Path) -> Path:
    import pypandoc

    try:
        pypandoc.get_pandoc_path()
    except OSError as exc:
        raise RuntimeError(
            "未找到 pandoc 可执行文件。请安装 pypandoc-binary 或系统 pandoc。"
        ) from exc
    output_path.parent.mkdir(parents=True, exist_ok=True)
    pypandoc.convert_file(
        str(input_path),
        to="markdown",
        format="docx",
        outputfile=str(output_path),
    )
    return output_path.resolve()


def _soffice() -> str:
    home = Path.home()
    for c in (
        "/Applications/LibreOffice.app/Contents/MacOS/soffice",
        str(home / "Applications/LibreOffice.app/Contents/MacOS/soffice"),
        shutil.which("soffice"),
        shutil.which("libreoffice"),
    ):
        if c and Path(c).is_file():
            return c
    raise RuntimeError(
        "未找到 LibreOffice（soffice）。请先安装 LibreOffice（例: brew install --cask libreoffice）。"
    )


def _run_soffice(
    soffice: str,
    user_inst: str,
    convert_to: str,
    outdir: Path,
    src: Path,
    *,
    infilter: str | None = None,
) -> None:
    cmd: list[str] = [
        soffice,
        f"-env:UserInstallation={user_inst}",
        "--headless",
        "--norestore",
        "--nologo",
    ]
    if infilter:
        cmd.append(f"--infilter={infilter}")
    cmd.extend(
        [
            "--convert-to",
            convert_to,
            "--outdir",
            str(outdir),
            str(src),
        ]
    )
    subprocess.run(cmd, check=True)


def convert_libreoffice_html(input_path: Path, output_path: Path) -> Path:
    import html2text

    soffice = _soffice()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        prof = t / "lo1"
        prof.mkdir()
        hdir = t / "html"
        hdir.mkdir()
        _run_soffice(
            soffice,
            prof.resolve().as_uri(),
            "html:HTML (StarWriter)",
            hdir,
            input_path,
        )
        html = hdir / f"{input_path.stem}.html"
        if not html.is_file():
            hs = list(hdir.glob("*.html"))
            if len(hs) != 1:
                raise RuntimeError(f"未找到唯一的 HTML（{hdir}）")
            html = hs[0]
        raw = html.read_text(encoding="utf-8", errors="replace")
        conv = html2text.HTML2Text()
        conv.body_width = 0
        conv.unicode_snob = True
        md = conv.handle(raw).strip() + "\n"
        output_path.write_text(md, encoding="utf-8")
    return output_path.resolve()


def convert_libreoffice_pdf(input_path: Path, output_path: Path) -> Path:
    import fitz

    soffice = _soffice()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        prof = t / "lo"
        prof.mkdir()
        pdf_dir = t / "pdf"
        pdf_dir.mkdir()
        _run_soffice(soffice, prof.resolve().as_uri(), "pdf", pdf_dir, input_path)
        pdf = pdf_dir / f"{input_path.stem}.pdf"
        if not pdf.is_file():
            pdfs = list(pdf_dir.glob("*.pdf"))
            if len(pdfs) != 1:
                raise RuntimeError(f"未找到唯一的 PDF（{pdf_dir}）")
            pdf = pdfs[0]
        doc = fitz.open(pdf)
        try:
            parts: list[str] = []
            for i, page in enumerate(doc):
                body = page.get_text("text", sort=True).strip()
                parts.append(
                    f"## Page {i + 1}\n\n{body}" if body else f"## Page {i + 1}\n\n"
                )
            text = "\n\n".join(parts).rstrip() + "\n"
        finally:
            doc.close()
        output_path.write_text(text, encoding="utf-8")
    return output_path.resolve()


ENGINE_FUNCS = {
    "mammoth": convert_mammoth,
    "python-docx": convert_python_docx,
    "pandoc": convert_pandoc,
    "libreoffice-html": convert_libreoffice_html,
    "libreoffice-pdf": convert_libreoffice_pdf,
}
