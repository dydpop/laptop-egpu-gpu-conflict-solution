# Community Outreach Kit: Hybrid GPU Conflict Mitigation for Laptop eGPU Setups

> Purpose: safely introduce this project to eGPU, Windows, NVIDIA, Intel, Razer/enclosure, and general technical communities.  
> Privacy rule: share only generic symptoms, generic hardware categories, and the public repository link. Do not share local paths, private config, logs, support bundles, device IDs, monitor IDs, or personal information.

Repository: https://github.com/dydpop/laptop-egpu-gpu-conflict-solution

## One-Line Summary

This is a source-available Windows toolkit for diagnosing and mitigating hybrid GPU conflicts on laptops using an Intel integrated GPU together with an external desktop-class NVIDIA eGPU enclosure, with focus on hot-plugging, WHEA 17, TDR, DXGI device removed, and monitor activity classification.

## Where to Share

- GitHub Discussions / Issues: useful when joining existing eGPU, DXGI, TDR, or WHEA 17 discussions.
- eGPU.io: the most targeted audience for full case studies and test methodology.
- Reddit: use a short English post for `r/eGPU`, `r/Windows11`, `r/nvidia`, or `r/techsupport`.
- Razer / NVIDIA / Intel communities: useful for link stability, enclosure, driver, and firmware discussions.
- Chinese platforms such as V2EX, Zhihu, CSDN, or cnblogs: use the Chinese outreach kit.

## Do Not Share

- Do not share `gpu-control/config/gpu-policy.json`; share only `gpu-policy.example.json`.
- Do not share `gpu-control/state/`.
- Do not share raw files from `gpu-control/support-bundles/`.
- Do not share Windows user directories, local usernames, full app paths, or game library paths.
- Do not share raw monitor IDs, device instance paths, serial numbers, BIOS serials, or board serials.
- Do not share full unredacted event logs.
- Do not share GitHub tokens, API keys, private keys, or account emails.

## Safe To Share

- Repository and release links.
- Generic hardware categories: Windows 11 laptop, Intel integrated GPU, NVIDIA desktop-class eGPU, USB4/Thunderbolt-class enclosure.
- Generic symptoms: crashes after hot-plugging, `DXGI_ERROR_DEVICE_REMOVED`, TDR, WHEA-Logger 17, device lost errors, external display visible but not desktop-active.
- Generic strategy: keep both GPUs enabled; do not force a single GPU; do not modify BIOS; do not replace system drivers; apply only current-user Windows graphics preferences with rollback.
- Sanitized state labels: `Detached`, `Attached-InternalOnly`, `Attached-Extended`, `Attached-ExternalOnly`, `Attached-Degraded`.

## Short Post

Title:

```text
Hybrid GPU conflict mitigation for Windows laptops with Intel iGPU + NVIDIA eGPU enclosure
```

Body:

```text
I published a source-available Windows toolkit for diagnosing and mitigating hybrid GPU conflicts on laptops using an Intel integrated GPU together with an external desktop-class NVIDIA eGPU enclosure.

The core issue is usually not solved by simply disabling the iGPU or forcing every process onto NVIDIA. eGPU hot-plugging, USB4/Thunderbolt/PCIe link behavior, Windows graphics preferences, NVIDIA/Intel drivers, external monitor topology, launchers/WebView helper processes, and application-level GPU selection can all interact. Typical symptoms include WHEA-Logger 17, TDR, DXGI device removed, device lost errors, and external displays being visible to Windows but not actually desktop-active.

The toolkit keeps both GPUs available and only applies current-user, rollbackable Windows graphics preferences. It also provides read-only diagnostics, eGPU eject preparation, support bundle export, and rollback/uninstall scripts. It does not disable devices, modify BIOS settings, or replace system drivers.

Repository:
https://github.com/dydpop/laptop-egpu-gpu-conflict-solution

If you have a similar Intel + NVIDIA + eGPU setup, feedback and issue reports are welcome, especially with sanitized WHEA/TDR behavior and display topology notes.
```

## Long Post Outline

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

## Recommended Tags

`egpu`, `hybrid-gpu`, `windows-11`, `nvidia`, `intel-gpu`, `thunderbolt`, `usb4`, `whea-17`, `tdr`, `dxgi-device-removed`, `gpu-hotplug`, `external-gpu`

## Visual Prompt

Use the existing repository preview first:

- `docs/assets/repository-preview.svg`

If generating a social image, use a privacy-safe prompt like this:

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

## Pre-Post Privacy Checklist

- The link points to the public repository or release, not a local file.
- The post does not contain local Windows user directories.
- The post does not contain personal email addresses, phone numbers, or account tokens.
- The post does not contain real `gpu-policy.json` content.
- The post does not contain raw support bundles or full event logs.
- The post does not contain monitor IDs, PnP device instance paths, or serial numbers.
- The post does not contain local app library paths.
- The post does not promise to permanently solve every eGPU crash; it says "diagnose and mitigate."
- The post states that the license is source-available, non-commercial, and attribution-required, not OSI open source.

## Suggested Posting Order

1. After a GitHub release is available, post the English short version to eGPU.io or Reddit.
2. Post the Chinese long version to V2EX, Zhihu, CSDN, or a personal technical blog.
3. If people reply, share only sanitized state summaries, not raw support bundles.
4. If a community asks for logs, export the default support bundle and review it manually first. Do not publicly share a bundle generated with `-IncludePrivateDetails`.
5. Turn useful feedback into issues or documentation updates, then run a privacy scan before committing changes.
