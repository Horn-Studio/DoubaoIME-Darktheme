@echo off
chcp 65001 >nul
title 豆包输入法 v0.9 深色主题 - 恢复浅色

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在请求管理员权限...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
echo ============================================
echo   豆包输入法 v0.9 - 恢复官方浅色原版
echo ============================================
echo.
where pwsh >nul 2>&1
if %errorlevel% equ 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch_theme.ps1" light
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch_theme.ps1" light
)
echo.
pause
