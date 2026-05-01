local _G = GLOBAL
local Prefabs = _G.Prefabs

-- 鸟笼吃蔬果时，原版会尝试掉落 food.prefab .. "_seeds"
-- 这里先算一遍，只有真实存在的种子 prefab 才参与品质继承.
local function getSeedPrefab(item)
	if item == nil or item.prefab == nil then
		return nil
	end

	local seedPrefab = string.lower(item.prefab.."_seeds")
	return Prefabs[seedPrefab] ~= nil and seedPrefab or nil
end

-- 记录“鸟笼稍后应该吐出的种子 prefab”和“它应该继承的品质”.
-- 原版鸟笼会在 accept 后延迟 60 frames 消化，所以这里用队列承接这段时间差.
local function pushPendingSeed(inst, prefab, quality)
	inst.aipPendingBirdSeeds = inst.aipPendingBirdSeeds or {}

	table.insert(inst.aipPendingBirdSeeds, {
		prefab = prefab,
		quality = quality,
	})
end

local function clearPendingSeeds(inst)
	inst.aipPendingBirdSeeds = nil
end

AddPrefabPostInit("birdcage", function(inst)
	if not _G.TheWorld.ismastersim then
		return
	end

	-- 鸟笼接受喂食后先记录作物品质，稍后吐种子时再应用
	inst:ListenForEvent("trade", function(inst, data)
		local item = data ~= nil and data.item or nil
		local quality = item ~= nil and item.components.aipc_quality or nil
		local seedPrefab = getSeedPrefab(item)

		if quality ~= nil and seedPrefab ~= nil then
			pushPendingSeed(inst, seedPrefab, quality:GetVal())
		end
	end)

	-- 鸟笼掉出东西时，只和队首的预期种子比较，不匹配就清空队列
	inst:ListenForEvent("loot_prefab_spawned", function(inst, data)
		local pendingSeeds = inst.aipPendingBirdSeeds
		if pendingSeeds == nil or #pendingSeeds <= 0 then
			return
		end

		local loot = data ~= nil and data.loot or nil
		local pending = pendingSeeds[1]

		if loot ~= nil and loot.prefab == pending.prefab then
			if loot.components.aipc_quality ~= nil then
				loot.components.aipc_quality:SetVal(pending.quality)
			end

			table.remove(pendingSeeds, 1)
			if #pendingSeeds <= 0 then
				clearPendingSeeds(inst)
			end
		else
			clearPendingSeeds(inst)
		end
	end)
end)
