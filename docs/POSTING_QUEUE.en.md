# Community Posting Queue

> Purpose: publish this project to suitable communities in a controlled, privacy-safe order.
> Last checked: 2026-06-20.
> Privacy rule: share only the public repository link, generic symptoms, generic hardware categories, and sanitized troubleshooting strategy. Do not share local paths, real config, support bundles, logs, device IDs, monitor IDs, serial numbers, account emails, tokens, or keys.

Repository: https://github.com/dydpop/laptop-egpu-gpu-conflict-solution

## Posting Strategy

Start with the most targeted eGPU and hardware communities. The first wave should test whether other users recognize the same state-machine model, monitor active-state misclassification, WHEA 17, TDR, DXGI device removed, and hot-plug failure patterns. Do not post the same content everywhere at once; one focused post per platform is enough.

## Priority 1

### 1. eGPU.io - Thunderbolt Windows eGPU

- Entry: https://egpu.io/forums/pc-setup/
- Posting entry: `Add topic` on the forum page.
- Language: English.
- Suggested title:
  `Windows 11 Intel iGPU + NVIDIA eGPU conflict mitigation toolkit: hot-plug, WHEA 17, TDR, DXGI device removed`
- Suggested content: use the English Short Post in `docs/COMMUNITY_OUTREACH.en.md`; expand with the Long Post Outline if needed.
- Login status: login required before posting.
- Current judgment: highest priority. This is the most targeted audience, and the board already has related Windows eGPU, WHEA, disconnect, Code 14/47, internal-display, external-display, and performance topics.
- Note: do not post local logs or real support bundles. Ask for sanitized WHEA/TDR behavior and display topology feedback only.

### 2. Reddit - r/eGPU

- Entry: https://www.reddit.com/r/eGPU/
- Posting entry: https://www.reddit.com/r/eGPU/submit
- Language: English.
- Suggested title:
  `Hybrid GPU conflict mitigation for Windows laptops with Intel iGPU + NVIDIA eGPU`
- Suggested content: use the English Short Post in `docs/COMMUNITY_OUTREACH.en.md`.
- Login status: Reddit login required; the submit URL redirects to login when signed out.
- Current judgment: second priority. The audience is targeted enough to collect feedback from different enclosures, cables, drivers, and GPU generations.
- Note: avoid exaggerated titles, short links, affiliate links, sales language, or claims that the toolkit permanently solves every crash.

## Priority 2

### 3. V2EX - Hardware

- Entry: https://www.v2ex.com/go/hardware
- Language: Chinese.
- Suggested title:
  `基于笔记本外接桌面级显卡坞的显卡冲突问题解决方案：Intel 核显 + NVIDIA eGPU + Windows 11`
- Suggested content: use the Chinese short post in `docs/COMMUNITY_OUTREACH.zh-CN.md`; expand into a longer post if feedback is good.
- Login status: V2EX login required.
- Current judgment: first Chinese-language priority. The hardware node is active and fits Chinese hardware, docking, monitor, and Windows troubleshooting discussions.
- Note: write it as a field report and troubleshooting note, not a promotional announcement.

### 4. Intel Community - Graphics

- Entry: https://community.intel.com/t5/Graphics/bd-p/graphics
- Posting entry: https://community.intel.com/t5/forums/postpage/board-id/graphics
- Language: English.
- Suggested title:
  `Hybrid Intel iGPU + NVIDIA eGPU on Windows: display-active detection and rollbackable GPU preferences`
- Suggested content: keep it short. Emphasize keeping Intel as fallback, distinguishing connected monitors from desktop-active monitors, and applying rollbackable current-user graphics preferences.
- Login status: Intel account required; some actions may require email verification.
- Current judgment: useful for Intel graphics, integrated GPU, multi-monitor, Windows graphics preferences, and DirectX crash discussions.
- Note: avoid framing it as an NVIDIA or Razer complaint. Keep the focus on hybrid GPU policy and rollback.

### 5. Razer Insider - Razer Support

- Entry: https://insider.razer.com/razer-support-45
- Posting entry: `Create` on the forum page.
- Language: English.
- Suggested title:
  `Razer Core-class eGPU stability checklist for Windows hybrid GPU conflicts`
- Suggested content: post only the Razer Core-class enclosure-relevant parts: cable, power, firmware, hot-plug, Windows event log checks, and the repository link.
- Login status: Razer login required.
- Current judgment: suitable for enclosure-specific discussion, but broader and less technically focused than eGPU.io.
- Note: Razer asks support threads to be detailed, focused, non-duplicative, and clearly titled. Do not write an emotional complaint; write a reproducible checklist.

### 6. NVIDIA GeForce Forums

- Entry: https://www.nvidia.com/en-us/geforce/forums/discover/
- Language: English.
- Suggested title:
  `Windows eGPU hot-plug crashes and DXGI device removed: Intel iGPU + NVIDIA external GPU mitigation toolkit`
- Suggested content: focus on NVIDIA eGPU, TDR, DXGI device removed, device lost, and pre-eject checks.
- Login status: JavaScript and browser login required.
- Current judgment: large audience, but the topic can easily be treated as a driver/game/hardware support issue. Use this in the second wave.
- Note: frame the post as a diagnostic toolkit and rollbackable policy, not as a driver complaint.

## Priority 3: Chinese Long-Form Platforms

### 7. Zhihu

- Entry: https://www.zhihu.com/
- Language: Chinese.
- Recommended format: article rather than short status update.
- Suggested title:
  `笔记本外接桌面级显卡坞后，核显和 NVIDIA eGPU 冲突应该怎么排查？`
- Suggested content: use the Chinese long-post structure and cover the root cause model, state machine, hot-plug workflow, rollback, and privacy boundary.
- Login status: Zhihu login required; the site may trigger a manual security verification.
- Current judgment: useful for long-term Chinese search visibility.

### 8. CSDN

- Entry: https://www.csdn.net/
- Writing entry: https://editor.csdn.net/md
- Language: Chinese.
- Recommended format: technical article.
- Suggested title:
  `Windows 笔记本 Intel 核显 + NVIDIA eGPU 冲突诊断与可回滚策略`
- Suggested content: use the Chinese long-post structure, repository link, and privacy boundary.
- Login status: login required.
- Current judgment: useful for search indexing, but usually less interactive than eGPU.io, Reddit, and V2EX.

### 9. cnblogs

- Entry: https://www.cnblogs.com/
- Writing entry: https://i.cnblogs.com/posts/edit
- Language: Chinese.
- Recommended format: technical blog post.
- Suggested title:
  `Windows 笔记本 Intel 核显 + NVIDIA eGPU 冲突诊断与可回滚策略`
- Suggested content: use the Chinese long-post structure, repository link, and privacy boundary.
- Login status: login required; the writing entry may be unavailable while signed out.
- Current judgment: useful for long-term technical writing. If only one Chinese long-form platform is selected, prefer Zhihu; if developer search indexing matters more, choose either CSDN or cnblogs.

## Suggested Posting Order

1. eGPU.io
2. Reddit r/eGPU
3. V2EX
4. Intel Community Graphics
5. Razer Insider
6. NVIDIA GeForce Forums
7. Zhihu article
8. CSDN or cnblogs

## Pre-Post Checklist

- Do not post `gpu-control/config/gpu-policy.json`.
- Do not post `gpu-control/state/`.
- Do not post raw files from `gpu-control/support-bundles/`.
- Do not post local Windows user directories, full application paths, or game library paths.
- Do not post device instance paths, monitor IDs, serial numbers, BIOS serials, or motherboard serials.
- Do not post full unredacted event logs.
- Do not post personal emails, tokens, API keys, or private keys.
- Use the original GitHub link, not short links.
- Do not promise to permanently solve every eGPU crash; describe the project as diagnosis and mitigation.

## When Login Blocks Posting

If a page shows a login wall, manual verification, disabled posting button, or JavaScript restriction, do not bypass it. Keep the platform URL and posting URL, wait for the account to be registered, signed in, and verified, then continue posting manually from the prepared drafts.

## Pages That Need Manual Login

- eGPU.io: https://egpu.io/forums/pc-setup/
- Reddit: https://www.reddit.com/r/eGPU/submit
- V2EX: https://www.v2ex.com/go/hardware
- Intel Community: https://community.intel.com/t5/forums/postpage/board-id/graphics
- Razer Insider: https://insider.razer.com/razer-support-45
- NVIDIA GeForce Forums: https://www.nvidia.com/en-us/geforce/forums/discover/
- Zhihu: https://www.zhihu.com/
- CSDN: https://editor.csdn.net/md
- cnblogs: https://i.cnblogs.com/posts/edit
