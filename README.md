# EasyISP - A Mod for Kerbal Space Program Users

Current Version - [v1.3.1](https://github.com/Tempus-superest/EasyISP/releases/tag/v1.3.1)

**EasyISP** is a **KSP** add-on that increases engine efficiency so your rockets can go farther on the same amount of fuel. In **KSP**, higher **ISP** means you get more delta-v from a single tank. **EasyISP** applies **ModuleManager** patches that edit the **atmosphereCurve** on each targeted **Engine module** (including **ModuleEngines** and **ModuleEnginesFX**), applying a predictable global **ISP** multiplier while keeping each engine’s curve shape and relative behavior intact. The default **ISP** multiplier applied by **EasyISP** is `2`.

Tune **ISP** down for a tougher career, up for a more relaxed game, or push into near-future performance and simulate fictional settings like *The Expanse*.

**EasyISP** is designed as a global multiplier that scales the final ISP values produced by your full mod stack.

## Features

- Applies a global **ISP** adjustment across engine **atmosphereCurve** data.
- Modifies each targeted **Engine module** (covers **ModuleEngines** and **ModuleEnginesFX**) via **ModuleManager**.
- Scales all engines **ISP** uniformly while preserving their relative performance profile.
- Supports B9PartSwitch engine subtypes. Stored engine configs are scaled so switching modes preserves the EasyISP multiplier.
- No in-game UI required; effects apply automatically on game load.
- Uses ModuleManager `:FINAL` pass so the multiplier is applied last after other mods.

## Installation

Install EasyISP via [CKAN](https://github.com/KSP-CKAN/CKAN) for an automated setup; CKAN installs the same files/layout described below.

### Manual installation

- Download the [latest release](https://github.com/Tempus-superest/EasyISP/releases) of **EasyISP** or the ZIP from [SpaceDock](https://spacedock.info/mod/4132/EasyISP).
- Extract the downloaded archive.
- Copy the `EasyISP` folder into your **KSP** `GameData` directory.
- Launch **KSP**.

## Instructions

After installation, **EasyISP** applies its **ModuleManager** patches automatically during game load. No additional setup is required for the default behavior; the default **ISP** multiplier is `2`.

## Customize **ISP** away from the default value

You can adjust the global **ISP** multiplier to tune overall engine efficiency.

- Open `GameData/EasyISP/EasyISP.cfg`.
- Find the `EASYISP_SETTINGS` block.
- Set `ispMultiplier` to scale **ISP** for all engines.
- Save the file and restart **KSP**.

## Support

If you encounter any issues or have suggestions for improvements, please feel free to open an issue on the [GitHub repository](https://github.com/Tempus-superest/EasyISP/issues).

## License

This project is released into the public domain under The Unlicense, which means you can use, modify, and distribute it without any restrictions. More details can be found in the LICENSE file.

## Acknowledgments

- Special thanks to the Kerbal Space Program community for their valuable feedback and support.
