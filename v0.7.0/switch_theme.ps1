# DoubaoIME v0.7.0 深色/浅色主题切换脚本（皮肤 + 设置界面补丁）
# Usage: powershell -ExecutionPolicy Bypass -File switch_theme.ps1 dark|light
param([Parameter(Mandatory=$true)][string]$Mode)

$ErrorActionPreference = "Stop"
$log = Join-Path $PSScriptRoot ("switch_" + $Mode + "_log.txt")

function Log($m) {
  $line = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "  " + $m
  Write-Host $line
  Add-Content -Path $log -Value $line -Encoding UTF8
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Log ("管理员权限: " + $isAdmin)
if (-not $isAdmin) { Log "!! 未获得管理员权限，请以管理员运行"; exit 1 }

$pf = "C:/Program Files/DoubaoIME"
$skinDir = Join-Path $pf "files/data/skin/default"
if (-not (Test-Path $skinDir)) { Log ("!! 皮肤目录不存在: " + $skinDir); exit 1 }

$srcDir = Join-Path $PSScriptRoot $(if ($Mode -eq "dark") { "dark" } else { "light" })
if (-not (Test-Path $srcDir)) { Log ("!! 找不到主题文件目录: " + $srcDir); exit 1 }

# 设置界面二进制（安装根目录）
$settingsBinaries = @("DoubaoIme.Settings.UI.dll", "DoubaoImeSettings.exe")

# 1) 备份当前文件（皮肤 + 设置界面二进制）
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$bakDir = Join-Path $pf ("skin_backup_" + $Mode + "_" + $stamp)
New-Item -ItemType Directory -Force -Path $bakDir | Out-Null
Copy-Item (Join-Path $skinDir "*") $bakDir -Recurse -Force
foreach ($f in $settingsBinaries) {
  $p = Join-Path $pf $f
  if (Test-Path $p) { Copy-Item $p (Join-Path $bakDir $f) -Force }
}
Log ("已备份当前文件 -> " + $bakDir)

# 2) 停止输入法组件 + 设置程序
foreach ($n in @("ImeService","ImeWatchdog")) {
  $p = Get-Process -Name $n -ErrorAction SilentlyContinue
  if ($p) {
    try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Log ("已停止 " + $n + " (PID " + $p.Id + ")") }
    catch { Log ("停止 " + $n + " 失败: " + $_.Exception.Message) }
  } else { Log ($n + " 未运行") }
}
Get-Process DoubaoImeSettings -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# 3) 复制皮肤文件（dark/light 全部 -> skin/default）
Copy-Item (Join-Path $srcDir "*") $skinDir -Recurse -Force
Log ("已应用" + $(if ($Mode -eq "dark") { "深色" } else { "浅色(原版)" }) + "皮肤 -> " + $skinDir)

# 4) 复制设置界面二进制（dark -> 深色版，light -> 原版）
foreach ($f in $settingsBinaries) {
  $s = Join-Path $srcDir $f
  $d = Join-Path $pf $f
  if (Test-Path $s) {
    Copy-Item $s $d -Force
    Log ("已" + $(if ($Mode -eq "dark") { "替换设置界面为深色版" } else { "还原设置界面为原版(浅色)" }) + ": " + $f)
  } else {
    Log ("!! 源缺失: " + $f + "（" + $srcDir + "）")
  }
}

# 5) 校验
$ok = $true
Get-ChildItem $srcDir -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Substring($srcDir.Length).TrimStart("/", "\")
  $dst = Join-Path $skinDir $rel
  if (-not (Test-Path $dst)) { $dst = Join-Path $pf $rel }
  if (Test-Path $dst) {
    $a = (Get-FileHash $_.FullName -Algorithm MD5).Hash
    $b = (Get-FileHash $dst -Algorithm MD5).Hash
    if ($a -ne $b) { Log ("!! 校验失败: " + $rel); $ok = $false }
  } else { Log ("!! 目标缺失: " + $rel); $ok = $false }
}
Log ("文件校验: " + $(if ($ok) { "全部一致" } else { "存在不一致" }))

# 6) 重启组件
Start-Process -FilePath (Join-Path $pf "ImeService.exe") -WorkingDirectory $pf | Out-Null
Start-Process -FilePath (Join-Path $pf "ImeWatchdog.exe") -WorkingDirectory $pf | Out-Null
Start-Sleep -Seconds 5
$running = Get-Process -Name ImeService, ImeWatchdog -ErrorAction SilentlyContinue
if ($running) { $running | ForEach-Object { Log ("运行中: " + $_.ProcessName + " (PID " + $_.Id + ")") } }
else { Log "!! 5秒后未见组件进程" }

Log ("=== " + $(if ($Mode -eq "dark") { "深色主题应用完成（含设置界面深色补丁）" } else { "浅色主题恢复完成（含设置界面原版）" }) + " ===")
