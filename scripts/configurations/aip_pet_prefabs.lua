local dev_mode = aipGetModConfig("dev_mode") == "enabled"

------------------------------- 猎犬 -------------------------------
local function houndPostInit(bank, skipSwim)
    return function(inst)
        -- SG 用了，加一下不要挂
        inst:AddComponent("follower")

        if skipSwim ~= true then
            inst:AddComponent("amphibiouscreature")
            inst.components.amphibiouscreature:SetBanks(bank, bank.."_water")
            inst.components.amphibiouscreature:SetEnterWaterFn(function(inst)
                inst.components.locomotor.hop_distance = 4
            end)
        end
    end
end

local houndSounds = {
    pant = "dontstarve/creatures/hound/pant",
    attack = "dontstarve/creatures/hound/attack",
    bite = "dontstarve/creatures/hound/bite",
    bark = "dontstarve/creatures/hound/bark",
    death = "dontstarve/creatures/hound/death",
    sleep = "dontstarve/creatures/hound/sleep",
    growl = "dontstarve/creatures/hound/growl",
    howl = "dontstarve/creatures/together/clayhound/howl",
    hurt = "dontstarve/creatures/hound/hurt",
}

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

    ----------------------------- 猎犬 -----------------------------
    -- 猎犬
    hound = {
        bank = "hound",
        build = "hound_ocean",
        anim = "idle",
        sg = "SGhound",
        origin = "hound",
        scale = 0.6,
        sounds = houndSounds,
        postInit = houndPostInit("hound"),
    },

    -- 火狗
    firehound = {
        bank = "hound",
        build = "hound_red_ocean",
        anim = "idle",
        sg = "SGhound",
        origin = "firehound",
        scale = 0.6,
        sounds = houndSounds,
        postInit = houndPostInit("hound"),
    },

    -- 冰狗
    icehound = {
        bank = "hound",
        build = "hound_ice_ocean",
        anim = "idle",
        sg = "SGhound",
        origin = "icehound",
        scale = 0.6,
        sounds = houndSounds,
        postInit = houndPostInit("hound"),
    },

    -- 黏土
    clayhound = {
        bank = "clayhound",
        build = "clayhound",
        anim = "idle",
        sg = "SGhound",
        origin = "clayhound",
        scale = 0.6,
        sounds = {
            pant = "dontstarve/creatures/together/clayhound/pant",
            attack = "dontstarve/creatures/together/clayhound/attack",
            bite = "dontstarve/creatures/together/clayhound/bite",
            bark = "dontstarve/creatures/together/clayhound/bark",
            death = "dontstarve/creatures/together/clayhound/death",
            sleep = "dontstarve/creatures/together/clayhound/sleep",
            growl = "dontstarve/creatures/together/clayhound/growl",
            howl = "dontstarve/creatures/together/clayhound/howl",
            hurt = "dontstarve/creatures/hound/hurt",
        },
        tags = { "clay" },
        postInit = houndPostInit("hound", true),
    },

    -- 僵尸
    mutatedhound = {
        bank = "hound",
        build = "hound_mutated",
        anim = "idle",
        sg = "SGhound",
        origin = "mutatedhound",
        scale = 0.6,
        sounds = houndSounds,
        postInit = houndPostInit("hound"),
    },

    -- 鲜花
    hedgehound = {
        bank = "hound",
        build = "hound_hedge_ocean",
        anim = "idle",
        sg = "SGhound",
        origin = "hedgehound",
        scale = 0.6,
        sounds = {
            pant = "dontstarve/creatures/hound/pant",
            attack = "dontstarve/creatures/hound/attack",
            bite = "dontstarve/creatures/hound/bite",
            bark = "dontstarve/creatures/hound/bark",
            death = "stageplay_set/briar_wolf/destroyed",
            sleep = "dontstarve/creatures/hound/sleep",
            growl = "dontstarve/creatures/hound/growl",
            howl = "dontstarve/creatures/together/clayhound/howl",
            hurt = "dontstarve/creatures/hound/hurt",
        },
        postInit = houndPostInit("hound"),
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

    ------------------------- 猎犬 -------------------------
    hound = {
        houndstooth = 0.05, -- 5% 概率掉犬牙
    },
    firehound = {
        houndstooth = 0.05, -- 5% 概率掉犬牙
        redgem = 0.01,      -- 1% 概率掉红宝石
    },
    icehound = {
        houndstooth = 0.05, -- 5% 概率掉犬牙
        bluegem = 0.01,     -- 1% 概率掉蓝宝石
    },
	clayhound = {
        redpouch = 0.05,    -- 5% 概率掉红袋子
    },
	mutatedhound = {
        houndstooth = 0.1,  -- 10% 概率掉犬牙
    },
	hedgehound = {
        petals = 0.5,         -- 50% 概率掉花瓣
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

		if seer ~= nil and seer.components.sanity ~= nil then
            local sanityVal = seer:HasTag("dappereffects") and TUNING.DAPPER_BEARDLING_SANITY or TUNING.BEARDLING_SANITY
            local isinsane =    seer.components.sanity:IsInsanityMode() and
                                seer.replica.sanity:GetPercent() <= sanityVal

            -- 如果理智值太低，则变成疯兔
            if isinsane then
			    subPrefab = "_crazy"
            end
		end
	end

    ------------------------- 猎犬 -------------------------
    if prefab == "moonhound" then
        prefab = "hound"
    end

	return prefab, subPrefab
end

-- 获取宠物专属技能
local function getSkills(prefab, subPrefab)
    ------------------------- 兔子 -------------------------
    if prefab == "rabbit" and subPrefab == "_crazy" then
        return {
            "cool",
        }
    end

    ------------------------- 猎犬 -------------------------
    if prefab == "icehound" then
        return {
            "cool",
        }
    elseif prefab == "firehound" then
        return {
            "hot",
        }
    end
end

return {
	PREFABS = PREFABS,
	getPrefab = getPrefab,
    getSkills = getSkills,
    SHEDDING_LOOT = SHEDDING_LOOT,
}