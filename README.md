# 基于笔记本电脑外接桌面级显卡坞的显卡冲突问题解决方案

## A Hybrid GPU Conflict Mitigation Strategy for Laptops with External Desktop GPU Enclosures

这是一个公开可读的 Windows 混合 GPU 控制与诊断脚本包，面向“笔记本核显 + 外接桌面级 NVIDIA 显卡坞”这类容易出现 GPU 选择混乱、DXGI device removed、TDR、WHEA 17 和热插拔崩溃的环境。

This is a public, source-available Windows hybrid GPU control and diagnostics toolkit for laptops that use an integrated GPU together with an external desktop-class NVIDIA GPU enclosure.

> License note: this repository is public for reading, searching, auditing, and non-commercial diagnostic use only. Commercial use, resale, SaaS integration, paid support repackaging, or proprietary product integration is not allowed. See [LICENSE](LICENSE).

## 中文说明

### 具体环境

本项目来自一台需要 NVIDIA eGPU 热插拔的 Windows 笔记本环境。为避免公开仓库泄露可关联到个人设备的信息，以下只保留脱敏后的设备类型：

- 笔记本：Windows 轻薄本
- 核显：Intel 集成显卡
- 外接显卡：NVIDIA 桌面级显卡
- 显卡坞：USB4/Thunderbolt 类外接显卡坞
- 系统：Windows 11
- 使用方式：
  - 只用笔记本内屏
  - 笔记本内屏 + 插在 NVIDIA eGPU 上的副屏
  - 合盖，只用插在 NVIDIA eGPU 上的副屏

### 问题本质

这个问题通常不是“Intel 和 NVIDIA 谁该被禁用”的简单问题，而是两个层面叠加：

1. eGPU 链路和设备重置层：USB4/PCIe 外接显卡链路如果出现 WHEA-Logger 17、设备重置、驱动恢复或瞬时断开，DirectX/Vulkan/CUDA 程序会看到设备丢失。
2. 应用 GPU 选择层：Windows、NVIDIA Control Panel、启动器、WebView/CEF、游戏本体、AI 程序可能对“该用哪张卡”理解不一致。已经运行的图形上下文不能被脚本无感迁移。

因此本项目不采用“禁用核显”或“所有程序永久写死到 NVIDIA”的方案，而是做轻量、可回滚、按状态切换的用户级策略。

### 解决策略

脚本按当前状态判断策略：

- `Detached`：NVIDIA eGPU 不在线，只使用 Intel。
- `Attached-InternalOnly`：NVIDIA 在线，只用笔记本内屏；重图形、游戏、AI 程序优先 NVIDIA，桌面和轻应用保留 Intel。
- `Attached-Extended`：内屏 + NVIDIA 上的副屏同时使用；副屏输出和重负载优先 NVIDIA，内屏轻负载保留 Intel。
- `Attached-ExternalOnly`：合盖或只用副屏；图形和计算优先 NVIDIA，但不禁用 Intel。
- `Attached-Degraded`：NVIDIA 在线但 WHEA 17、TDR 或设备重置异常增长；暂停把新重负载推到 NVIDIA，优先排查链路/驱动/线材/固件。

### 仓库内容

- [gpu-control/config/gpu-policy.example.json](gpu-control/config/gpu-policy.example.json)：脱敏后的应用分类、默认 GPU 策略、健康阈值和显示器匹配规则模板。
- [gpu-control/scripts/Check-GpuState.ps1](gpu-control/scripts/Check-GpuState.ps1)：只读检查 GPU、显示器、WHEA/TDR、CUDA/nvidia-smi 和 Windows 图形偏好。
- [gpu-control/scripts/Apply-GpuPolicy.ps1](gpu-control/scripts/Apply-GpuPolicy.ps1)：按当前状态应用当前用户的 Windows 图形偏好。
- [gpu-control/scripts/Prepare-EgpuEject.ps1](gpu-control/scripts/Prepare-EgpuEject.ps1)：热拔前列出可能占用 NVIDIA 的进程，并打开 Windows 原生弹出入口。
- [gpu-control/scripts/Export-GpuSupportBundle.ps1](gpu-control/scripts/Export-GpuSupportBundle.ps1)：导出支持包，便于给厂商、社区或下一个排查者。
- [gpu-control/scripts/Rollback-GpuPolicy.ps1](gpu-control/scripts/Rollback-GpuPolicy.ps1)：恢复首次应用策略前的图形偏好。
- [gpu-control/scripts/Uninstall-GpuControl.ps1](gpu-control/scripts/Uninstall-GpuControl.ps1)：删除本工具生成的可选快捷方式、计划任务和状态文件。
- [docs/CASE_STUDY.zh-CN.md](docs/CASE_STUDY.zh-CN.md)：中文案例拆解。
- [docs/USAGE.zh-CN.md](docs/USAGE.zh-CN.md)：中文使用指南，包含日常使用、热拔、支持包、回滚和隐私边界。
- [docs/CASE_STUDY.en.md](docs/CASE_STUDY.en.md)：English case study.
- [docs/REFERENCES.md](docs/REFERENCES.md)：官方文档和社区相似问题参考。
- [SECURITY.md](SECURITY.md)：公开上传前的隐私注意事项。

### 快速使用

在 PowerShell 中运行：

```powershell
Set-Location .\gpu-control
Copy-Item .\config\gpu-policy.example.json .\config\gpu-policy.json

.\scripts\Check-GpuState.ps1
.\scripts\Apply-GpuPolicy.ps1 -WhatIf
.\scripts\Apply-GpuPolicy.ps1
.\scripts\Prepare-EgpuEject.ps1 -OpenDeviceEject
.\scripts\Export-GpuSupportBundle.ps1
.\scripts\Rollback-GpuPolicy.ps1
```

公开仓库只提供脱敏模板 `gpu-policy.example.json`。真实 `gpu-policy.json` 可能包含你的应用路径和显示器匹配规则，应保留在本机，不要提交。

安装登录任务和设备变化触发任务：

```powershell
.\scripts\Install-GpuControl.ps1
```

如果确实需要桌面快捷方式，显式使用：

```powershell
.\scripts\Install-GpuControl.ps1 -CreateDesktopShortcuts
```

彻底回滚并清理：

```powershell
.\scripts\Uninstall-GpuControl.ps1 -RestorePreferences -RemovePackage
```

### 重要边界

- 不修改 BIOS。
- 不禁用 Intel 核显。
- 不修改系统级驱动。
- 不使用 `pciexpress forcedisable` 这类会破坏混合 GPU 共存的粗暴方案。
- 默认只修改当前用户的 `HKCU\Software\Microsoft\DirectX\UserGpuPreferences`。
- 默认诊断输出和支持包会隐藏应用完整路径、显示器原始 ID、序列号、BIOS/电脑型号等私密细节；只有显式使用 `-IncludePrivateDetails` 才会包含原始信息。
- 不能保证已经运行的 DirectX/Vulkan/CUDA 程序在 eGPU 被拔掉时不崩溃；脚本的目标是减少错误路由、降低热拔风险、保留诊断和回滚能力。

## English

### Hardware Context

This project was built around a Windows laptop that needs NVIDIA eGPU hot-plug support. To avoid exposing personally linkable device details, the public repository keeps only a sanitized hardware category:

- Laptop: Windows ultrabook
- Integrated GPU: Intel integrated GPU
- External GPU: NVIDIA desktop-class GPU
- Enclosure: USB4/Thunderbolt-class eGPU enclosure
- OS: Windows 11
- Display modes:
  - Internal panel only
  - Internal panel plus an external monitor attached to the NVIDIA eGPU
  - External monitor only with the laptop lid closed

### Root Cause Model

The failure mode is usually not solved by disabling either GPU. Two layers interact:

1. eGPU transport and reset instability: WHEA-Logger 17, TDR, driver recovery, or a transient PCIe/USB4 disconnect can make graphics APIs report a lost or removed device.
2. Application adapter selection: Windows graphics preferences, NVIDIA Control Panel, launchers, WebView/CEF helper processes, games, and AI workloads may not agree on which GPU should be used. A running DirectX/Vulkan/CUDA context cannot be live-migrated by a script.

### Strategy

The toolkit keeps both GPUs available and applies only current-user Windows graphics preferences based on the detected state:

- `Detached`: NVIDIA eGPU is offline; use Intel.
- `Attached-InternalOnly`: NVIDIA is online, internal panel only; heavy graphics/game/AI workloads prefer NVIDIA.
- `Attached-Extended`: internal panel plus an external display on NVIDIA; keep light internal-panel work on Intel and heavy/external-display work on NVIDIA.
- `Attached-ExternalOnly`: lid closed or external-only mode; prefer NVIDIA for graphics and compute while keeping Intel as fallback.
- `Attached-Degraded`: NVIDIA is online but WHEA/TDR/device-reset evidence is increasing; stop assigning new heavy workloads to NVIDIA until the link/driver/cable/firmware problem is handled.

### What This Repository Provides

- A lightweight PowerShell toolkit under [gpu-control](gpu-control).
- A configurable app policy template in [gpu-control/config/gpu-policy.example.json](gpu-control/config/gpu-policy.example.json).
- Read-only GPU/display/health checks.
- State-aware Windows graphics preference application.
- eGPU eject preparation.
- Support bundle export.
- One-command rollback and uninstall.
- Sanitized-by-default diagnostics and support bundles.

### Limits

This is a mitigation and operations toolkit, not a kernel driver or GPU scheduler. It does not modify BIOS settings, disable devices, replace drivers, or guarantee that applications survive physical GPU removal.

The public repository tracks only `gpu-policy.example.json`. Keep your real `gpu-policy.json` private because it may contain application paths and monitor matching patterns.
