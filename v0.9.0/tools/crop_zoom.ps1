# 裁剪并放大图片指定区域，便于目视检查
param(
  [Parameter(Mandatory=$true)][string]$In,
  [Parameter(Mandatory=$true)][string]$Out,
  [Parameter(Mandatory=$true)][int]$X,
  [Parameter(Mandatory=$true)][int]$Y,
  [Parameter(Mandatory=$true)][int]$W,
  [Parameter(Mandatory=$true)][int]$H,
  [int]$Scale = 4
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$src = New-Object System.Drawing.Bitmap($In)
$rect = New-Object System.Drawing.Rectangle($X, $Y, $W, $H)
$crop = $src.Clone($rect, $src.PixelFormat)
$dst = New-Object System.Drawing.Bitmap(($W * $Scale), ($H * $Scale))
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($crop, 0, 0, $W * $Scale, $H * $Scale)
$g.Dispose()
$dst.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose(); $crop.Dispose(); $src.Dispose()
Write-Host ("saved -> " + $Out)
