# 生成豆包输入法 v0.9 深色主题资源（皮肤 + 设置界面二进制）
# 从当前已安装的 v0.9 原版文件中派生 dark\ ，并把原版完整备份到 light\
$ErrorActionPreference = "Stop"

$Root      = "F:\v0.9.0"
$InstallPf = "C:\Program Files\DoubaoIME"
$VersionDir = $null

# 自动定位当前生效的版本目录（0.9 起皮肤/二进制都在 versions\<ver>\ 下）
$act = Join-Path $env:ProgramData "DoubaoIME\Update\activation_history.json"
if (Test-Path $act) {
  $j = Get-Content $act -Raw | ConvertFrom-Json
  $healthy = $j.versions | Where-Object { $_.status -eq "healthy" } | Select-Object -Last 1
  if ($healthy) { $VersionDir = $healthy.version_dir }
}
if (-not $VersionDir -or -not (Test-Path $VersionDir)) {
  $cand = Get-ChildItem (Join-Path $InstallPf "versions") -Directory -ErrorAction SilentlyContinue |
          Sort-Object Name -Descending | Select-Object -First 1
  if ($cand) { $VersionDir = $cand.FullName }
}
if (-not $VersionDir) { throw "找不到生效的版本目录" }
Write-Host ("生效版本目录: " + $VersionDir)

$srcSkin = Join-Path $VersionDir "files\data\skin\default"
$srcDll  = Join-Path $VersionDir "DoubaoIme.Settings.UI.dll"
if (-not (Test-Path $srcSkin)) { throw ("皮肤目录不存在: " + $srcSkin) }
if (-not (Test-Path $srcDll))  { throw ("设置界面 DLL 不存在: " + $srcDll) }

$darkSkin = Join-Path $Root "dark\skin"
$lightSkin = Join-Path $Root "light\skin"
New-Item -ItemType Directory -Force -Path $darkSkin, $lightSkin | Out-Null

# ---------- 工具函数：字节级 ASCII 替换（文本文件允许变长，二进制补丁强制等长） ----------
function Replace-Bytes {
  param([byte[]]$Data, [string]$From, [string]$To, [switch]$SameLength)
  if ($SameLength -and $From.Length -ne $To.Length) { throw "长度不一致，无法安全替换: '$From' -> '$To'" }
  $f = [System.Text.Encoding]::ASCII.GetBytes($From)
  $t = [System.Text.Encoding]::ASCII.GetBytes($To)
  $out = New-Object System.Collections.Generic.List[byte]
  $hits = 0
  $i = 0
  while ($i -lt $Data.Length) {
    $match = $false
    if ($i -le $Data.Length - $f.Length) {
      $match = $true
      for ($j = 0; $j -lt $f.Length; $j++) { if ($Data[$i+$j] -ne $f[$j]) { $match = $false; break } }
    }
    if ($match) { foreach ($x in $t) { $out.Add($x) }; $i += $f.Length; $hits++ }
    else { $out.Add($Data[$i]); $i++ }
  }
  return @{ Bytes = $out.ToArray(); Hits = $hits }
}

function Save-Patched {
  param([string]$SrcPath, [string]$DstPath, [object[]]$Rules)
  $data = [System.IO.File]::ReadAllBytes($SrcPath)
  $total = 0
  foreach ($r in $Rules) {
    $res = Replace-Bytes -Data $data -From $r[0] -To $r[1]
    if ($res.Hits -eq 0) { Write-Host ("    !! 未命中: " + $r[0] + "  (" + (Split-Path $SrcPath -Leaf) + ")") }
    $data = $res.Bytes
    $total += $res.Hits
  }
  [System.IO.File]::WriteAllBytes($DstPath, $data)
  Write-Host ("  {0,-28} 替换 {1} 处" -f (Split-Path $SrcPath -Leaf), $total)
}

# ---------- 1) 原版完整备份 -> light\ ----------
Copy-Item (Join-Path $srcSkin "*") $lightSkin -Recurse -Force
Copy-Item $srcDll (Join-Path $Root "light\DoubaoIme.Settings.UI.dll") -Force
Write-Host "已备份原版 -> light\"

# ---------- 2) 皮肤：候选框背景 bk_image_1~7 + white_bk ----------
# 0.9 候选项背景仍是 bk_image_%d.svg（ImeService 按 %d 动态选取），window.xml 里的 white_bk.svg 是模板备用
foreach ($n in 1..7) {
  Save-Patched -SrcPath (Join-Path $srcSkin "bk_image_$n.svg") -DstPath (Join-Path $darkSkin "bk_image_$n.svg") `
    -Rules @( ,@('fill="white"/>', 'fill="#303030" stroke="#666666" stroke-width="1.5"/>') )
}
Save-Patched -SrcPath (Join-Path $srcSkin "white_bk.svg") -DstPath (Join-Path $darkSkin "white_bk.svg") `
  -Rules @( ,@('fill="white"/>', 'fill="#303030" stroke="#666666" stroke-width="1.5"/>') )

# ---------- 3) window.xml：候选字/序号/滚动条颜色 ----------
Save-Patched -SrcPath (Join-Path $srcSkin "window.xml") -DstPath (Join-Path $darkSkin "window.xml") -Rules @(
  ,@('textcolor="#73000000"',      'textcolor="#CCFFFFFF"')      # 序号 45%黑 -> 80%白
  ,@('textcolor="#BF000000"',      'textcolor="#E6FFFFFF"')      # 候选字 75%黑 -> 90%白（两处）
  ,@('thumbnormalcolor="#14000000"','thumbnormalcolor="#14FFFFFF"')
  ,@('thumbhotcolor="#28000000"',  'thumbhotcolor="#28FFFFFF"')
)

# ---------- 4) 翻页箭头 ----------
Save-Patched -SrcPath (Join-Path $srcSkin "page_open.svg") -DstPath (Join-Path $darkSkin "page_open.svg") `
  -Rules @( ,@('stroke="black" stroke-opacity="0.45"', 'stroke="white" stroke-opacity="0.8"') )

# ---------- 5) 中英切换 toast ----------
Save-Patched -SrcPath (Join-Path $srcSkin "toast.xml") -DstPath (Join-Path $darkSkin "toast.xml") `
  -Rules @( ,@('textcolor="#FF222222"', 'textcolor="#FFE6E6E6"') )
Save-Patched -SrcPath (Join-Path $srcSkin "toast_bk.svg") -DstPath (Join-Path $darkSkin "toast_bk.svg") `
  -Rules @( ,@('fill="#FFFFFF" stroke="#E5E7EB"', 'fill="#303030" stroke="#666666"') )
foreach ($n in @("toast_en.svg", "toast_zhong.svg")) {
  Save-Patched -SrcPath (Join-Path $srcSkin $n) -DstPath (Join-Path $darkSkin $n) `
    -Rules @( ,@('fill="#333333"', 'fill="#E6E6E6"') )
}

# ---------- 6) 设置界面：Themes/SettingsTokens.xaml 颜色 token（18 个，等长替换） ----------
# token 顺序 = BAML 资源字典中的声明顺序，已由名称表交叉验证
$tokenMap = @(
  @{ Name = "SettingsAccentColor";             Off = 1892033; Old = "#4F84FF";   New = "#4F84FF"   }, # 品牌蓝，保留
  @{ Name = "SettingsContentBackgroundColor";  Off = 1892050; Old = "#F7F7F7";   New = "#1E1E1E"   },
  @{ Name = "SettingsSidebarBackgroundColor";  Off = 1892067; Old = "#F3F3F3";   New = "#252525"   },
  @{ Name = "SettingsSidebarOverlayColor";     Off = 1892084; Old = "#40F3F3F3"; New = "#40252525" },
  @{ Name = "SettingsCardBackgroundColor";     Off = 1892103; Old = "#FFFFFFFF"; New = "#FF2D2D2D" },
  @{ Name = "SettingsCardBorderColor";         Off = 1892122; Old = "#14000000"; New = "#14FFFFFF" },
  @{ Name = "SettingsDividerColor";            Off = 1892141; Old = "#14000000"; New = "#14FFFFFF" },
  @{ Name = "SettingsTitleRowBackgroundColor"; Off = 1892160; Old = "#03000000"; New = "#03FFFFFF" },
  @{ Name = "SettingsMutedTextColor";          Off = 1892179; Old = "#4D000000"; New = "#80FFFFFF" },
  @{ Name = "SettingsInputBackgroundColor";    Off = 1892198; Old = "#0F000000"; New = "#0FFFFFFF" },
  @{ Name = "SettingsInputBorderColor";        Off = 1892217; Old = "#1F000000"; New = "#1FFFFFFF" },
  @{ Name = "SettingsAccentBackgroundColor";   Off = 1892236; Old = "#1A4F84FF"; New = "#1A4F84FF" }, # 蓝色底，保留
  @{ Name = "SettingsPrimaryTextColor";        Off = 1892255; Old = "#D9000000"; New = "#E6FFFFFF" },
  @{ Name = "SettingsSecondaryTextColor";      Off = 1892274; Old = "#66000000"; New = "#B3FFFFFF" },
  @{ Name = "SettingsSelectedTextColor";       Off = 1892293; Old = "#FFFFFFFF"; New = "#FFFFFFFF" }, # 蓝底白字，保留
  @{ Name = "SettingsOverlayBackgroundColor";  Off = 1892312; Old = "#66000000"; New = "#B3000000" },
  @{ Name = "SettingsSubheadingTextColor";     Off = 1892331; Old = "#80000000"; New = "#CCFFFFFF" },
  @{ Name = "SettingsDisabledTextColor";       Off = 1892350; Old = "#59000000"; New = "#59FFFFFF" }
)

$dll = [System.IO.File]::ReadAllBytes($srcDll)
$changed = 0
foreach ($t in $tokenMap) {
  $got = [System.Text.Encoding]::ASCII.GetString($dll, $t.Off, $t.Old.Length)
  if ($got -ne $t.Old) { throw ("色值校验失败 @{0}: 期望 {1}，实际 {2}" -f $t.Off, $t.Old, $got) }
  if ($t.Old -ne $t.New) {
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($t.New)
    [Array]::Copy($bytes, 0, $dll, $t.Off, $bytes.Length)
    $changed++
  }
}
[System.IO.File]::WriteAllBytes((Join-Path $Root "dark\DoubaoIme.Settings.UI.dll"), $dll)
Write-Host ("  {0,-28} 替换 {1} 处 token" -f "DoubaoIme.Settings.UI.dll", $changed)

Write-Host ""
Write-Host "生成完毕。"
