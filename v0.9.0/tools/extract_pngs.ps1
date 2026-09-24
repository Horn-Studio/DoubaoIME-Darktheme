# 从 DLL 中提取所有内嵌 PNG 资源（签名为 \x89PNG\r\n\x1a\n，以 IEND 结束）
param(
  [Parameter(Mandatory=$true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$OutDir
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$b = [System.IO.File]::ReadAllBytes($Path)
$sig = [byte[]](0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A)
$iend = [System.Text.Encoding]::ASCII.GetBytes("IEND")
$n = 0
for ($i = 0; $i -lt $b.Length - 8; $i++) {
  $m = $true
  for ($j = 0; $j -lt 8; $j++) { if ($b[$i+$j] -ne $sig[$j]) { $m = $false; break } }
  if (-not $m) { continue }
  # 找 IEND + 4 字节 CRC
  $end = -1
  for ($k = $i + 8; $k -lt [Math]::Min($b.Length - 8, $i + 20000000); $k++) {
    if ($b[$k] -eq 0x49 -and $b[$k+1] -eq 0x45 -and $b[$k+2] -eq 0x4E -and $b[$k+3] -eq 0x44) { $end = $k + 8; break }
  }
  if ($end -lt 0) { continue }
  $n++
  $file = Join-Path $OutDir ("img_{0:D2}_{1}.png" -f $n, $i)
  $out = New-Object byte[] ($end - $i)
  [Array]::Copy($b, $i, $out, 0, $end - $i)
  [System.IO.File]::WriteAllBytes($file, $out)
  try {
    $img = [System.Drawing.Image]::FromFile($file)
    Write-Host ("{0}  offset={1}  {2}x{3}  {4:N0} bytes" -f (Split-Path $file -Leaf), $i, $img.Width, $img.Height, $out.Length)
    $img.Dispose()
  } catch { Write-Host ("{0}  offset={1}  (解析失败) {2:N0} bytes" -f (Split-Path $file -Leaf), $i, $out.Length) }
  $i = $end - 1
}
Write-Host ("共提取 " + $n + " 个 PNG")
