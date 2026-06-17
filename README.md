# Path Converter

将 Windows / Mac 路径自然互转的极简菜单栏工具。

## 设计目标

在 VFX / CG 行业工作流中，常需要将 Windows 工作站上的路径（`P:\shots\seq\shot_001`）转换为 Mac 路径（`/Volumes/projects/shots/seq/shot_001`）。

这个工具刻意保持安静：

- 监听剪贴板变化，正常用 **Cmd+C**、右键复制或远程桌面剪贴板同步都可以触发
- 剪贴板包含 Windows 路径时，轻量弹出转换结果
- 剪贴板包含 Mac 路径时，只弹出提示；**默认不反转**，点击 **Convert to Windows** 后才转换
- 不拦截复制、不抢主窗口、不需要手动切换 app
- 操作后自动消失；不操作也会短暂显示后消失
- **Esc**、点击外部区域、Copy、Open Folder 都会关闭浮窗

## 盘符映射

| Windows 盘符 | Mac 映射路径 | 行为 |
|---|---|---|
| C: | （空） | 忽略，不弹窗 |
| P: | `/Volumes/projects` | 转换 |
| Y: | `/Volumes/framestore` | 转换 |
| 其他 (D, E, F…) | `/Volumes/{盘符}/` | 转换 |

默认映射表内置在 app 包里。首次运行时，app 会把它复制到用户配置目录，之后你可以通过菜单栏 **Open Config** 手动编辑，再点 **Reload Config** 生效，**无需重新编译**。

## 编译方法

### 前置条件

确保 Mac 已安装 Xcode **或** Command Line Tools：

```bash
xcode-select --install
```

### 编译 & 运行

```bash
bash build.sh
```

编译完成后，在 Finder 中打开：

```text
PathConverter.app
```

首次运行建议 **右键 → 打开**。

### 首次使用

1. 打开 app 后，菜单栏会出现路径转换图标
2. 它会在后台监听剪贴板变化，不需要无障碍权限
3. 直接 `Cmd+C` 复制路径即可触发

### 关闭 app

点击菜单栏 **🔄** 图标 → **Quit Path Converter**，或按 `Cmd + Q`。

## 界面说明

### Windows 路径

```
┌──────────────────────────────────────┐
│  Windows path                    ×   │
│                                        │
│  In: P:\shots\seq\shot_001\work\...   │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │ /Volumes/projects/shots/seq/... │ │
│  └──────────────────────────────────┘ │
│  P: → /Volumes/projects               │
│                                        │
│  [ 📋 Copy ]    [ 📁 Open Folder ]   │
└──────────────────────────────────────┘
```

### Mac 路径

```
┌──────────────────────────────────────┐
│  Mac path                        ×   │
│                                        │
│  In: /Volumes/projects/shots/...      │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │ Convert only when you ask        │ │
│  └──────────────────────────────────┘ │
│  P: → /Volumes/projects               │
│                                        │
│  [ Convert to Windows ]               │
└──────────────────────────────────────┘
```

- **In:** 原始路径，自动截断中间部分
- **转换结果框**：Windows 路径会直接显示 Mac 结果；Mac 路径默认只显示提示
- **映射标签**：显示当前使用的盘符映射
- **Copy**：复制转换后的路径，自动关闭窗口
- **Open Folder**：在 Finder 打开 Mac 路径对应目录，自动关闭窗口
- **Convert to Windows**：仅在识别到 Mac 路径时出现，点击后才反转为 Windows 路径

## 配置文件

开发默认配置：

```text
data/config.json
```

app 内置配置：

```text
PathConverter.app/Contents/Resources/config.json
```

运行时可编辑配置：

```text
~/Library/Application Support/PathConverter/config.json
```

```json
{
  "mappings": [
    { "win": "C", "mac": "" },
    { "win": "P", "mac": "/Volumes/projects" },
    { "win": "Y", "mac": "/Volumes/framestore" }
  ]
}
```

- `mac` 为空字符串 = 忽略该盘符
- 菜单栏图标 → **Open Config** 可以直接打开配置文件
- 菜单栏图标 → **Reload Config** 可以重新加载配置

## 项目文件

| 文件 | 用途 |
|---|---|
| `Sources/PathConverterCore/` | 路径识别、转换、配置读写 |
| `Sources/PathConverter/` | 菜单栏 app、浮窗、剪贴板监听 |
| `Tests/PathConverterCoreTests/` | 转换规则测试 |
| `build.sh` | 一键编译脚本 |
| `data/config.json` | 构建时写入 app 的默认盘符映射 |
| `PathConverter.app` | 编译产物 |

## 拷贝到其他电脑

- 只拷贝 `PathConverter.app`：可以运行，并且会带着 app 内部的默认映射。
- 到新电脑首次运行后，用菜单栏 **Open Config** 打开配置文件，按需手改。
- 不需要拷贝 `Sources/`、`Tests/`、`.build/`、`Package.swift`，那些只是开发文件。
