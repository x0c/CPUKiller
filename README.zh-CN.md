**语言：** [English](README.md) | 简体中文

# CPU Killer

<p align="center">
  <img src="docs/images/app-icon.png" width="128" height="128" alt="CPU Killer 应用图标：白色 CPU 芯片">
</p>

CPU Killer 是 **macOS 菜单栏进程表**。电脑卡的时候点开，看清是谁在吃 CPU，然后结束那一行。

它不是 Stats，也不是活动监视器。没有进程树、没有温度风扇。日常界面是菜单栏里那张表。如果隐藏了菜单栏图标，用带标题栏的小恢复窗把应用找回来——那不是桌面进程表。

**需要 macOS 26 或更高。** MIT 开源。数据只留在这台 Mac 上——没有账号，没有遥测。

<p align="center">
  <img src="docs/images/panel.png" width="480" alt="CPU Killer 菜单栏表：应用名、CPU 与内存占用、结束">
</p>

## 支持的平台

- **macOS 26+**（Apple 芯片与 Intel）
- **不支持 Windows 或 Linux。** 本应用读取 macOS 进程身份、住在菜单栏、结束本机进程。这些能力在其他系统上不存在。

## 安装

### Homebrew（推荐）

```sh
brew tap x0c/tap
brew install --cask cpu-killer
```

### 直接下载

从 [releases](https://github.com/x0c/CPUKiller/releases/latest) 下载已签名并公证的 `CPU-Killer-x.y.z.dmg`，把 CPU Killer 拖进「应用程序」。

CPU Killer 会自动检查更新（[Sparkle](https://sparkle-project.org)）。右键菜单栏图标可选「检查更新…」。

### 从源码构建

需要 Xcode 26+ 和 [XcodeGen](https://github.com/yonaskolb/XcodeGen)：

```sh
git clone https://github.com/x0c/CPUKiller.git
cd CPUKiller
xcodegen generate
xcodebuild -project CPUKiller.xcodeproj -scheme CPUKiller -configuration Release \
  -destination 'platform=macOS' -derivedDataPath build/DerivedData build
rm -rf "/Applications/CPU Killer.app"
ditto "build/DerivedData/Build/Products/Release/CPU Killer.app" "/Applications/CPU Killer.app"
open "/Applications/CPU Killer.app"
```

## 用法

1. 点菜单栏双环（外环 CPU、内环内存），表出现在图标正下方。
2. 每一行是人话名、整机 CPU%、物理内存%、结束。点 CPU 或内存表头按该列从高到低排。
3. 鼠标停在结束符号上时这一行钉住，刷新不会把你对准的行换掉。再点一下结束。
4. 点表外面关掉。右键图标可开机自启、菜单栏图标不可隐藏；登录自启时静默，不弹设置窗。
5. 开机自启默认关。菜单栏图标不可隐藏；登录自启时静默，不弹设置窗。

## 功能

- 平表，只显示有意义的行，人话名（ChatGPT 就是 ChatGPT，不是 `node`）
- 整机 CPU%（上限 100%）和物理内存%
- 一键结束当前用户的进程；系统进程只展示、不能杀
- 实时刷新，可用开关冻结名单；悬停结束会钉住那一行
- 收起表或冻结名单时，菜单栏双环仍继续更新

## 明确不做

Stats / iStat 那种只看传感器的菜单栏、程序坞图标、桌面进程表工作区、可展开进程树、Mac App Store、沙盒、辅助功能 / 完整磁盘访问、Windows / Linux 客户端。菜单栏图标不可隐藏；登录自启时静默，不弹设置窗。

## 许可证

[MIT](LICENSE)
