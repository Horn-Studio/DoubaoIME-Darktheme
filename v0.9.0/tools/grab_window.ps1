# 直接抓取指定进程主窗口的位图（PrintWindow + PW_RENDERFULLCONTENT），不受遮挡影响
param(
  [string]$ProcName = "DoubaoImeSettings",
  [string]$Out = "F:\v0.9.0-work\settings_shot.png"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$src = @"
using System;
using System.Runtime.InteropServices;
public class W32B {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
if (-not ("W32B" -as [type])) { Add-Type -TypeDefinition $src }

$p = Get-Process $ProcName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $p) { Write-Host "!! no window"; exit 1 }
$h = $p.MainWindowHandle

$r = New-Object W32B+RECT
[void][W32B]::GetWindowRect($h, [ref]$r)
$w = $r.Right - $r.Left; $ht = $r.Bottom - $r.Top
Write-Host ("pid=" + $p.Id + " hwnd=" + $h + " rect=" + $w + "x" + $ht)
if ($w -le 0 -or $ht -le 0) { exit 1 }

$bmp = New-Object System.Drawing.Bitmap($w, $ht)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
$ok = [W32B]::PrintWindow($h, $hdc, 2)
$g.ReleaseHdc($hdc)
Write-Host ("PrintWindow=" + $ok)
New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host ("saved -> " + $Out)
