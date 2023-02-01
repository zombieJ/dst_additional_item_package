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

-- 掉毛概率
local SHEDDING_LOOT = {
    ------------------------- 兔子 -------------------------
    rabbit = {              -- 5% 概率掉兔毛
        manrabbit_tail = dev_mode and 100 or 0.05
    },
    rabbit_winter = {       -- 10% 概率掉兔毛
        manrabbit_tail = 0.1
    },
    rabbit_crazy = {        -- 10% 概率掉胡子
        beardhair = 0.1
    },

    ------------------------- 蜘蛛 -------------------------
    spider = {              -- 5% 概率掉蜘蛛丝
        silk = 0.05
    },
    spider_warrior = {      -- 10% 概率掉蜘蛛丝
        silk = 0.1
    },
    
    spider_healer = {       -- 10% 概率掉蜘蛛腺体
        spidergland = 0.1
    },
    spider_moon = {         -- 10% 概率掉月光玻璃
        moonglass = 0.1
    },
}

SHEDDING_LOOT.spider_hider = SHEDDING_LOOT.spider_warrior       -- 洞穴蜘蛛
SHEDDING_LOOT.spider_spitter = SHEDDING_LOOT.spider_warrior     -- 喷射蜘蛛
SHEDDING_LOOT.spider_dropper = SHEDDING_LOOT.spider             -- 垂线蜘蛛
SHEDDING_LOOT.spider_water = SHEDDING_LOOT.spider_warrior       -- 海生蜘蛛

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
    SHEDDING_LOOT = SHEDDING_LOOT,
}