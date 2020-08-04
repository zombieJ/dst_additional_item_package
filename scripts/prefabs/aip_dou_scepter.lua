-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	["english"] = {
        ["NAME"] = "Mystic Scepter",
        ["REC_DESC"] = "Customize your magic!",
		["DESC"] = "Customize your magic!",
	},
	["chinese"] = {
        ["NAME"] = "神秘权杖",
        ["REC_DESC"] = "自定义你的魔法！",
		["DESC"] = "自定义你的魔法！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_DOU_SCEPTER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_DOU_SCEPTER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_SCEPTER = LANG.DESC

local assets = {
    -- Asset("ANIM", "anim/aip_dou_scepter.zip"),
    -- Asset("ANIM", "anim/aip_dou_scepter_swap.zip"),
    -- Asset("ANIM", "anim/floating_items.zip"),
    -- Asset("ATLAS", "images/inventoryimages/aip_dou_scepter.xml"),
}


local prefabs = {}

--------------------------------- 配方 ---------------------------------
local function onsave(inst, data)
	data.magicSlot = inst._magicSlot
end

local function onload(inst, data)
	if data ~= nil then
        inst._magicSlot = data.magicSlot

        if inst.components.container ~= nil then
            inst.components.container:WidgetSetup("aip_dou_scepter"..tostring(inst._magicSlot))
        end
	end
end

-- 合成科技
local function onturnon(inst)
    inst.AnimState:PlayAnimation("proximity_pre")
    inst.AnimState:PushAnimation("proximity_loop", true)
end

local function onturnoff(inst)
    if not inst.components.inventoryitem:IsHeld() then
        inst.AnimState:PlayAnimation("proximity_pst")
        inst.AnimState:PushAnimation("idle", false)
    else
        inst.AnimState:PlayAnimation("idle")
    end
end

-- 装备
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "aip_dou_scepter_swap", "aip_dou_scepter_swap")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

-- 添加元素
local function onItemLoaded(inst, data)
	-- if inst.components.weapon ~= nil then
	-- 	if data ~= nil and data.item ~= nil then
	-- 		inst.components.weapon:SetProjectile(data.item.prefab.."_proj")
	-- 		data.item:PushEvent("ammoloaded", {slingshot = inst})
	-- 	end
	-- end
end

local function onItemUnloaded(inst, data)
	-- if inst.components.weapon ~= nil then
	-- 	inst.components.weapon:SetProjectile(nil)
	-- 	if data ~= nil and data.prev_item ~= nil then
	-- 		data.prev_item:PushEvent("ammounloaded", {slingshot = inst})
	-- 	end
	-- end
end

-- 范围武器
local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

STRINGS.ACTIONS.CASTSPELL.GENERIC = "十年啊"

ACTIONS.CASTSPELL.fn = function()
    aipPrint("?????")
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_dou_scepter")
    inst.AnimState:SetBuild("aip_dou_scepter")
    inst.AnimState:PlayAnimation("idle")

    -- weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    inst:AddTag("prototyper")
    inst:AddTag("throw_line")

    MakeInventoryFloatable(inst, "med", 0.1, 0.75)

    inst.entity:SetPristine()

    -- 添加施法者
    inst:AddComponent("aipc_caster")
    inst.components.aipc_caster:SetUp("line")

    -- 客户端也需要的 AOE 效果
    -- inst:AddComponent("aoetargeting")
    -- inst.components.aoetargeting:SetAlwaysValid(true)
    -- inst.components.aoetargeting.reticule.reticuleprefab = "reticulelong"
    -- inst.components.aoetargeting.reticule.pingprefab = "reticulelongping"
    -- inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    -- inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    -- inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    -- inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    -- inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    -- inst.components.aoetargeting.reticule.ease = true
    -- inst.components.aoetargeting.reticule.mouseenabled = true

    inst:AddComponent("aipc_action")
    inst.components.aipc_action.canActOn = function(inst, doer, target)
        
    end
    inst.components.aipc_action.canActOnPoint = function()
        return true
    end

    if not TheWorld.ismastersim then
        return inst
    end


    -- -- 施法动作
    -- inst:AddComponent("spellcaster")
    -- inst.components.spellcaster.CanCast = (function (inst, target, pos)
    --     aipPrint("CanCast:", inst, target, pos)
    --     return true
    -- end)
    -- inst.components.spellcaster:SetSpellFn((function (inst, target, pos)
    --     aipPrint("SPELL!!!!")
    --     local caster = inst.components.inventoryitem.owner

    --     if pos ~= nil then --the point on map that has been targeted to cast spell there
    --         aipPrint("do cast!!!!")
    --     end
    -- end))
    -- inst.components.spellcaster.canuseontargets = true --retains the default functionality of ice staff
    -- inst.components.spellcaster.canuseonpoint = true  --adds aoe spell

    -- -- 武器伤害
    -- inst:AddComponent("weapon")
    -- inst.components.weapon:SetDamage(0)
    -- inst.components.weapon:SetRange(8, 10)
    -- inst.components.weapon:SetProjectile("fire_projectile")

    -- 接受元素提炼
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_dou_scepter4")
    inst.components.container.canbeopened = false
    inst:ListenForEvent("itemget", onItemLoaded)
    inst:ListenForEvent("itemlose", onItemUnloaded)

    inst:AddComponent("inspectable")

    -- 本身也是一个合成台
    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnon
    inst.components.prototyper.onturnoff = onturnoff
    -- inst.components.prototyper.onactivate = onactivate
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.AIP_DOU_SCEPTER_ONE

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dou_scepter.xml"
    inst.components.inventoryitem.imagename = "aip_dou_scepter"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT

    MakeHauntableLaunch(inst)

    inst._magicSlot = 1

    inst.OnLoad = onload
    inst.OnSave = onsave

    return inst
end

return Prefab("aip_dou_scepter", fn, assets, prefabs)
