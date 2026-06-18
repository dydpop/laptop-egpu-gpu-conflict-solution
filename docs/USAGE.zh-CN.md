# 使用指南：Windows 混合 GPU 动态策略与回滚方案

本文面向实际使用者，说明这个脚本包做了什么、文件在哪里、平时要不要管、什么时候需要手动操作，以及出现问题时如何导出诊断和回滚。

## 先看结论

这个方案不是把系统改成“只用 NVIDIA”或“只用核显”。它保留 Intel 核显和 NVIDIA eGPU 同时可用，只在当前用户范围内调整 Windows 图形偏好：

```text
HKCU\Software\Microsoft\DirectX\UserGpuPreferences
```

安装计划任务后，日常基本不用管。你需要手动操作的情况主要有五类：

- 第一次配置应用列表时。
- 新增游戏、创作软件、AI/CUDA 程序时。
- 拔 eGPU 前检查占用进程时。
- 出现崩溃、黑屏、设备丢失、WHEA/TDR 增长时导出支持包。
- 需要回滚或彻底卸载时。

默认不会创建桌面快捷方式。只有你显式运行 `Install-GpuControl.ps1 -CreateDesktopShortcuts` 才会往桌面放快捷方式。

## 这次做了哪些内容

### 1. 建立了轻量控制包

核心目录是：

```text
gpu-control/
```

其中包含：

- `gpu-control/config/gpu-policy.example.json`：公开的脱敏配置模板。
- `gpu-control/config/gpu-policy.json`：本机私有配置，默认被 `.gitignore` 排除，不应提交到公开仓库。
- `gpu-control/scripts/`：所有 PowerShell 脚本入口。
- `gpu-control/state/`：本机运行状态、日志、备份目录，默认被忽略。
- `gpu-control/support-bundles/`：导出的诊断支持包目录，默认被忽略。

### 2. 实现了动态状态判断

脚本会把当前情况归类成这些状态：

| 状态 | 含义 | 默认处理 |
| --- | --- | --- |
| `Detached` | NVIDIA eGPU 不在线 | 不把新任务推到 NVIDIA，保留 Intel |
| `Attached-InternalOnly` | eGPU 在线，但只用笔记本内屏 | 重图形、游戏、AI 程序可优先 NVIDIA |
| `Attached-Extended` | 内屏 + 接在 eGPU 上的副屏同时使用 | 内屏轻应用走 Intel，重负载和副屏场景优先 NVIDIA |
| `Attached-ExternalOnly` | 合盖或只用副屏 | 图形和计算优先 NVIDIA，Intel 保留为 fallback |
| `Attached-Degraded` | NVIDIA 在线但近期 WHEA 17、TDR 或重置异常增长 | 暂停把新重负载推到 NVIDIA，先排查链路、驱动、线材或固件 |

这里有一个容易误导的点：脚本会同时显示 `Connected monitors` 和 `Desktop-active monitors`。前者只代表 Windows 还能读到显示器设备/EDID；后者才代表这个屏幕当前真的有桌面区域和分辨率。外屏插在 eGPU 上但黑屏、关闭、或在 Windows 显示设置里没有被用于桌面时，应按单屏处理，不应算作扩展双屏。如果 `State` 因 WHEA/TDR 被覆盖为 `Attached-Degraded`，请同时看 `Display mode`，它会单独显示 `InternalOnly`、`Extended` 或 `ExternalOnly`。

### 3. 加了可回滚机制

第一次真正运行：

```powershell
.\scripts\Apply-GpuPolicy.ps1
```

脚本会先备份当前用户的 `UserGpuPreferences`。之后如果你觉得策略不合适，可以用：

```powershell
.\scripts\Rollback-GpuPolicy.ps1
```

恢复到第一次应用策略之前的图形偏好。

### 4. 加了安装和自动刷新

安装命令：

```powershell
.\scripts\Install-GpuControl.ps1
```

默认会创建两个轻量计划任务：

- 登录时应用一次 GPU 策略。
- 设备变化事件出现时应用一次 GPU 策略。

这不是常驻托盘程序，也不是高频轮询。平时几乎不占 CPU/GPU，只在登录、设备变化或你手动运行脚本时执行。

### 5. 做了公开仓库安全处理

公开仓库只保留可审计的源码、说明文档和脱敏配置模板。以下内容默认不会公开：

- 真实 `gpu-policy.json`。
- `state/` 中的日志、备份和运行状态。
- `support-bundles/` 中的支持包。
- 本机应用完整路径。
- 显示器原始 ID、设备序列号、BIOS/电脑型号等可追踪信息。
- 带 `-IncludePrivateDetails` 导出的原始诊断细节。

公开分享前仍建议自己打开 zip 或 JSON 看一遍，尤其不要把带私密细节的支持包直接发到公开社区。

## 第一次怎么用

以下命令都在 PowerShell 中运行。先进入工具目录：

```powershell
Set-Location .\gpu-control
```

创建本机私有配置：

```powershell
Copy-Item .\config\gpu-policy.example.json .\config\gpu-policy.json
```

然后编辑：

```text
gpu-control/config/gpu-policy.json
```

把里面的示例程序改成你自己的程序。重点看 `applications` 数组：

```json
{
  "name": "Example game executable",
  "path": "C:\\Path\\To\\ExampleGame\\Game.exe",
  "category": "PreferNvidiaWhenHealthy",
  "gpuPreference": "HighPerformance",
  "protectedOnEject": false
}
```

字段含义：

| 字段 | 用法 |
| --- | --- |
| `name` | 方便你识别的应用名 |
| `path` | 程序 exe 的完整路径 |
| `category` | 应用分类，决定不同 GPU 状态下如何处理 |
| `gpuPreference` | Windows 图形偏好：`PowerSaving`、`HighPerformance`、`Auto` |
| `protectedOnEject` | 热拔前是否重点提醒，不会自动强杀 |

常用分类：

| 分类 | 适合放什么 |
| --- | --- |
| `AlwaysIntel` | 浏览器基础进程、聊天、办公、终端、系统小工具 |
| `PreferNvidiaWhenHealthy` | 游戏本体、Unreal/Unity、Blender、DaVinci、AI/CUDA 程序 |
| `Auto` | 启动器、WebView、CEF、崩溃上报程序、不确定的程序 |

配置好以后先只读检查：

```powershell
.\scripts\Check-GpuState.ps1
```

再预览策略，不改系统：

```powershell
.\scripts\Apply-GpuPolicy.ps1 -WhatIf
```

确认没有问题后真正应用：

```powershell
.\scripts\Apply-GpuPolicy.ps1
```

最后安装自动刷新任务：

```powershell
.\scripts\Install-GpuControl.ps1
```

## 平时用不用管

安装后，平时基本不用管。

推荐习惯是：

- 插上 eGPU 后，等 Windows 识别完成，再启动游戏、创作软件或 AI 程序。
- 如果你刚插上 eGPU 就要立刻跑重任务，可以手动运行一次 `Apply-GpuPolicy.ps1`。
- 拔 eGPU 前，不要直接拔线，先运行 `Prepare-EgpuEject.ps1 -OpenDeviceEject`。
- 新安装了需要固定策略的软件，再把它加进 `gpu-policy.json`，然后运行一次 `Apply-GpuPolicy.ps1`。
- 频繁崩溃或黑屏时，先运行 `Check-GpuState.ps1` 看是否进入 `Attached-Degraded`。

## 各脚本怎么用

### `Check-GpuState.ps1`

用途：只读检查当前 GPU、显示器、近期 WHEA/TDR、CUDA/nvidia-smi 和 Windows 图形偏好摘要。

常用命令：

```powershell
.\scripts\Check-GpuState.ps1
```

导出 JSON：

```powershell
.\scripts\Check-GpuState.ps1 -Json -OutputPath .\state\reports\gpu-state.json
```

只有本机排查时才使用：

```powershell
.\scripts\Check-GpuState.ps1 -IncludePrivateDetails
```

`-IncludePrivateDetails` 可能显示驱动版本、原始显示器信息、设备细节等，不建议把输出直接贴到公开社区。

### `Apply-GpuPolicy.ps1`

用途：根据当前状态和 `gpu-policy.json` 写入当前用户的 Windows 图形偏好。

先预览：

```powershell
.\scripts\Apply-GpuPolicy.ps1 -WhatIf
```

真正应用：

```powershell
.\scripts\Apply-GpuPolicy.ps1
```

注意：它影响的是“之后启动的程序”。已经运行的 DirectX/Vulkan/CUDA 程序不会被无感迁移到另一张 GPU。

### `Prepare-EgpuEject.ps1`

用途：拔 eGPU 前列出可能占用 NVIDIA 的进程，并打开 Windows 原生安全弹出入口。

```powershell
.\scripts\Prepare-EgpuEject.ps1 -OpenDeviceEject
```

脚本默认不会强杀进程。你需要自己判断哪些程序可以关闭。确认 NVIDIA 占用释放后，再走 Windows 的“安全删除硬件/弹出设备”流程，最后再拔线。

### `Export-GpuSupportBundle.ps1`

用途：出现问题时导出支持包，给厂商、社区或后续排查者看。

默认导出脱敏支持包：

```powershell
.\scripts\Export-GpuSupportBundle.ps1
```

生成位置：

```text
gpu-control/support-bundles/
```

默认支持包通常包含：

- `summary.txt`
- `gpu-state.json`
- `gpu-policy.sanitized.json`
- `user-gpu-preferences-summary.json`

需要本机完整排查时才使用：

```powershell
.\scripts\Export-GpuSupportBundle.ps1 -IncludePrivateDetails
```

这个参数会导出更多原始信息，例如真实配置、完整图形偏好、系统/BIOS/电脑型号、电源策略和日志。不要把这种支持包直接公开上传。

### `Rollback-GpuPolicy.ps1`

用途：把 Windows 图形偏好恢复到第一次应用策略前。

先预览：

```powershell
.\scripts\Rollback-GpuPolicy.ps1 -WhatIf
```

真正回滚：

```powershell
.\scripts\Rollback-GpuPolicy.ps1
```

### `Uninstall-GpuControl.ps1`

用途：删除计划任务、可选桌面快捷方式，并可选择恢复图形偏好、删除脚本包。

只删除自动任务和快捷方式：

```powershell
.\scripts\Uninstall-GpuControl.ps1
```

删除任务并恢复图形偏好：

```powershell
.\scripts\Uninstall-GpuControl.ps1 -RestorePreferences
```

恢复图形偏好并删除整个工具目录：

```powershell
.\scripts\Uninstall-GpuControl.ps1 -RestorePreferences -RemovePackage
```

先预览要做什么：

```powershell
.\scripts\Uninstall-GpuControl.ps1 -RestorePreferences -RemovePackage -WhatIf
```

## 你的几个实际使用场景

### 只带笔记本出去

eGPU 不在线时，状态应为：

```text
Detached
```

这时不会把新程序推到 NVIDIA。正常使用核显即可。

### 插上 eGPU，但只用笔记本内屏

状态应为：

```text
Attached-InternalOnly
```

这种情况下，桌面和轻应用保留 Intel，重图形、游戏、AI 程序可以优先 NVIDIA。因为画面可能需要回传到内屏，这种模式更要留意 WHEA/TDR 是否增长。

如果外屏只是连接着、Windows 能读到设备信息，但外屏黑屏/关闭/未参与桌面，状态也应归到这里，而不是 `Attached-Extended`。

### 笔记本内屏 + 插在 eGPU 上的副屏

状态应为：

```text
Attached-Extended
```

这是比较适合混合 GPU 的场景：内屏轻负载继续用 Intel，副屏输出和重负载程序优先 NVIDIA。

### 合盖，只用插在 eGPU 上的副屏

状态应为：

```text
Attached-ExternalOnly
```

这时 NVIDIA 更接近主要图形设备，但脚本仍不会禁用 Intel。Intel 保留为系统 fallback。

### 出现 `Attached-Degraded`

说明脚本观察到近期 WHEA 17、TDR 或设备重置类异常增长。此时不要继续强行把更多新任务推到 NVIDIA。建议顺序：

1. 关闭正在跑的重图形或 CUDA 程序。
2. 导出默认脱敏支持包。
3. 检查连接线、显卡坞供电、接口、驱动、固件。
4. 重启后再观察是否继续增长。
5. 如果要发给厂商，先检查支持包内容。

## 拔 eGPU 的正确流程

不要在游戏、CUDA、视频渲染或 3D 软件运行中直接拔 eGPU。推荐流程：

1. 保存工作。
2. 退出游戏、AI 程序、渲染软件、会占用 NVIDIA 的进程。
3. 运行：

```powershell
.\scripts\Prepare-EgpuEject.ps1 -OpenDeviceEject
```

4. 如果脚本列出占用进程，先关闭你确认可以退出的程序。
5. 使用 Windows 原生安全弹出界面弹出 eGPU 相关设备。
6. 系统确认可以移除后，再物理拔线。
7. 拔掉后如有需要，运行一次：

```powershell
.\scripts\Apply-GpuPolicy.ps1
```

## 出问题时怎么给别人看

优先导出默认脱敏支持包：

```powershell
.\scripts\Export-GpuSupportBundle.ps1
```

然后打开生成的 zip 检查一遍。确认没有不想公开的信息后，再上传给社区或厂商。

报告问题时建议同时说明：

- 当前状态：`Detached`、`Attached-InternalOnly`、`Attached-Extended`、`Attached-ExternalOnly` 或 `Attached-Degraded`。
- 当前显示模式：只内屏、扩展双屏、只副屏。
- 崩溃发生在插入、启动程序、切屏、合盖、睡眠唤醒，还是热拔时。
- WHEA 17 / TDR 是否在增长。
- 是所有程序都会崩，还是某类程序崩。

不要公开上传：

- 真实 `gpu-policy.json`。
- 带 `-IncludePrivateDetails` 的支持包。
- `state/` 目录。
- 任何含完整本机路径、显示器原始 ID、序列号、账号名、令牌或日志的文件。

## 什么时候需要改配置

这些情况需要改 `gpu-policy.json`：

- 新安装了一个游戏或 AI 程序。
- 某个 launcher 被错误地推到 NVIDIA，导致启动器、小窗口或 WebView 不稳定。
- 某个重图形程序没有优先使用 NVIDIA。
- 你想把某个常驻轻应用固定为省电。
- 你换了外接显示器，显示器匹配规则需要重新确认。

改完后运行：

```powershell
.\scripts\Apply-GpuPolicy.ps1 -WhatIf
.\scripts\Apply-GpuPolicy.ps1
```

## 不建议做的事

- 不要禁用 Intel 核显。
- 不要把所有程序永久写死到 NVIDIA。
- 不要用破坏混合 GPU 共存的 PCIe 全局禁用方案。
- 不要在重图形/CUDA 程序运行时直接拔 eGPU。
- 不要把真实配置、状态目录或支持包提交到公开仓库。
- 不要随便使用 `-IncludePrivateDetails` 后直接公开分享输出。

## 这个方案的边界

这个工具是用户级策略和诊断工具，不是驱动、不是内核调度器，也不是硬件故障修复器。

它能做：

- 检测当前 GPU/显示器/健康状态。
- 根据状态写入当前用户图形偏好。
- 帮你在热拔前找出可疑占用进程。
- 导出可分享的脱敏诊断包。
- 回滚和卸载自身造成的用户级改动。

它不能做：

- 保证运行中的 DirectX/Vulkan/CUDA 程序在拔 eGPU 时不崩溃。
- 把已经运行的程序从 NVIDIA 无感迁移到 Intel。
- 修复物理链路、供电、线材、固件或驱动层面的真实不稳定。
- 替你判断所有第三方程序内部如何选择 GPU。

## 最短操作清单

首次配置：

```powershell
Set-Location .\gpu-control
Copy-Item .\config\gpu-policy.example.json .\config\gpu-policy.json
notepad .\config\gpu-policy.json
.\scripts\Check-GpuState.ps1
.\scripts\Apply-GpuPolicy.ps1 -WhatIf
.\scripts\Apply-GpuPolicy.ps1
.\scripts\Install-GpuControl.ps1
```

日常检查：

```powershell
.\scripts\Check-GpuState.ps1
```

拔 eGPU 前：

```powershell
.\scripts\Prepare-EgpuEject.ps1 -OpenDeviceEject
```

出问题导出支持包：

```powershell
.\scripts\Export-GpuSupportBundle.ps1
```

回滚：

```powershell
.\scripts\Rollback-GpuPolicy.ps1
```

彻底恢复并删除工具：

```powershell
.\scripts\Uninstall-GpuControl.ps1 -RestorePreferences -RemovePackage
```
