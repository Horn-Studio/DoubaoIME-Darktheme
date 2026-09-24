# 迭代验证：把待测 DLL 放进测试环境 -> 重启测试设置窗口 -> 截图
param(
  [Parameter(Mandatory=$true)][string]$Dll,
  [string]$Out = "F:\v0.9.0-work\test_shot.png"
)
$ErrorActionPreference = "Stop"
$td = "$env:TEMP\dbime-test"
$exe = Join-Path $td "DoubaoImeSettings.exe"

Get-Process DoubaoImeSettings -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
Copy-Item $Dll (Join-Path $td "DoubaoIme.Settings.UI.dll") -Force
Start-Process -FilePath $exe | Out-Null
Start-Sleep -Seconds 8
pwsh -NoProfile -ExecutionPolicy Bypass -File "F:\v0.9.0\tools\grab_window.ps1" -ProcName DoubaoImeSettings -Out $Out
