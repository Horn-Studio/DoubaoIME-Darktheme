# 解析 BAML 资源字典中的颜色 token 文本字面量（形如 #RRGGBB / #AARRGGBB）
# BAML 的 StringValue 结构为：0x0B/0x0D/0x0F/0x11(长度+4) + 长度 + 内容
param(
  [Parameter(Mandatory=$true)][string]$Path
)
$ErrorActionPreference = "Stop"
$b = [System.IO.File]::ReadAllBytes($Path)
$results = New-Object System.Collections.Generic.List[object]
for ($i = 2; $i -lt $b.Length; $i++) {
  if ($b[$i] -ne 0x23) { continue }                       # '#'
  $lenByte  = $b[$i-1]
  $declByte = $b[$i-2]
  if ($declByte -ne ($lenByte + 4)) { continue }
  $len = [int]$lenByte
  if ($len -ne 7 -and $len -ne 9) { continue }            # #RRGGBB / #AARRGGBB
  if ($i + $len -gt $b.Length) { continue }
  $isHex = $true
  for ($j = $i + 1; $j -lt $i + $len; $j++) {
    $c = $b[$j]
    if (-not (($c -ge 0x30 -and $c -le 0x39) -or ($c -ge 0x41 -and $c -le 0x46) -or ($c -ge 0x61 -and $c -le 0x66))) { $isHex = $false; break }
  }
  if (-not $isHex) { continue }
  $results.Add([pscustomobject]@{ Offset = $i; Len = $len; Color = [System.Text.Encoding]::ASCII.GetString($b, $i, $len) })
}
Write-Host ("file     : " + $Path)
Write-Host ("literals : " + $results.Count)
$results | Format-Table -AutoSize
