---
name: "dst_reader"
description: "Read Don't Starve Together base-game scripts and this mod's files when implementing or verifying DST APIs. Use when code depends on DST components, prefabs, widgets, stategraphs, or engine-side Lua behavior."
---

# DST Reader

Use this skill when work depends on DST engine or game-script details.

## Source priorities

1. Base-game scripts:

```text
D:\softwares\Steam\steamapps\common\Don't Starve Together\data\databundles\scripts
```

2. Current mod workspace.

## Workflow

1. Identify the target API, component, prefab, widget, or stategraph.
2. Read the corresponding DST source file first.
3. Verify the exact method or field exists before using it in mod code.
4. Then compare with the mod's implementation and patch only after the API shape is confirmed.

## Verification rule

Before using a DST method, find its definition in the game scripts.

Examples:

- `components/edible.lua`
- `components/health.lua`
- `prefabs/torch.lua`
- `widgets/*.lua`
- `stategraphs/*.lua`

Search for concrete definitions such as:

- `function Edible:OnEaten`
- `function Health:DoDelta`

## Practical guidance

- Prefer primary source verification over memory.
- If a symbol starts with `aip` or `aipc`, inspect the mod first.
- If the symbol is vanilla DST, inspect the base-game scripts first.
- When explaining findings, cite the exact file you checked.

