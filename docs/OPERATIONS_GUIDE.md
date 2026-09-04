# 本地构建与验证 Guide

## 文档定位

本 Guide 只覆盖 CPU Killer 的本地工程生成、构建、测试、覆盖安装与基础运行确认。不定义进程识别、菜单栏交互或发布渠道的产品规则；这些分别由对应领域知识库和产品契约负责。

## 验证结论摘要

本次文档初始化已在 `app-macos/` 运行完整测试：

```bash
xcodebuild -project CPUKiller.xcodeproj -scheme CPUKiller -destination 'platform=macOS' -derivedDataPath /tmp/cpu-killer-doc-init-derived-data test
```

结果：2026-09-04 在本机 arm64 macOS 目标通过 31 项测试，0 失败、0 跳过。该结论只证明当前工作树能构建并通过自动测试；没有替代实际安装版的菜单栏视觉、结束动作、签名、公证或在线更新验收。

## 本地启动前检查

- 实际 Git 仓是 `app-macos/`；外层 CPUKiller 目录不是 Git 工作树。
- `project.yml` 是 Xcode 工程唯一来源。修改源文件清单、资源或构建设置后，必须先执行 `xcodegen generate`，不要手改 `CPUKiller.xcodeproj`。
- 使用 macOS 与 Xcode 的本地 Swift 工具链。构建会解析 Sparkle 与 MacKit 包；没有网络缓存时需要可用的包下载环境。
- 版本、签名与公开发行的额外前提见 [安装、更新与公开发布领域知识库](DISTRIBUTION_AND_UPDATE_KNOWLEDGE_BASE.md)。

## 构建与测试命令

在 `app-macos/` 执行：

```bash
xcodegen generate
xcodebuild -project CPUKiller.xcodeproj -scheme CPUKiller -configuration Release \
  -destination 'platform=macOS' -derivedDataPath build/DerivedData build
```

普通回归测试可用独立派生目录，避免污染正在使用的构建结果：

```bash
xcodebuild -project CPUKiller.xcodeproj -scheme CPUKiller \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/cpu-killer-derived-data test
```

只验证一个领域时，优先使用该知识库给出的定向测试；改变菜单栏、进程表或网速后，仍要运行受影响的完整测试组。

## 本机启动与覆盖安装

Release 构建成功后，应用产物位于：

```text
build/DerivedData/Build/Products/Release/CPU Killer.app
```

仅在“应用程序”目录可无交互写入时，才可以整包替换并启动：

```bash
rm -rf '/Applications/CPU Killer.app'
ditto 'build/DerivedData/Build/Products/Release/CPU Killer.app' '/Applications/CPU Killer.app'
open '/Applications/CPU Killer.app'
```

若系统要求管理员授权，停止，不要弹出图形授权。不能用 Debug 或临时签名产物覆盖 Developer ID 安装版。

## 存活与用户可见验证

- 自动测试：以 `xcodebuild test` 的 XCTest 结果为准；本次为 31/31 通过。
- 启动后：确认菜单栏出现双环；左键出现图标正下方的进程表；右键才出现设置、图标显示、开机自启、检查更新与退出选项。
- 视觉、真实结束、覆盖安装版本与更新链路必须按相关领域知识库在每次影响改动后重新实测；仅看到进程存在或测试通过不算用户可见验收。

## 常见启动失败信号

| 现象 | 优先检查 | 下一步 |
|---|---|---|
| 工程与源码/资源不同步 | 是否改过 `project.yml` 却没有重新生成工程 | 运行 `xcodegen generate` 后重新构建。 |
| 测试或构建使用了陈旧中间产物 | 派生目录是否和并行构建共用 | 改用独立 `-derivedDataPath` 重新执行。 |
| 安装后看见旧图标或旧版本 | 是否只覆盖了包内文件而非整包替换 | 删除旧应用后完整复制，再重新启动相关应用。 |
| 菜单栏应用似乎“消失” | 图标是否被隐藏、恢复窗口是否出现 | 从应用程序或 Spotlight 再次打开，确认恢复窗口可找回图标。 |

## 未确认项

- 本次没有执行 Release 签名、公证、DMG、GitHub Release、Homebrew 或在线更新验证；这些必须由发行流程按当次版本重新核验。
- 本次没有对实际安装版截屏或结束真实进程；菜单栏视觉和结束安全验收仍须在影响相关行为的改动后完成。

<!-- 该文档由 doc-init 生成于 2026-09-04；定位：本地构建、测试、启动和覆盖安装的快速参考。 -->
