# Abysall Hosted — Self-Contained UI Library

This repository hosts the self-contained version of the **Abysall** UI interface module.

All dependencies use multiple CDN fallback mirrors, and Abysall-owned modules
(InfoTab, SettingsTab) are inlined directly into a single file.

## Files

| File | Description |
|------|-------------|
| `Interface.luau` | Main entry module (single-file, self-contained) |
| `InfoTab.luau`  | Information tab module |
| `SettingsTab.luau` | Settings tab module |

## Usage

```lua
loadstring(game:HttpGet("YOUR_CDN_URL/Interface.luau"))()
```

The default theme is **CreamBlue** (奶蓝).

## Credits

Original project: [bocaj111004/Abysall](https://github.com/bocaj111004/Abysall)
