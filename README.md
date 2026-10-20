# FinderRightClick

**FinderRightClick** 是一个极简、零第三方依赖、纯原生 Swift 编写的 macOS 访达（Finder）右键菜单增强工具。基于 Apple 官方 `FIFinderSync` (Finder Sync Extension) 接口构建，无需关闭 SIP，支持在**任意文件夹空白处**或选中项上右键一键操作。

---

## ✨ 核心功能

支持在 Finder **文件夹内部空白处右键**、**文件/文件夹图标上右键**以及 **Finder 顶部工具栏按钮**：

1. **🖥 在终端中打开 (Open in Terminal)**
   - 自动检测系统中已安装的现代终端（优先级：`iTerm2` > `Warp` > `Ghostty` > `WezTerm` > `kitty` > `Alacritty` > `Hyper` > `系统 Terminal`）。
   - 如果安装了第三方终端（如 `iTerm2`），菜单同时提供 **「在 iTerm2 中打开」** 与 **「在系统终端 (Terminal) 中打开」**。
2. **📋 复制文件路径 (Copy File Path)**
   - 在空白处右键直接复制当前所在文件夹的 POSIX 绝对路径；选中多个文件时复制所有选中文件的路径列表。
3. **➕ 在此新建文件... (Create File with Prompt)**
   - 弹出原生命名对话框，支持输入文件名并一键选择 `.txt`、`.md`、`.py`（或自定义任意后缀），创建后自动在 Finder 中高亮选中。
4. **⚡ 快速新建 (.txt / .md / .py)**
   - 免弹窗一键生成 `untitled.txt`、`untitled.md`、`untitled.py`。
   - **防覆盖保护**：若存在同名文件，自动递增命名为 `untitled_1.py`、`untitled_2.py`，绝不覆盖已有数据。

---

## 🏗 架构设计与最佳实践 (Why It Works on Modern macOS)

许多早期开源 Finder 扩展在新版 macOS 上会出现“菜单不显示”或“点击无响应”的问题，本项目针对 macOS 沙盒与 XPC 机制进行了专门的工程优化：

1. **Extension + Host Helper 双进程架构**：
   - `FinderRightClickExtension.appex` 运行在受限的 App Sandbox 中，仅负责轻量级监听挂载卷与注入 `NSMenu`。
   - `FinderRightClick.app` 作为无沙盒（Unsandboxed）后台常驻守护进程（`LSUIElement` + `LaunchAgent`），通过 `DistributedNotificationCenter` 接收来自扩展的指令，突破沙盒对任意目录创建文件、弹出模态输入框 (`NSAlert`) 以及调用外部终端的限制。
2. **规避 XPC `NSMenuItem` 序列化丢失问题**：
   - Finder 在跨进程序列化 `NSMenu` 时会丢弃 `NSMenuItem.representedObject`，本项目采用独立 Objective-C `@objc` Selector 绑定，确保每一项菜单点击 100% 触发。
3. **零 Xcode 工程膨胀 (Zero-Xcode CLI Build)**：
   - 无需安装数十 GB 的完整版 Xcode，仅需 macOS Command Line Tools (`swiftc`) 即可在 2 秒内完成编译、签名与打包。

---

## 🚀 快速开始 (Build & Install)

### 环境要求
- macOS 12.0+ (全面兼容最新 macOS Tahoe / Sequoia)
- Xcode Command Line Tools (`xcode-select --install`)

### 一键编译并安装

```bash
git clone https://github.com/struggler2020/FinderRightClick.git
cd FinderRightClick
make install
```

### 常用 Makefile 命令

| 命令 | 说明 |
| :--- | :--- |
| `make build` | 仅编译并生成签名好的 `build/FinderRightClick.app` |
| `make install` | 编译、安装至 `/Applications`、配置 `LaunchAgent` 并自动启用 Finder 扩展 |
| `make uninstall` | 停止后台服务、注销扩展并从系统中彻底移除 |
| `make clean` | 清理 `build/` 构建产物 |

---

## 📂 目录结构

```text
FinderRightClick/
├── Makefile                        # 构建、安装、卸载入口
├── LICENSE                         # MIT 开源协议
├── README.md                       # 项目文档
├── Sources/
│   ├── Shared/
│   │   └── SharedModels.swift      # 跨进程常量与终端自动探测模型
│   ├── HostApp/
│   │   └── HostApp.swift           # 后台宿主守护程序（处理新建文件弹窗、文件写入与启动终端）
│   └── FinderExtension/
│       └── FinderSync.swift        # Finder Sync 扩展（负责渲染右键菜单与复制路径）
├── Resources/
│   ├── HostInfo.plist              # 主程序 Info.plist
│   ├── ExtensionInfo.plist         # 扩展 Info.plist
│   └── Extension.entitlements      # 扩展沙盒权限声明
└── scripts/
    ├── build.sh                    # 纯 swiftc 编译打包脚本
    ├── install.sh                  # 自动化部署与激活脚本
    └── uninstall.sh                # 彻底卸载清理脚本
```

---

## 📄 开源协议

本项目基于 [MIT License](LICENSE) 开源。
