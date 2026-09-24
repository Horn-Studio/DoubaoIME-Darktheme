# 用 UI Automation 点击设置窗口左侧导航按钮，逐页截图
param(
  [string]$OutDir = "F:\v0.9.0-work\pages",
  [string]$ProcName = "DoubaoImeSettings"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$p = Get-Process $ProcName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $p) { Write-Host "!! 未找到设置窗口"; exit 1 }
$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)

$cond = New-Object System.Windows.Automation.PropertyCondition(
  [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
  [System.Windows.Automation.ControlType]::Button)
$buttons = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
Write-Host ("按钮数量: " + $buttons.Count)

$i = 0
foreach ($b in $buttons) {
  $r = $b.Current.BoundingRectangle
  if ($r.X -lt 0 -or $r.Width -lt 100) { continue }   # 只要左侧导航大按钮
  $name = ""
  try {
    $tc = New-Object System.Windows.Automation.PropertyCondition(
      [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
      [System.Windows.Automation.ControlType]::Text)
    $t = $b.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $tc)
    if ($t) { $name = $t.Current.Name }
  } catch {}
  if ([string]::IsNullOrWhiteSpace($name)) { continue }
  $i++
  try { $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke() }
  catch { Write-Host ("  无法激活: " + $name); continue }
  Start-Sleep -Seconds 4
  $out = Join-Path $OutDir ("{0:D2}_{1}.png" -f $i, $name)
  pwsh -NoProfile -ExecutionPolicy Bypass -File "F:\v0.9.0\tools\grab_window.ps1" -ProcName $ProcName -Out $out | Out-Null
  Write-Host ("  [" + $i + "] " + $name + " -> " + $out)
}
