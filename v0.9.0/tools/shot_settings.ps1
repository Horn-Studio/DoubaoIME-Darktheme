# 启动豆包设置并截图指定窗口，用于视觉验证
param(
  [string]$Exe = "C:\Program Files\DoubaoIME\versions\v0.9.0.0\DoubaoImeSettings.exe",
  [string]$Out = "F:\v0.9.0-work\settings_shot.png",
  [int]$WaitSec = 6
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$src = @"
using System;
using System.Runtime.InteropServices;
public class W32 {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
if (-not ("W32" -as [type])) { Add-Type -TypeDefinition $src }

$before = (Get-Process DoubaoImeSettings -ErrorAction SilentlyContinue).Id
if (-not $before) {
  Start-Process -FilePath $Exe | Out-Null
  Write-Host "launched settings"
} else { Write-Host "settings already running" }
Start-Sleep -Seconds $WaitSec

$p = Get-Process DoubaoImeSettings -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { Write-Host "!! settings process not found"; exit 1 }
$h = $p.MainWindowHandle
Write-Host ("pid=" + $p.Id + " hwnd=" + $h)
if ($h -eq 0) { Write-Host "!! no main window handle"; exit 1 }
[void][W32]::ShowWindow($h, 9)
[void][W32]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 800

$r = New-Object W32+RECT
[void][W32]::GetWindowRect($h, [ref]$r)
$w = $r.Right - $r.Left; $ht = $r.Bottom - $r.Top
Write-Host ("rect = {0},{1} {2}x{3}" -f $r.Left, $r.Top, $w, $ht)
if ($w -le 0 -or $ht -le 0) { Write-Host "!! bad rect"; exit 1 }

$bmp = New-Object System.Drawing.Bitmap($w, $ht)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, (New-Object System.Drawing.Size($w, $ht)))
New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host ("saved -> " + $Out)
