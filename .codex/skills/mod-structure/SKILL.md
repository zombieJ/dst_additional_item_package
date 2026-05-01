---
name: "mod-structure"
description: "Explain the structure of the dst_additional_item_package mod. Use when the task is to orient within this repository, find where features live, or recall naming conventions and core directories."
---

# Mod Structure

This skill is for navigating the `dst_additional_item_package` repository.

## Start here

- `modmain.lua`: mod bootstrap, imports, prefab registration, hooks
- `modinfo.lua`: metadata and config options
- `scripts/`: core Lua gameplay code
- `scripts/prefabs/`: prefab implementations
- `scripts/components/`: custom components
- `scripts/hooks/`: integration hooks into DST behavior
- `scripts/configurations/`: shared config tables
- `gen/`: asset or content generation scripts
- `tools-scripts/`: packaging and helper scripts
- `images/`, `anim/`, `exported/`: art and exported assets

## Naming conventions

- `aip_`: custom prefabs
- `aipc_`: custom components
- `AIP_`: tuning/config constants
- `aip*`: shared helper functions, often in `scripts/aipUtils.lua`

## Navigation rules

1. If the target starts with `aip` or `aipc`, inspect this repo first.
2. Check `modmain.lua` to see how the feature is wired in.
3. Reuse helpers from `scripts/aipUtils.lua` when possible instead of re-implementing utilities.
4. For recipe questions, inspect `scripts/recpiesHooker.lua` and related config.
5. For prefab behavior patches, inspect `scripts/prefabsHooker.lua` and `scripts/hooks/`.

## Useful reminders

- This mod is large and feature-dense; avoid assuming a feature is isolated to one file.
- Many behaviors are introduced via hooks rather than the prefab file alone.
- Dev-only behavior is often gated by `dev_mode`.

