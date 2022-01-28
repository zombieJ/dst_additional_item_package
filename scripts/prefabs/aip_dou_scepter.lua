-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

local calculateProjectile = require("utils/aip_scepter_util").calculateProjectile

local language = aipGetModConfig("language")

local BASIC_USE = TUNING.LARGE_FUEL / 10
local MAX_USES = BASIC_USE * 10 * 5

-- 文字描述
local LANG_MAP = {
	english = {
        NAME = "Mystic Scepter",
        REC_DESC = "Customize your magic!",
        DESC = "Looks like a key?",
        EMPOWER_DESC = "A fully key!",
        EMPTY = "No more mana!",
        NOT_KEY = "No a real key",

        HUGE = "Expansion",
        SAVING = "Saving",
        RUNNER = "Runer",
        POWER = "Power",
        VAMPIRE = "Vampire",
        LOCK = "Moon",
	},
	chinese = {
        NAME = "神秘权杖",
        REC_DESC = "自定义你的魔法！",
        DESC = "看起来像一把钥匙？",
        EMPOWER_DESC = "一把完整的钥匙！",
        EMPTY = "权杖需要充能了",
        NOT_KEY = "不是一把完整的钥匙",

        HUGE = "扩容",      -- 更大容量
        SAVING = "节能",    -- 更少消耗
        RUNNER = "奔驰",    -- 更快速度
        POWER = "赋能",     -- 更多伤害
        VAMPIRE = "嗜血",   -- 伤害吸血
        LOCK = "月能",      -- 拉至中心
	},
	russian = {
        NAME = "Мистический Cкипетр",
        REC_DESC = "Настройте свою магию!",
        DESC = "Похоже на ключ?",
        EMPOWER_DESC = "Полный ключ!",
        EMPTY = "Маны нет!",

        HUGE = "Расширение",
        SAVING = "Сохранение",
        RUNNER = "Бегун",
        POWER = "Сила",
        VAMPIRE = "Вампир",
        LOCK = "Moon",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 获取名称
local function getStr(name)
    return LANG[name] or LANG_MAP.english[name]
end

STRINGS.NAMES.AIP_DOU_SCEPTER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_DOU_SCEPTER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_SCEPTER = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_SCEPTER_NOT_KEY = LANG.NOT_KEY

STRINGS.NAMES.AIP_DOU_EMPOWER_SCEPTER = LANG.NAME
STRINGS.NAMES.AIP_DOU_HUGE_SCEPTER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_EMPOWER_SCEPTER = LANG.EMPOWER_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_HUGE_SCEPTER = LANG.EMPOWER_DESC

local assets = {
    Asset("ANIM", "anim/aip_dou_scepter.zip"),
    Asset("ANIM", "anim/aip_dou_scepter_swap.zip"),
    Asset("ANIM", "anim/aip_dou_empower_scepter.zip"),
    Asset("ANIM", "anim/aip_dou_empower_scepter_swap.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_dou_scepter.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_dou_empower_scepter.xml"),
}


local prefabs = {
    "aip_dou_scepter_projectile",
    "wormwood_plant_fx",
    "aip_shadow_wrapper",
    "gridplacer",
}

--------------------------------- 配方 ---------------------------------
local function refreshScepter(inst)
    local projectileInfo = { queue = {} }

    if inst.components.container ~= nil then
        -- 不能用 GetAllItems，否则顺序不对
        projectileInfo = calculateProjectile(inst.components.container.slots, inst)
    elseif inst.replica.container ~= nil then
        projectileInfo = calculateProjectile(inst.replica.container:GetItems(), inst)
    end

    inst._projectileInfo = projectileInfo

    if inst.components.aipc_caster ~= nil then
        inst.components.aipc_caster:SetUp(
            projectileInfo.action
        )
    end

    return projectileInfo
end

local function toggleIndicator(inst, doer)
    if inst.components.aipc_caster ~= nil then
        inst.components.aipc_caster:ToggleIndicator()
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

-- 添加元素
local function onCasterEquip(inst)
    refreshScepter(inst)
end

local function onCasterUnequip(inst)
    refreshScepter(inst)
end

-- 使用消耗
local function beforeAction(inst, projectileInfo, doer)
    if inst.components.fueled:IsEmpty() then
        doer.components.talker:Say(LANG.EMPTY)
        return false
    end

    inst.components.fueled:DoDelta(-BASIC_USE * projectileInfo.uses)

    -- 如果没有能量了，就看看有没有放置噩梦燃料来充能
    if inst.components.fueled:IsEmpty() then
        local items = inst.components.container:GetAllItems()
        for i, item in ipairs(items) do
            -- 噩梦燃料
            if item.prefab == "nightmarefuel" then
                local pop = inst.components.container:RemoveItem(item)

                inst.components.fueled:TakeFuelItem(pop, doer)
                break

            --噩梦之灵
            elseif item.prefab == "aip_nightmare_package" then
                inst.components.fueled:DoDelta(MAX_USES, doer)
                item.components.finiteuses:Use(4)
                break
            end
        end
    end
    return true
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>> 赋能 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
local empowerLock = {
    empower = "LOCK",       -- 吸附至目标点
}

local empowerList = {
    {
        prefab = "aip_dou_huge_scepter",
        empower = "HUGE",       -- 更大容量
    },
    {
        empower = "SAVING",     -- 更少消耗
    },
    {
        empower = "RUNNER",     -- 更快速度
    },
    {
        empower = "POWER",      -- 更多伤害
    },
    {
        empower = "VAMPIRE",    -- 伤害吸血
    },
    empowerLock,
}

local function empowerEffect(inst)
    local emp = inst._aip_empower

    if emp == "RUNNER" then
        inst.components.equippable.walkspeedmult = 1.55
    end

    if emp == "LOCK" then
        inst:AddTag("aip_lock")
    end
end

local function onsave(inst, data)
    data.empower = inst._aip_empower
end

local function onload(inst, data)
	if data ~= nil then
        inst._aip_empower = data.empower
        empowerEffect(inst)
	end
end

local function empower(inst, doer, customizeEmpower)
    inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_repair")

    -- 掉出所有符文
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end

    -- 随机选择强化类型
    local emp = customizeEmpower
    if not emp then
        emp = aipRandomEnt(empowerList)
        if TheWorld.state.isfullmoon then -- 如果是满月，则一定是解锁
            emp = empowerLock
        end
    end
    local prefab = emp.prefab or "aip_dou_empower_scepter"
    local empower = emp.empower

    -- 获取文字描述
    local originName = getStr("NAME")
    local prefixName = getStr(empower)

    ---------------- 创建法杖 & 赋能 ----------------
    local cepter = aipReplacePrefab(inst, prefab)
    cepter.components.named:SetName(prefixName.."-"..originName)
    cepter._aip_empower = empower
    empowerEffect(cepter)
end

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>> 生成 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
local function genScepter(containerName, animName)
    local anim = animName or containerName

    ------------------------- 装备 -------------------------
    local swapName = anim.."_swap"

    local function onequip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", swapName, swapName)

        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")

        if inst.components.container ~= nil then
            inst.components.container:Open(owner)
        end

        inst.components.container.canbeopened = true
    end

    local function onunequip(inst, owner)
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")

        if inst.components.container ~= nil then
            inst.components.container:Close()
        end

        inst.components.container.canbeopened = false
    end

    ------------------------- 实体 -------------------------
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(anim)
        inst.AnimState:SetBuild(anim)
        inst.AnimState:PlayAnimation("idle")

        -- weapon (from weapon component) added to pristine state for optimization
        inst:AddTag("weapon")
        inst:AddTag("prototyper")
        inst:AddTag("throw_line")
        inst:AddTag("aip_dou_scepter")

        MakeInventoryFloatable(inst, "med", 0.1, 0.75)

        inst.entity:SetPristine()

        -- 添加施法者
        inst:AddComponent("aipc_caster")
        inst.components.aipc_caster.onEquip = onCasterEquip
        inst.components.aipc_caster.onUnequip = onCasterUnequip

        -- 鼠标类型判断，在判断的时候会刷新一下指针类型，这样利用了 POINT 就实现了动态刷新的效果。学到了就给我的 mod 点个赞吧
        inst:AddComponent("aipc_action_client")
        inst.components.aipc_action_client.canActOn = function(inst, doer, target)
            refreshScepter(inst)
            return (
                inst._projectileInfo.action == "FOLLOW" and
                -- 有生命的单位
                (target.components.health ~= nil or target.replica.health ~= nil)
            )
        end
        inst.components.aipc_action_client.canActOnPoint = function()
            refreshScepter(inst)
            return inst._projectileInfo.action ~= "FOLLOW"
        end

        if not TheWorld.ismastersim then
            return inst
        end

        -- 施法
        inst:AddComponent("aipc_action")

        inst.components.aipc_action.onDoPointAction = function(inst, doer, point)
            local projectileInfo = refreshScepter(inst)

            if beforeAction(inst, projectileInfo, doer) then
                local projectile = SpawnPrefab("aip_dou_scepter_projectile")
                projectile.components.aipc_dou_projectile:StartBy(doer, projectileInfo.queue, nil, point)
            end
        end

        inst.components.aipc_action.onDoTargetAction = function(inst, doer, target)
            local projectileInfo = refreshScepter(inst)

            if beforeAction(inst, projectileInfo, doer) then
                local projectile = SpawnPrefab("aip_dou_scepter_projectile")
                projectile.components.aipc_dou_projectile:StartBy(doer, projectileInfo.queue, target)
            end
        end

        inst.components.aipc_action.onDoAction = toggleIndicator

        -- 接受元素提炼
        inst:AddComponent("container")
        inst.components.container:WidgetSetup(containerName)
        inst.components.container.canbeopened = false

        inst:AddComponent("named")
        inst:AddComponent("inspectable")

        -- 本身也是一个合成台
        inst:AddComponent("prototyper")
        inst.components.prototyper.onturnon = onturnon
        inst.components.prototyper.onturnoff = onturnoff
        -- inst.components.prototyper.onactivate = onactivate
        -- inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.AIP_DOU_SCEPTER_ONE
        inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.AIP_DOU_SCEPTER

        -- 需要充能
        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
        inst.components.fueled:InitializeFuelLevel(MAX_USES)
        -- inst.components.fueled:SetDepletedFn(nofuel)
        -- inst.components.fueled:SetTakeFuelFn(ontakefuel)
        inst.components.fueled.accepting = true

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..anim..".xml"
        inst.components.inventoryitem.imagename = anim

        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT

        inst._aipEmpower = empower

        MakeHauntableLaunch(inst)

        inst.OnLoad = onload
        inst.OnSave = onsave

        return inst
    end
end

------------------------------- 黑暗爆炸 -------------------------------
local function explodeShadowFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	MakeFlyingCharacterPhysics(inst, 1, .5)

	inst.AnimState:SetBank("projectile")
	inst.AnimState:SetBuild("staff_projectile")
	inst.AnimState:PlayAnimation("fire_spin_loop", true)
	
	inst:AddTag("projectile")
	inst:AddTag("flying")
	inst:AddTag("ignorewalkableplatformdrowning")

	-- 添加一抹灯光
	inst.Light:SetIntensity(.6)
	inst.Light:SetRadius(.5)
	inst.Light:SetFalloff(.6)
	inst.Light:Enable(true)
	inst.Light:SetColour(180 / 255, 195 / 255, 225 / 255)

	inst.entity:SetPristine() -- 客户端执行相同实体，Transform AnimState Network 等等

	if not TheWorld.ismastersim then
		return inst
	end

	
	inst:DoTaskInTime(0.5, function()
		if inst._master ~= true then
			inst:Remove()
		end
	end)

	return inst
end


-- 普通权杖
return Prefab("aip_dou_scepter", genScepter("aip_dou_scepter"), assets, prefabs),
    -- 强化权杖
    Prefab("aip_dou_empower_scepter", genScepter("aip_dou_empower_scepter"), assets, prefabs),
    -- 扩容权杖
    Prefab("aip_dou_huge_scepter", genScepter("aip_dou_huge_scepter", "aip_dou_empower_scepter"), assets, prefabs),
    -- 黑暗爆炸，不知道干啥的
    Prefab("aip_explode_shadow", explodeShadowFn, { Asset("ANIM", "anim/staff_projectile.zip") }, { "fire_projectile" }),
    -- 测试用，月能权杖
    Prefab("aip_dou_scepter_lock", function()
        local inst = genScepter("aip_dou_empower_scepter")()
        inst:DoTaskInTime(0.5, function()
            empower(inst, nil, empowerLock)
        end)
        return inst
    end, assets, prefabs)


--[[


c_give"aip_dou_huge_scepter"


]]
