# 打印设置窗口的 UI Automation 树（限制深度）
param(
  [string]$ProcName = "DoubaoImeSettings",
  [int]$MaxDepth = 4
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process $ProcName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $p) { Write-Host "!! 未找到窗口"; exit 1 }
$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)

function Walk($el, $d) {
  $pad = "  " * $d
  $ct = $el.Current.ControlType.ProgrammaticName -replace '^ControlType\.', ''
  $nm = $el.Current.Name
  if ($nm.Length -gt 60) { $nm = $nm.Substring(0, 60) + "..." }
  $r = $el.Current.BoundingRectangle
  Write-Host ("{0}{1}  '{2}'  [{3:N0},{4:N0} {5:N0}x{6:N0}]" -f $pad, $ct, $nm, $r.X, $r.Y, $r.Width, $r.Height)
  if ($d -ge $MaxDepth) { return }
  $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
  $c = $walker.GetFirstChild($el)
  while ($c -ne $null) { Walk $c ($d + 1); $c = $walker.GetNextSibling($c) }
}
Walk $root 0
