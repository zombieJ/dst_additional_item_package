---
name: "dst-test-plan"
description: "通过对比当前分支与 `master`（或用户指定的其他基准引用）、检查差异，并把变更行为整理成最小可行的游戏内检查清单，为这个 Don't Starve Together 模组生成手动测试计划。当用户要求测试计划、QA 清单、验证步骤、回归清单，或询问如何在没有自动化测试的情况下手动测试 DST 模组改动时使用。"
---

# DST 测试计划

使用这个 skill 根据 git 变更生成手动测试计划。

## 工作流程

1. 除非用户指定其他基准，否则将当前分支与 `master` 对比：
   - `git --no-pager diff --stat master...HEAD`
   - `git --no-pager diff --name-status master...HEAD`
   - `git --no-pager log --oneline master..HEAD`
2. 只读取理解行为所需的已变更文件。
3. 将 diff 归纳为少量测试主题，而不是逐文件叙述。
4. 为每个变更行为编写能证明它的最短手动测试。
5. 优先使用直接生成/设置命令，而不是漫长的生存流程。
6. 如果变更涉及白天/黄昏/夜晚、天数推进、月相、季节、周期计时器或随时间变化的组件，先使用 `dst_reader` skill 查原版时间相关代码，再写测试命令。

## 设置规则

- 控制台命令必须是玩家能直接粘贴到 DST 控制台执行的公开调试指令或事件调用，例如 `c_give(...)`、`c_spawn(...)`、`c_select(...)`、`c_countprefabs(...)`、`TheWorld:PushEvent(...)`。
- 不要输出需要在控制台里注入局部变量或临时 Lua 脚本的命令，例如 `local i = SpawnPrefab(...)`、`local x,y,z = ...`、`for ... do ... end`、直接调用 `SpawnPrefab(...)` 后再改组件字段等。
- 如果某个状态无法只靠公开控制台命令设置，优先改用游戏内可操作路径：给予开发道具、生成目标 prefab、让玩家点击/施法/放入容器/烹饪/收获。
- 如果仍然没有公开入口能设置该状态，在测试用例里明确写“当前无法仅靠公开控制台命令快速设置，需要先添加临时调试命令/开发道具入口”，不要伪造不可直接执行的命令。
- 当变更行为发生在物品或消耗品上时，优先使用 `c_give("<prefab>")`。
- 当变更行为发生在世界物体、生物、植物、建筑或特效上时，优先使用 `c_spawn("<prefab>")`。
- 如果功能基于配方，提供以下两类命令：
  - 需要时提供制作站的生成命令
  - 提供制作所需材料的给予命令
- 如果不需要通过制作来证明变更，就跳过制作，直接给予/生成最终 prefab。
- 如果行为依赖某种状态，包含所需的最少额外设置命令。
- 如果行为依赖物品内部组件状态，但没有公开控制台入口能直接设置，优先寻找本 mod 已暴露的开发物品或调试行为；找不到时把它作为测试前置缺口说明。

## 时间相关测试

当测试目标和时间有关时，先判断它依赖的是哪一类时间源，再给出最短切换命令。

- 如果依赖白天/黄昏/夜晚，优先使用原版 `clock` 事件切换阶段：
  - `TheWorld:PushEvent("ms_setphase", "day")`
  - `TheWorld:PushEvent("ms_setphase", "dusk")`
  - `TheWorld:PushEvent("ms_setphase", "night")`
  - `TheWorld:PushEvent("ms_nextphase")`
- 如果依赖新的一天或跨天刷新，使用：
  - `TheWorld:PushEvent("ms_nextcycle")`
- 如果需要固定昼夜长度，使用：
  - `TheWorld:PushEvent("ms_setclocksegs", {day = 16, dusk = 0, night = 0})`
  - `TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 0, night = 16})`
- 如果依赖月相，使用：
  - `TheWorld:PushEvent("ms_setmoonphase", {moonphase = "full", iswaxing = true})`
  - `TheWorld:PushEvent("ms_setmoonphase", {moonphase = "new", iswaxing = true})`
- 如果依赖季节，使用：
  - `TheWorld:PushEvent("ms_setseason", "autumn")`
  - `TheWorld:PushEvent("ms_setseason", "winter")`
  - `TheWorld:PushEvent("ms_setseason", "spring")`
  - `TheWorld:PushEvent("ms_setseason", "summer")`
  - `TheWorld:PushEvent("ms_advanceseason")`
- 如果依赖组件自己的定时器、冷却、腐烂、燃烧、生产或周期任务，先用 `dst_reader` 检查对应原版组件的时间字段和更新函数，再决定是切换世界时间、调用 `LongUpdate`，还是等待最短秒数。
- 在输出测试计划时，写明要观察的时间点。例如“切到夜晚后立刻检查一次，再推进一天后检查一次”。
- 如果控制台命令来自原版事件，说明已根据 `dst_reader` 检查过 `components/clock.lua` 或 `components/seasons.lua`。

## 需要读取的内容

- `modmain.lua`：确认功能已经接入。
- `scripts/hooks/`：检查行为补丁和注入逻辑。
- `scripts/prefabs/`：检查物品、建筑、食物和生物行为。
- `scripts/recpiesHooker.lua`：查找配方材料、制作过滤器和制作建筑。
- `scripts/prefabsHooker.lua`：查找添加到原版 prefab 上的行为。
- 时间相关变更：使用 `dst_reader` 读取原版 `components/clock.lua`、`components/seasons.lua`，以及实际被 hook 或调用的原版组件。
- 使用 `rg` 查找 prefab 名称、配方，以及适合控制台设置的切入点。

有用的搜索命令：

```powershell
rg -n "Prefab\\(\" scripts
rg -n "rec\\(|AddRecipe|AddRecipe2|Ingredient\\(" scripts
rg -n "c_give|c_spawn|ThePlayer|GetSkillInfo|DoDelta" scripts
rg -n "ms_setphase|ms_nextcycle|ms_setmoonphase|ms_setseason|LongUpdate|DoTaskInTime|DoPeriodicTask" scripts
```

## 测试计划风格

保持计划简洁、实用。

每个测试用例包含：

1. 目标
2. 设置
3. 步骤
4. 预期结果

优先输出类似格式：

```markdown
## 1. 种子品质增益
目标：确认品质会改变可食用物品的恢复数值。

设置：
- `c_give("carrot_seeds", 5)`
- `c_give("reskin_tool")`

步骤：
1. 使用调试物品提高种子品质。
2. 吃掉一颗种子。

预期：
- 饥饿/生命/理智变化符合新的品质倍率。
```

## 规划启发

- 优先使用一个端到端证明新行为的测试，而不是多个细碎重复的测试。
- 只有当 diff 暗示可能出现破坏时，才添加第二个回归测试。
- 如果功能同时影响生食和熟食，只有当 diff 触及两条路径时才同时测试两者。
- 如果 hook 改变了合并/拆分/保存/加载行为，只有在证明该行为确实需要时，才加入堆叠、丢弃、重进游戏或重新烹饪步骤。
- 当命令名或 prefab 名称是根据代码推断出来的，要明确说明假设。

## 输出期望

使用这个 skill 回答时：

- 先用一段话概述从 diff 得出的测试范围。
- 然后列出手动测试用例。
- 只包含可直接粘贴到游戏控制台运行的公开命令；不要包含 `local` 变量、循环、临时函数或直接改组件字段的 Lua 片段。
- 对无法用公开控制台命令快速设置的前置状态，明确写出需要的游戏内操作或需要补充的临时调试入口。
- 优先选择开发者能在本地调试世界中最快执行的路径。
