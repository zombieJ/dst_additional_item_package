local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local PREFABS = {
	----------------------------- 兔子 -----------------------------
    rabbit = {
        bank = "rabbit",
        build = "rabbit_build",
        anim = "idle",
        sg = "SGrabbit",
        sounds = {
            scream = "dontstarve/rabbit/scream",
            hurt = "dontstarve/rabbit/scream_short",
        },
        origin = "rabbit",
    },
    rabbit_winter = {
        bank = "rabbit",
        build = "rabbit_winter_build",
        anim = "idle",
        sg = "SGrabbit",
        sounds = {
            scream = "dontstarve/rabbit/winterscream",
            hurt = "dontstarve/rabbit/winterscream_short",
        },
        origin = "rabbit",
    },
    rabbit_crazy = {
        bank = "rabbit",
        build = "beard_monster",
        anim = "idle",
        sg = "SGrabbit",
        sounds = {
            scream = "dontstarve/rabbit/scream",
            hurt = "dontstarve/rabbit/scream_short",
        },
        origin = "rabbit",
    },

	----------------------------- 蜘蛛 -----------------------------
    -- 蜘蛛
	spider = {
        bank = "spider",
        build = "spider_build",
        anim = "idle",
        sg = "SGspider",
        origin = "spider",
    },

    -- 蜘蛛战士
    spider_warrior = {
        bank = "spider",
        build = "spider_warrior_build",
        anim = "idle",
        sg = "SGspider",
        origin = "spider_warrior",
        tags = { "spider_warrior" }
    },

    -- 洞穴蜘蛛
    spider_hider = {
        bank = "spider_hider",
        build = "DS_spider_caves",
        anim = "idle",
        sg = "SGspider",
        origin = "spider_hider",
        tags = { "spider_hider" }
    },

    -- 治疗蜘蛛
    spider_healer = {
        bank = "spider",
        build = "spider_wolf_build",
        anim = "idle",
        sg = "SGspider",
        origin = "spider_healer",
        tags = { "spider_healer" }
    },

    -- 喷吐蜘蛛
    spider_spitter = {
        bank = "spider_spitter",
        build = "DS_spider2_caves",
        anim = "idle",
        sg = "SGspider",
        origin = "spider_spitter",
        tags = { "spider_spitter" }
    },
    
    -- 悬丝蜘蛛
    spider_dropper = {
        bank = "spider",
        build = "spider_white",
        anim = "idle",
        sg = "SGspider",
        origin = "spider_dropper",
        tags = { "spider_warrior" }
    },
    
    -- 月光蜘蛛
    spider_moon = {
        bank = "spider_moon",
        build = "ds_spider_moon",
        anim = "idle",
        sg = "SGspider",
        origin = "spider_moon",
        tags = { "spider_moon" }
    },
    
    -- 水生蜘蛛
    spider_water = {
        bank = "spider_water",
        build = "spider_water",
        anim = "idle",
        sg = "SGspider_water",
        origin = "spider_water",
        tags = { "spider_water" },
        postInit = function(inst)
            inst.components.locomotor.hop_distance = 4

            inst:AddComponent("amphibiouscreature")
            inst.components.amphibiouscreature:SetBanks("spider_water", "spider_water_water")
            inst.components.amphibiouscreature:SetEnterWaterFn(function(inst)
                inst.AnimState:SetBuild("spider_water_water")
            end)
            inst.components.amphibiouscreature:SetExitWaterFn(function(inst)
                inst.AnimState:SetBuild("spider_water")
            end)
        end,
    },
}

local function getPrefab(inst, seer)
	local prefab = inst.prefab
	local subPrefab = nil

	------------------------- 兔子 -------------------------
	if prefab == "rabbit" then
		if
			inst.components.inventoryitem ~= nil and
			inst.components.inventoryitem.imagename == "rabbit_winter"
		then
			subPrefab = "_winter"
		end

		if
			seer ~= nil and seer.components.sanity ~= nil and
			seer.components.sanity:IsInsanityMode()
		then
			subPrefab = "_crazy"
		end
	end

	return prefab, subPrefab
end

return {
	PREFABS = PREFABS,
	getPrefab = getPrefab,
}