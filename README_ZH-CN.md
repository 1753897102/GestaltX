# GestaltX

[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/huami1314/GestaltX)
[![Platform](https://img.shields.io/badge/iOS-26.0%2B-black?logo=apple)](#兼容性)
[![SwiftUI](https://img.shields.io/badge/Swift-SwiftUI-orange?logo=swift)](https://github.com/huami1314/GestaltX)
[![License](https://img.shields.io/badge/license-GPLv3-blue)](LICENSE)

[English](README.md) · [简体中文](README_ZH-CN.md)

适用于 iPhone 和 iPad 的 MobileGestalt 编辑工具，由 [huamidev](https://github.com/huami1314) 开发。

## 功能

| 分类 | 预设与工具 |
| --- | --- |
| 显示 | 灵动岛功能标记与布局、全天候显示、AOD 色彩、液态玻璃低性能渲染 |
| 设备 | 机型名称、开关机提示音、充电上限、轻点唤醒、相机控制设置、操作按钮设置 |
| iPad | Apple Pencil 设置、台前调度功能标记、iPad 应用兼容性 |
| 智能 | Apple 智能功能标记、销售地区选项 |
| 高级 | Apple 内部功能标记、内部存储视图、安全研究设备标记 |
| 字段编辑 | 读取、搜索、添加、编辑与删除 `CacheExtra` 字段；本地 plist 导入导出；支持字符串、整数、浮点数、布尔值、数据、日期、数组和字典 |
| 更改管理 | 启动自动读取、手动重新读取、暂存更改前后对比、写入验证 |
| 备份 | 自动与手动备份；打开、导出、恢复和删除 |
| 日志与注销 | 实际漏洞利用过程日志、手动 NeoSpring 注销 |

预设修改的是功能标记，实际效果取决于设备与系统。

修改前请备份设备。错误的 MobileGestalt 值可能导致系统不稳定，严重时需要恢复设备。

## 兼容性

应用要求 iOS / iPadOS 26.0 及以后版本。[worse_query](https://github.com/forcequitOS/worse_query) 声明的范围为 iOS 26.0–26.7.2 / 27.2，但仅列明 iOS 27 可访问 `SystemGroup`；本机 MobileGestalt 访问会实际检测，无法访问时仍可编辑本地 plist。

签名所用的证书及描述文件必须提供至少一个可用的 App Group。GestaltX 会在运行时读取实际签名中的 App Group，以兼容重签。

## 语言

English · 简体中文 · 繁體中文（台灣）· 繁體中文（香港）· Tiếng Việt · Русский · فارسی

## 鸣谢

- [forcequitOS / Taj C — worse_query](https://github.com/forcequitOS/worse_query)
- [neonmodder123](https://github.com/neonmodder123)
- [skadz108](https://github.com/skadz108)
- [rooootdev — NeoSpring](https://github.com/rooootdev/neospring)
- [Nouvborne — Ketamine](https://github.com/Nouvborne/Ketamine)
- [PoomSmart — MGKeys](https://github.com/PoomSmart/MGKeys)
- [leminlimez — Nugget](https://github.com/leminlimez/Nugget)
- [rooootdev — mond](https://github.com/rooootdev/mond)
- [frs0n — GestaltEdit](https://github.com/frs0n/GestaltEdit)

## 许可证

[GNU GPL v3](LICENSE) · Copyright © 2026 huamidev。
