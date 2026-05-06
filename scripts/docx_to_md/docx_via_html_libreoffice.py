#!/usr/bin/env python3
"""配置中 docx_to_md.input_dir 下 .docx 经 LibreOffice 转为 HTML，再用 html2text 转为 Markdown 写入 output_dir。

需安装 LibreOffice；pip install html2text PyYAML。DOCX→HTML 使用显式过滤器 HTML (StarWriter)。
"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import html2text

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
    raise SystemExit(
        "未找到 LibreOffice（soffice），请先安装（例: brew install --cask libreoffice）"
    )


def _run(
    soffice: str,
    user_inst: str,
    convert_to: str,
    outdir: Path,
    src: Path,
    *,
    infilter: str | None = None,
) -> None:
    """convert_to 使用「扩展名:LibreOffice 过滤器名」；必要时指定 infilter（须为 --infilter=值 单参数）。"""
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


def _html_to_markdown(html_path: Path) -> str:
    raw = html_path.read_text(encoding="utf-8", errors="replace")
    conv = html2text.HTML2Text()
    conv.body_width = 0
    conv.unicode_snob = True
    return conv.handle(raw).strip() + "\n"


inp, out = docx_to_md_dirs()
out.mkdir(parents=True, exist_ok=True)
soffice = _soffice()

for p in sorted(inp.glob("*.docx")):
    dest = out / f"{p.stem}_via_html_libreoffice.md"
    try:
        with tempfile.TemporaryDirectory() as td:
            t = Path(td)
            prof = t / "lo1"
            prof.mkdir()
            hdir = t / "html"
            hdir.mkdir()
            _run(
                soffice,
                prof.resolve().as_uri(),
                "html:HTML (StarWriter)",
                hdir,
                p,
            )
            html = hdir / f"{p.stem}.html"
            if not html.is_file():
                hs = list(hdir.glob("*.html"))
                if len(hs) != 1:
                    raise RuntimeError(f"未找到唯一的 HTML（{hdir}）")
                html = hs[0]
            dest.write_text(_html_to_markdown(html), encoding="utf-8")
        print(f"完成: {p.name} → {dest}")
    except Exception as e:
        print(f"跳过: {p.name} ({e})")
