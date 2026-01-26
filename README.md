# EasyISP - A Mod for Kerbal Space Program

Current Version - [v1.1.0](https://github.com/Tempus-superest/EasyISP/releases)

**EasyISP** is a **KSP** add-on that increases engine efficiency so your rockets can go farther on the same amount of fuel. In **KSP**, higher **ISP** means you get more delta-v from a single tank. **EasyISP** applies **ModuleManager** patches that edit the **atmosphereCurve** on each targeted **Engine module** (including **ModuleEngines** and **ModuleEnginesFX**), creating a predictable global shift in **Sea-level Isp** and **Vacuum Isp** while keeping each engine’s curve shape and relative behavior intact. The default **ISP** multiplier applied by **EasyISP** is `2`.

Tune **ISP** down for a tougher career, up for a more relaxed game, or push into near-future performance and simulate fictional setting like *The Expanse*.

## Features

- Applies a global **ISP** adjustment across engine **atmosphereCurve** data.
- Modifies each targeted **Engine module** (covers **ModuleEngines** and **ModuleEnginesFX**) via **ModuleManager**.
- Shifts **Sea-level Isp** and **Vacuum Isp** predictably while preserving each engine’s relative performance profile.
- No in-game UI required; effects apply automatically on game load.

## Installation

[CKAN](https://github.com/KSP-CKAN/CKAN) installation is preferred.

### Manual installation

- Download the [latest release](https://github.com/Tempus-superest/EasyISP/releases) of **EasyISP**.
- Extract the downloaded archive.
- Copy the `EasyISP` folder into your **KSP** `GameData` directory.
- Launch **KSP**.

## Instructions

After installation, **EasyISP** applies its **ModuleManager** patches automatically during game load. No additional setup is required for the default behavior; the default **ISP** multiplier is `2`.

## Customize **ISP** away from the default value

You can adjust **Sea-level Isp** or **Vacuum Isp** independently, but matching them is recommended for consistent-feeling performance.

- Open `GameData/EasyISP/EasyISP.cfg`.
- Find the `EASYISP_SETTINGS` block.
- Set `seaLevelMultiplier` to adjust **Sea-level Isp**.
- Set `vacuumMultiplier` to adjust **Vacuum Isp**.
- Save the file and restart **KSP**.

## Support

If you encounter any issues or have suggestions for improvements, please feel free to open an issue on the [GitHub repository](https://github.com/Tempus-superest/EasyISP/issues).

## License

This project is released into the public domain under The Unlicense, which means you can use, modify, and distribute it without any restrictions. More details can be found in the LICENSE file.

## Acknowledgments

- Special thanks to the Kerbal Space Program community for their valuable feedback and support.
