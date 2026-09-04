<!-- managed:inherited-agents:start -->
<!-- source: /Users/geraltgraham/Codes/CPUKiller/AGENTS.md -->
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
- **菜单栏应用**：程序坞没有图标，没有常驻桌面进程表工作区。左键打开点开结束的表，表出现在菜单栏图标正下方，点外面关；右键才是开机自启 / 隐藏图标 / 打开主窗口 / 设置 / 检查更新 / 退出。禁止把菜单常挂在状态项上。禁止因拿不到图标坐标而掉到屏幕角落。隐藏菜单栏图标后必须出示带标题栏的轻量恢复窗口（现用设置窗承载）；**进程表不能当恢复面**。
- 表顶有刷新开关，默认开；开关只冻结进程列表，菜单栏双环继续刷新；收起面板不更新进程列表，但双环指标保持独立刷新。鼠标停在某一行的结束符号上时，这一行钉在原位，避免刷新跳动误杀。表头 CPU / 内存列写出整机汇总（如 `CPU 88.8%` `Mem 68.8%`），点对应列在两种从高到低之间切换，没有升序。表头不许留出大块空白。
- 开机自启默认关。不上 App Store。关沙盒。不要申请辅助功能或完整磁盘访问。
- 中英文案。无系统蓝框。分层应用图标 + 菜单栏模板图标。

人话名、整机占比、结束边界的权威说明见产品契约。

## 基线豁免

合法暂缓：

- **A2** 隐私清单：不收集、不上报用户数据。
- **A5** 桌面进程表工作区的位置记忆：不适用。隐藏菜单栏图标所需的轻量恢复窗口不在此豁免内，实施时必须按基线保存并恢复其位置与尺寸。
- **B2** 全局快捷键：唤出不是靠热键，不适用。
- **B3** 账号登录：纯本地工具，无账号。
- **B5** App Intents：第一波没有要交给快捷指令的无人值守动作。
- **B7** 离线优先：无网络数据。

**A1 不再豁免。** 公开仓库的 macOS 图形应用必须具备 Developer ID 签名、公证 dmg、Sparkle 应用内自更新、Homebrew 一键安装。发版走 `app-macos/scripts/publish-release.sh`。

**下列不是豁免，必须过：** A3 中英、A4 无蓝框、A7 分层图标与菜单栏模板、A8 版本双轨、B1 开机自启开关且默认关、关沙盒。禁止用「第一波能编译」覆盖立刻可见条款。禁止再加回桌面进程表工作区；隐藏菜单栏图标所需的轻量恢复窗口例外且必须提供。

## 明确不做

做成 Stats / iStat 那种只看温度没有结束的菜单栏；再加一个桌面进程表工作区或程序坞常驻图标；做成可展开进程树；做成第二个 Corral；上 Mac App Store；开沙盒；申请辅助功能 / 完整磁盘访问；用 Java；做 Windows / Linux 客户端。隐藏菜单栏图标必需的轻量恢复窗口不属于上述禁止范围，且进程表不能当恢复面。

## 文档导航

- [~/.config/agentsync/docs/MACOS_APP_DEVELOPMENT_GUIDE.md](~/.config/agentsync/docs/MACOS_APP_DEVELOPMENT_GUIDE.md)：改、评审或排查 CPU Killer 的菜单栏图标、开机自启动、隐藏图标、恢复窗口或检查更新前**必读**。不读会把隐藏图标后仍需找回应用的恢复面误删，或把菜单栏入口误作进程保活机制。
- [app-macos/AGENTS.md](app-macos/AGENTS.md)：改、评审或排查 macOS 客户端工程、菜单栏浮层、进程表、结束、覆盖安装、公开开源或发版前**必读**。不读会加回桌面进程表工作区、把菜单挂到左键上、开沙盒导致进程表空，覆盖安装把签名装坏，或把内网地址推进公开仓。
- [app-macos/docs/PRODUCT_CONTRACT.md](app-macos/docs/PRODUCT_CONTRACT.md)：改、评审或排查菜单栏图标/模板图、隐藏图标、恢复窗口、开机自启三态或任何其他用户可见行为（人话名折行、名字列过宽、长包名省略、Chrome 显示成 `Goog...rome`、长名字减小字体、前缀省略、中间省略、整机占比、刚开机内存六十多、表头汇总、点列名排序、表出现在图标下方、掉到屏幕角落、结束边界、菜单栏点开/点外面关、刷新开关、表头顶空白、结束符号悬停钉行、检查更新入口、进程表仍显示旧图标/粉底黑叉）前**必读**。不读会把已锁体验改掉、把开机六十当泄漏去改口径、把 ChatGPT/Cursor Agent/Corral 显示回 node/Python、把隐藏图标后的恢复面做成进程表，或把系统还在吐旧图当成图标没装进去去重做。
- [~/Codes/_standards/swift.md](../_standards/swift.md)：新建、评审或改造本 macOS 应用前**必读**。不读会偏离 Swift 6 并发基线和覆盖安装闭环。
- [~/Codes/_standards/workspace-docs/swift-docs/macos-app-baseline.md](../_standards/workspace-docs/swift-docs/macos-app-baseline.md)：脚手架、评审完整度、补分发/开机自启/设置窗前**必读**。不读会把「第一波能跑」当成完成，或把未对外发行的暂缓当成可以永久不做。
- [~/.config/agentsync/docs/MAC_PROCESS_IDENTITY_KNOWLEDGE_BASE.md](~/.config/agentsync/docs/MAC_PROCESS_IDENTITY_KNOWLEDGE_BASE.md)：改人话名、责任进程、整机 CPU%、折行规则前**必读**。不读会做成进程树或按 Unix 父进程建树。

<!-- managed:inherited-agents:end -->

# AGENTS.md

## 2026-09-04 状态栏分区点击：1.0.6 已在本机覆盖安装

v1.0.6 / 内部构建号 17 已覆盖安装进本机「应用程序」并启动，Developer ID 签名校验通过。双环与网速读数的分区点击不许再从全局事件反推位置；必须使用按钮里的透明点击层直接接收本地坐标，状态项宽度与图像一致。双环命中区须覆盖圆环所在的整条横向区域，不得受菜单栏纵向坐标影响；双环只进 CPU / 内存，读数才进网络表；网络表每次打开默认 Download 降序。发布前必须在真实菜单栏验证两个入口。

## 2026-09-04 圆环入口与默认排序：1.0.4 已在本机覆盖安装

v1.0.4 / 内部构建号 15 已覆盖安装进本机「应用程序」并启动。点击实际绘制的双环区域必须只进 CPU / 内存表，不能被状态项的额外点击留白误判成网络表；只有点击上、下行读数才进网络表。网络表不管从哪一行读数打开，都默认按 Download 从高到低排；用户点上行或下行表头时再按该列从高到低排。

## 2026-09-04 网络占用列表：1.0.3 已在本机覆盖安装

v1.0.3 / 内部构建号 14 已覆盖安装进本机「应用程序」并启动，Developer ID 签名校验通过。双环是 CPU / 内存列表入口；上行和下行读数分别打开对应方向排序的网络占用列表。两张列表只有一张浮层，沿用图标、人话名、结束和悬停钉行的边界；网络表只展示上行、下行。网络表按一秒节奏刷新，必须和菜单栏网速读数没有可感知的刷新断层；收起时保留最近有效名单，首次无缓存时必须显示“正在读取网络占用”，禁止白屏或空白面板。

## 2026-09-04 菜单栏网速：1.0.2 已在本机覆盖安装

v1.0.2 / 内部构建号 13 已覆盖安装进本机「应用程序」并启动。双环和右侧网速块共用菜单栏中间的 17pt 画布，上下各留 2.5pt；圆环与网速块维持约 6% 的整体放大。上面永远是上行和 `↑`，下面永远是下行和 `↓`；这一映射不随字号、数值、单位或布局改变。发生上下颠倒时只能修正纵向坐标锚点：上行贴高边、下行贴低边；禁止交换读数或箭头。网速块内，较快方向的数字和单位使用 9.5pt 大号字，较慢方向使用 7.5pt 小号字；箭头始终使用 8.5pt 基准尺寸与位置，上下相等或任一行无读数时两行恢复 8.5pt。每次绘制都按本帧数字、单位和箭头的实际字形边界分别锚定上下两行：上行字形贴齐画布上缘，下行字形贴齐画布下缘，让网速块与双环同高同中线；禁止改回固定像素偏移、只对齐行框或只做整块居中。两行之间不额外留隙，不能再靠压缩行距放大。单位统一右对齐，数字紧贴各自单位左侧；禁止把两行数字强行右对齐。数字右侧、箭头左侧的单位在两行完整重复，箭头位于最右列并对齐；字号变化只能向左侧伸缩，数字随本行单位贴合。两行单位取当次上下行中量级更大者，必须完全一致；较小读数不足一个共同单位时显示 `<1`，不夸大成 `1`。默认出口切换时先清空并重取基线，不能把多个接口相加；右键「显示网速」默认开、会记住选择，关掉只收起两行读数。30 项自动检查、正式构建和 Developer ID 签名校验已通过。用户尚未批准发布：本轮没有提交、推送或对外发版。菜单栏应用没有普通窗口可供自动化截图，真实状态栏呈现须以系统菜单栏目视为准。

数字贴在本行单位左侧时必须保留固定 2pt 的细小阅读间隔；这是排版规则，不可拿来补偿对齐，禁止数字与单位粘连。

## 2026-09-01 菜单栏专项：1.0.1 已在本机覆盖安装

v1.0.1 / 内部构建号 12 已装进本机「应用程序」。菜单栏双环在；左键打开的是进程表不是菜单；设置窗是带标题栏的恢复面（状态说明、开机自启、显示图标），进程表不是恢复面。本机开机自启开关当时是开——系统已真正启用，不是待批准假开（待批准会出现橙色说明和「打开登录项」）。锁屏未测。合成右键点图标会被当成左键（拿不到当前事件就开进程表），右键六条菜单以安装包英文案 + 源码接线为准，未做条目级点选。

通用工程规范：本机 Swift 规范（`~/Codes/_standards/swift.md`）。

本仓库是 CPU Killer 的 macOS 客户端。产品级约定见上级 [../AGENTS.md](../AGENTS.md)。用户可见行为以 [docs/PRODUCT_CONTRACT.md](docs/PRODUCT_CONTRACT.md) 为准。

## 工程源

- [`project.yml`](project.yml) 是 Xcode 工程的唯一来源。不要手改 `CPUKiller.xcodeproj`。
- 增删源文件或改构建设置后必须先 `xcodegen generate` 再构建。
- `Assets.xcassets` 与 `Localizable.xcstrings` 必须留在 sources 里随编译打进包，不要再 exclude 后当 resources 拷——xcodegen 那样拷会丢，窗口标题会显示键名。字符串目录必须带 `"version": "1.0"`。
- Bundle ID：`top.caozc.CPUKiller`。展示名：CPU Killer。版本双轨在 `Configuration/Base.xcconfig` 与 `project.yml`，发版脚本会比对并拦截不一致。
- 公开 GitHub：`x0c/CPUKiller`。许可证 MIT。Homebrew cask：`x0c/tap` 的 `cpu-killer`。

## 钉死的实现约束

- **这是菜单栏应用。** 必须 `LSUIElement`。禁止加桌面进程表工作区、禁止程序坞常驻图标；隐藏菜单栏图标时必须有独立轻量恢复窗口。设置窗用独立小窗，打开时临时切到普通激活，关掉改回附件。
- **关掉设置窗不退出。** `applicationShouldTerminateAfterLastWindowClosed` 返回 false。退出只走用户点的「退出」→ `requestTermination`。Sparkle 正在安装更新时必须放行终止，否则更新装不上。
- **关沙盒。** entitlements 空 dict。开沙盒进程表会空。不要申请辅助功能或完整磁盘访问。
- **禁止把菜单挂到状态项上。** 左键打开表；右键才弹开机自启 / 隐藏图标 / 打开主窗口 / 设置 / 检查更新 / 退出。左键赋了 `statusItem.menu` 会变成弹菜单，结束路径就没了。
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
- **开机自启默认关**，用登录项三态；待批准不能显示成已开启，并引导去系统设置登录项。
- **隐藏菜单栏图标**后必须出示恢复窗（设置窗），禁止用进程表当恢复面。再次打开若图标已隐藏必须把恢复窗带到前面。藏图标触发的系统退出必须拦住；Sparkle 正在安装更新时放行。
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

脚本会跳过 git 钩子，发版前必须按公开仓档做泄漏扫描（`leakgate.py scan --profile public`）。origin 是私有镜像时默认不会按公开仓拦截内网地址。

推公开仓快照若远程断开：本地已公证的安装包和更新清单仍可用，从快照推送 / 发行页 / 一键安装配方续跑，**禁止因此重新公证**。配方写入须防版本回退。

Debug 测试目标默认不绑主线程；应用里给测试读的常量袋必须标成不绑线程，否则测试编不过。

首次安装渠道：GitHub Release 的公证 dmg 与 Homebrew（`brew tap x0c/tap && brew install --cask cpu-killer`）；自动更新源为仓库根 `appcast.xml`。GitHub 发行页必须先建空再传安装包——一条命令带附件会在上传接口返回 404。

开源门面对标：Stats（首屏真实界面图、Homebrew、dmg 直链）；本机 NeatPaste（双语 README、Sparkle、共用 `x0c/tap`、一条命令发版）。不抄 Stats 的长 FAQ，不在安装说明里教用户绕过系统保护。

## 基线豁免

见上级产品 `AGENTS.md`。A1 已具备，不再暂缓。A3、A4、A7、A8、B1、关沙盒不是豁免。桌面进程表工作区不适用 A5，但隐藏图标所需的恢复窗口必须按 A5 保存位置与尺寸。

## 文档导航

- [docs/design/APP_ICON_EXPLORATION.md](docs/design/APP_ICON_EXPLORATION.md)：重新设计、选择、精绘、接入应用图标，或排查进程表 / Finder 仍显示旧图标（粉底黑叉）前**必读**。不读会把九宫格探索稿当终稿，覆盖当前母版与菜单栏模板，或把系统还在吐旧图误判成母版没换。
- [docs/PRODUCT_CONTRACT.md](docs/PRODUCT_CONTRACT.md)：改、评审或排查菜单栏图标/模板图、两行网速、自动识别当前网卡、隐藏图标、恢复窗口、开机自启三态或任何其他用户可见行为（人话名折行、名字列过宽、长包名省略、Chrome 显示成 `Goog...rome`、长名字减小字体、前缀省略、中间省略、整机占比、刚开机内存六十多、表头汇总、点列名排序、表出现在图标下方、掉到屏幕角落、结束边界、刷新开关、表头顶空白、结束符号悬停钉行、检查更新入口、进程表仍显示旧图标/粉底黑叉）前**必读**。不读会把网速算到错误网卡上、把 ChatGPT 拆成一堆 node、把开机六十当泄漏去改口径、把 Cursor Agent 折进 Cursor.app、把隐藏图标后的恢复面做成进程表，或把系统还在吐旧图当成图标没装进去去重做。
- 本机 overlay / 玻璃 / 图标 / 本地化 / 设置项配方在 `~/Codes/_standards/workspace-docs/swift-docs/`，改对应能力前必读。不读会把三种浮层混用、把列表做成玻璃、再补扁平切图、或把键名显示给用户。
- 本机进程身份识别知识库：`~/.config/agentsync/docs/MAC_PROCESS_IDENTITY_KNOWLEDGE_BASE.md`。改身份识别或 CPU 口径前**必读**。
- [docs/PROCESS_MONITORING_AND_TERMINATION_KNOWLEDGE_BASE.md](docs/PROCESS_MONITORING_AND_TERMINATION_KNOWLEDGE_BASE.md)：改、评审或排查实时占用、人话名、排序、刷新、结束权限或终止流程前**必读**。不读会把整机口径、平表聚合或安全结束边界改错。
- [docs/MENU_BAR_INTERACTION_KNOWLEDGE_BASE.md](docs/MENU_BAR_INTERACTION_KNOWLEDGE_BASE.md)：改、评审或排查菜单栏左右键、浮层锚定、网速、隐藏图标、恢复窗口、开机自启或退出前**必读**。不读会让左键误弹菜单、面板掉到角落或隐藏后无稳定入口。
- [docs/DISTRIBUTION_AND_UPDATE_KNOWLEDGE_BASE.md](docs/DISTRIBUTION_AND_UPDATE_KNOWLEDGE_BASE.md)：改、评审或排查构建、签名、公证、应用内更新、GitHub Release 或 Homebrew 前**必读**。不读会把工程源、版本、签名链或公开发行边界改坏。
- [docs/OPERATIONS_GUIDE.md](docs/OPERATIONS_GUIDE.md)：构建、测试、启动、覆盖安装或排查本机开发环境前**必读**。不读会在错误仓根构建、误把测试通过当安装验收，或覆盖错误版本。

## 领域地图（doc-init）

<!-- 覆盖度复核基线：2026-09-04 · 源码指纹 扫描 137 文件 / Swift 28 / 0 子模块 · 基线提交 f2830e8 -->

| 领域 | 入口锚点 |
|------|---------|
| 实时占用与结束 | CPUKiller/Services/ · CPUKiller/Models/ · CPUKiller/Views/ProcessTableView.swift · CPUKiller/Views/ProcessRowView.swift · CPUKillerTests/ProcessTableRankingTests.swift |
| 菜单栏操作与恢复 | CPUKiller/AppDelegate.swift · CPUKiller/StatusItem/ · CPUKiller/App/ · CPUKiller/Views/SettingsView.swift |
| 安装、更新与公开发布 | project.yml · Configuration/Base.xcconfig · scripts/publish-release.sh · appcast.xml |
