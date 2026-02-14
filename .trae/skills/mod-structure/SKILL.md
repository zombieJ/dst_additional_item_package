---
name: "mod-structure"
description: "介绍 DST 额外物品包 mod 的文件结构。当用户询问 mod 结构、文件组织或想了解 mod 如何组织时调用。"
---

# DST 额外物品包 Mod 文件结构

本技能提供了 DST（饥荒联机版）额外物品包 mod 的文件结构概览。

## 根目录文件

| 文件 | 描述 |
|------|-------------|
| [modmain.lua](modmain.lua) | 主 mod 配置文件 - 预加载资源和注册物品 |
| [modinfo.lua](modinfo.lua) | Mod 元数据 - 名称、描述、作者、配置选项 |
| [package.json](package.json) | Node.js 包配置，用于构建工具和脚本 |
| [README.md](README.md) | 项目文档和用户反馈 |
| [TODO.md](TODO.md) | 开发待办事项列表 |

## 命名规范

### aip 前缀规则

本 mod 的所有自定义内容都使用 `aip` 前缀命名，这是识别 mod 内容的关键标识：

- **预制件**：以 `aip_` 开头（如 `aip_divine_rapier`, `aip_gourd`）
- **组件**：以 `aipc_` 开头（如 `aipc_action`, `aipc_orbit_driver`）
- **配置**：以 `AIP_` 开头（如 `AIP_DOU_SCEPTER`, `AIP_DOU_TOTEM`）
- **工具函数**：以 `aip` 开头（如 `aipPrint`, `aipSpawnPrefab`）

### 查找顺序

在开发模组时，遵循以下查找顺序：

1. **优先查找 mod 文件** - 如果组件或物品以 `aip` 开头，直接在 mod 的 `scripts/` 目录中查找
2. **检查游戏源码** - 如果找不到或不是 aip 开头，再到游戏源码中查找
3. **使用 dst_reader skill** - 当需要查找游戏 API 时，使用 dst_reader skill 从游戏源码中获取参考

### 示例

```lua
-- mod 内容（在 scripts/ 中查找）
aip_divine_rapier          -- 预制件
aipc_action                -- 组件
aipPrint()                 -- 工具函数

-- 游戏内容（使用 dst_reader 查找）
inst.components.health     -- DST 原生组件
AddRecipe2()               -- DST 原生 API
TUNING.NIGHTSWORD_DAMAGE   -- DST 原生配置
```

## 核心目录

### scripts/
包含 mod 的所有 Lua 脚本：

- **prefabs/** - 物品和实体预制件（200+ 个文件）
  - 武器、护甲、食物、建筑、装饰等
  - 示例：[aip_divine_rapier.lua](scripts/prefabs/aip_divine_rapier.lua), [aip_gourd.lua](scripts/prefabs/aip_gourd.lua)

- **components/** - 提供功能的自定义组件
  - [aipc_action.lua](scripts/components/aipc_action.lua) - 动作系统
  - [aipc_orbit_driver.lua](scripts/components/aipc_orbit_driver.lua) - 轨道系统
  - [aipc_pet_owner.lua](scripts/components/aipc_pet_owner.lua) - 宠物系统

- **brains/** - 生物的 AI 大脑
  - [aip_dragon_brain.lua](scripts/brains/aip_dragon_brain.lua) - 龙 AI
  - [aip_pet_brain.lua](scripts/brains/aip_pet_brain.lua) - 宠物 AI

- **behaviours/** - 生物行为
- **hooks/** - 游戏集成的事件钩子
- **configurations/** - Mod 配置文件
- **aipStory/** - 故事文本（中文/英文）

### artist/
美术和设计文件：
- 原始源文件（.sai, .sai2）
- 预览图片（.png, .jpg）
- Mod 图标和宣传材料

### images/
编译后的游戏图片：
- [inventoryimages/](images/inventoryimages) - 物品图标（.tex, .xml）
- [aipBuffer/](images/aipBuffer) - UI 资源

### exported/ & exported_done/
导出的动画文件（Spriter 格式）：
- .scml 动画文件
- 编译后的纹理图集

### gen/
生成工具和资源：
- [veggie.js](gen/veggie.js) - 种子生成
- [foodPreview.js](gen/foodPreview.js) - 食物预览生成器
- [init.js](gen/init.js) - 初始化脚本
- [res/](gen/res) - 资源图片

### docs/
文档：
- [develop.md](docs/develop.md) - 开发指南
- [item.md](docs/item.md) - 物品创建指南

## Mod 功能

Mod 按类别提供额外物品：
- **武器** - 额外武器配方
- **建筑** - 建筑和结构配方
- **生存** - 生存物品和工具
- **食物** - 新食物配方
- **服饰** - 衣服和护甲
- **雕塑** - 大理石雕像
- **轨道** - 轨道系统（独特功能）
- **魔法** - 魔法物品和法术

## 配置

Mod 选项在 [modinfo.lua](modinfo.lua) 中定义：
- 语言选择
- 启用/禁用物品类别
- 武器使用次数和伤害
- 食物效果
- 服饰耐久度
- 飞行图腾行为

## 开发工作流程

1. 在 [artist/](artist/) 中创建美术资源
2. 导出动画到 [exported/](exported/)
3. 在 [scripts/prefabs/](scripts/prefabs/) 中编写预制件代码
4. 在 [scripts/components/](scripts/components/) 中添加组件
5. 在 [modmain.lua](modmain.lua) 中注册物品
6. 使用 [package.json](package.json) 中的脚本构建和测试

## 关键工具

- [aipUtils.lua](scripts/aipUtils.lua) - 辅助函数
- [componentsHooker.lua](scripts/componentsHooker.lua) - 组件系统集成
- [prefabsHooker.lua](scripts/prefabsHooker.lua) - 预制件系统集成
- [custom_tech_tree.lua](scripts/custom_tech_tree.lua) - 自定义科技树

## aipUtils.lua 函数检查规范

本 mod 的核心辅助工具是 [aipUtils.lua](scripts/aipUtils.lua)，其中定义了 60+ 个全局辅助函数。在进行任何代码开发或修改时，**必须**遵循以下规范：

### 1. 优先检查 aipUtils.lua

当代码中出现 `_G.aip` 开头的函数调用时，**必须首先**检查该函数是否已在 [aipUtils.lua](scripts/aipUtils.lua) 中定义。避免重复实现已存在的功能。

### 2. aipUtils.lua 核心函数列表

**表格操作：**
| 函数 | 描述 |
|------|------|
| `aipCountTable(tbl)` | 计算表格元素数量 |
| `aipInTable(tbl, match)` | 查询元素是否在表格中 |
| `aipFlattenTable(originTbl)` | 打平表格 |
| `aipTableRemove(tbl, item)` | 从表格中移除元素 |
| `aipTableSlice(tbl, start, len)` | 表格切片 |
| `aipTableConcat(tbl1, tbl2)` | 合并表格 |
| `aipTableIndex(tbl, item)` | 查找元素索引 |
| `aipFilterTable(originTbl, filterFn)` | 过滤表格 |
| `aipCloneTable(originTbl)` | 复制表格 |
| `aipFilterKeysTable(originTbl, keys)` | 按 key 过滤 |
| `aipTableKeys(tbl)` | 获取所有 key |
| `aipTableMap(tbl, fn)` | Map 遍历表格 |

**调试输出：**
| 函数 | 描述 |
|------|------|
| `aipPrint(...)` | 基础打印 |
| `aipStr(...)` | 字符串拼接 |
| `aipTypePrint(...)` | 带类型打印 |

**位置与距离：**
| 函数 | 描述 |
|------|------|
| `aipGetAngle(src, tgt)` | 获取角度 (0~360) |
| `aipAngleDist(sourcePos, angle, distance)` | 按角度前进 |
| `aipDiffAngle(a1, a2)` | 计算角度偏差 |
| `aipToAngle(srcAngle, tgtAngle, step)` | 角度过渡 |
| `aipDist(p1, p2, includeY)` | 两点距离 |

**实体查找：**
| 函数 | 描述 |
|------|------|
| `aipFindNearEnts(inst, prefabNames, distance, includeInv)` | 查找附近实体 |
| `aipFindNearPlayers(inst, dist)` | 查找附近玩家 |
| `aipFindCloseEnt(inst, targetList)` | 查找最近实体 |
| `aipFindEnt(...)` | 查找单个实体 |
| `aipFindEnts(...)` | 查找多个实体 |
| `aipCountEnts(...)` | 统计实体数量 |
| `aipFindRandomEnt(...)` | 随机查找实体 |

**生成与移除：**
| 函数 | 描述 |
|------|------|
| `aipSpawnPrefab(inst, prefab, tx, ty, tz)` | 生成预制件 |
| `aipReplacePrefab(inst, prefab, ...)` | 替换预制件 |
| `aipRemove(inst)` | 移除实体 |
| `aipGetOne(inst)` | 获取单个物品 |
| `aipCopy(item)` | 复制物品 |
| `aipFlingItem(loot, pt, config)` | 丢弃物品 |

**位置计算：**
| 函数 | 描述 |
|------|------|
| `aipGetSpawnPoint(startPT, distance, onGround)` | 获取可生成点 |
| `aipFindNearbyOcean(pt, dist)` | 找海边点 |
| `aipIsNaturalPoint(pt)` | 检查自然地皮 |
| `aipGetSecretSpawnPoint(...)` | 获取隐秘生成点 |
| `aipFindRandomPointInOcean(...)` | 随机海上点 |
| `aipFindRandomPointInLand(emptyDistance)` | 随机陆地点 |
| `aipValidateOceanPoint(pt, radius, prefabRadius)` | 验证海点 |
| `aipGetTopologyPoint(tag, prefab, dist)` | 拓扑点查找 |

**其他工具：**
| 函数 | 描述 |
|------|------|
| `aipGetModConfig(key)` | 获取 Mod 配置 |
| `aipGetAnimation(inst)` | 获取动画名 |
| `aipGetAnimState(inst)` | 获取 AnimState |
| `aipJoin(strList, spliter)` | 字符串拼接 |
| `aipSplit(str, spliter)` | 字符串分割 |
| `aipCanAttack(target, attacker, keepTarget)` | 检查可攻击 |
| `aipIsShadowCreature(inst)` | 检查暗影生物 |
| `aipRandomLoot(lootTbl)` | 随机概率抽取 |
| `aipChance(chance, inst, bonus)` | 概率判定 |
| `aipRPC(funcName, ...)` | 服务端 RPC |
| `aipRPCClient(funcName, ...)` | 客户端 RPC |
| `aipGetActionableItem(doer)` | 获取可交互物品 |
| `aipQueue(tasks)` | 任务队列 |

### 3. 代码复用原则

当需要实现新功能时，应优先：

1. **检查现有函数** - 在 aipUtils.lua 中寻找可复用的函数
2. **扩展而非重写** - 如果现有函数功能不足，考虑扩展而非重新实现
3. **保持一致性** - 使用统一的辅助函数确保代码风格一致

### 4. 添加新函数的规范

如需在 aipUtils.lua 中添加新函数，应遵循：
- 使用 `function _G.aipXXX(...)` 格式定义
- 添加清晰的函数注释说明用途
- 考虑函数的通用性，避免过于业务特定的逻辑

## 中英文翻译实现

Mod 使用多语言系统支持中文和英文：

### 1. 配置系统
在 [modinfo.lua](modinfo.lua) 中定义语言选项：
```lua
{
    name = "language",
    label = Lang("Language", "语言"),
    options = {
        {description = "中文", data = "chinese"},
        {description = "English", data = "english"},
        -- ... 其他语言
    },
    default = "english",
}
```

### 2. 语言映射表
在各个预制件文件中使用 `LANG_MAP` 定义多语言文本：

**示例：[aip_divine_rapier.lua](scripts/prefabs/aip_divine_rapier.lua)**
```lua
local LANG_MAP = {
    english = {
        NAME = "Divine Rapier",
        DESC = "The combination of light and dark",
        REC_DESC = "Fusing the power of both...",
    },
    chinese = {
        NAME = "圣剑",
        DESC = "光与暗的结合",
        REC_DESC = "融合两者的力量...",
    },
}

local language = aipGetModConfig("language")
local LANG = LANG_MAP[language] or LANG_MAP.english
```

### 3. 字符串注册
使用 DST 的 `STRINGS` 全局表注册文本：
```lua
STRINGS.NAMES.AIP_DIVINE_RAPIER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DIVINE_RAPIER = LANG.DESC
STRINGS.RECIPE_DESC.AIP_DIVINE_RAPIER = LANG.REC_DESC
```

### 4. 独立语言文件
对于复杂内容（如食物），使用独立语言文件：

**[foods_lang.lua](scripts/prefabs/foods_lang.lua)**
```lua
local LANG_MAP = {
    english = {
        EGG_PANCAKE = {
            NAME = "Egg Pancake",
            DESC = "Too many eggs!",
        },
        -- ...
    },
    chinese = {
        EGG_PANCAKE = {
            NAME = "蛋饼",
            DESC = "鸡蛋太多了！",
        },
        -- ...
    },
}
return LANG_MAP
```

在预制件中引用：
```lua
local LANG_MAP = require("prefabs/foods_lang")
local LANG = LANG_MAP[language] or LANG_MAP.english
```

### 5. 故事文本
[aipStory/](scripts/aipStory/) 目录包含故事文本的中文和英文版本，通过 `require` 加载。

## 配方实现逻辑

Mod 使用统一的配方系统管理所有物品配方：

### 1. 配方钩子系统
[recpiesHooker.lua](scripts/recpiesHooker.lua) 是配方管理的核心文件：

#### 配置读取
```lua
local language = _G.aipGetModConfig("language")
local additional_weapon = _G.aipGetModConfig("additional_weapon") == "open"
local additional_survival = _G.aipGetModConfig("additional_survival") == "open"
```

#### 配方过滤器
根据配置决定是否启用配方：
```lua
local function recWeapon(...)
    if not additional_weapon then
        return
    end
    return rec(...)
end
```

#### 统一配方函数
```lua
local function rec(name, tech, filters, ingredients, placerOrConfig)
    local config = {}
    if type(placerOrConfig) == "table" then
        config = placerOrConfig
    else
        config.placer = placerOrConfig
    end

    config.atlas = config.atlas or "images/inventoryimages/"..name..".xml"

    AddRecipe2(name, ingredients, tech, config, filterNames)
    AddRecipeToFilter(name, "AIP_FILTERS")
end
```

### 2. 配方分类
配方按类别组织：

- **武器配方** (`recWeapon`) - 需要启用武器选项
- **生存配方** (`recSurvival`) - 需要启用生存选项
- **服饰配方** (`recDress`) - 需要启用服饰选项
- **通用配方** (`rec`) - 不受分类限制

### 3. 配方示例

**基础武器配方：**
```lua
recWeapon("aip_fish_sword", TECH.SCIENCE_TWO, 
    { CRAFTING_FILTERS.WEAPONS },
    {Ingredient("pondfish", 1), Ingredient("nightmarefuel", 2), Ingredient("rope", 1)})
```

**建筑配方（带放置器）：**
```lua
rec("aip_igloo", TECH.SCIENCE_TWO, 
    { CRAFTING_FILTERS.STRUCTURES },
    {Ingredient("ice", 21), Ingredient("carrot", 1), Ingredient("twigs", 2)},
    "aip_igloo_placer")
```

**自定义科技树配方：**
```lua
recWeapon("aip_divine_rapier", TECH.AIP_DOU_TOTEM, 
    { CRAFTING_FILTERS.WEAPONS, CRAFTING_FILTERS.MAGIC },
    {
        Ingredient("aip_oldone_hand", 1, "images/inventoryimages/aip_oldone_hand.xml"),
        Ingredient("aip_living_friendship", 1, "images/inventoryimages/aip_living_friendship.xml"),
    },
    { nounlock=true })
```

### 4. 自定义科技树
[custom_tech_tree.lua](scripts/custom_tech_tree.lua) 实现自定义科技树：

```lua
AddNewTechTree("AIP_DOU_SCEPTER")  -- 神秘权杖科技树
AddNewTechTree("AIP_DOU_TOTEM")    -- 联结图腾科技树
```

在预制件中添加科技树：
```lua
env.AddPrototyperDef("aip_dou_scepter", {
    icon_atlas = "images/inventoryimages/aip_dou_tech.xml",
    icon_image = "aip_dou_tech.tex",
    is_crafting_station = true,
    action_str = "SCULPTING",
    filter_text = _G.STRINGS.UI.CRAFTING_STATION_FILTERS.SCULPTING,
})
```

### 5. 配方过滤器
Mod 使用自定义过滤器组织配方：
```lua
AddRecipeFilter({
    name = "AIP_FILTERS",
    atlas = "images/inventoryimages/aip_particles_bottle.xml",
    image = "aip_particles_bottle.tex"
})
```

### 6. 动态参数
配方支持根据配置调整参数：

**武器伤害和使用次数：**
```lua
local USES_MAP = {
    less = 200,
    normal = 400,
    much = 1000,
}

local DAMAGE_MAP = {
    less = TUNING.NIGHTSWORD_DAMAGE / 68 * 22,
    normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 33,
    large = TUNING.NIGHTSWORD_DAMAGE / 68 * 44,
}

local weapon_uses = aipGetModConfig("weapon_uses")
local weapon_damage = aipGetModConfig("weapon_damage")

TUNING.AIP_DIVINE_RAPIER_USES = USES_MAP[weapon_uses]
TUNING.AIP_DIVINE_RAPIER_DAMAGE = DAMAGE_MAP[weapon_damage]
```
