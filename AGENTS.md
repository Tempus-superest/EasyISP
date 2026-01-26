# EasyISP

**EasyISP** is a **KSP** add-on that uses **ModuleManager** to modify engine performance by editing the **atmosphereCurve** on each targeted **Engine module** (including **ModuleEngines** and **ModuleEnginesFX**). The patch adjusts **Sea-level Isp** and **Vacuum Isp** by changing the curve so **ISP** values at 1 atm and 0 atm shift in a predictable, global way while preserving each engine’s curve shape and relative behavior.

## References 

- `/AGENTS.md` - AI coding tool instructions for working in this repo
- `/README.md` - Human facing overview of **EasyISP**

## Terminology

Use these exact terms consistently across docu and code.

- **EasyISP**: This **KSP** add-on.
- **KSP**: Kerbal Space Program.
- **ISP**: Specific impulse; the engine efficiency metric used by **KSP**.
- **Sea-level Isp**: Isp at 1 atm.
- **Vacuum Isp**: Isp at 0 atm.
- **atmosphereCurve**: The **KSP** engine config curve mapping atmospheric pressure to **ISP**.
- **Engine module**: The part module category targeted by **EasyISP**
- **ModuleManager**: The patching system **KSP** uses to modify configs at load time.
- **ModuleEngines**: An **Engine module** that uses **atmosphereCurve** to map pressure to **ISP**.
- **ModuleEnginesFX**: An **Engine module** equivalent to **ModuleEngines** with additional visual/audio effects

## Core Rules

### versioning Rules

All required files MUST be updated on every version change. The version MUST match across `EasyISP.version`, the Git tag, and the GitHub Release.

#### Required version format

- Release version format: `X.Y.Z`.
- Release tag format: `vX.Y.Z`.
- All locations that store a version MUST use these formats.

#### File list

Files required to be udpated when updating version

- `EasyISP.version` — Update: `VERSION` (MAJOR/MINOR/PATCH) to `X.Y.Z`.
- `EasyISP.version` — Update: `DOWNLOAD` to `https://github.com/Tempus-superest/EasyISP/releases/tag/vX.Y.Z`.
- `README.md` — Update: `Current Version` link text to `vX.Y.Z`.
