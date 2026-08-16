# DoubaoIME-Darktheme

豆包输入法（Doubao IME）深色主题补丁集合 · Dark theme patches for DoubaoIME

为豆包输入法 Windows 版提供官方暂未提供的深色主题。

## 效果预览

| 浅色（官方原版） | 深色（本补丁） |
|---|---|
| ![浅色输入框](https://horn-studio.github.io/DoubaoIME-Darktheme/screenshot/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202026-08-16%20191629.png) | ![深色输入框](https://horn-studio.github.io/DoubaoIME-Darktheme/screenshot/%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE%202026-08-16%20191731.png) |

| 版本 | Patch 方式 | 改动范围 | 备份/恢复 |
|---|---|---|---|
| [v0.6.2](./v0.6.2) | 皮肤文件 + 二进制（DLL/EXE） | 候选框 + 设置界面 | 自动备份，可手动恢复 |
| [v0.7.0](./v0.7.0) | 皮肤文件 + 设置界面二进制（颜色 token 替换） | 候选框 + 输入提示 + 设置界面 | 一键恢复浅色 |

> ⚠️ 每个版本补丁**不通用**：v0.6.2 补丁含二进制，直接用于 v0.7 会导致崩溃；v0.7.0 补丁只做数据/颜色级替换，不修改代码逻辑。



---

## v0.6.2 

适用：`v0.6.2.07201`。补丁包含 **5 个文件**（皮肤 + 设置界面）：

| 文件 | 目标位置 | 内容 |
|---|---|---|
| `window.xml` | `files\data\skin\default\` | 候选字颜色 → 白色（#CCFFFFFF/#E6FFFFFF） |
| `white_bk.svg` | 同上 | 候选框背景 → #303030 + #666666 描边 |
| `page_open.svg` | 同上 | 翻页箭头 → 白色 |
| `DoubaoIme.Settings.UI.dll` | 安装根目录 | 设置界面深色 |
| `DoubaoImeSettings.exe` | 安装根目录 | 设置程序深色 |

**步骤**：
1. 备份原文件（脚本自动备份到 `%APPDATA%\DoubaoImeThemeTool\backup`）
2. 停止 ImeService（看门狗会自动拉起）
3. 复制上述 5 个文件到对应位置
4. 重启输入法

**使用**：双击 `一键应用深色.bat`（自动提权 + 备份 + 替换 + 重启）。

**注意**：脚本内置版本检测，在 v0.7.x 上运行会被拒绝（避免崩溃）。

---

## v0.7.0

适用：`v0.7.0.08104`。共 **16 个文件**（14 皮肤 + 2 设置界面二进制）：

### 1. 候选框/输入提示皮肤（纯 XML/SVG，无风险）

| 文件 | 内容 |
|---|---|
| `window.xml` | 候选字 → 白色（#CCFFFFFF/#E6FFFFFF），滚动条 → 浅色 |
| `bk_image_1~7.svg` | ⭐ 候选框背景（v0.7 实际使用的背景图，7 种圆角）→ #303030 + #666666 |
| `white_bk.svg` | 备用背景 → 深色 |
| `page_open.svg` | 翻页箭头 → 白色 |
| `toast.xml` / `toast_bk.svg` / `toast_en.svg` / `toast_zhong.svg` | 中英切换提示 → 深色 |
v0.7 候选框背景由 ImeService.exe 硬编码 `file='bk_image_%d.svg'` 加载，
不是 window.xml 里写的 `white_bk.svg`。只改 white_bk.svg 背景不会变化（候选字变白后看不见）。

### 2. 设置界面深色补丁

| 文件 | 目标位置 | 内容 |
|---|---|---|
| `DoubaoIme.Settings.UI.dll` | 安装根目录 | 88 处颜色替换（黑字→白字；浅灰背景 #F7F7F7/#F3F3F3/白 → 深灰 #1E1E1E/#252525/#2D2D2D；蓝色品牌色保留） |
| `DoubaoImeSettings.exe` | 安装根目录 | 6 处颜色替换（黑→白） |

设置界面为 WPF 应用，颜色定义在 BAML 资源字典 `Themes/SettingsTokens.xaml` 中，
以 `#RRGGBB`/`#AARRGGBB` 字符串形式存储，直接做字符串级替换即可，无需修改代码逻辑。

### 3. 应用步骤
1. 备份当前皮肤+二进制（脚本自动备份到 `C:\Program Files\DoubaoIME\skin_backup_<mode>_<时间戳>\`）
2. 停止 ImeService + ImeWatchdog（以及设置程序）
3. 复制 `dark\` 全部文件（皮肤 → `files\data\skin\default\`，二进制 → 安装根目录）
4. 启动 ImeService（先）再 ImeWatchdog（后）

**使用**：
- 双击 `一键应用深色.bat` 应用深色（含设置界面）
- 双击 `一键恢复浅色.bat` 恢复官方原版（`light\` 含完整 49 文件）

---

## 目录结构

```
DoubaoIME-Darktheme/
├── README.md                 # 本文件
├── v0.6.2/                   # v0.6.2 补丁（含 DLL/EXE）
│   ├── 一键应用深色.bat
│   ├── apply_dark_062.ps1
│   ├── dark/                 # 深色资源 5 文件
│   └── README.txt
└── v0.7.0/                   # v0.7.0 补丁（皮肤 + 设置界面）
    ├── 一键应用深色.bat
    ├── 一键恢复浅色.bat
    ├── switch_theme.ps1
    ├── dark/                 # 深色资源 16 文件（14 皮肤 + 2 设置界面）
    ├── light/                # 浅色原版完整备份 49 文件
    ├── README.txt
    └── PATCH-说明.md         # 详细 patch 原理
```

## 声明

- 本仓库仅用于学习研究，修改官方软件有一定风险，请自行备份后再操作
- 输入法版本更新后补丁会失效，新版本可能官方会添加深色模式，那时此项目将停止或转型
