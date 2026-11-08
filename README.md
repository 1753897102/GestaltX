<p align="center">
  <img src="GestaltX/Assets.xcassets/AppIcon.appiconset/AppIcon.png" alt="GestaltX" width="112" height="112">
</p>

<h1 align="center">GestaltX</h1>

[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/huami1314/GestaltX)
[![Platform](https://img.shields.io/badge/iOS-26.0--26.7.2%20%2F%2027.x-black?logo=apple)](#compatibility)
[![SwiftUI](https://img.shields.io/badge/Swift-SwiftUI-orange?logo=swift)](https://github.com/huami1314/GestaltX)
[![License](https://img.shields.io/badge/license-GPLv3-blue)](LICENSE)

[English](README.md) · [简体中文](README_ZH-CN.md)

A MobileGestalt editor for iPhone and iPad. Developed by [huamidev](https://github.com/huami1314).

## Features

| Category | Presets and tools |
| --- | --- |
| Display | Dynamic Island capability and layout, Always-On Display, AOD Vibrancy, Liquid Glass low-power rendering |
| Device | Model name, boot/shutdown chime, charge limit, tap to wake, Camera Control settings, Action Button settings |
| iPad | Apple Pencil settings, Stage Manager capability, iPad app compatibility |
| Intelligence | Apple Intelligence capability flag and sales-region options, including activation attempts on China-mainland devices |
| Advanced | Apple internal feature flags, internal storage view, Security Research Device flag |
| Field editor | Read, search, add, edit, and remove `CacheExtra` fields; local plist import/export; String, Integer, Real, Boolean, Data, Date, Array, and Dictionary values |
| Changes | Automatic reading and manual re-read, staged before/after review, verified writes |
| Backups | Automatic and manual backups; open, export, restore, and delete |
| Logs & respring | Actual exploit-stage logs and manual NeoSpring respring |

Presets modify capability flags; actual effects depend on the device and OS. China-mainland devices can use the Apple Intelligence and region options to attempt activation; availability also depends on the model, OS version, and Apple services.

Back up your device before making changes. Incorrect MobileGestalt values can cause system instability or require a device restore.

## Compatibility

Supports **iOS / iPadOS 26.0–26.7.2 / 27.x**. Powered by [worse_query](https://github.com/forcequitOS/worse_query). SystemGroup access requires iOS 27; available features depend on the device and OS. Local plist editing is also supported.

Signing requires a certificate and provisioning profile with at least one usable App Group. GestaltX detects the signed App Group at runtime.

## Language support

GestaltX follows your iOS language settings, with English as the default and fallback. Persian includes right-to-left layout support.

| Language | Locale |
| --- | --- |
| English | `en` |
| 简体中文 — Simplified Chinese | `zh-Hans` |
| 繁體中文（台灣）— Traditional Chinese (Taiwan) | `zh-Hant-TW` |
| 繁體中文（香港）— Traditional Chinese (Hong Kong) | `zh-Hant-HK` |
| Tiếng Việt — Vietnamese | `vi` |
| Русский — Russian | `ru` |
| فارسی — Persian | `fa` |

## Credits

- [forcequitOS / Taj C — worse_query](https://github.com/forcequitOS/worse_query)
- [neonmodder123](https://github.com/neonmodder123)
- [skadz108](https://github.com/skadz108)
- [rooootdev — NeoSpring](https://github.com/rooootdev/neospring)
- [Nouvborne — Ketamine](https://github.com/Nouvborne/Ketamine)
- [PoomSmart — MGKeys](https://github.com/PoomSmart/MGKeys)
- [leminlimez — Nugget](https://github.com/leminlimez/Nugget)
- [rooootdev — mond](https://github.com/rooootdev/mond)
- [frs0n — GestaltEdit](https://github.com/frs0n/GestaltEdit)

## License

[GNU GPL v3](LICENSE) · Copyright © 2026 huamidev.
