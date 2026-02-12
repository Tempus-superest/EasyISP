# EasyISP

**EasyISP** is a **KSP** add-on that uses **ModuleManager** to modify engine performance by editing the **atmosphereCurve** on each targeted **Engine module** (including **ModuleEngines** and **ModuleEnginesFX**). The patch adjusts **ISP** by applying a predictable, global multiplier while preserving each engine’s curve shape and relative behavior.

## References

- `/AGENTS.md` - AI coding tool instructions for working in this repo
- `/README.md` - Human facing overview of **EasyISP**
- `/RELEASING.md` — Maintainer-facing release process and automation rules

## Terminology

Use these exact terms consistently across docu and code.

- **EasyISP**: This **KSP** add-on.
- **KSP**: Kerbal Space Program.
- **ISP**: Specific impulse; the engine efficiency metric used by **KSP**.
- **atmosphereCurve**: The **KSP** engine config curve mapping atmospheric pressure to **ISP** values.
- **Engine module**: The part module category targeted by **EasyISP**
- **ModuleManager**: The patching system **KSP** uses to modify configs at load time.
- **ModuleEngines**: An **Engine module** that uses **atmosphereCurve** to map pressure to **ISP**.
- **ModuleEnginesFX**: An **Engine module** equivalent to **ModuleEngines** with additional visual/audio effects

## Core Rules

### ModuleManager timing

EasyISP is intended to be a global ISP multiplier. It MUST run in the ModuleManager `:FINAL` pass so it applies after all other engine balance changes and scales the final `atmosphereCurve` ISP values.

### versioning Rules

`VERSION` (repo root) is authoritative for releases and MUST contain `vX.Y.Z`. Release automation and `scripts/sync-version.sh` keep `EasyISP.version` and `README.md` in sync with `VERSION`.

#### Required version format

- Authoritative version format: `vX.Y.Z` in `VERSION`.
- Release version format in `EasyISP.version`: `X.Y.Z`.
- Release tag format: `vX.Y.Z`.
- Draft/publish behavior is controlled by `vars.RELEASE_MODE`.

#### File list

Files required to be updated when updating version

- `VERSION` — Authoritative tag-form version `vX.Y.Z`.
- `EasyISP.version` — Synced: `VERSION` (MAJOR/MINOR/PATCH) to `X.Y.Z`.
- `EasyISP.version` — Synced: `DOWNLOAD` to `https://github.com/Tempus-superest/EasyISP/releases/tag/vX.Y.Z`.
- `README.md` — Synced: `Current Version` link text/URL to `vX.Y.Z`.
