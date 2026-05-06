#Requires -Version 5.1
<#
  安装后检测：若系统已有 LibreOffice（soffice），则退出 0；
  否则从 TDF 下载 MSI 并静默安装。版本升级时请更新下面两常量。
#>
$ErrorActionPreference = "Stop"

# 若链接 404，请到 https://download.documentfoundation.org/libreoffice/stable/ 核对路径后更新。
$LoVersion = "26.2.2"
$LoMsiUrl = "https://download.documentfoundation.org/libreoffice/stable/$LoVersion/win/x86_64/LibreOffice_${LoVersion}_Win_x86-64.msi"

function Test-SofficePath([string]$Path) {
    return (Test-Path -LiteralPath $Path -PathType Leaf)
}

$candidates = @(
    (Join-Path ${env:ProgramFiles} "LibreOffice\program\soffice.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "LibreOffice\program\soffice.exe")
)
foreach ($p in $candidates) {
    if (Test-SofficePath $p) { exit 0 }
}

$cmd = Get-Command soffice.exe -ErrorAction SilentlyContinue
if ($cmd -and (Test-SofficePath $cmd.Source)) { exit 0 }

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) "LibreOffice_$LoVersion_Win_x86-64.msi"
Write-Host "正在下载 LibreOffice $LoVersion ..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $LoMsiUrl -OutFile $tmp -UseBasicParsing

Write-Host "正在静默安装 LibreOffice（可能需要数分钟）..."
$p = Start-Process -FilePath "msiexec.exe" -ArgumentList @("/i", "`"$tmp`"", "/qn", "/norestart") -Wait -PassThru
if ($p.ExitCode -notin 0, 3010) {
    Write-Error "msiexec 退出码: $($p.ExitCode)"
    exit 1
}

Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
exit 0
