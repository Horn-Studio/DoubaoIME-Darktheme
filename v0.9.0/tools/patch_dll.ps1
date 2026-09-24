# 可迭代的 DoubaoIme.Settings.UI.dll 深色化工具
#   - 先按精确偏移覆盖 Themes/SettingsTokens.xaml 的 18 个颜色 token（语义明确）
#   - 再对其余所有颜色字面量做通用"明暗反转"（黑白灰反转，品牌色保留）
#   - 最后修掉 SettingsTitleTextBrush 未定义导致的标题黑字问题
# 用法: patch_dll.ps1 -Out <输出 dll 路径> [-NoGlobal]
param(
  [Parameter(Mandatory=$true)][string]$Out,
  [string]$Src = "F:\v0.9.0\light\DoubaoIme.Settings.UI.dll",
  [switch]$NoGlobal,
  [switch]$NoTitleFix
)
$ErrorActionPreference = "Stop"
$b = [System.IO.File]::ReadAllBytes($Src)

# ---------- 1) 精确 token 覆盖（偏移基于原版 DLL，等长替换） ----------
$tokens = @(
  @{ Off = 1892033; Old = "#4F84FF";   New = "#4F84FF"   },  # SettingsAccentColor            品牌蓝
  @{ Off = 1892050; Old = "#F7F7F7";   New = "#1E1E1E"   },  # SettingsContentBackgroundColor
  @{ Off = 1892067; Old = "#F3F3F3";   New = "#252525"   },  # SettingsSidebarBackgroundColor
  @{ Off = 1892084; Old = "#40F3F3F3"; New = "#40252525" },  # SettingsSidebarOverlayColor
  @{ Off = 1892103; Old = "#FFFFFFFF"; New = "#FF2D2D2D" },  # SettingsCardBackgroundColor
  @{ Off = 1892122; Old = "#14000000"; New = "#14FFFFFF" },  # SettingsCardBorderColor
  @{ Off = 1892141; Old = "#14000000"; New = "#14FFFFFF" },  # SettingsDividerColor
  @{ Off = 1892160; Old = "#03000000"; New = "#03FFFFFF" },  # SettingsTitleRowBackgroundColor
  @{ Off = 1892179; Old = "#4D000000"; New = "#CCFFFFFF" },  # SettingsMutedTextColor（被标题借用，需偏亮）
  @{ Off = 1892198; Old = "#0F000000"; New = "#0FFFFFFF" },  # SettingsInputBackgroundColor
  @{ Off = 1892217; Old = "#1F000000"; New = "#1FFFFFFF" },  # SettingsInputBorderColor
  @{ Off = 1892236; Old = "#1A4F84FF"; New = "#1A4F84FF" },  # SettingsAccentBackgroundColor  蓝色底
  @{ Off = 1892255; Old = "#D9000000"; New = "#E6FFFFFF" },  # SettingsPrimaryTextColor
  @{ Off = 1892274; Old = "#66000000"; New = "#B3FFFFFF" },  # SettingsSecondaryTextColor
  @{ Off = 1892293; Old = "#FFFFFFFF"; New = "#FFFFFFFF" },  # SettingsSelectedTextColor      蓝底白字
  @{ Off = 1892312; Old = "#66000000"; New = "#B3000000" },  # SettingsOverlayBackgroundColor 遮罩
  @{ Off = 1892331; Old = "#80000000"; New = "#CCFFFFFF" },  # SettingsSubheadingTextColor
  @{ Off = 1892350; Old = "#59000000"; New = "#59FFFFFF" }   # SettingsDisabledTextColor
)
$skip = @{}
foreach ($t in $tokens) {
  $cur = [System.Text.Encoding]::ASCII.GetString($b, $t.Off, $t.Old.Length)
  if ($cur -ne $t.Old) { throw ("token 校验失败 @{0}: 期望 {1} 实际 {2}" -f $t.Off, $t.Old, $cur) }
  if ($t.Old -ne $t.New) {
    [Array]::Copy([System.Text.Encoding]::ASCII.GetBytes($t.New), 0, $b, $t.Off, $t.New.Length)
  }
  $skip[$t.Off] = $true
}

# ---------- 2) 通用明暗反转 ----------
function Convert-Color([string]$hex) {
  # hex 形如 #RRGGBB 或 #AARRGGBB
  $s = $hex.Substring(1)
  if ($s.Length -eq 6) { $a = $null; $r = [Convert]::ToInt32($s.Substring(0,2),16); $g = [Convert]::ToInt32($s.Substring(2,2),16); $bl = [Convert]::ToInt32($s.Substring(4,2),16) }
  else { $a = $s.Substring(0,2); $r = [Convert]::ToInt32($s.Substring(2,2),16); $g = [Convert]::ToInt32($s.Substring(4,2),16); $bl = [Convert]::ToInt32($s.Substring(6,2),16) }
  $mx = [Math]::Max($r, [Math]::Max($g, $bl))
  $mn = [Math]::Min($r, [Math]::Min($g, $bl))
  $sat = if ($mx -eq 0) { 0 } else { ($mx - $mn) / $mx }
  $lum = 0.299 * $r + 0.587 * $g + 0.114 * $bl

  if ($lum -ge 0xB4) {
    # 浅色（含浅蓝灰等低饱和浅彩色）-> 深色面板：整体压到 ~18%
    $nr = [int][Math]::Round($r * 0.18); $ng = [int][Math]::Round($g * 0.18); $nb = [int][Math]::Round($bl * 0.18)
  } elseif ($sat -lt 0.25 -and $lum -lt 0x80) {
    # 近中性深灰/黑 -> 亮色（保留 alpha）
    $nr = 255 - $r; $ng = 255 - $g; $nb = 255 - $bl
  } else {
    return $hex                                        # 品牌蓝/红等饱和色保留
  }
  $nh = "{0:X2}{1:X2}{2:X2}" -f $nr, $ng, $nb
  if ($a) { return "#" + $a + $nh } else { return "#" + $nh }
}

if (-not $NoGlobal) {
  $isHex = { param($c) ($c -ge 0x30 -and $c -le 0x39) -or ($c -ge 0x41 -and $c -le 0x46) -or ($c -ge 0x61 -and $c -le 0x66) }
  $i = 0; $n = 0
  while ($i -lt $b.Length - 8) {
    if ($b[$i] -ne 0x23) { $i++; continue }
    $k = 0
    while (($i + 1 + $k) -lt $b.Length -and (& $isHex $b[$i + 1 + $k])) { $k++ }
    if (($k -eq 6 -or $k -eq 8) -and -not (& $isHex $b[$i + 1 + $k])) {
      if (-not $skip.ContainsKey($i)) {
        $old = [System.Text.Encoding]::ASCII.GetString($b, $i, $k + 1)
        $new = Convert-Color $old
        if ($new -ne $old) { [Array]::Copy([System.Text.Encoding]::ASCII.GetBytes($new), 0, $b, $i, $new.Length); $n++ }
      }
      $i += $k + 1
    } else { $i++ }
  }
  Write-Host ("  通用反转替换 " + $n + " 处")
}

# ---------- 3) 修复未定义的 SettingsTitleTextBrush ----------
# 该资源在整套资源字典中都没有定义，DynamicResource 解析失败会回退成黑色。
# 把它改名成唯一等长(22)且已定义的 SettingsMutedTextBrush。
if (-not $NoTitleFix) {
  $pat = [System.Text.Encoding]::ASCII.GetBytes("SettingsTitleTextBrush")
  $rep = [System.Text.Encoding]::ASCII.GetBytes("SettingsMutedTextBrush")
  $hit = 0
  for ($i = 0; $i -le $b.Length - $pat.Length; $i++) {
    $m = $true
    for ($j = 0; $j -lt $pat.Length; $j++) { if ($b[$i+$j] -ne $pat[$j]) { $m = $false; break } }
    if ($m) { [Array]::Copy($rep, 0, $b, $i, $rep.Length); $hit++; $i += $pat.Length - 1 }
  }
  Write-Host ("  SettingsTitleTextBrush -> SettingsMutedTextBrush : " + $hit + " 处")
}

[System.IO.File]::WriteAllBytes($Out, $b)
Write-Host ("已写入: " + $Out)
