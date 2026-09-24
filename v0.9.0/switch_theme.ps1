# 豆包输入法 v0.9 深色/浅色主题切换脚本
# Usage: pwsh -NoProfile -ExecutionPolicy Bypass -File switch_theme.ps1 dark|light
#
# v0.9 与 v0.7 最大的区别：皮肤和设置界面二进制都不再位于安装根目录，
# 而是位于 C:\Program Files\DoubaoIME\versions\<版本号>\ 下。
# 本脚本会自动读取 C:\ProgramData\DoubaoIME\Update\activation_history.json
# 找到当前生效的版本目录，因此小版本升级后重新运行即可。

param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("dark","light","verify")]
  [string]$Mode
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$log  = Join-Path $Root ("switch_" + $Mode + "_log.txt")

function Log($m) {
  $line = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "  " + $m
  Write-Host $line
  try { Add-Content -Path $log -Value $line -Encoding UTF8 } catch {}
}

# ---------------- 0) 定位生效版本目录 ----------------
function Get-ActiveVersionDir {
  $act = Join-Path $env:ProgramData "DoubaoIME\Update\activation_history.json"
  if (Test-Path $act) {
    try {
      $j = Get-Content $act -Raw | ConvertFrom-Json
      $h = $j.versions | Where-Object { $_.status -eq "healthy" } | Select-Object -Last 1
      if ($h -and (Test-Path $h.version_dir)) { return $h.version_dir }
    } catch {}
  }
  $vs = Join-Path "C:\Program Files\DoubaoIME" "versions"
  if (Test-Path $vs) {
    $c = Get-ChildItem $vs -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($c -and (Test-Path (Join-Path $c.FullName "ImeService.exe"))) { return $c.FullName }
  }
  return $null
}

$pf = "C:\Program Files\DoubaoIME"
$versionDir = Get-ActiveVersionDir
if (-not $versionDir) { Log "!! 找不到生效的版本目录（versions 下没有可用版本）"; exit 1 }
Log ("生效版本目录: " + $versionDir)

$skinDir = Join-Path $versionDir "files\data\skin\default"
$dllName = "DoubaoIme.Settings.UI.dll"
$dllDst  = Join-Path $versionDir $dllName
if (-not (Test-Path $skinDir)) { Log ("!! 皮肤目录不存在: " + $skinDir); exit 1 }

$srcSkin = Join-Path $Root $(if ($Mode -eq "dark") { "dark\skin" } else { "light\skin" })
$srcDll  = Join-Path $Root $(if ($Mode -eq "dark") { "dark\$dllName" } else { "light\$dllName" })

# ---------------- verify 模式：只读检查 ----------------
if ($Mode -eq "verify") {
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  Log ("管理员权限: " + $isAdmin)
  function Cmp($a, $b, $label) {
    if (-not (Test-Path $a)) { Log ("  [缺失] " + $label); return }
    if (-not (Test-Path $b)) { Log ("  [缺失] " + $label); return }
    $x = (Get-FileHash $a -Algorithm MD5).Hash; $y = (Get-FileHash $b -Algorithm MD5).Hash
    Log ("  [{0}] {1}" -f $(if ($x -eq $y) { "深色" } else { "浅色/其他" }), $label)
  }
  Log "---- 皮肤文件 ----"
  foreach ($f in (Get-ChildItem (Join-Path $Root "dark\skin") -File)) {
    Cmp $f.FullName (Join-Path $skinDir $f.Name) $f.Name
  }
  Log "---- 设置界面 ----"
  Cmp $srcDll $dllDst $dllName
  Log "---- 相关进程 ----"
  Get-Process ImeService, ImeWatchdog, DoubaoImeSettings -ErrorAction SilentlyContinue |
    ForEach-Object { Log ("  运行中: " + $_.ProcessName + " (PID " + $_.Id + ")") }
  exit 0
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Log ("管理员权限: " + $isAdmin)
if (-not $isAdmin) { Log "!! 未获得管理员权限，请以管理员运行"; exit 1 }

if (-not (Test-Path $srcSkin)) { Log ("!! 找不到主题文件目录: " + $srcSkin); exit 1 }

# ---------------- 1) 备份当前文件 ----------------
$stamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$bakDir = Join-Path $pf ("skin_backup_" + $Mode + "_v09_" + $stamp)
New-Item -ItemType Directory -Force -Path $bakDir | Out-Null
Copy-Item (Join-Path $skinDir "*") $bakDir -Recurse -Force
if (Test-Path $dllDst) { Copy-Item $dllDst (Join-Path $bakDir $dllName) -Force }
Log ("已备份当前文件 -> " + $bakDir)

# ---------------- 2) 停止输入法组件 ----------------
foreach ($n in @("ImeService","ImeWatchdog","DoubaoImeSettings","SettingsLauncher","UpdateWorker")) {
  $ps = Get-Process -Name $n -ErrorAction SilentlyContinue
  if ($ps) {
    foreach ($p in $ps) {
      try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Log ("已停止 " + $n + " (PID " + $p.Id + ")") }
      catch { Log ("停止 " + $n + " 失败: " + $_.Exception.Message) }
    }
  } else { Log ($n + " 未运行") }
}
Start-Sleep -Seconds 3

# ---------------- 3) 复制皮肤 ----------------
Copy-Item (Join-Path $srcSkin "*") $skinDir -Recurse -Force
Log ("已" + $(if ($Mode -eq "dark") { "应用深色" } else { "还原浅色(原版)" }) + "皮肤 -> " + $skinDir)

# ---------------- 4) 复制设置界面二进制 ----------------
if (Test-Path $srcDll) {
  Copy-Item $srcDll $dllDst -Force
  Log ("已" + $(if ($Mode -eq "dark") { "替换设置界面为深色版" } else { "还原设置界面为原版" }) + ": " + $dllName)
} else { Log ("!! 源缺失: " + $srcDll) }

# ---------------- 5) 校验 ----------------
$ok = $true
Get-ChildItem $srcSkin -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Substring($srcSkin.Length).TrimStart("\", "/")
  $dst = Join-Path $skinDir $rel
  if (Test-Path $dst) {
    if ((Get-FileHash $_.FullName -Algorithm MD5).Hash -ne (Get-FileHash $dst -Algorithm MD5).Hash) {
      Log ("!! 校验失败: " + $rel); $ok = $false
    }
  } else { Log ("!! 目标缺失: " + $rel); $ok = $false }
}
if (Test-Path $srcDll) {
  if ((Get-FileHash $srcDll -Algorithm MD5).Hash -ne (Get-FileHash $dllDst -Algorithm MD5).Hash) {
    Log ("!! 校验失败: " + $dllName); $ok = $false
  }
}
Log ("文件校验: " + $(if ($ok) { "全部一致" } else { "存在不一致" }))

# ---------------- 6) 重启组件 ----------------
$imeSvc = Join-Path $versionDir "ImeService.exe"
$wd     = Join-Path $pf "bootstrap\ImeWatchdog.exe"
if (Test-Path $imeSvc) {
  Start-Process -FilePath $imeSvc -WorkingDirectory $versionDir | Out-Null
  Log ("已启动: " + $imeSvc)
} else { Log ("!! 找不到 ImeService.exe: " + $imeSvc) }
Start-Sleep -Seconds 2
if (Test-Path $wd) {
  Start-Process -FilePath $wd -WorkingDirectory (Split-Path $wd) | Out-Null
  Log ("已启动: " + $wd)
} else { Log ("!! 找不到 ImeWatchdog.exe: " + $wd) }
Start-Sleep -Seconds 5

$running = Get-Process -Name ImeService,ImeWatchdog -ErrorAction SilentlyContinue
if ($running) { $running | ForEach-Object { Log ("运行中: " + $_.ProcessName + " (PID " + $_.Id + ")") } }
else { Log "!! 5 秒后未见组件进程，请手动重启一次输入法（切换输入法或重新登录）" }

Log ("=== " + $(if ($Mode -eq "dark") { "深色主题应用完成" } else { "浅色主题恢复完成" }) + " ===")
