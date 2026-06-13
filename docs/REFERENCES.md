# References / 参考资料

These links explain the behavior this project is built around. They are not endorsements of any single workaround.

## Official Documentation / 官方文档

- Microsoft DXGI error codes, including `DXGI_ERROR_DEVICE_REMOVED` and `DXGI_ERROR_DEVICE_RESET`: <https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/dxgi-error>
- Microsoft guidance on handling Direct3D device-lost scenarios: <https://learn.microsoft.com/en-us/windows/uwp/gaming/handling-device-lost-scenarios>
- Microsoft WDDM Timeout Detection and Recovery overview: <https://learn.microsoft.com/en-us/windows-hardware/drivers/display/timeout-detection-and-recovery>
- NVIDIA support article explaining that Windows 10 May 2020 Update (20H1) changed the process for assigning GPUs to applications: <https://nvidia.custhelp.com/app/answers/detail/a_id/5035/~/run-with-graphics-processor-missing-from-context-menu%3A-change-in-process-of>
- ASUS explanation that Windows graphics settings can determine the preferred GPU for an application: <https://www.asus.com/support/faq/1044213/>

## Community Patterns / 社区相似问题

- Barotrauma issue discussing `DXGI_ERROR_DEVICE_REMOVED`: <https://github.com/FakeFishGames/Barotrauma/issues/1833>
- G-Helper discussion with `DXGI_ERROR_DEVICE_REMOVED` during gameplay: <https://github.com/seerge/g-helper/discussions/2740>
- Dear ImGui issue involving DX11, Intel/NVIDIA selection, and `DXGI_ERROR_DEVICE_REMOVED`: <https://github.com/ocornut/imgui/issues/8418>
- eGPU.io forum thread about `DXGI_ERROR_DEVICE_REMOVED` in an eGPU setup: <https://egpu.io/forums/expresscard-mpcie-m-2-adapters/error-dxgi_error_device_removed/>

## Interpretation / 解读

The consistent pattern is:

- Device loss is a normal condition applications are expected to handle, but many desktop apps and games fail hard instead.
- TDR is a Windows recovery mechanism. Increasing TDR timeouts may hide symptoms, but it does not fix an unstable eGPU link.
- On modern Windows versions, per-app Windows graphics preferences can override older NVIDIA Control Panel defaults.
- For hot-plug eGPU use, preserving both Intel and NVIDIA while applying reversible per-user preferences is lower risk than disabling one GPU globally.
