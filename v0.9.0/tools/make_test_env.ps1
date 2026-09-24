# 搭建免提权的设置界面测试环境：
# 复制 <版本目录> 根目录中设置程序需要的文件到 %TEMP%\dbime-test\，
# 子目录用 junction 链接，从而可以用被改过的 DoubaoIme.Settings.UI.dll 直接启动设置窗口做视觉验证。
param(
  [string]$VersionDir = "C:\Program Files\DoubaoIME\versions\v0.9.0.0",
  [string]$TestDir    = "$env:TEMP\dbime-test"
)
$ErrorActionPreference = "Stop"

if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null

# 设置程序实际需要的最小文件集合（其余大文件如 ImeService/onnxruntime 不需要）
$need = @(
  "DoubaoImeSettings.exe", "DoubaoImeSettings.exe.config",
  "DoubaoIme.Settings.UI.dll", "DoubaoIme.Settings.NativeRuntime.dll", "DoubaoIme.Settings.ViewModels.dll",
  "QRCoder.dll", "Dbghelp.dll", "applogrs.dll", "oime-config.dll", "rpc.dll", "parfait.dll",
  "parfait_wer.dll", "parfait_crash_handler.exe", "version.dat", "build_channel.txt"
)
$copied = 0; $missing = @()
foreach ($f in $need) {
  $s = Join-Path $VersionDir $f
  if (Test-Path $s) { Copy-Item $s (Join-Path $TestDir $f) -Force; $copied++ } else { $missing += $f }
}
Get-ChildItem $VersionDir -Filter "SharpVectors*.dll" -File | ForEach-Object {
  Copy-Item $_.FullName (Join-Path $TestDir $_.Name) -Force; $copied++
}
foreach ($d in @("files", "Assets", "x86")) {
  $s = Join-Path $VersionDir $d
  if (Test-Path $s) {
    try { New-Item -ItemType Junction -Path (Join-Path $TestDir $d) -Target $s | Out-Null }
    catch { Write-Host ("子目录链接失败: " + $d) }
  }
}
Write-Host ("测试环境: " + $TestDir + "  复制 " + $copied + " 个文件")
if ($missing.Count) { Write-Host ("缺失: " + ($missing -join ", ")) }
Write-Host ("启动: " + (Join-Path $TestDir "DoubaoImeSettings.exe"))
