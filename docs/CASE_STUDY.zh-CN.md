# 案例拆解：笔记本核显 + 外接桌面级 NVIDIA 显卡坞冲突

## 背景

这套方案针对的是一台同时需要便携和高性能的 Windows 笔记本。为避免公开仓库泄露可关联到个人设备的信息，这里只保留脱敏后的设备类型：

- Windows 轻薄本
- Intel 集成显卡
- NVIDIA 桌面级外接显卡
- USB4/Thunderbolt 类外接显卡坞
- Windows 11

核心需求不是“永远只用 NVIDIA”，而是：

- 拔掉 eGPU 时，系统自动回到 Intel。
- 插上 eGPU 且健康时，游戏、AI、CUDA、视频和重图形工作优先 NVIDIA。
- 浏览器、聊天、办公、终端、系统工具等轻任务保留 Intel。
- 使用插在 NVIDIA 上的副屏时，允许 NVIDIA 负责副屏输出和重负载。
- 合盖只用副屏时，NVIDIA 作为主要图形设备，但 Intel 不被禁用。
- 出问题时可以导出支持包、回滚图形偏好、卸载工具。
- 默认不创建桌面快捷方式，避免打乱桌面；需要时可显式加 `-CreateDesktopShortcuts`。

## 本质判断

这类问题一般不是单一设置项造成的。更准确的模型是：

1. **链路层问题**：eGPU 通过 USB4/Thunderbolt/PCIe 隧道连接。只要链路出现纠错、瞬断、重枚举、供电波动或驱动重置，上层图形程序就可能收到设备丢失。
2. **应用层问题**：很多程序在启动时只选择一次 GPU。启动器、WebView、游戏本体、渲染器、CUDA 进程可能是不同的 exe。某些程序遇到 `DXGI_ERROR_DEVICE_REMOVED`、TDR 或 adapter reset 后不会优雅恢复。

所以，把 Intel 禁用、把所有程序写死 NVIDIA、强改 PCIe 策略，都会牺牲热插拔和便携性，而且可能让系统在 eGPU 不在线时更难恢复。

## 状态机

工具只在手动运行、登录、设备变化或导出诊断时执行，不做高频常驻轮询。

| 状态 | 条件 | 策略 |
| --- | --- | --- |
| `Detached` | NVIDIA 不在线 | 移除/避免 PreferNvidia 策略，回到 Intel |
| `Attached-InternalOnly` | NVIDIA 在线，只用内屏 | 重负载优先 NVIDIA，轻应用保留 Intel |
| `Attached-Extended` | 内屏 + NVIDIA 副屏 | 副屏输出和重负载优先 NVIDIA，内屏轻负载保留 Intel |
| `Attached-ExternalOnly` | 合盖或只用副屏 | 图形/计算优先 NVIDIA，Intel 保留 fallback |
| `Attached-Degraded` | WHEA 17、TDR、设备重置异常增长 | 暂停把新重负载推到 NVIDIA |

## 为什么只改当前用户图形偏好

Windows 10 20H1 之后，很多应用的 GPU 选择由 Windows 图形设置优先决定。这个工具因此只修改：

```text
HKCU\Software\Microsoft\DirectX\UserGpuPreferences
```

这样做的好处：

- 风险低，回滚简单。
- 不破坏 Intel + NVIDIA 共存。
- 不影响其他 Windows 用户。
- 不需要写常驻托盘程序。
- 不需要禁用设备或修改 BIOS。

## 典型操作流程

### 日常检查

```powershell
Set-Location .\gpu-control
.\scripts\Check-GpuState.ps1
```

### 预览策略

```powershell
.\scripts\Apply-GpuPolicy.ps1 -WhatIf
```

### 应用策略

```powershell
.\scripts\Apply-GpuPolicy.ps1
```

第一次实际应用会备份原始 `UserGpuPreferences`。

### 热拔前

```powershell
.\scripts\Prepare-EgpuEject.ps1 -OpenDeviceEject
```

脚本会列出可能占用 NVIDIA 的进程，并打开 Windows 原生弹出入口。默认不强杀进程。

### 出问题时导出支持包

```powershell
.\scripts\Export-GpuSupportBundle.ps1
```

支持包适合上传给厂商、社区或后续排查者，但公开上传前应先阅读 [SECURITY.md](../SECURITY.md)。

### 回滚

```powershell
.\scripts\Rollback-GpuPolicy.ps1
```

### 卸载

```powershell
.\scripts\Uninstall-GpuControl.ps1 -RestorePreferences -RemovePackage
```

## 不做什么

- 不禁用 Intel 核显。
- 不强制所有程序永久使用 NVIDIA。
- 不修改 BIOS。
- 不修改系统级驱动。
- 不默认修改 TDR 注册表超时。
- 不使用 `pciexpress forcedisable`。
- 不承诺运行中的图形程序在拔 eGPU 后继续存活。

## 判断这套方案是否有效

有效的表现：

- eGPU 不在线时，程序不会因为残留 NVIDIA 偏好而启动失败。
- eGPU 在线且健康时，重负载程序能优先 NVIDIA。
- 副屏插在 NVIDIA 上时，显示输出和重负载更稳定。
- WHEA/TDR 增长时，状态会进入 `Attached-Degraded`，避免继续把新负载推上不稳定链路。
- 支持包能留下足够证据，便于后续判断是驱动、线材、显卡坞、固件、电源还是应用自身问题。

## 仍然需要硬件层排查的情况

如果 WHEA-Logger 17、TDR 或 device removed 持续出现，应继续检查：

- USB4/Thunderbolt 线材和接口
- 显卡坞固件
- 显卡供电和电源余量
- NVIDIA/Intel 驱动版本
- BIOS/Thunderbolt/USB4 固件
- 外接显示器连接路径
- 具体应用的渲染 API 和启动参数
