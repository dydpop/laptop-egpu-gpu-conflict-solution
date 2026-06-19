# 社区传播包：笔记本外接桌面级显卡坞的显卡冲突解决方案

> 用途：把本项目安全地介绍给 eGPU、Windows、NVIDIA、Intel、Razer/显卡坞和中文技术社区。  
> 隐私原则：只公开通用问题、通用环境和项目链接，不公开本机路径、真实配置、日志、支持包、设备 ID、显示器 ID 或个人信息。

项目链接：https://github.com/dydpop/laptop-egpu-gpu-conflict-solution

## 一句话介绍

中文：
这是一个面向 Windows 笔记本外接桌面级 NVIDIA 显卡坞的混合 GPU 冲突诊断与缓解工具包，重点处理 Intel 核显 + NVIDIA eGPU 共存、热插拔、WHEA 17、TDR、DXGI device removed 和显示器活动状态误判问题。

English:
This is a source-available Windows toolkit for diagnosing and mitigating hybrid GPU conflicts on laptops using an Intel integrated GPU together with an external desktop-class NVIDIA eGPU enclosure, with focus on hot-plugging, WHEA 17, TDR, DXGI device removed, and monitor activity classification.

## 适合发布的平台

- GitHub Discussions / Issues：适合补充到已有 eGPU、DXGI、TDR、WHEA 17 相关讨论中。
- eGPU.io：最精准，适合发完整案例和测试方法。
- Reddit：适合 `r/eGPU`、`r/Windows11`、`r/nvidia`、`r/techsupport`，用英文短帖引流。
- Razer / NVIDIA / Intel 社区：适合偏故障定位、显卡坞链路、驱动和固件讨论。
- V2EX / 知乎 / CSDN / 博客园：适合中文长文和问题复盘。

## 不要公开的内容

- 不要贴 `gpu-control/config/gpu-policy.json`，只贴 `gpu-policy.example.json`。
- 不要贴 `gpu-control/state/`。
- 不要贴 `gpu-control/support-bundles/` 原始包。
- 不要贴 Windows 用户目录、本机用户名、完整应用路径、游戏库路径。
- 不要贴原始显示器 ID、设备实例路径、序列号、BIOS/主板序列号。
- 不要贴没有脱敏的事件日志全文。
- 不要贴任何 GitHub token、API key、私钥、账号邮箱。

## 可以公开的内容

- 项目链接和 Release 链接。
- 通用硬件类别：Windows 11 笔记本、Intel integrated GPU、NVIDIA desktop-class eGPU、USB4/Thunderbolt-class enclosure。
- 通用症状：热插拔后应用崩溃、`DXGI_ERROR_DEVICE_REMOVED`、TDR、WHEA-Logger 17、外屏黑屏但仍被识别为 connected。
- 通用策略：不禁用核显、不强制单卡、不改 BIOS、不改系统级驱动，只做当前用户 Windows 图形偏好、诊断、支持包、回滚。
- 脱敏后的状态摘要：`Detached`、`Attached-InternalOnly`、`Attached-Extended`、`Attached-ExternalOnly`、`Attached-Degraded`。

## 中文短帖

标题建议：
`基于笔记本外接桌面级显卡坞的显卡冲突问题解决方案：Intel 核显 + NVIDIA eGPU + Windows 11`

正文：

我整理并开源了一个 Windows 混合 GPU 诊断与缓解工具包，主要面向“笔记本 Intel 核显 + 外接桌面级 NVIDIA 显卡坞”的场景。

这类问题的麻烦点不是简单地禁用核显或强制所有程序走 NVIDIA，而是 eGPU 热插拔、USB4/Thunderbolt/PCIe 链路、Windows 图形偏好、NVIDIA/Intel 驱动、外接显示器和应用自身的 GPU 选择逻辑会叠在一起。常见表现包括 WHEA-Logger 17、TDR、DXGI device removed、应用 device lost、外屏黑屏但仍被系统识别等。

项目的思路是保留 Intel + NVIDIA 共存，只在当前用户层面做可回滚的图形偏好策略，并提供状态检测、热拔前检查、支持包导出和一键回滚。它不会禁用核显，不改 BIOS，不改系统级驱动。

项目地址：
https://github.com/dydpop/laptop-egpu-gpu-conflict-solution

欢迎遇到类似问题的人参考，也欢迎提 issue 或补充不同显卡坞/线材/驱动组合下的现象。

## English Short Post

Title:
`Hybrid GPU conflict mitigation for Windows laptops with Intel iGPU + NVIDIA eGPU enclosure`

Body:

I published a source-available Windows toolkit for diagnosing and mitigating hybrid GPU conflicts on laptops using an Intel integrated GPU together with an external desktop-class NVIDIA eGPU enclosure.

The core issue is usually not solved by simply disabling the iGPU or forcing every process onto NVIDIA. eGPU hot-plugging, USB4/Thunderbolt/PCIe link behavior, Windows graphics preferences, NVIDIA/Intel drivers, external monitor topology, launchers/WebView helper processes, and application-level GPU selection can all interact. Typical symptoms include WHEA-Logger 17, TDR, DXGI device removed, device lost errors, and external displays being visible to Windows but not actually desktop-active.

The toolkit keeps both GPUs available and only applies current-user, rollbackable Windows graphics preferences. It also provides read-only diagnostics, eGPU eject preparation, support bundle export, and rollback/uninstall scripts. It does not disable devices, modify BIOS settings, or replace system drivers.

Repository:
https://github.com/dydpop/laptop-egpu-gpu-conflict-solution

If you have a similar Intel + NVIDIA + eGPU setup, feedback and issue reports are welcome, especially with sanitized WHEA/TDR behavior and display topology notes.

## 中文长帖结构

### 1. 背景

我遇到的是一类典型的 Windows 混合 GPU 问题：笔记本本身有 Intel 核显，同时通过 USB4/Thunderbolt 类显卡坞外接桌面级 NVIDIA 显卡。平时需要带走电脑，所以 eGPU 必须支持热插拔；插上 eGPU 时，又希望游戏、CUDA/AI、渲染和重图形程序尽量用 NVIDIA。

### 2. 为什么不能粗暴禁用某一张卡

禁用 Intel 会损失笔记本便携状态下的稳定 fallback，也会破坏内屏路径。把所有程序永久写死到 NVIDIA，又会在 eGPU 不在线时留下残留偏好，导致一些程序启动异常。更重要的是，已经运行的 DirectX/Vulkan/CUDA 上下文不能靠脚本无感迁移到另一张 GPU。

### 3. 问题本质

这个问题通常分两层：

- 链路层：USB4/Thunderbolt/PCIe eGPU 链路如果出现 WHEA 17、TDR、设备重置或瞬断，图形程序可能收到 device removed/device lost。
- 应用层：Windows 图形偏好、NVIDIA 控制面板、launcher、WebView/CEF、游戏本体、AI 程序可能对“该用哪张 GPU”理解不一致。

### 4. 工具策略

项目采用状态机，而不是单一卡死策略：

- `Detached`：NVIDIA 不在线，只用 Intel。
- `Attached-InternalOnly`：NVIDIA 在线，只用内屏；重负载优先 NVIDIA，轻应用保留 Intel。
- `Attached-Extended`：内屏 + eGPU 外屏；外屏和重负载优先 NVIDIA。
- `Attached-ExternalOnly`：只用外屏；图形/计算优先 NVIDIA，Intel 保留 fallback。
- `Attached-Degraded`：NVIDIA 在线但 WHEA/TDR/设备重置异常增长，暂停把新重负载推到 NVIDIA。

### 5. 显示器判断修复

项目区分 `Connected monitors` 和 `Desktop-active monitors`。外屏即使能被 Windows 读到 EDID，也不代表它正在参与桌面。如果外屏黑屏、关闭或没有桌面区域，工具不会把它算作扩展双屏。

### 6. 回滚和隐私

首次应用策略前会备份当前用户的 Windows 图形偏好。所有操作都可以回滚或卸载。默认诊断和支持包会尽量脱敏；真实配置、状态目录和支持包不应该提交到公开仓库。

### 7. 链接

项目地址：
https://github.com/dydpop/laptop-egpu-gpu-conflict-solution

## English Long Post Structure

### 1. Background

This project targets a Windows laptop setup with an Intel integrated GPU and an external desktop-class NVIDIA GPU connected through a USB4/Thunderbolt-class eGPU enclosure. The machine needs to remain portable when detached, but when the eGPU is attached, heavy graphics, CUDA/AI, rendering, and gaming workloads should prefer NVIDIA.

### 2. Why not simply disable one GPU

Disabling the integrated GPU breaks the portable fallback path and may affect the internal panel. Forcing all applications permanently onto NVIDIA can leave broken preferences when the eGPU is detached. A running DirectX/Vulkan/CUDA context also cannot be live-migrated by a PowerShell script.

### 3. Root cause model

The failure mode usually has two layers:

- Transport/reset layer: USB4/Thunderbolt/PCIe eGPU instability may produce WHEA 17, TDR, device reset, or transient disconnect behavior.
- Application selection layer: Windows graphics preferences, NVIDIA Control Panel, launchers, WebView/CEF helpers, games, and AI processes may not agree on which GPU to use.

### 4. Toolkit strategy

The toolkit uses a state-driven policy model:

- `Detached`: NVIDIA eGPU offline; use Intel.
- `Attached-InternalOnly`: NVIDIA online, internal display only; heavy workloads prefer NVIDIA.
- `Attached-Extended`: internal display plus eGPU-attached external display; heavy/external-display work prefers NVIDIA.
- `Attached-ExternalOnly`: external-only mode; graphics and compute prefer NVIDIA while Intel remains fallback.
- `Attached-Degraded`: NVIDIA online but WHEA/TDR/reset evidence is increasing; stop assigning new heavy workloads to NVIDIA.

### 5. Monitor activity fix

The toolkit distinguishes connected monitors from desktop-active monitors. A display may be visible by EDID but not actually part of the Windows desktop. A black, powered-off, or desktop-disabled external display is not treated as an extended desktop.

### 6. Rollback and privacy

The toolkit backs up current-user Windows graphics preferences before applying changes. It provides rollback, uninstall, and sanitized support bundle export. Real config, state files, and support bundles should stay private.

### 7. Link

Repository:
https://github.com/dydpop/laptop-egpu-gpu-conflict-solution

## 推荐标签

英文：
`egpu`, `hybrid-gpu`, `windows-11`, `nvidia`, `intel-gpu`, `thunderbolt`, `usb4`, `whea-17`, `tdr`, `dxgi-device-removed`, `gpu-hotplug`, `external-gpu`

中文：
`外接显卡坞`, `混合显卡`, `核显独显冲突`, `Windows 11`, `NVIDIA`, `Intel 核显`, `USB4`, `Thunderbolt`, `WHEA 17`, `TDR`, `热插拔`, `DXGI device removed`

## 图片/配图建议

优先使用仓库已有预览图：

- `docs/assets/repository-preview.svg`

如果要用 imagegen 生成社区配图，建议使用下面的安全提示词。图片里不要出现真实品牌外观、真实设备序列号、真实桌面截图或本机路径。

Prompt:

```text
Use case: infographic-diagram
Asset type: social preview image for a technical GitHub repository
Primary request: Create a clean technical infographic about a Windows laptop using an integrated GPU together with an external desktop-class GPU enclosure.
Scene/backdrop: abstract workstation diagram, not a real screenshot, no identifiable device serial numbers
Subject: laptop, internal GPU block, external GPU enclosure block, USB4/Thunderbolt link, external monitor, diagnostic state labels
Style/medium: modern flat technical illustration, high readability, GitHub README preview style
Composition/framing: 16:9 landscape, centered architecture flow, enough empty space around text
Text (verbatim): "Hybrid GPU eGPU Toolkit" and "Intel iGPU + NVIDIA eGPU"
Constraints: no real personal data, no local paths, no serial numbers, no screenshots, no brand logos except generic text labels, no watermark
Avoid: photorealistic identifiable hardware, cluttered cables, private logs, terminal screenshots
```

## 发布前检查清单

- 链接指向公开仓库首页或 Release，而不是本机文件。
- 文案没有本机 Windows 用户目录。
- 文案没有个人邮箱、手机号、账号 token。
- 文案没有真实 `gpu-policy.json` 内容。
- 文案没有原始支持包或事件日志全文。
- 文案没有显示器 ID、PnP 设备实例路径、序列号。
- 文案没有具体本机应用库路径。
- 文案没有承诺“彻底解决所有 eGPU 崩溃”，只说“诊断与缓解”。
- 文案说明许可证是 source-available、non-commercial、attribution-required，不是 OSI open source。

## 建议发布顺序

1. GitHub Release 已完成后，先发 eGPU.io 或 Reddit 英文短帖。
2. 然后发 V2EX 或知乎中文长帖。
3. 有人回复后，只分享脱敏状态摘要，不分享原始支持包。
4. 如果社区要求日志，先导出默认支持包，再手动检查；不要公开 `-IncludePrivateDetails` 版本。
5. 把有价值的反馈整理成 issue 或 docs 更新，再走隐私扫描后提交。
