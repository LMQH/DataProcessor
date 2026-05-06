#Requires -Version 5.1
<#
.SYNOPSIS
  使用 PyInstaller 生成 convert_cli.exe，并复制到 Inno Setup 输入目录。
.PARAMETER CompileInstaller
  若本机已安装 Inno Setup 6，编译生成 dist\DataProcess_Setup.exe。
#>
param([switch]$CompileInstaller)

$ErrorActionPreference = "Stop"
$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Python = Join-Path $RootDir ".conda\python.exe"
if (-not (Test-Path -LiteralPath $Python)) {
    $Python = "python"
}

$Work = Join-Path $RootDir "build\pyinstaller-win"
$Dist = Join-Path $RootDir "build\python-backend-win"
$Staging = Join-Path $RootDir "installer\windows\staging"
$Spec = $Work
$Entry = Join-Path $RootDir "backend\convert_cli.py"

New-Item -ItemType Directory -Force -Path $Staging, $Work, $Dist | Out-Null

Push-Location $RootDir
try {
    & $Python -m pip install -q -r (Join-Path $RootDir "requirements-build.txt")
    & $Python -m PyInstaller `
        --clean --noconfirm --onefile `
        --name convert_cli `
        --distpath $Dist `
        --workpath $Work `
        --specpath $Spec `
        --hidden-import pypandoc `
        --hidden-import html2text `
        --hidden-import fitz `
        --hidden-import scripts.docx_to_md.docx_to_md_python_docx `
        --collect-data pypandoc `
        $Entry

    $BuiltExe = Join-Path $Dist "convert_cli.exe"
    if (-not (Test-Path -LiteralPath $BuiltExe)) {
        throw "未找到 PyInstaller 输出: $BuiltExe"
    }
    Copy-Item -LiteralPath $BuiltExe -Destination (Join-Path $Staging "convert_cli.exe") -Force
    Write-Host "已生成: $(Join-Path $Staging 'convert_cli.exe')"
}
finally {
    Pop-Location
}

if ($CompileInstaller) {
    $iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    if (-not (Test-Path -LiteralPath $iscc)) {
        throw "未找到 Inno Setup 6（ISCC.exe）。请安装后重试，或去掉 -CompileInstaller。"
    }
    $iss = Join-Path $RootDir "installer\windows\DataProcess.iss"
    & $iscc $iss
    Write-Host "安装包应在: $(Join-Path $RootDir 'dist')"
}
