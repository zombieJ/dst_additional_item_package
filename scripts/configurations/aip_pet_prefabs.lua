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

------------------------------- 蜘蛛 -------------------------------
local function SpiderSoundPath(inst, event)
    local creature = "spider"
    if inst:HasTag("spider_healer") then
        return "webber1/creatures/spider_cannonfodder/" .. event
    elseif inst:HasTag("spider_moon") then
        return "turnoftides/creatures/together/spider_moon/" .. event
    elseif inst:HasTag("spider_warrior") then
        creature = "spiderwarrior"
    elseif inst:HasTag("spider_hider") or inst:HasTag("spider_spitter") then
        creature = "cavespider"
    else
        creature = "spider"
    end
    return "dontstarve/creatures/" .. creature .. "/" .. event
end

local function spiderPostInit(inst)
    inst.SoundPath = SpiderSoundPath
    inst.incineratesound = SoundPath(inst, "die")
end

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
        postInit = spiderPostInit,
    },

    -- 蜘蛛战士
    spider_warrior = {
        bank = "spider",
        build = "spider_warrior_build",
        anim = "idle",
        sg = "SGspider",
        tags = { "spider_warrior" },
        postInit = spiderPostInit,
    },

    -- 洞穴蜘蛛
    spider_hider = {
        bank = "spider_hider",
        build = "DS_spider_caves",
        anim = "idle",
        sg = "SGspider",
        tags = { "spider_hider" },
        postInit = spiderPostInit,
    },

    -- 治疗蜘蛛
    spider_healer = {
        bank = "spider",
        build = "spider_wolf_build",
        anim = "idle",
        sg = "SGspider",
        tags = { "spider_healer" },
        postInit = spiderPostInit,
    },

    -- 喷吐蜘蛛
    spider_spitter = {
        bank = "spider_spitter",
        build = "DS_spider2_caves",
        anim = "idle",
        sg = "SGspider",
        tags = { "spider_spitter" },
        postInit = spiderPostInit,
    },
    
    -- 悬丝蜘蛛
    spider_dropper = {
        bank = "spider",
        build = "spider_white",
        anim = "idle",
        sg = "SGspider",
        tags = { "spider_warrior" },
        postInit = spiderPostInit,
    },
    
    -- 月光蜘蛛
    spider_moon = {
        bank = "spider_moon",
        build = "ds_spider_moon",
        anim = "idle",
        sg = "SGspider",
        tags = { "spider_moon" },
        postInit = spiderPostInit,
    },
    
    -- 水生蜘蛛
    spider_water = {
        bank = "spider_water",
        build = "spider_water",
        anim = "idle",
        sg = "SGspider_water",
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

            spiderPostInit(inst)
        end,
    },

    ----------------------------- 猎犬 -----------------------------
    -- 猎犬
    hound = {
        bank = "hound",
        build = "hound_ocean",
        anim = "idle",
        sg = "SGhound",
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

    ----------------------------- 蜜蜂 -----------------------------
    -- 蜜蜂
	bee = {
        bank = "bee",
        build = "bee_build",
        anim = "idle",
        sg = "SGbee",
        scale = 0.8,
        sounds = {
            takeoff = "dontstarve/bee/bee_takeoff",
            attack = "dontstarve/bee/bee_attack",
            buzz = "dontstarve/bee/bee_fly_LP",
            hit = "dontstarve/bee/bee_hurt",
            death = "dontstarve/bee/bee_death",
        },
    },

    -- 杀人蜂
    killerbee = {
        bank = "bee",
        build = "bee_angry_build",
        anim = "idle",
        sg = "SGbee",
        scale = 0.8,
        sounds = {
            takeoff = "dontstarve/bee/killerbee_takeoff",
            attack = "dontstarve/bee/killerbee_attack",
            buzz = "dontstarve/bee/killerbee_fly_LP",
            hit = "dontstarve/bee/killerbee_hurt",
            death = "dontstarve/bee/killerbee_death",
        },
    },

    -- 大黄蜂
    beeguard = {
        bank = "bee_guard",
        build = "bee_guard_build",
        anim = "idle",
        sg = "SGbeeguard",
        scale = 0.8,
        sounds = {
            attack = "dontstarve/bee/killerbee_attack",
            buzz = "dontstarve/bee/bee_fly_LP",
            hit = "dontstarve/creatures/together/bee_queen/beeguard/hurt",
            death = "dontstarve/creatures/together/bee_queen/beeguard/death",
        },
        face = 6,
    },

    --------------------------- 曼德拉草 ---------------------------
	mandrake_active = {
        bank = "mandrake",
        build = "mandrake",
        anim = "idle_loop",
        sg = "SGMandrake",
        scale = 0.9,
    },

    ----------------------------- 蝴蝶 -----------------------------
	butterfly = {
        bank = "butterfly",
        build = "butterfly_basic",
        anim = "idle",
        sg = "SGbutterfly",
        scale = 1,
        face = 2,
        bb = true,
    },

    --------------------------- 编织暗影 ---------------------------
    -- 爪
    stalker_minion1 = {
        bank = "stalker_minion",
        build = "stalker_minion",
        anim = "idle",
        sg = "SGstalker_minion",
        origin = "stalker_minion",
        scale = 0.8,
        face = 6,
    },

    -- 牙
    stalker_minion2 = {
        bank = "stalker_minion_2",
        build = "stalker_minion_2",
        anim = "idle",
        sg = "SGstalker_minion",
        origin = "stalker_minion",
        scale = 0.8,
        face = 6,
    },

    ----------------------------- 鼹鼠 -----------------------------
    -- 鼹鼠
	mole = {
        bank = "mole",
        build = "mole_build",
        anim = "idle_under",
        sg = "SGmole",
        postInit = function(inst)
            inst._aipCanRun = false

            inst.SetUnderPhysics = function()
                inst.isunder = true
            end
            inst.SetAbovePhysics = function()
                inst.isunder = false
            end
        end,
    },

    ----------------------------- 浣猫 -----------------------------
    -- 浣猫
	catcoon = {
        bank = "catcoon",
        build = "catcoon_build",
        anim = "idle_loop",
        sg = "SGcatcoon",
    },

    ----------------------------- 戳食 -----------------------------
    -- 戳食者
    slurper = {
        bank = "slurper",
        build = "slurper_basic",
        anim = "idle_loop",
        sg = "SGslurper",
        scale = 0.6,
        postInit = function(inst)
            inst._light = SpawnPrefab("slurperlight")
            inst._light.entity:SetParent(inst.entity)

            inst._light.Light:SetRadius(0.5)
        end,
    },

    ----------------------------- 泥蟹 -----------------------------
    -- 泥蟹
    aip_mud_crab = {
        bank = "aip_mud_crab",
        build = "aip_mud_crab",
        anim = "idle_loop",
        sg = "SGaip_mud_crab",
        scale = 1,
        face = 2,
        bb = true,
        postInit = function(inst) -- 强制切换一下 SG
            inst:DoTaskInTime(0, function()
                inst.sg:GoToState("idle")
            end)
        end,
    },

    --------------------------- 球状光虫 ---------------------------
    -- 球状光虫
    lightflier = {
        bank = "lightflier",
        build = "lightflier",
        anim = "idle_loop",
        sg = "SGlightflier",
        scale = 1,
        bb = true,

        preInit = function(inst)
            inst.entity:AddLight()
            inst.Light:SetColour(1, 0, 0)
        end,
    },

    ----------------------------- 龙虾 -----------------------------
    -- 龙虾
    wobster_sheller_land = {
        bank = "lobster",
        build = "lobster_sheller",
        anim = "idle",
        sg = "SGwobsterland",
        origin = "wobster_sheller",
    },

    -- 月光龙虾
    wobster_moonglass_land = {
        bank = "lobster",
        build = "lobster_moonglass",
        anim = "idle",
        sg = "SGwobsterland",
        origin = "wobster_moonglass",
    },

    ------------------------- 欧米伽黏菌团 -------------------------
    -- 欧米伽黏菌团
    aip_slime_mold = {
        bank = "aip_slime_mold",
        build = "aip_slime_mold",
        anim = "idle_loop",
        sg = "SGaip_slime_mold",
        scale = 0.8,
        face = 2,
        bb = true,
    },

    --------------------------- 恐怖之眼 ---------------------------
    eyeofterror = {
        bank = "eyeofterror",
        build = "eyeofterror_basic",
        anim = "eye_idle",
        sg = "SGeyeofterror",
        origin = "eyeofterror",
        scale = 0.3,
        face = 6,
        postInit = function(inst) -- 添加一下声音
            inst._soundpath = "terraria1/eyeofterror/"
        end,
    },
}

-- 填充一下 origin
for name, info in pairs(PREFABS) do
    if not info.origin then
        info.origin = name
    end
end

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
        petals = 0.5,       -- 50% 概率掉花瓣
    },

    ------------------------- 蜜蜂 -------------------------
    bee = {
        honey = 0.05,       -- 5% 概率掉蜂蜜
    },
    killerbee = {
        stinger = 0.05,     -- 5% 概率掉蜂刺
    },

    ------------------------ 曼德拉 ------------------------
    mandrake_active = {     -- 什么都不掉
    },

    ------------------------- 蝴蝶 -------------------------
    butterfly = {
        petals = 0.5,       -- 50% 概率掉花瓣
    },

    ----------------------- 编织暗影 -----------------------
    stalker_minion1 = {
        nightmarefuel = .05,    -- 5% 概率掉噩梦燃料
    },

    ------------------------- 鼹鼠 -------------------------
    mole = {
        rocks = 0.5,
        flint = 0.2,
        nitre = 0.2,
        goldnugget = 0.05,
    },

    ------------------------- 浣猫 -------------------------
    catcoon = {
        spoiled_food = 0.5,
        cutgrass = 0.5,
        feather_crow = 0.1,
        feather_robin = 0.1,
        feather_robin_winter = 0.1,
        feather_canary = 0.05,
    },

    ------------------------- 戳食 -------------------------
    slurper = {
        beardhair = 0.01,           -- 1% 概率掉胡子
    },
}

SHEDDING_LOOT.spider_hider = SHEDDING_LOOT.spider_warrior       -- 洞穴蜘蛛
SHEDDING_LOOT.spider_spitter = SHEDDING_LOOT.spider_warrior     -- 喷射蜘蛛
SHEDDING_LOOT.spider_dropper = SHEDDING_LOOT.spider             -- 垂线蜘蛛
SHEDDING_LOOT.spider_water = SHEDDING_LOOT.spider_warrior       -- 海生蜘蛛

SHEDDING_LOOT.beeguard = SHEDDING_LOOT.bee                      -- 蜜蜂守卫

SHEDDING_LOOT.stalker_minion2 = SHEDDING_LOOT.stalker_minion1   -- 编织暗影

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

    ------------------------- 蜜蜂 -------------------------
	if prefab == "bee" then
		if
			inst.components.inventoryitem ~= nil and
			inst.components.inventoryitem.imagename == "killerbee"
		then
			prefab = "killerbee"
		end
	end

    ----------------------- 恐怖之眼 -----------------------
    if prefab == "aip_pet_eyeofterror" then
        prefab = "eyeofterror"
    end

	return prefab, subPrefab
end

-- 获取宠物专属技能
local function getSkills(prefab, subPrefab)
    ------------------------- 兔子 -------------------------
    if prefab == "rabbit" then
        local skills = {
            "lucky",
        }

        if subPrefab == "_winter" then
            table.insert(skills, "cool")
        end

        return skills
    end

    ------------------------- 蜘蛛 -------------------------
    if prefab == "spider_healer" then
        return {
            "cure",
        }
    elseif prefab == "spider_water" then
        return {
            "winterSwim",
        }
    elseif prefab == "spider_moon" then
        return {
            "luna",
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

    ------------------------- 蜜蜂 -------------------------
    if prefab == "bee" or prefab == "killerbee" or prefab == "beeguard" then
        local list = {
            "acupuncture",
        }

        if prefab == "beeguard" then
            table.insert(list, "ge")
        end

        return list
    end

    ------------------------- 曼德拉 -------------------------
    if prefab == "mandrake_active" then
        return {
            "hypnosis",
        }
    end

    ------------------------- 蝴蝶 -------------------------
    if prefab == "butterfly" then
        return {
            "dancer",
        }
    end

    ------------------------- 编织暗影 -------------------------
    if prefab == "stalker_minion1" or prefab == "stalker_minion2" then
        return {
            "d4c",
        }
    end

    ------------------------- 鼹鼠 -------------------------
    if prefab == "mole" then
        return {
            "dig",
        }
    end

    ------------------------- 浣猫 -------------------------
    if prefab == "catcoon" then
        return {
            "play",
        }
    end

    ------------------------ 戳食者 ------------------------
    if prefab == "slurper" then
        return {
            "migao",
        }
    end

    ------------------------- 泥蟹 -------------------------
    if prefab == "aip_mud_crab" then
        return {
            "muddy",
        }
    end

    ----------------------- 球状光虫 -----------------------
    if prefab == "lightflier" then
        return {
            "bubble",
        }
    end

    ------------------------- 龙虾 -------------------------
    if prefab == "wobster_sheller_land" or prefab == "wobster_moonglass_land" then
        return {
            "shrimp",
        }
    end

    --------------------- 欧米伽黏菌团 ---------------------
    if prefab == "aip_slime_mold" then
        return {
            "resonance",
        }
    end
end

return {
	PREFABS = PREFABS,
	getPrefab = getPrefab,
    getSkills = getSkills,
    SHEDDING_LOOT = SHEDDING_LOOT,
}