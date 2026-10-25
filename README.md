# Fence Distance Hotfix

Lets husbandry mods be placed again after FS25 patch 1.25 changed the validation of the distance between fence posts.

## Why you need it

Patch 1.25 added a minimum length for a fence segment, based on the shortest panel of that fence. A pasture with a built-in fence checks every built-in segment while you place it. If one segment is shorter than the minimum, the pasture cannot be placed anywhere: the cursor shows **Distance too short**, and nothing appears in the log.

Some husbandry mods have such a segment. For example, in FS25_FencelessPastures 1.0.0.0 the sheep/goat, chicken and pig pastures cannot be placed on 1.25, while the cow and horse pastures still can.

## A temporary fix

This mod is a stopgap. It keeps affected pastures placeable so husbandry mod authors can update their mods for patch 1.25 without hurry. The hotfix will be retired in a while, once authors have had time to update. Once the husbandry mods you use are updated, you no longer need this mod.

## Features

- **Pastures place again** - a pasture whose built-in fence has a short segment can be placed, as before patch 1.25.
- **Should work for every pasture** - with no settings and no changes to the husbandry mod.
- **Short segments look as before 1.25** - a segment too short for one panel gets no fence panel, which is how the game built it before the patch.
- **Your own fences keep the new rule** - fences you draw with the fence tool, including a pasture's customizable side, still need the 1.25 minimum length.
- **Nothing is saved** - the mod writes no savegame data, and pastures placed with it still load after you remove it.
- **Singleplayer only** - this version does not support multiplayer.

## Installation

### From GitHub Releases
1. Download the latest release from [Releases](https://github.com/rittermod/FS25_FenceDistanceHotfix/releases)
2. Place the `.zip` file in your mods folder:
   - **Windows**: `%USERPROFILE%\Documents\My Games\FarmingSimulator2025\mods\`
   - **macOS**: `~/Library/Application Support/FarmingSimulator2025/mods/`
3. Enable the mod in-game

### Manual Installation
1. Clone or download this repository
2. Copy the `FS25_FenceDistanceHotfix` folder to your mods folder
3. Enable the mod in-game

## Usage

Enable the mod for your savegame, then place the pasture as usual. There is nothing to configure.

The mod only changes the fence length check while you place a pasture. Every other placement check still applies, for example owned land, collisions with other objects, and the fence tool's own checks.

## Troubleshooting

The log shows one `FALLBACK:` line for each short segment the mod let through, with its length and the fence's panel data. Include those lines when you report a problem.

If the log shows no `FALLBACK:` lines, open the developer console and run:

```
rmSetLoglevel FenceDistanceHotfix DEBUG
```

Then place the pasture again.

## Compatibility

- **Game Version**: Farming Simulator 25, patch 1.25 or later. On earlier patches the mod has nothing to do.
- **Multiplayer**: Not supported yet - singleplayer only
- **Platform**: PC (Windows/macOS)

## Known limitations

- A short built-in segment gets no fence panel, so a visible fence shows a gap there, as it did before patch 1.25. To get a panel on that segment, the husbandry mod itself needs an update.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

This mod is provided as-is for personal use with Farming Simulator 25.

## Credits

- **Author**: [Ritter](https://github.com/rittermod)

## Support

Found a bug or have a feature request? [Open an issue](https://github.com/rittermod/FS25_FenceDistanceHotfix/issues)
