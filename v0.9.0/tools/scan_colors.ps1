# 全量扫描文件中的颜色字面量（# 后 6 或 8 位十六进制，且后面不再是十六进制字符）
param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = "Stop"
$b = [System.IO.File]::ReadAllBytes($Path)
$isHex = { param($c) ($c -ge 0x30 -and $c -le 0x39) -or ($c -ge 0x41 -and $c -le 0x46) -or ($c -ge 0x61 -and $c -le 0x66) }
$res = New-Object System.Collections.Generic.List[object]
$i = 0
while ($i -lt $b.Length - 8) {
  if ($b[$i] -ne 0x23) { $i++; continue }
  $n = 0
  while (($i + 1 + $n) -lt $b.Length -and (& $isHex $b[$i + 1 + $n])) { $n++ }
  if (($n -eq 6 -or $n -eq 8) -and -not (& $isHex $b[$i + 1 + $n])) {
    $res.Add([pscustomobject]@{ Offset = $i; Len = $n + 1; Color = [System.Text.Encoding]::ASCII.GetString($b, $i, $n + 1) })
    $i += $n + 1
  } else { $i++ }
}
Write-Host ("file      : " + $Path)
Write-Host ("total     : " + $res.Count)
Write-Host ""
Write-Host "---- 按色值汇总 ----"
$res | Group-Object Color | Sort-Object Count -Descending |
  Select-Object Count, Name | Format-Table -AutoSize | Out-String -Width 60 | Write-Host
Write-Host "---- 前 40 个字面量（含偏移）----"
$res | Select-Object -First 40 | Format-Table -AutoSize | Write-Host
