--[[
	config: {
		keepHead: bool, - 保留原始头部
		hideHead: bool,
		walkspeedmult: number - 移动速度增加,
		fueled: {
			level: number - 穿戴后消耗时间
		},
		armor: {
			amount: number - 护甲值
			absorb_percent: number - 吸收伤害百分比
			tag: string - 指定免疫的单位类型
		},
		waterproofer: bool,
		dapperness: number - 恢复理智值,
	}
]]

local function template(name, config)
	-- 资源
	local assets =
	{
		Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
		Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
		Asset("ANIM", "anim/"..name..".zip"),
	}

	aipPrint(">>>>>>>>>>>>>>", "images/inventoryimages/"..name..".tex")

	local prefabs =
	{
	}

	local function onequip(inst, owner)
		owner.AnimState:OverrideSymbol("swap_hat", name, "swap_hat")

		owner.AnimState:Show("HAT")
		if not config.keepHead then
			owner.AnimState:Show("HAIR_HAT")
			owner.AnimState:Hide("HAIR_NOHAT")
			owner.AnimState:Hide("HAIR")
		end

		if owner:HasTag("player") and not config.keepHead then
			owner.AnimState:Hide("HEAD")
			if not config.hideHead then
				owner.AnimState:Show("HEAD_HAT")
			end
		end

		if inst.components.fueled ~= nil then
			inst.components.fueled:StartConsuming()
		end
	end

	local function onunequip(inst, owner)
		owner.AnimState:ClearOverrideSymbol("swap_hat")

		owner.AnimState:Hide("HAT")
		if not config.keepHead then
			owner.AnimState:Hide("HAIR_HAT")
			owner.AnimState:Show("HAIR_NOHAT")
			owner.AnimState:Show("HAIR")
		end

		if owner:HasTag("player") and not config.keepHead then
			owner.AnimState:Show("HEAD")
			if not config.hideHead then
				owner.AnimState:Hide("HEAD_HAT")
			end
		end

		if inst.components.fueled ~= nil then
			inst.components.fueled:StopConsuming()
		end
	end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBank(name)
		inst.AnimState:SetBuild(name)
		inst.AnimState:PlayAnimation("anim")

		inst:AddTag("hat")
		inst:AddTag("waterproofer")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

		inst:AddComponent("inspectable")

		inst:AddComponent("tradable")

		inst:AddComponent("equippable")
		inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
		inst.components.equippable:SetOnEquip(onequip)
		inst.components.equippable:SetOnUnequip(onunequip)
		if config.walkspeedmult then
			inst.components.equippable.walkspeedmult = config.walkspeedmult
		end
		if config.dapperness then
			inst.components.equippable.dapperness = config.dapperness
		end

		-- 消耗品
		if config.fueled then
			inst:AddComponent("fueled")
			inst.components.fueled.fueltype = FUELTYPE.USAGE
			inst.components.fueled:InitializeFuelLevel(config.fueled.level)
			inst.components.fueled:SetDepletedFn(inst.Remove)
		end

		MakeHauntableLaunch(inst)

		-- 防水
		if config.waterproofer then
			inst:AddComponent("waterproofer")
			inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
		end

		-- 护甲
		if config.armor then
			inst:AddComponent("armor")
			inst.components.armor:InitCondition(config.armor.amount, config.armor.absorb_percent * (TUNING.ARMORWOOD_ABSORPTION / .8))

			if config.armor.tag then
				inst.components.armor:SetTags({ config.armor.tag })
			end
		end

		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

return template