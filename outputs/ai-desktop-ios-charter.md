# AI Desktop iOS — Charter & Checkpoint

日期：2026-09-23
状态：**Architecture: OPEN → directionally settled**
性质：本地项目宪章。只记录已裁决项与已完成的事实核查；不含未裁决的假设。

相关文档：[repo-candidate-audit.md](repo-candidate-audit.md)（六个候选的只读事实矩阵）

---

## 1. 已裁决项（本轮锁定）

| # | 事项 | 裁决 | 依据 |
|---|---|---|---|
| 1 | iOS deployment target | **裁决 B：adapter-local iOS 26** | 根包保持 iOS 17 / macOS 14 中性；iOS 26 只由 `Adapters/ManifoldAdapter` 承担。见 §5 与 docs/ADR-0002 |
| 2 | Persona 形态 | **V0 = SwiftUI 平面 / 矢量** | 先验证产品闭环；Live2D 移 V1 |
| 3 | Herald | **移出候选（正式淘汰）** | 穷尽检索无可核验的 iOS AI companion 仓库 |
| 4 | ExperimentalAlice | **接受"抄模式、不引代码"** | 其 `CompanionTurn → CharacterControlState → renderer` 模式已验证有价值；不继承其工程债（0 用户 / 11 commit / 作者自述穿模） |

---

## 2. 架构（当前方向）

```text
AI Desktop iOS
│
├── Shell                  ← 自研
│
├── Persona                ← 自研
│   └── CharacterState
│
├── State                  ← 自研
│
├── Brain                  ← 唯一允许外部推理依赖
│   ├── Apple Foundation Models
│   ├── Remote LLM
│   └── ManifoldKit
│
├── JudgmentBackend        ← 可选协议
│   ├── Rule
│   ├── LLM
│   └── Jev (future)
│
├── Memory                 ← 自研
│
├── Action / Authorization ← 自研
│
└── iOS Surfaces
    └── V0: App only
        V1: Widget / Live Activity
```

**定位修正**：ManifoldKit 不称"底座壳"，称 **Inference / runtime substrate**。
它负责把 Brain 层跑起来，**它不定义我们的 Companion**。

---

## 3. 硬门：从"编码规范"升级为"编译期约束"

原则：**Persona / State 不得 import ManifoldKit。**

要让这条成为真硬门而非 code review 规则，用 SwiftPM 包边界落实：

```text
ProductCore                       BrainKit
（零外部推理依赖）                   （唯一允许依赖 ManifoldKit）
  Shell                             BrainProtocol 的 adapter
  Persona / CharacterState          把 provider 输出映射成
  State                             ProductCore 定义的结构化响应
  Memory
  Action / Authorization
  BrainProtocol          ← 协议定义在这里
  结构化响应类型           ← 我们的 CompanionTurn 等价物
      ↑
      └──── 依赖方向：BrainKit → ProductCore（反向在 SwiftPM 层即编译错误）
```

**关键推论**：结构化响应的类型必须定义在 ProductCore，**不得复用 ManifoldKit 的类型**。
否则类型会沿返回值向上泄漏，硬门当场失效。

---

## 4. V0 范围

只验证一条闭环：

```text
Launch
 ↓
Persona appears
 ↓
用户说话 / 输入
 ↓
Brain
 ↓
Structured response
 ↓
Persona state changes
 ↓
语音 / 文本呈现
```

即先证明：**"iOS 上的 AI Desktop / Companion"这个最小产品形态成立。**

**V0 明确不做**：Widget、Live Activity、Live2D、后台主动行为、多 Persona、Jev、DigitalSelf 接入。

**V1 / HOLD**：Widget、Live Activity、Live2D、后台主动行为、多 Persona。
（依据：Widget / Live Activity 不是界面问题，是独立 target + entitlement + App Group + 后台刷新预算；塞进 V0 会导致第一版发不出去。）

---

## 5. 事实核查结果（本轮）

### 5.1 ManifoldKit 平台地板 —— 已确定

| 证据来源 | 内容 |
|---|---|
| `Package.swift` | `platforms: [.iOS("26.0"), .macOS("26.0")]` → SwiftPM 硬门，低于 26 无法解析依赖 |
| README 正文 | 多处 "iOS 26+ / macOS 26+"；"Most of the surface builds and runs down to the package floor (iOS 26 / macOS 26)" |
| README（平台策略段） | 自述站在 **n-1 代**：WWDC 2026 把 Foundation Models 的 provider 层开在 iOS 27+，ManifoldKit 明确选择 iOS 26 这一代 |
| README 徽章 | 写 "iOS 18+ / macOS 15+" —— 与 manifest 及正文矛盾 |

**判定**：徽章为文档错误，以 manifest 为准。
**结论**：**未 fork `Package.swift` 的前提下，ManifoldKit 的接入底线就是 iOS 26，不存在 18 / 17 选项。**

### 5.2 Herald —— 已淘汰

穷尽检索（`herald in:name`、`herald in:name language:Swift`、`herald companion`、`herald ai assistant` 多组查询），
**无可核验的 iOS AI companion 仓库**。同名结果均为无关项：

- `theheraldproject/herald-for-ios` —— BLE 通信库，2023 停更
- `HeraldStudio/herald-ios-v1` —— 2018–2020 的中国校园 App 客户端
- `mdsakalu/herald`、`awizemann/herald` —— macOS 通知 CLI / 邮件客户端
- 其余为 Telegram / Java / Go / Python 的 AI 助手，与 iOS 无关

### 5.3 仍然只能由 Mac 完成的部分

- ManifoldKit 在 Xcode 26 上的**实际可跑性**：`quickStart()` 是否开箱可用、Foundation Models 在目标设备的可用性。
- 注意：这**已不是"下限是多少"**（已确定为 26.0），而是"**能不能开箱跑起来**"。
- 本环境为 Windows，无 Xcode 26 / macOS SDK，无法代为验证。

---

## 6. 不变项

- **Jev**：仅为 `JudgmentBackend` 的可选实现，V0 不存在。
- **DigitalSelf**：不动。
- **SETV**：不碰。

---

## 7. Checkpoint

```text
AI Desktop iOS
Architecture: OPEN → directionally settled

Base shell:
    SELF-BUILD

Inference runtime:
    ManifoldKit candidate (Inference/runtime substrate — not a base shell)

ExperimentalAlice:
    PATTERN REFERENCE ONLY

Persona:
    SwiftUI flat/vector V0

Live2D:
    V1 / HOLD

Widget / Live Activity:
    V1 / HOLD

Jev:
    optional JudgmentBackend / V0 absent

DigitalSelf:
    untouched

SETV:
    untouched

Hard boundary:
    Persona / State MUST NOT import ManifoldKit
    （通过 ProductCore / BrainKit 包边界在编译期强制）

Deployment target:
    裁决 B —— root package 中性（iOS 17 / macOS 14）
    iOS 26 = Adapters/ManifoldAdapter 的 adapter-local 约束
    → 未验证项：真实 SwiftPM/Xcode resolution 是否真把 26 挡在 App closure 之外

Trust boundary:
    BrainResponse   untrusted / provider-facing（候选，原始字符串）
    CompanionTurn   ProductCore-owned（closed vocabulary）
    → 两段式 pipeline 保持，CLOSED

Verification:
    ProductCore / BrainKit = VERIFIED on both toolchains
      Windows (Swift 6.4)                 macOS CI (Apple Swift 6.3.3)
        swift build -> Build complete
        swift test  -> 32 passed / 0 failed   （两个工具链一致）
        gate        -> 10 PASS / 0 FAIL / 0 NEEDS-APPLE-TOOLCHAIN

    SwiftUI App = 编译级 VERIFIED（首次）
        Xcode 26.6 / iOS 26.5 SDK -> ** BUILD SUCCEEDED **
        xcodegen 生成的工程可用；probe 以 App 为 host 在模拟器中运行

    Foundation Models = MEASURED，且结论是负面的
        import FoundationModels   -> importable
        SystemLanguageModel.availability -> available（CI 环境实测）
        一次真实生成请求          -> FAILED
            ModelManagerServices.ModelManagerError Code=1026
            latency 1.9s / availability 却报 available
        → availability ≠ 请求能完成。此前的警告已被实测证实。
        → 1026 的含义未确认，记录为 unknown，不做解释

    界面 = 首次可见
        screenshots/main-scene.png（模拟器截图，App 正常渲染）
        注意：这只回答"能不能渲染"，不回答"好不好看 / 行为对不对"

    仍未验证: 生成成功 / 界面正确性 / 性能 / ManifoldKit 集成
              装机（需签名 + 开发者账号）

Swift change gate（不可绕过）:
    edit -> swift build -> swift test -> python Tests/check_boundaries.py
    Gate 1（结果）: PASS 才能继续；FAIL 即 STOP / 修复
                    NEEDS(-APPLE)-TOOLCHAIN 不是 PASS
    Gate 2（证据）: 必须存在可复跑、可引用的实际执行输出
                    文档里的 "PASS" 不能替代执行证据
                    被引用的脚本/工具不存在时，任何声称的 PASS 作废
                    可复跑的现实证据 > agent 的口头状态
                    （此规则源自一次"8/8 PASS 但无真实执行"的事故）

Apple 环境模拟:
    FORBIDDEN AS VERIFICATION SUBSTITUTE
    （用 stub 填补缺口 = 把诚实的 unknown 变成假 PASS）
```

证据：docs/EVIDENCE-windows-swift-6.4.md · docs/EVIDENCE-apple-ci.md
仓库：https://github.com/Marcowu7756/ai-desktop-ios （公开，仅此一个）
工具链：Swift 6.4（x86_64-unknown-windows-msvc），已安装并保留
