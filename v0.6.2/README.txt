# 豆包输入法 v0.6.2 深色主题 - 一键应用工具

## 重要警告
!! 本工具仅适用于 DoubaoIME v0.6.2.07201 !!
包含设置界面 DLL/EXE 替换，直接用于 v0.7 及以上版本会导致崩溃！
（脚本会自动检测版本目录，v0.7.x 会拒绝执行）

## 来源
资源提取自：D:\DoubaoImeDarkThemeTool.exe（0.6.2 深色主题工具，PyInstaller 打包）
与原工具内嵌资源哈希完全一致。

## 使用方法
双击「一键应用深色.bat」（会请求管理员权限，UAC 点"是"）
脚本自动：备份当前文件 -> 停止输入法组件 -> 替换 -> 校验 -> 重启组件

## 目录说明
- dark\  深色资源 5 个：
  - DoubaoIme.Settings.UI.dll（设置界面深色）
  - DoubaoImeSettings.exe（设置程序深色）
  - window.xml / white_bk.svg / page_open.svg（候选框深色皮肤）
- apply_dark_062.ps1  核心脚本
- 一键应用深色.bat    启动器

## 缺陷说明
原工具只内置深色资源（浅色原版依赖运行时备份），因此本包只提供深色应用。

## 恢复浅色
应用前会自动备份当前文件到：
  C:\Program Files\DoubaoIME\skin_backup_062dark_<时间戳>\
把备份文件复制回原位并重启输入法即可恢复。

## 手动恢复（备份丢失时）
0.6.2 原版文件可从以下位置找回：
- C:\Program Files\DoubaoIME\dark_theme_backup\（DoubaoIme.Settings.UI.dll / DoubaoImeSettings.exe / tsf-oime-core.dll.bak）
- C:\Program Files\DoubaoIME\files\data\skin\default_backup_light\（浅色皮肤）
