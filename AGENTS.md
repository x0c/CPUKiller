<!-- managed:inherited-agents:start -->
<!-- source: ../AGENTS.md -->
# CPU Killer

通用工程规范：[Swift 规范](../_standards/swift.md)

CPU Killer 是本机极简进程表：卡的时候一眼看到是谁占满整机 CPU，并立刻结束。小学生一看名字就知道干什么。

## 组件一览

| 目录 | 说明 | 状态 |
|---|---|---|
| `app-macos/` | macOS 客户端（独立 git 仓库） | 已交付，已公开开源 |

Remote：`app-macos` → GitHub 公开 [`x0c/CPUKiller`](https://github.com/x0c/CPUKiller)；Forgejo 私有镜像只留在本机 `git remote origin`，**禁止**把内网地址写进仓库。本产品文件夹不是 git 仓库。

**【裁定 2026-08-30】** 面向公众开源到 GitHub `x0c/CPUKiller`。许可证 MIT。只支持 macOS（绑定本机进程身份、菜单栏与结束 API）。第一次公开发布就必须带齐签名公证安装包、应用内自更新、一键安装，不允许「先公开源码、发行以后再补」。更新清单和安装包发在源码仓自己的 Release，禁止另建更新仓。公开仓用当前树的干净快照历史，不要把私有开发史上的内网地址推上去。

## 钉死的体验

- 名字就是 **CPU Killer**，不要再换成谜语名。
- 极简平表：图标、人话名、整机 CPU%、内存%、结束。不要进程树，不要展开孩子。
- **菜单栏应用**：程序坞没有图标，没有桌面主窗口。左键打开点开结束的表，表出现在菜单栏图标正下方，点外面关；右键才是设置 / 检查更新 / 退出。禁止把菜单常挂在状态项上。禁止因拿不到图标坐标而掉到屏幕角落。
- 表顶有刷新开关，默认开；开关只冻结进程列表，菜单栏双环继续刷新；收起面板不更新进程列表，但双环指标保持独立刷新。鼠标停在某一行的结束符号上时，这一行钉在原位，避免刷新跳动误杀。表头 CPU / 内存列写出整机汇总（如 `CPU 88.8%` `Mem 68.8%`），点对应列在两种从高到低之间切换，没有升序。表头不许留出大块空白。
- 开机自启默认关。不上 App Store。关沙盒。不要申请辅助功能或完整磁盘访问。
- 中英文案。无系统蓝框。分层应用图标 + 菜单栏模板图标。

人话名、整机占比、结束边界的权威说明见产品契约。

## 基线豁免

合法暂缓：

- **A2** 隐私清单：不收集、不上报用户数据。
- **A5** 主窗口位置记忆：没有桌面主窗口，不适用。设置窗每次居中打开即可。
- **B2** 全局快捷键：唤出不是靠热键，不适用。
- **B3** 账号登录：纯本地工具，无账号。
- **B5** App Intents：第一波没有要交给快捷指令的无人值守动作。
- **B7** 离线优先：无网络数据。

**A1 不再豁免。** 公开仓库的 macOS 图形应用必须具备 Developer ID 签名、公证 dmg、Sparkle 应用内自更新、Homebrew 一键安装。发版走 `app-macos/scripts/publish-release.sh`。

**下列不是豁免，必须过：** A3 中英、A4 无蓝框、A7 分层图标与菜单栏模板、A8 版本双轨、B1 开机自启开关且默认关、关沙盒。禁止用「第一波能编译」覆盖立刻可见条款。禁止再加回桌面主窗口。

## 明确不做

做成 Stats / iStat 那种只看温度没有结束的菜单栏；再加一个桌面主窗口或程序坞常驻图标；做成可展开进程树；做成第二个 Corral；上 Mac App Store；开沙盒；申请辅助功能 / 完整磁盘访问；用 Java；做 Windows / Linux 客户端。

## 文档导航

- [app-macos/AGENTS.md](app-macos/AGENTS.md)：改、评审或排查 macOS 客户端工程、菜单栏浮层、进程表、结束、覆盖安装、公开开源或发版前**必读**。不读会加回桌面主窗口、把菜单挂到左键上、开沙盒导致进程表空，覆盖安装把签名装坏，或把内网地址推进公开仓。
- [app-macos/docs/PRODUCT_CONTRACT.md](app-macos/docs/PRODUCT_CONTRACT.md)：改、评审或排查菜单栏图标/模板图或任何其他用户可见行为（人话名折行、名字列过宽、长包名省略、整机占比、刚开机内存六十多、表头汇总、点列名排序、表出现在图标下方、掉到屏幕角落、结束边界、菜单栏点开/点外面关、刷新开关、表头顶空白、结束符号悬停钉行、检查更新入口）前**必读**。不读会把已锁体验改掉、把开机六十当泄漏去改口径，或把 ChatGPT/Cursor Agent/Corral 显示回 node/Python。
- [~/Codes/_standards/swift.md](../_standards/swift.md)：新建、评审或改造本 macOS 应用前**必读**。不读会偏离 Swift 6 并发基线和覆盖安装闭环。
- [~/Codes/_standards/workspace-docs/swift-docs/macos-app-baseline.md](../_standards/workspace-docs/swift-docs/macos-app-baseline.md)：脚手架、评审完整度、补分发/开机自启/设置窗前**必读**。不读会把「第一波能跑」当成完成，或把未对外发行的暂缓当成可以永久不做。
- [~/.config/agentsync/docs/MAC_PROCESS_IDENTITY_KNOWLEDGE_BASE.md](~/.config/agentsync/docs/MAC_PROCESS_IDENTITY_KNOWLEDGE_BASE.md)：改人话名、责任进程、整机 CPU%、折行规则前**必读**。不读会做成进程树或按 Unix 父进程建树。

<!-- managed:inherited-agents:end -->

# AGENTS.md

通用工程规范：本机 Swift 规范（`~/Codes/_standards/swift.md`）。

本仓库是 CPU Killer 的 macOS 客户端。产品级约定见上级 [../AGENTS.md](../AGENTS.md)。用户可见行为以 [docs/PRODUCT_CONTRACT.md](docs/PRODUCT_CONTRACT.md) 为准。

## 工程源

- [`project.yml`](project.yml) 是 Xcode 工程的唯一来源。不要手改 `CPUKiller.xcodeproj`。
- 增删源文件或改构建设置后必须先 `xcodegen generate` 再构建。
- `Assets.xcassets` 与 `Localizable.xcstrings` 必须留在 sources 里随编译打进包，不要再 exclude 后当 resources 拷——xcodegen 那样拷会丢，窗口标题会显示键名。字符串目录必须带 `"version": "1.0"`。
- Bundle ID：`top.caozc.CPUKiller`。展示名：CPU Killer。版本双轨在 `Configuration/Base.xcconfig` 与 `project.yml`，发版脚本会比对并拦截不一致。
- 公开 GitHub：`x0c/CPUKiller`。许可证 MIT。Homebrew cask：`x0c/tap` 的 `cpu-killer`。

## 钉死的实现约束

- **这是菜单栏应用。** 必须 `LSUIElement`。禁止再加桌面主窗口、禁止程序坞常驻图标。设置窗用独立小窗，打开时临时切到普通激活，关掉改回附件。
- **关掉设置窗不退出。** `applicationShouldTerminateAfterLastWindowClosed` 返回 false。退出只走用户点的「退出」→ `requestTermination`。Sparkle 正在安装更新时必须放行终止，否则更新装不上。
- **关沙盒。** entitlements 空 dict。开沙盒进程表会空。不要申请辅助功能或完整磁盘访问。
- **禁止把菜单挂到状态项上。** 左键打开表；右键才弹「设置 / 检查更新 / 退出」。左键赋了 `statusItem.menu` 会变成弹菜单，结束路径就没了。
- **菜单栏浮层是唤出工具（形态 1）。** 点面板外立刻关；点面板内、本菜单栏图标不关。不能靠失焦关窗。列表是内容层，不要玻璃；外框可以通透玻璃。根视图必须忽略标题栏安全区，禁止再出现巨大空白表头。**表必须锚在菜单栏图标正下方。** 图标坐标宽高为 0、或不在屏幕顶上菜单栏带里，一律当没拿到，禁止用这种假位置把表放到左下角。拿不到就等一拍再打开。
- **刷新开关默认开。** 开关只冻结进程列表；菜单栏双环和表头汇总继续刷新。收起面板不更新进程列表，但双环指标保持独立刷新。不要在 `ProcessTableView` 一创建就开刷。
- **结束符号悬停钉行。** 鼠标停在结束符号上时，这一行钉在原位，占用数字可原位更新；不要因此把整张表冻住（整表冻结走刷新开关）。悬停期间这一行没了立刻解除钉死。钉死只针对结束符号，停在名字或占用数字上名单照常跳。
- **表头汇总与点列排序。** CPU / 内存列名写成 `CPU 88.8%` / `Mem 68.8%`（中文内存列为 `内存`），数字与双环同一口径：CPU 用各行人话行加总上限 100%，内存读系统级物理占用，禁止把内存行相加。点 CPU 或内存列按该列从高到低排，没有升序；默认 CPU 从高到低；名字/结束列不可点来排序。
- **列表永远是平的。** 禁止进程树、禁止展开孩子。同一桌面应用底下的助手折进该应用那一行并加总。Cursor.app 对从它拉起的外部命令按终端处理，独立工具不折进 Cursor 那一行。
- **人话名优先读启动参数，不要用解释器短名。** 责任进程用 `dlsym("responsibility_get_pid_responsible_for_pid")`，失败再退回包路径。不要 Endpoint Security。参数按 pid+启动时刻缓存，进程出现时读一次，禁止每秒重读。
- **CPU 是整机占比，上限 100%。** 两次采样 Δ(user+system) / (墙钟秒 × 逻辑核数) × 100。Apple Silicon 上 `pti_total_user/system` 是 mach ticks，必须乘 timebase（原生约 125/3，htop FB9546856）；禁止只换墙钟、不换进程时间。
- **内存是物理占用账本 / 物理内存 ×100**，不要 resident。列表行与菜单栏内环分别取进程级和系统级统计，禁止把列表行相加。
- **CPU 外环只接受有效的前后两次样本。** 进程刚出现、刚退出或系统瞬时读不到 CPU 时保留上一帧，不能闪成空环；真实 0% 仍显示为空环。
- **结束：** `.app` 用 `NSRunningApplication.terminate` 再 `forceTerminate`；解释器用 SIGTERM 再 SIGKILL。只结束当前用户进程；别人的只展示。系统进程禁止一键杀。结束 ChatGPT 这一行等于结束它拉的电脑操控；结束 Corral 不杀 tmux 保活里的助手；结束某个 Cursor Agent 只杀那一只。WindowServer 这类系统进程的 argv0 常等于短名，禁止当成「具名工具」放开结束。
- **无系统蓝框**，可键盘处补自有焦点态。
- **开机自启默认关**，用 `SMAppService.mainApp`；待批准不能显示成已开启。
- **公开仓脱敏。** 禁止把内网地址、本机绝对用户路径写进将推到 GitHub 的文件。GitHub 用当前树的干净快照，不要把私有开发史原样推上去。

## 构建与覆盖安装

固定 derivedData，先删旧包再整包复制：

```bash
xcodegen generate
xcodebuild -project CPUKiller.xcodeproj -scheme CPUKiller -configuration Release \
  -derivedDataPath build/DerivedData -destination 'platform=macOS' build
rm -rf "/Applications/CPU Killer.app"
ditto "build/DerivedData/Build/Products/Release/CPU Killer.app" "/Applications/CPU Killer.app"
xattr -dr com.apple.quarantine "/Applications/CPU Killer.app" 2>/dev/null || true
open "/Applications/CPU Killer.app"
```

覆盖安装若需要管理员密码：先做免密探测；失败立刻停，禁止弹出图形授权窗口。

对外发版（签名公证 dmg + Sparkle 更新包 + GitHub Release + appcast + Homebrew，一条命令、可重复执行；`--local-only` 只产本地公证包不碰远端）：

```bash
scripts/publish-release.sh
```

首次安装渠道：GitHub Release 的公证 dmg 与 Homebrew（`brew tap x0c/tap && brew install --cask cpu-killer`）；自动更新源为仓库根 `appcast.xml`。

开源门面对标：Stats（首屏真实界面图、Homebrew、dmg 直链）；本机 NeatPaste（双语 README、Sparkle、共用 `x0c/tap`、一条命令发版）。不抄 Stats 的长 FAQ，不在安装说明里教用户绕过系统保护。

## 基线豁免

见上级产品 `AGENTS.md`。A1 已具备，不再暂缓。A3、A4、A7、A8、B1、关沙盒不是豁免。A5 因没有桌面主窗口而豁免。

## 文档导航

- [docs/design/APP_ICON_EXPLORATION.md](docs/design/APP_ICON_EXPLORATION.md)：重新设计、选择、精绘或接入应用图标前**必读**。不读会把九宫格探索稿当终稿，或覆盖当前母版与菜单栏模板。
- [docs/PRODUCT_CONTRACT.md](docs/PRODUCT_CONTRACT.md)：改、评审或排查菜单栏图标/模板图或任何其他用户可见行为（人话名折行、名字列过宽、长包名省略、整机占比、刚开机内存六十多、表头汇总、点列名排序、表出现在图标下方、掉到屏幕角落、结束边界、刷新开关、表头顶空白、结束符号悬停钉行、检查更新入口）前**必读**。不读会把 ChatGPT 拆成一堆 node、把开机六十当泄漏去改口径，或把 Cursor Agent 折进 Cursor.app。
- 本机 overlay / 玻璃 / 图标 / 本地化 / 设置项配方在 `~/Codes/_standards/workspace-docs/swift-docs/`，改对应能力前必读。不读会把三种浮层混用、把列表做成玻璃、再补扁平切图、或把键名显示给用户。
- 本机进程身份识别知识库：`~/.config/agentsync/docs/MAC_PROCESS_IDENTITY_KNOWLEDGE_BASE.md`。改身份识别或 CPU 口径前**必读**。
