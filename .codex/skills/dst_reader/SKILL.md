---
name: "dst_reader"
description: "Read Don't Starve Together base-game scripts, this mod's files, and animation resource references when implementing or verifying DST APIs and prefab behavior. Use when code depends on DST components, prefabs, widgets, stategraphs, AnimState bank/build/symbol names, or when Codex needs to inspect a game's item animation contents."
---

# DST Reader

Use this skill when work depends on DST engine, game-script details, or animation resource references.

## Source priorities

1. Base-game scripts:

```text
D:\softwares\Steam\steamapps\common\Don't Starve Together\data\databundles\scripts
```

2. Base-game animation resources:

```text
D:\softwares\Steam\steamapps\common\Don't Starve Together\data\anim
```

3. Current mod workspace.

## Workflow

1. Identify the target API, component, prefab, widget, stategraph, or animation resource.
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

## Animation resources

When asked to inspect a game's item animation, trace the resource name from code before unpacking files.

1. Search the relevant prefab, hook, component, or stategraph for `Asset("ANIM", "anim/<name>.zip")`, `AnimState:SetBank`, `AnimState:SetBuild`, `AnimState:PlayAnimation`, and `AnimState:OverrideSymbol`.
2. Treat bank, build, and prefab names as related but not always identical. Equipment, swap builds, effects, and overrides may require inspecting more than one animation zip.
3. Locate the zip in this order: this mod's `anim/<name>.zip`, then `package/anim/<name>.zip` for reference only, then base-game `D:\softwares\Steam\steamapps\common\Don't Starve Together\data\anim\<name>.zip`.
4. If the animation contents need to be viewed, create `_anim/<name>` in the current repo if needed, copy the matching zip there, extract it into that same folder, then run:

```powershell
npm run krane -- .\_anim\<name>
```

The `krane` script expects `anim.bin`, `build.bin`, and the atlas `.tex` files in the target folder, then writes `.scml` and frame PNGs to `_anim/<name>/output`.

Keep `_anim` as a local inspection workspace. Do not move files into `exported_done`, and do not run DST compile tools or create committed `anim/*.zip`, `*.tex`, or `*.xml` outputs while only inspecting resources.

## Practical guidance

- Prefer primary source verification over memory.
- If a symbol starts with `aip` or `aipc`, inspect the mod first.
- If the symbol is vanilla DST, inspect the base-game scripts first.
- When explaining findings, cite the exact file you checked.
- When unpacking animation resources, cite both the code reference that named the resource and the copied zip path.

