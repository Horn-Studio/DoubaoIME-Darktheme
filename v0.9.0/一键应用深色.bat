@echo off
chcp 65001 >nul
title 豆包输入法 v0.9 深色主题 - 应用

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 正在请求管理员权限...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
echo ============================================
echo   豆包输入法 v0.9 - 应用深色主题
echo   （候选框皮肤 + 设置界面）
echo ============================================
echo.
where pwsh >nul 2>&1
if %errorlevel% equ 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch_theme.ps1" dark
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch_theme.ps1" dark
)
echo.
pause
