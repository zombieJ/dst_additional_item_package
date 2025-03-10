# 开发须知

# 项目目录结构

| 文件名                        | 描述                           |
| ----------------------------- | ------------------------------ |
| modmain.lua                   | 配置预加载资源与物品           |
| modinfo.lua                   | 描述信息，配置 mod 预览页面    |
| exported                      | 导出的文件                     |
| scripts                       |                                |
| scripts/prefabs               | 物品文件夹                     |
| scripts/components            | 组件，物品的功能是由组件提供的 |
| widgets                       | 界面相关内容                   |
| images                        |                                |
| images/inventoryimages        | 物品图片文件夹                 |
| images/inventoryimages/\*.tex | 物品编译图片                   |
| images/inventoryimages/\*.xml | 物品图片配置信息               |

# 开发目录结构

| 文件名          | 描述                                                       |
| --------------- | ---------------------------------------------------------- |
| exported_done   | 已经导出的文件                                             |
| gen             | 生成工具集                                                 |
| gen.cutTextXml  |                                                            |
| gen.foodPreview | 生成预览食物图片，用于 steam mod 页面                      |
| gen.seed        | 种子文件                                                   |
| gen.veggie      | 生成种子文件模板                                           |
| images_done     | 生成完成的图片，因为放在 images 下会被编译拖慢饥荒打开速度 |

# 开发 MOD

- [物品制作](./item.md)

## 替换 Symbol

https://www.it610.com/article/5028120.htm

## 动画队列结束

animqueueover

## 永远垂直

redlanternbody.lua

## 地图区块数据

TheWorld.topology.nodes
- type: NODE_TYPE.x
- poly
- tags
- cent [x, z]
- x
- y
- c
- neighbours
- area
- validedges: TheWorld.topology.edgeToNodes

TheWorld.topology.ids

## 找对象

simutil.lua

FindEntities(x, y, z, radius, musthavetags, nottags, hasoneoftags)

# apiUtils

提供了一些辅助方法

- aipPrint(...) 打印内容
- aipTypePrint(...) 打印内容，同时打印出类别
- aipGetModConfig(configName: string) 获取全局的 mod 配置信息

# 坐标

local pt = inst:GetPosition()

# 物理的一些知识

https://forums.kleientertainment.com/forums/topic/34074-the-physics-of-the-dont-starve-world/
https://forums.kleientertainment.com/forums/topic/76982-solved-i-need-help-with-physicsknockback-thing/
https://forums.kleientertainment.com/forums/topic/123069-bizarre-physics-velocity-bug-that-only-happens-when-no-ones-watching/

https://forums.kleientertainment.com/forums/topic/126774-documentation-list-of-all-engine-functions/?tab=comments#comment-1477045

MASS 质量

### mathutil.lua

* Lerp(min, max, ptg)：取 min ~ max 的范围值
* Remap(currentValue, currentMin, currentMax, targetMin, targetMax)：把一个范围转成另一个范围


inst.AnimState:SetRayTestOnBB(true) 小物体会直接用盒装模型碰撞检测

### 配方原型配置

https://forums.kleientertainment.com/forums/topic/147251-tutorialcomplete-tutorial-for-dsts-new-craft-menu/

### 配方特殊物品

例如 Ingredient(CHARACTER_INGREDIENT.HEALTH, 40)

* CHARACTER_INGREDIENT.HEALTH
* CHARACTER_INGREDIENT.MAX_SANITY
* TECH_INGREDIENT.SCULPTING
* CHARACTER_INGREDIENT.SANITY

### 瞬移

c_goto(c_find("aip_dou_totem_broken"))

### 改变季节

TheWorld:PushEvent("ms_setseason", "summer")
TheWorld:PushEvent("ms_setseason", "winter")

TheWorld:PushEvent("phasechanged", "day")
TheWorld:PushEvent("phasechanged", "night")

### AnimateState:Show 工作条件 

https://forums.kleientertainment.com/forums/topic/47818-how-to-compile-for-animstatehide/

需要重命名 layer，改成 snow-0_0 就可以通过 Show / Hide 来控制了

### mainfunctions

lureplant 有个 OnEntitySleep OnLongUpdate 方法，当实体休眠时调用

### AnimateState 方法

设置：
AddOverrideBuild
AssignItemSkins

SetAddColour
SetBank
SetBankAndPlayAnimation
SetBloomEffectHandle
SetBrightness
SetBuild
SetClientSideBuildOverrideFlag
SetClientsideBuildOverride
SetDefaultEffectHandle
SetDeltaTimeMultiplier
SetDepthBias
SetDepthTestEnabled
SetDepthWriteEnabled
SetErosionParams
SetFinalOffset
SetFloatParams
SetFrame
SetHatOffset
SetHaunted
SetHighlightColour
SetHue
SetInheritsSortKey
SetLayer
SetLightOverride
SetManualBB
SetMultColour
SetMultiSymbolExchange
SetOceanBlendParams
SetOrientation
SetPercent
SetRayTestOnBB
SetSaturation
SetScale
SetSkin
SetSortOrder
SetSortWorldOffset
SetSymbolAddColour
SetSymbolBloom
SetSymbolBrightness
SetSymbolExchange
SetSymbolHue
SetSymbolLightOverride
SetSymbolMultColour
SetSymbolSaturation
SetTime
SetUILightParams
SetWorldSpaceAmbientLightPos

OverrideBrightness
OverrideHue
OverrideShade
OverrideSaturation
OverrideSkinSymbol
OverrideItemSkinSymbol
OverrideSymbol
OverrideMultColour

ClearDefaultEffectHandle
ClearBloomEffectHandle
ClearOverrideBuild
ClearOverrideSymbol
ClearSymbolExchanges
ClearAllOverrideSymbols
ClearSymbolBloom

获取：
GetAddColour
GetBrightness
GetBuild
GetCurrentAnimationFrame
GetCurrentAnimationLength
GetCurrentAnimationTime
GetCurrentBankName
GetCurrentFacing
GetHistoryData
GetHue
GetInheritsSortKey
GetLayer
GetMultColour
GetSaturation
GetSkinBuild
GetSortOrder
GetSymbolAddColour
GetSymbolHSB
GetSymbolMultColour
GetSymbolOverride
GetSymbolPosition

其他：
AnimDone
AnimateWhilePaused
BuildHasSymbol
CompareSymbolBuilds
Show
Hide
ShowSymbol
HideSymbol
PushAnimation
PlayAnimation
UsePointFiltering
FastForward
Pause
Resume
IsCurrentAnimation
UseColourCube
IsSymbolOverridden


### Entity 方法

AddAccountManager
AddAnimState
AddClientSleepable
AddDebugRender
AddDynamicShadow
AddEnvelopeManager
AddFollower
AddFontManager
AddGraphicsOptions
AddGroundCreep
AddGroundCreepEntity
AddImage
AddImageWidget
AddLabel
AddLight
AddLightWatcher
AddMap
AddMapExplorer
AddMapGenSim
AddMapLayerManager
AddMiniMap
AddMiniMapEntity
AddNetwork
AddParticleEmitter
AddPathfinder
AddPhysics
AddPhysicsWaker
AddPostProcessor
AddRoadManager
AddShadowManager
AddShardClient
AddShardNetwork
AddSoundEmitter
AddStaticShadow
AddTag
AddTextEditWidget
AddTextWidget
AddTransform
AddTwitchOptions
AddUITransform
AddVFXEffect
AddVideoWidget
AddWaveComponent


CallPrefabConstructionComplete
CanPredictMovement
EnableMovementPrediction
FlattenMovementPrediction
FlushLocalDirtyNetVars
FrustumCheck
GetAnimStateData
GetDebugString
GetGUID
GetHistoryData
GetName
GetParent
GetPlatform
GetPrefabName
HasTag
Hide
IsAwake
IsValid
IsVisible
LocalToWorldSpace
LocalToWorldSpaceIncParent
MoveToBack
MoveToFront
RemoveTag
Retire
SetAABB
SetCanSleep
SetClickable
SetInLimbo
SetIsPredictingMovement
SetName
SetParent
SetPlatform
SetPrefabName
SetPristine
SetSelected
Show
WorldToLocalSpace

### Follower 方法

SetOffset
StopFollowing
FollowSymbol