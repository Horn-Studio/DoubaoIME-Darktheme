# DoubaoIME v0.6.2 深色主题一键应用（仅深色；无浅色恢复资源）
# 注意：仅适用于 v0.6.2！包含设置界面 DLL/EXE 替换，勿用于 v0.7 及以上版本！
# Usage: powershell -ExecutionPolicy Bypass -File apply_dark_062.ps1
$ErrorActionPreference = "Stop"
$log = Join-Path $PSScriptRoot "apply_dark_062_log.txt"

function Log($m) {
  $line = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "  " + $m
  Write-Host $line
  Add-Content -Path $log -Value $line -Encoding UTF8
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Log ("管理员权限: " + $isAdmin)
if (-not $isAdmin) { Log "!! 未获得管理员权限，请以管理员运行"; exit 1 }

$pf = "C:\Program Files\DoubaoIME"
$skinDir = Join-Path $pf "files\data\skin\default"

# --- 版本检查：仅允许 v0.6.x ---
$verDir = (Get-ItemProperty 'HKCU:\Software\DoubaoIme' -Name VersionDir -ErrorAction SilentlyContinue).VersionDir
Log ("当前版本目录: " + $verDir)
if ($verDir -match 'v0\.7') {
  Log "!! 检测到 v0.7.x！此补丁仅适用于 v0.6.2（含 DLL/EXE，直接替换会导致崩溃）。已中止。"
  Read-Host "按回车退出"
  exit 1
}
if ($verDir -notmatch 'v0\.6') {
  Log ("!! 未识别到 v0.6.x 版本目录（" + $verDir + "），已中止。")
  Read-Host "按回车退出"
  exit 1
}

$srcDir = Join-Path $PSScriptRoot "dark"
if (-not (Test-Path $srcDir)) { Log ("!! 找不到主题文件目录: " + $srcDir); exit 1 }

# 目标文件映射：DLL/EXE -> 安装根目录；皮肤 -> skin\default
$targets = @(
  @{ Name = "DoubaoIme.Settings.UI.dll"; Src = "DoubaoIme.Settings.UI.dll"; Dst = Join-Path $pf "DoubaoIme.Settings.UI.dll" },
  @{ Name = "DoubaoImeSettings.exe";     Src = "DoubaoImeSettings.exe";     Dst = Join-Path $pf "DoubaoImeSettings.exe" },
  @{ Name = "window.xml";                Src = "window.xml";                Dst = Join-Path $skinDir "window.xml" },
  @{ Name = "white_bk.svg";              Src = "white_bk.svg";              Dst = Join-Path $skinDir "white_bk.svg" },
  @{ Name = "page_open.svg";             Src = "page_open.svg";             Dst = Join-Path $skinDir "page_open.svg" }
)

# 1) 备份当前文件
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$bakDir = Join-Path $pf ("skin_backup_062dark_" + $stamp)
New-Item -ItemType Directory -Force -Path $bakDir | Out-Null
foreach ($t in $targets) {
  if (Test-Path $t.Dst) { Copy-Item $t.Dst (Join-Path $bakDir (Split-Path $t.Dst -Leaf)) -Force }
}
Log ("已备份当前文件 -> " + $bakDir)

# 2) 停止输入法组件
foreach ($n in @("ImeService","ImeWatchdog")) {
  $p = Get-Process -Name $n -ErrorAction SilentlyContinue
  if ($p) {
    try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Log ("已停止 " + $n + " (PID " + $p.Id + ")") }
    catch { Log ("停止 " + $n + " 失败: " + $_.Exception.Message) }
  } else { Log ($n + " 未运行") }
}
Start-Sleep -Seconds 3

# 3) 应用深色文件
foreach ($t in $targets) {
  $s = Join-Path $srcDir $t.Src
  if (Test-Path $s) {
    Copy-Item $s $t.Dst -Force
    Log ("已写入 " + $t.Name + " -> " + $t.Dst)
  } else { Log ("!! 源文件缺失: " + $s) }
}

# 4) 校验
$ok = $true
foreach ($t in $targets) {
  $s = Join-Path $srcDir $t.Src
  if (Test-Path $s -and Test-Path $t.Dst) {
    $a = (Get-FileHash $s -Algorithm MD5).Hash
    $b = (Get-FileHash $t.Dst -Algorithm MD5).Hash
    if ($a -ne $b) { Log ("!! 校验失败: " + $t.Name); $ok = $false }
  }
}
Log ("文件校验: " + $(if ($ok) { "全部一致" } else { "存在不一致" }))

# 5) 重启组件
Start-Process -FilePath (Join-Path $pf "ImeService.exe") -WorkingDirectory $pf | Out-Null
Start-Process -FilePath (Join-Path $pf "ImeWatchdog.exe") -WorkingDirectory $pf | Out-Null
Start-Sleep -Seconds 5
$running = Get-Process -Name ImeService, ImeWatchdog -ErrorAction SilentlyContinue
if ($running) { $running | ForEach-Object { Log ("运行中: " + $_.ProcessName + " (PID " + $_.Id + ")") } }
else { Log "!! 5秒后未见组件进程" }

Log "=== 0.6.2 深色主题应用完成 ==="
