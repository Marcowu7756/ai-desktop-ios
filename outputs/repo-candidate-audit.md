# iOS AI Companion — 开源候选只读审计

审计日期：2026-09-23 ｜ 审计范围：ExperimentalAlice / Miru / mobileLLM / ManifoldKit / FoundationBuddy / Herald

审计性质：**只读**。未 clone、未 fork、未修改任何外部仓库。全部数据来自 GitHub API、仓库 README、源码文件与 Xcode 工程文件。

---

## 0. 结论先行

六个候选里，**没有任何一个可以直接当"基底壳"**。

- 唯一够格作为**依赖型底座**的是 **ManifoldKit**（Brain / 推理运行时层）。
- 唯一**完整实现我们要的 State 模式**的是 ExperimentalAlice，但它只有 2 天生命、0 用户、1 位作者，只能抄设计，不能当地基。
- Miru 的 iOS 端不存在；FoundationBuddy 已停更 14 个月；Herald 无法验证身份。

简报里"先找现成开源底座、不自研"这个前提，在事实层面站不住。**结论修正为：不自研的是推理运行时（用 ManifoldKit），必须自研的是 Shell / Persona / State / Surfaces。**

---

## 1. 审计方法与一条硬限制

**方法**：GitHub REST API 读取仓库元数据（许可、活跃度、社区规模）→ raw 读取 README 与关键源码 → 读取 `project.pbxproj` 确认部署目标 → 递归读取 git tree 统计关键模块是否存在。

**硬限制（必须先说）**：当前环境是 Windows，没有 Xcode 26、没有 macOS SDK。

因此矩阵中的 **"可构建性"只能给出"声明要求"与 CI 证据，不等于实测通过**。任何"这个项目能编译"的判断，都必须由你在 Mac 上跑一次复核。我没有把未实测的东西写成已实测。

---

## 2. 事实矩阵（2026-09-23 实测）

| 候选 | 性质 | 语言 / 平台 | 许可 | 最后 push | ★ / fork | 可构建性证据 | Persona·动画 | 后端可替换性 | Memory | Voice | 权限边界 | 改造成本 | 判定 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ExperimentalAlice** | 完整 App（单角色） | Swift / SwiftUI，iOS **26.0** | MIT | 2026-08-31 | **0 / 0** | 无 CI；Xcode 26 + iOS 26；README 给 CLI 命令 | ⚠️ 有结构化 turn + rig 契约，但**无 Live2D 运行时**，仅 1 张平面 PNG | ❌ 无 backend 协议；FoundationModels + Kimi REST + xAI TTS 硬编码 | ✅ 类型化 + 会话摘要 + affinity | ✅ 系统 TTS + xAI | ✅ 工具需确认（alarm/reminder/calendar/email/Shortcuts） | **低，但会继承一个 0 用户的实验** | 只做**参考实现** |
| **Miru** | 自托管服务 + 多端壳 | **Python/Flask**；macOS / Windows / Android | Apache-2.0 | 2026-09-10 | **160 / 20** | 无 iOS 目标 | ✅ Live2D 桌宠 + AttentionEngine | ✅ 任意 OpenAI 兼容（三层模型） | ✅ Markdown 可审计 + journal + soul.md | ❌ | ✅ 屏幕感知可完全关闭 | **不可复用（非 iOS）** | **架构参考**，非候选 |
| **mobileLLM** | Agent 聊天 App | Swift / SwiftUI；iOS 17+（弱链接）· macOS | MIT（LICENSE 文件确认） | 2026-09-06 | 6 / 4 | 有 CI；200 commits；iOS 17 起可跑 | ❌ 全仓库 0 处 Persona/Companion/Character/Animation | ✅ 三引擎一个 `LLMEngine` 协议 + OpenAI 兼容 | ✅ 可读可改 | ✅ 听写 | ✅ `prepare→authorize→execute` 能力上限 + 审批 | 中（要拆掉聊天 UI） | **运行时参考** |
| **ManifoldKit** | **SwiftPM 库**（非 App） | Swift 6.1 / SwiftUI；iOS 26+ · macOS 26+ | MIT | **2026-09-22** | 8 / 1 | ✅ CI + DocC + 版本发布 **v0.79.0（09-20）** + 37 open issues | ❌（不是它的职责） | ✅ `InferenceBackend`：Foundation / OpenAI / Anthropic / Ollama / MLX / llama.cpp | ⚠️ SwiftData 会话持久化，非 companion memory | ❌ | ⚠️ 需自查 | **低（它就是用来被依赖的）** | ✅ **唯一底座候选** |
| **FoundationBuddy** | App 演示 | Swift / SwiftUI，iOS 26+ | MIT | **2025-07-16** | 7 / 0 | 无 CI | ❌ 无 | ❌ | ❌ | ❌ | ❌ | 低但无价值 | ❌ **淘汰** |
| **Herald** | 身份未确认 | — | — | — | — | — | — | — | — | — | — | — | ❓ **无法验证** |

---

## 3. 与简报不符的事实（必须纠正的 6 处）

**① ExperimentalAlice 的 Live2D 不是"接口"，是一份 DIY 教程。**

README 明确写着仓库只提供一张平面 PNG，`AliceCharacterView` 只做呼吸和说话抬升；"articulated eyes, mouth, hair, arms, and poses require a layered model created with Live2D Cubism Editor and a runtime integration"——后面是 5 步手工接入指引。而且 Cubism SDK **不在 MIT 覆盖范围内**，需另循 Live2D 商业许可，README 自己声明了这一点（Miru 同样把 Live2D 组件排除在 Apache-2.0 之外）。

简报里的 "Live2D Cubism 接口" 应改写为 "**Cubism 接入文档 + 未接完的 rig 契约**"。

**② ExperimentalAlice 是两天大的实验，不是"现成壳"。**

created 2026-08-30，最后一次 push 2026-08-31，**1 位贡献者、约 11 个 commit、0 star、0 fork**。作者自述 "I just vibe coded an attempt"，并承认当前动作会 "deformate the character's body"。它不是"接近目标所以能直接用"，而是"接近目标因为只做了我们最想做的那个模式"。

**③ 但它的核心设计确实是我们要的——这是本次审计最大的正收益。**

`CompanionTurn.swift` 用 `@Generable` 定义了一个**先于语音提交的结构化 turn**，字段顺序为：

```
mood / gaze / gesture  →  speech  →  remember（可选）
```

源码注释原文：*"The order of these fields is intentional. Foundation Models emits the earliest stable fields first, so the face and pose can commit before Alice has a complete sentence to say."*

配合 `AliceRigContract.swift` 里与 AI 完全解耦的 `AliceCharacterControlState`（mood / pose / expression / mouthOpenAmount / bodyImpulse / reduceMotion），**"AI 不直接控制动画，而是结构化输出 → 确定性 mapper → 角色状态"这条原则，它已经实现了**。

→ 结论：**这套模式照搬，代码不要照搬。**

**④ ExperimentalAlice 的云端后端不可替换。**

它没有 backend 抽象协议，是 FoundationModels + `AliceKimiBrain`（Moonshot）+ `AliceCloudVoice`（xAI TTS）三条硬编码路径。简报里"可选云端模型"成立，但"AI backend 可替换性"这一项**不合格**。真正可替换的是 mobileLLM 的 `LLMEngine` 和 ManifoldKit 的 `InferenceBackend`。

**⑤ Miru 没有 iOS 端，它是 Python。**

仓库语言是 Python/Flask，发布物是 macOS dmg / Windows exe / Android apk / Linux 服务镜像。README 的 roadmap 里 `iOS client` 是一个**未勾选的方框**。它可以整体作为"长期 Companion + 记忆 + 主动性"的**架构范本**（可审计 Markdown 记忆、AttentionEngine、soul.md、三层模型），但对 iOS 项目**零代码可复用**。

**⑥ FoundationBuddy 不是"很新"，是"很旧且已停更"。**

created **2025-07-16**，最后一次 push **同一天 23:05**，此后 14 个月无任何提交，7 star、0 fork、无 CI。简报的"很新"判断有误。→ **淘汰**。

**附加发现**：ExperimentalAlice 和 mobileLLM 的仓库树里，`Widget` / `LiveActivity` 的出现次数**都是 0**。

→ 你架构图里的 **iOS Surfaces（Widget / Live Activity / Notification）在六个候选里全部是空白**。这一层没有任何现成可借的东西，是纯新增工作量，也是本项目真正的差异化所在。

---

## 4. 无法验证的候选：Herald

简报把 Herald 列入候选，但**我无法把它解析到任何一个真实的 iOS AI companion 仓库**。GitHub 上名为 Herald 的相关结果只有两个，均不匹配：

- `yalongwastaken/herald` — RPi5 上的本地 voice → LLM → MQTT 命令分发，与 iOS 无关。
- `hypafrag/herald-companion-ios` — 2018 年创建的 Objective-C 仓库，0 star、无描述、无许可、334 KB。

**处理建议**：请提供 Herald 的准确 URL；否则从候选名单移除，不要让一个身份不明的名字占据审计位。

---

## 5. 基底候选选择

### 唯一选择：**ManifoldKit**

理由（按权重排序）：

1. **它是唯一"设计上就用来被依赖"的候选。** SwiftPM 库、语义化版本（v0.79.0）、CI、DocC、明确要求的 `InferenceBackend` 协议。改造 = 加一行依赖，而不是 fork 别人的 App。
2. **活跃度和工程纪律最好。** 2026-09-22 仍在提交，有版本发布和 37 个公开 issue——issue 多在这里是**信任信号**（说明有人在用、有反馈闭环），不是质量差的证据。
3. **后端可替换性满分。** Foundation Models / OpenAI / Anthropic / Ollama / MLX / llama.cpp / MCP / RAG 全在一个协议后。这正好承载你架构里的 **Brain** 层，并把"Brain 可换"从口号变成编译期事实。
4. **许可干净**：MIT，无 Live2D 类附加条款。

### 反选说明：为什么不选 ExperimentalAlice 当地基

它**模式最对、身体最弱**。把它当基底意味着：接受一个 0 用户、11 commit、作者自述会穿模的实验作为长期地基；接受 iOS 26 硬门槛（`IPHONEOS_DEPLOYMENT_TARGET = 26.0`，比 mobileLLM 的 iOS 17 窄得多）；再自己补 Widget / Live Activity / 通知扩展 / Live2D 运行时。补完之后的代码量，已经超过"写一个干净的 Shell"。

**抄它的模式，不背它的债。**

### 明确淘汰

FoundationBuddy（停更 14 个月）、Miru（无 iOS 代码）、Herald（无法验证）。

### 保留为参考（不设依赖）

mobileLLM（`LLMEngine` 协议设计、`prepare→authorize→execute` 权限边界、可读可改的 memory 交互——**权限边界这一项它是全部候选里最好的**）、Miru（可审计记忆 + 主动性架构）。

### 一个必须标注的坑

ManifoldKit 的 README 自相矛盾：徽章写 **iOS 18+**，正文与 Requirements 写 **iOS 26+**。引入前必须在 Mac 上读 `Package.swift` 的 `platforms` 确认真实下限，这决定我们的部署目标能不能低于 26。

另外 `ManifoldKit/manifold-apps`（官方展示 App）**没有 license**——不要从那里复制代码。

---

## 6. 对你架构的修订建议

你给的骨架基本不用动，只有"哪个格子由谁实现"需要改：

```
AI Desktop iOS
│
├── Shell        ← 全新自研（无候选可借）
├── Persona      ← 全新自研，模式照搬 ExperimentalAlice 的
│                   "结构化 turn 先于语音" + RigContract 解耦
├── State        ← 全新自研（确定性 mapper 是核心资产）
├── Brain        ← 【ManifoldKit】InferenceBackend 协议，不自己写
├── Judgment     ← 自研接口（Rule / LLM / Jev? / Future，V0 只有 Rule + LLM）
├── Memory       ← 自研（参考 Miru 的可审计 Markdown、mobileLLM 的可读可改）
├── Actions      ← 自研（ExperimentalAlice 的 Tools 是最佳功能参照）
└── iOS Surfaces ← 全新自研，且是差异化所在（候选全空白）
```

**三条保持不变**：Jev 仍只在 `JudgmentBackend` 插槽里、V0 不存在；DigitalSelf 不动；SETV 不碰。

**新增一条强约束**：`Persona` / `State` 层不允许 import ManifoldKit。Brain 是唯一依赖外部推理库的层，这样换 Brain 才不会波及角色。

---

## 7. V0 范围（按审计结果微调）

你原本的 V0 是 7 项。基于事实，建议调整为：

| 项目 | 处理 |
|---|---|
| 一个 Persona | 保留 |
| 一个主场景 | 保留 |
| 一个 AI backend | 保留，但由 ManifoldKit 提供，降级为"接一根线" |
| 一个 State machine | 保留，★ 核心资产，自研 |
| 一个对话入口 | 保留 |
| 一个动画状态系统 | 保留，但**明确用平面/矢量角色或 Live2D 占位**，不阻塞 |
| 一个本地 memory | 保留 |
| Widget / Live Activity | **移出 V0** |

**为什么移出 Widget / Live Activity**：它们不是"顺手加"，而是独立 target + 独立的 entitlement / App Group / 后台刷新预算问题。放进 V0 会让第一个版本永远发不出去。

**V0 之前建议先做一次 30 分钟验证**：在 Mac 上 `xcodebuild` 跑通 ManifoldKit 的 `quickStart()`，确认它真实的 platform 下限与 Foundation Models 可用性。这一条通过，整个方案才成立。

---

## 8. 需要你决策的 4 件事

1. **部署目标底线**：跟随 ManifoldKit 的 iOS 26（API 最全、设备覆盖最少），还是坚持 iOS 18/17 并接受自己包一层 Foundation Models 可用性判断？
2. **角色渲染路线**：平面/矢量 SwiftUI 角色（当天可动、无许可风险）／ Live2D Cubism（需商业许可 + Objective-C++ 桥 + 分层美术资产）？这条决定 V0 工期是 2 周还是 2 个月。
3. **Herald 是否提供 URL**，否则移出候选。
4. **是否接受"抄 ExperimentalAlice 的模式、不引入其代码"**——这是本次审计最需要你确认的取舍。
