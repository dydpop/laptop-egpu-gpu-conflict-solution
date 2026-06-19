# 社区发布队列

> 目的：把本项目按合适平台逐步发布出去。
> 最近核对：2026-06-20。
> 隐私原则：只发布公开仓库链接、通用症状、通用硬件类别和脱敏后的解决思路；不发布本机路径、真实配置、支持包、日志、设备 ID、显示器 ID、序列号、账号邮箱、token 或密钥。

项目链接：https://github.com/dydpop/laptop-egpu-gpu-conflict-solution

## 发布策略

优先发到最精准的 eGPU/硬件社区，先看是否有人遇到同类状态机、外屏活动状态误判、WHEA 17/TDR/DXGI device removed 和热插拔问题。第一波不要铺太广，避免被误判成广告；每个平台只发一帖，后续根据回复补充脱敏信息。

## 第一优先级

### 1. eGPU.io - Thunderbolt Windows eGPU

- 入口：https://egpu.io/forums/pc-setup/
- 发帖入口：页面上的 `Add topic`
- 语言：英文
- 推荐标题：
  `Windows 11 Intel iGPU + NVIDIA eGPU conflict mitigation toolkit: hot-plug, WHEA 17, TDR, DXGI device removed`
- 推荐内容：使用 `docs/COMMUNITY_OUTREACH.en.md` 的 English Short Post，必要时补充 Long Post Outline。
- 登录状态：需要登录后发帖。
- 当前判断：最优先。这个板块非常精准，页面已有 Windows eGPU、WHEA、随机断连、Code 14/47、内部屏幕/外部屏幕、性能异常等同类主题。
- 注意：不要贴本机日志和真实支持包。只欢迎别人用脱敏后的 WHEA/TDR 行为和显示拓扑反馈。

### 2. Reddit - r/eGPU

- 入口：https://www.reddit.com/r/eGPU/
- 发帖入口：https://www.reddit.com/r/eGPU/submit
- 语言：英文
- 推荐标题：
  `Hybrid GPU conflict mitigation for Windows laptops with Intel iGPU + NVIDIA eGPU`
- 推荐内容：使用 `docs/COMMUNITY_OUTREACH.en.md` 的 English Short Post。
- 登录状态：需要 Reddit 登录；未登录打开发帖入口会跳转到登录页。
- 当前判断：第二优先。人群精准，适合让更多 eGPU 用户看到工具，并收集不同显卡坞、线材、驱动组合反馈。
- 注意：标题不要夸张，不要承诺“完全解决所有崩溃”；不要使用短链接、返利链接或销售语气。

## 第二优先级

### 3. V2EX - 硬件

- 入口：https://www.v2ex.com/go/hardware
- 语言：中文
- 推荐标题：
  `基于笔记本外接桌面级显卡坞的显卡冲突问题解决方案：Intel 核显 + NVIDIA eGPU + Windows 11`
- 推荐内容：使用 `docs/COMMUNITY_OUTREACH.zh-CN.md` 的中文短帖；如果反馈好，再扩成长帖。
- 登录状态：需要 V2EX 登录。
- 当前判断：中文第一优先。硬件节点活跃，适合中文硬件、拓展坞、显示器、Windows 问题复盘。
- 注意：V2EX 更适合经验复盘和讨论，不要写成项目宣传稿。正文开头先讲问题场景，再放仓库链接。

### 4. Intel Community - Graphics

- 入口：https://community.intel.com/t5/Graphics/bd-p/graphics
- 发帖入口：https://community.intel.com/t5/forums/postpage/board-id/graphics
- 语言：英文
- 推荐标题：
  `Hybrid Intel iGPU + NVIDIA eGPU on Windows: display-active detection and rollbackable GPU preferences`
- 推荐内容：短帖即可，重点强调 Intel 核显保留为 fallback、显示器 connected 与 desktop-active 的区别、当前用户图形偏好可回滚。
- 登录状态：需要 Intel 账号；页面提示部分操作可能需要邮箱验证。
- 当前判断：适合讨论 Intel 图形驱动、核显、多显示器、Windows 图形偏好和 DirectX 崩溃现象。
- 注意：不要写成 NVIDIA 或 Razer 投诉帖，重点放在混合 GPU 判断和回滚策略。

### 5. Razer Insider - Razer Support

- 入口：https://insider.razer.com/razer-support-45
- 发帖入口：页面上的 `Create`
- 语言：英文
- 推荐标题：
  `Razer Core-class eGPU stability checklist for Windows hybrid GPU conflicts`
- 推荐内容：只发与 Razer Core-class enclosure 相关的部分：线材、供电、固件、热插拔、Windows 事件日志检查，以及仓库链接。
- 登录状态：需要 Razer 登录。
- 当前判断：适合显卡坞厂商相关讨论，但 Razer Support 板块较泛，技术受众不如 eGPU.io 精准。
- 注意：Razer 支持论坛要求主题清晰、聚焦、不要重复发帖、不要劫持他人主题。这里要写成可复现的检查清单，不要写成情绪化抱怨。

### 6. NVIDIA GeForce Forums

- 入口：https://www.nvidia.com/en-us/geforce/forums/discover/
- 语言：英文
- 推荐标题：
  `Windows eGPU hot-plug crashes and DXGI device removed: Intel iGPU + NVIDIA external GPU mitigation toolkit`
- 推荐内容：强调 NVIDIA eGPU、TDR、DXGI device removed、设备丢失和热插拔前检查。
- 登录状态：页面需要 JavaScript，通常需要浏览器登录后操作。
- 当前判断：受众大，但问题容易被归类为具体驱动、游戏或硬件支持；放在第二波。
- 注意：主贴不要写成“驱动投诉”，要写成“诊断工具和可回滚策略”。

## 第三优先级：中文长文平台

### 7. 知乎

- 入口：https://www.zhihu.com/
- 语言：中文
- 推荐形式：文章，不建议只发短动态。
- 推荐标题：
  `笔记本外接桌面级显卡坞后，核显和 NVIDIA eGPU 冲突应该怎么排查？`
- 推荐内容：使用中文长帖结构，讲清楚问题本质、状态机、热拔、回滚和隐私边界。
- 登录状态：需要知乎登录；网页可能触发安全验证，需手动打开。
- 当前判断：适合沉淀中文长文，搜索流量比论坛更长期。

### 8. CSDN

- 入口：https://www.csdn.net/
- 写作入口：https://editor.csdn.net/md
- 语言：中文
- 推荐形式：技术文章。
- 推荐标题：
  `Windows 笔记本 Intel 核显 + NVIDIA eGPU 冲突诊断与可回滚策略`
- 推荐内容：使用中文长帖结构，附 GitHub 仓库链接和安全边界。
- 登录状态：需要登录。
- 当前判断：适合搜索引擎长期收录，但互动质量通常不如 eGPU.io、Reddit、V2EX。

### 9. 博客园

- 入口：https://www.cnblogs.com/
- 写作入口：https://i.cnblogs.com/posts/edit
- 语言：中文
- 推荐形式：技术文章或随笔。
- 推荐标题：
  `Windows 笔记本 Intel 核显 + NVIDIA eGPU 冲突诊断与可回滚策略`
- 推荐内容：使用中文长帖结构，附 GitHub 仓库链接和安全边界。
- 登录状态：需要登录；未登录时写作入口可能不可用。
- 当前判断：适合长期技术沉淀。若只选一个中文长文平台，优先知乎；如果重视开发者搜索收录，CSDN/博客园二选一。

## 建议发布顺序

1. eGPU.io
2. Reddit r/eGPU
3. V2EX
4. Intel Community Graphics
5. Razer Insider
6. NVIDIA GeForce Forums
7. 知乎文章
8. CSDN 或博客园

## 每次发帖前检查

- 不贴 `gpu-control/config/gpu-policy.json`。
- 不贴 `gpu-control/state/`。
- 不贴 `gpu-control/support-bundles/` 原始文件。
- 不贴本机 Windows 用户目录、完整应用路径、游戏库路径。
- 不贴设备实例路径、显示器 ID、序列号、BIOS/主板序列号。
- 不贴未脱敏事件日志全文。
- 不贴个人邮箱、token、API key、私钥。
- 链接使用 GitHub 原始链接，不使用短链接。
- 不承诺“彻底解决所有 eGPU 崩溃”，只说“诊断与缓解”。

## 登录受限时的处理

如果打开页面时遇到登录限制、安全验证、发帖按钮不可用或 JavaScript 限制，不强行绕过。保留该平台入口和发帖入口，等账号完成注册、登录和验证后，再继续统一发帖。

## 这一步需要手动登录的平台

- eGPU.io：https://egpu.io/forums/pc-setup/
- Reddit：https://www.reddit.com/r/eGPU/submit
- V2EX：https://www.v2ex.com/go/hardware
- Intel Community：https://community.intel.com/t5/forums/postpage/board-id/graphics
- Razer Insider：https://insider.razer.com/razer-support-45
- NVIDIA GeForce Forums：https://www.nvidia.com/en-us/geforce/forums/discover/
- 知乎：https://www.zhihu.com/
- CSDN：https://editor.csdn.net/md
- 博客园：https://i.cnblogs.com/posts/edit
