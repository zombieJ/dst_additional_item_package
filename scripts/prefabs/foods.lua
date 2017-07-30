local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_food = GetModConfigData("additional_food", foldername)
if additional_food ~= "open" then
	return nil
end

local food_effect = GetModConfigData("food_effect", foldername)
local language = GetModConfigData("language", foldername)

-- 默认参数
local EFFECT_MAP = {
	["less"] = 0.6,
	["normal"] = 1,
	["large"] = 1.5,
}
local effectPTG = EFFECT_MAP[food_effect]

-- 语言
local LANG_MAP = {
	["english"] = {
		["EGG_PANCAKE"] = {
			["NAME"] = "Egg Pancake",
			["DESC"] = "Too many eggs!",
		},
		["MONSTER_SALAD"] = {
			["NAME"] = "Monster Salad",
			["DESC"] = "At least something I can eat",
		},
		["SKUNK_SMOOTHIES"] = {
			["NAME"] = "Skunk Smoothies",
			["DESC"] = "What Is The SMELLLL!",
		},
		["FISH_FROGGLE"] = {
			["NAME"] = "Fish Froggle",
			["DESC"] = "Delicious from China",
		},
		["BAMBOO_LIGHT"] = {
			["NAME"] = "Bamboo Light",
			["DESC"] = "Why are you so cute?",
		},
		["VEGETABALLS"] = {
			["NAME"] = "Vegetaballs",
			["DESC"] = "Is that healthy?",
		},
		["VEG_LOHAN"] = {
			["NAME"] = "Veggie Lohan",
			["DESC"] = "Something comes from Buddhism?",
		},
		["HONEY_DRUMSTICK"] = {
			["NAME"] = "Honey Drumstick",
			["DESC"] = "Let's play the honey music",
		},
		["MEAT_BURGER"] = {
			["NAME"] = "Meat Burger",
			["DESC"] = "Everything is meat",
		},
		["VEGGIE_SKEWERS"] = {
			["NAME"] = "Veggie Skewers",
			["DESC"] = "The mirror of Kabobs",
		},
		["STINKY_MANDARIN_FISH"] = {
			["NAME"] = "Stinky Mandarin Fish",
			["DESC"] = "Amazing fish cook!",
		},
		["WATERMELON_JUICE"] = {
			["NAME"] = "Watermelon Juice",
			["DESC"] = "Best drink in summer",
		},
		["CATERPILLAR_BREAD"] = {
			["NAME"] = "Caterpillar Bread",
			["DESC"] = "It is moving",
		},
		["DURIAN_SUGAR"] = {
			["NAME"] = "Durian Sugar",
			["DESC"] = "Not this one",
		},
		["FROZEN_HEART"] = {
			["NAME"] = "Frozen Heart",
			["DESC"] = "Why pot can make this",
		},
	},
	["spanish"] = {
		["EGG_PANCAKE"] = {
			["NAME"] = "Pancake de huevos",
			["DESC"] = "Demasiados huevos!",
		},
		["MONSTER_SALAD"] = {
			["NAME"] = "Ensalada de Monstruo",
			["DESC"] = "Fianlmente algo que puedo comer!",
		},
		["SKUNK_SMOOTHIES"] = {
			["NAME"] = "Batido de Zorrillo",
			["DESC"] = "¡¿Qué es ese hedor?!",
		},
		["FISH_FROGGLE"] = {
			["NAME"] = "Pollo a la Anca",
			["DESC"] = "Delicias de China",
		},
		["BAMBOO_LIGHT"] = {
			["NAME"] = "Luz de Bambú",
			["DESC"] = "¿Porqué eres tan lindo?",
		},
		["VEGETABALLS"] = {
			["NAME"] = "Albondivegetales",
			["DESC"] = "¿Son saludables?",
		},
		["VEG_LOHAN"] = {
			["NAME"] = "Vegetales a la Lohan",
			["DESC"] = "¿Algo viene del Budismo?",
		},
		["HONEY_DRUMSTICK"] = {
			["NAME"] = "Perniles con Miel",
			["DESC"] = "Toquémos música dulce",
		},
		["MEAT_BURGER"] = {
			["NAME"] = "Hamburguesa de Carne",
			["DESC"] = "Todo es carne",
		},
		["VEGGIE_SKEWERS"] = {
			["NAME"] = "Brochetas Vegetales",
			["DESC"] = "El espejo de los Kebab",
		},
		["STINKY_MANDARIN_FISH"] = {
			["NAME"] = "Pescado Chino Apestoso",
			["DESC"] = "¡Impresionante comida de mar!",
		},
		["WATERMELON_JUICE"] = {
			["NAME"] = "Juego de Sandía",
			["DESC"] = "Recomendada en el Verano",
		},
		["CATERPILLAR_BREAD"] = {
			["NAME"] = "Pan de Mariposa",
			["DESC"] = "Se está moviendo",
		},
		["DURIAN_SUGAR"] = {
			["NAME"] = "Endulzante de Durian",
			["DESC"] = "Este no",
		},
		["FROZEN_HEART"] = {
			["NAME"] = "Corazón Congelado",
			["DESC"] = "¿Porqué se puede cocinar esto?",
		},
	},
	["russian"] = {
		["EGG_PANCAKE"] = {
			["NAME"] = "Блин с яйцом",
			["DESC"] = "Слишком много яиц!",
		},
		["MONSTER_SALAD"] = {
			["NAME"] = "Салат из мяса монстра",
			["DESC"] = "Хоть что-то, что я могу съесть.",
		},
		["SKUNK_SMOOTHIES"] = {
			["NAME"] = "Скунсовый Смузи",
			["DESC"] = "Как же оно ВОНЯЕТ!",
		},
		["FISH_FROGGLE"] = {
			["NAME"] = "Рыба с лягушачьими лапками",
			["DESC"] = "Деликатес из Китая",
		},
		["BAMBOO_LIGHT"] = {
			["NAME"] = "Бамбуковый свет",
			["DESC"] = "Почему ты такой милый?",
		},
		["VEGETABALLS"] = {
			["NAME"] = "Овощные шарики",
			["DESC"] = "Это полезно для здоровья?",
		},
		["VEG_LOHAN"] = {
			["NAME"] = "Вегетарианский Лохан",
			["DESC"] = "Что-то связанное с буддизмом?",
		},
		["HONEY_DRUMSTICK"] = {
			["NAME"] = "Ножка индейки в меду:",
			["DESC"] = "Давайте сыграем сладкую мелодию!",
		},
		["MEAT_BURGER"] = {
			["NAME"] = "Мясной бургер",
			["DESC"] = "Мясо - это всё",
		},
		["VEGGIE_SKEWERS"] = {
			["NAME"] = "Вегетарианский шашлык",
			["DESC"] = "Отражение кебабов",
		},
		["STINKY_MANDARIN_FISH"] = {
			["NAME"] = "Вонючая Мандаринка",
			["DESC"] = "Отлично приготовленная рыба!",
		},
		["WATERMELON_JUICE"] = {
			["NAME"] = "Арбузный сок",
			["DESC"] = "Лучший напиток для лета!",
		},
		["CATERPILLAR_BREAD"] = {
			["NAME"] = "Хлеб - Гусеница",
			["DESC"] = "Оно движется...",
		},
		["DURIAN_SUGAR"] = {
			["NAME"] = "Дуриановый сахар",
			["DESC"] = "Ммм...Вкусно",
		},
		["FROZEN_HEART"] = {
			["NAME"] = "Ледяное Сердце",
			["DESC"] = "Почему я могу сделать это в казане?",
		},
	},
	["chinese"] = {
		["EGG_PANCAKE"] = {
			["NAME"] = "鸡蛋灌饼",
			["DESC"] = "天呐，满满都是蛋！",
		},
		["MONSTER_SALAD"] = {
			["NAME"] = "怪物沙拉",
			["DESC"] = "至少这东西可以充饥",
		},
		["SKUNK_SMOOTHIES"] = {
			["NAME"] = "臭鼬果昔",
			["DESC"] = "这到底是什么味道！",
		},
		["FISH_FROGGLE"] = {
			["NAME"] = "美蛙鱼头",
			["DESC"] = "中华美食~",
		},
		["BAMBOO_LIGHT"] = {
			["NAME"] = "星光特典",
			["DESC"] = "天呐，怎么这么可爱？",
		},
		["VEGETABALLS"] = {
			["NAME"] = "蔬菜丸子",
			["DESC"] = "它吃起来够健康吗？",
		},
		["VEG_LOHAN"] = {
			["NAME"] = "素罗汉",
			["DESC"] = "一念成佛，一口吃饱",
		},
		["HONEY_DRUMSTICK"] = {
			["NAME"] = "蜜汁鸡腿",
			["DESC"] = "卡路里的完美融合",
		},
		["MEAT_BURGER"] = {
			["NAME"] = "混合肉堡",
			["DESC"] = "全部都是肉！",
		},
		["VEGGIE_SKEWERS"] = {
			["NAME"] = "素食串",
			["DESC"] = "这是烤串的镜像",
		},
		["STINKY_MANDARIN_FISH"] = {
			["NAME"] = "臭鲑鱼",
			["DESC"] = "完美的鱼料理",
		},
		["WATERMELON_JUICE"] = {
			["NAME"] = "西瓜汁",
			["DESC"] = "夏日最佳饮品",
		},
		["CATERPILLAR_BREAD"] = {
			["NAME"] = "毛毛虫",
			["DESC"] = "它是在动吗",
		},
		["DURIAN_SUGAR"] = {
			["NAME"] = "榴莲糖",
			["DESC"] = "我才不想吃",
		},
		["FROZEN_HEART"] = {
			["NAME"] = "冰冻之心",
			["DESC"] = "它是怎么被烹饪出来的？",
		},
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local prefabList = {}
local prefabs =
{
	"spoiled_food",
}

local HP = TUNING.HEALING_TINY -- 1 healing
local HU = TUNING.CALORIES_HUGE / 75 -- 1 hunger
local SAN = TUNING.SANITY_SUPERTINY -- 1 sanity
local PER = TUNING.PERISH_ONE_DAY -- 1 day
local CO = 1 / 20 -- 1 second

-- 方法
local function getCount(entity, name)
	return entity[name] or 0
end

-- 配方
local food_recipes = {
	egg_pancake = {
		test = function(cooker, names, tags) return tags.egg and tags.egg >= 3 and not tags.inedible end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 20,
		hunger = HU * 80,
		sanity = SAN * 10,
		perishtime = PER * 5,
		cooktime = CO * 20,
	},

	monster_salad = {
		test = function(cooker, names, tags) return tags.monster and tags.veggie and tags.veggie >= 3 and not tags.inedible end,
		priority = 0,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 65,
		sanity = SAN * 10,
		perishtime = PER * 6,
		cooktime = CO * 20,
	},
	
	skunk_smoothies = {
		test = function(cooker, names, tags)
			return (names.durian or names.durian_cooked) and tags.frozen and tags.fruit and tags.fruit >= 2 and not tags.inedible
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 20,
		sanity = SAN * 35,
		perishtime = PER * 6,
		cooktime = CO * 10,
	},
	fish_froggle = {
		test = function(cooker, names, tags)
			return (names.froglegs or names.froglegs_cooked) and tags.fish and not tags.inedible
		end,
		priority = 2,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 30,
		hunger = HU * 80,
		sanity = SAN * 15,
		perishtime = PER * 6,
		cooktime = CO * 40,
	},
	bamboo_light = {
		test = function(cooker, names, tags)
			return (names.corn or names.corn_cooked) and (names.carrot or names.carrot_cooked) and (names.pumpkin or names.pumpkin_cooked)
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 100,
		hunger = HU * 5,
		sanity = SAN * 10,
		perishtime = PER * 20,
		cooktime = CO * 15,
	},
	vegetaballs = {
		test = function(cooker, names, tags)
			return tags.meat and tags.veggie and not tags.inedible and not tags.frozen and not tags.fruit
		end,
		priority = 0,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 5,
		hunger = HU * 60,
		sanity = SAN * 10,
		perishtime = PER * 10,
		cooktime = CO * 15,
	},
	veg_lohan = {
		test = function(cooker, names, tags)
			local red = getCount(names, "red_cap") +  getCount(names, "red_cap_cooked")
			local green = getCount(names, "green_cap") +  getCount(names, "green_cap_cooked")
			local blue = getCount(names, "blue_cap") +  getCount(names, "blue_cap_cooked")
			return red + green + blue > 3
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 50,
		sanity = SAN * 15,
		perishtime = PER * 20,
		cooktime = CO * 30,
	},
	honey_drumstick = {
		test = function(cooker, names, tags)
			return names.drumstick and tags.sweetener and tags.sweetener >= 2 and tags.meat and tags.meat < 1
		end,
		priority = 3,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 20,
		hunger = HU * 40,
		sanity = SAN * 5,
		perishtime = PER * 6,
		cooktime = CO * 30,
		tags = {"honeyed"},
	},
	meat_burger = {
		test = function(cooker, names, tags)
			return tags.meat and tags.meat > 1 and tags.egg and (names.froglegs or names.froglegs_cooked) and tags.fish
		end,
		priority = 3,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 20,
		hunger = HU * 150,
		sanity = SAN * 5,
		perishtime = PER * 10,
		cooktime = CO * 15,
	},
	veggie_skewers = {
		test = function(cooker, names, tags)
			return tags.veggie and tags.inedible and tags.inedible < 2 and not tags.meat
		end,
		priority = -1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 30,
		sanity = SAN * 5,
		perishtime = PER * 15,
		cooktime = CO * 20,
	},
	stinky_mandarin_fish = {
		test = function(cooker, names, tags)
			return tags.fish and tags.monster and not tags.inedible
		end,
		priority = 0,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 10,
		hunger = HU * 65,
		sanity = SAN * 5,
		perishtime = PER * 10,
		cooktime = CO * 30,
	},
	watermelon_juice = {
		test = function(cooker, names, tags)
			return names.watermelon and tags.fruit and tags.fruit > 1 and tags.frozen
		end,
		priority = 1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 5,
		hunger = HU * 40,
		sanity = SAN * 5,
		perishtime = PER * 6,
		cooktime = CO * 20,
	},
	caterpillar_bread = {
		test = function(cooker, names, tags)
			return names.butterflywings and tags.meat
		end,
		priority = 10,
		weight = 1,
		foodtype = FOODTYPE.MEAT,
		health = HP * 15,
		hunger = HU * 50,
		sanity = SAN * 5,
		perishtime = PER * 15,
		cooktime = CO * 40,
	},
	durian_sugar = {
		test = function(cooker, names, tags)
			return (names.durian or names.durian_cooked) and tags.sweetener and tags.sweetener >= 2
		end,
		priority = 20,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * (-10),
		hunger = HU * 20,
		sanity = SAN * 20,
		perishtime = PER * 15,
		cooktime = CO * 30,
		tags = {"honeyed"},
	},
	frozen_heart = {
		test = function(cooker, names, tags)
			return tags.frozen and tags.frozen > 3
		end,
		priority = -1,
		weight = 1,
		foodtype = FOODTYPE.VEGGIE,
		health = HP * 0,
		hunger = HU * 0,
		sanity = SAN * 0,
		perishtime = PER * 30,
		cooktime = CO * 10,
		temperature = TUNING.COLD_FOOD_BONUS_TEMP,
		temperatureduration = TUNING.FOOD_TEMP_LONG,
		goldvalue = TUNING.GOLD_VALUES.MEAT,
	},
}

--------------------------------------------------
for name,data in pairs(food_recipes) do
	-- 预处理
	data.name = name
	data.weight = data.weight or 1
	data.priority = data.priority or 0

	-- 食物属性
	data.health = data.health * effectPTG
	data.hunger = data.hunger * effectPTG
	data.sanity = data.sanity * effectPTG

	-- 添加文字
	local upperCase = string.upper(name)
	STRINGS.NAMES[upperCase] = LANG[upperCase].NAME
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperCase] = LANG[upperCase].DESC

	-- 添加食物
	AddModPrefabCookerRecipe("cookpot", data)

	-------------------- 创建食物实体 --------------------
	local assets = {
		Asset("ATLAS", "images/inventoryimages/"..data.name..".xml"),
		Asset("IMAGE", "images/inventoryimages/"..data.name..".tex"),
		Asset("ANIM", "anim/"..data.name..".zip"),
	}

	function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBuild(data.name)
		inst.AnimState:SetBank(data.name)
		inst.AnimState:PlayAnimation("BUILD", false)

		inst:AddTag("preparedfood")
		if data.tags then
			for i,v in pairs(data.tags) do
				inst:AddTag(v)
			end
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		-- 食物
		inst:AddComponent("edible")
		inst.components.edible.healthvalue = data.health
		inst.components.edible.hungervalue = data.hunger
		inst.components.edible.foodtype = data.foodtype or FOODTYPE.GENERIC
		inst.components.edible.sanityvalue = data.sanity or 0
		inst.components.edible.temperaturedelta = data.temperature or 0
		inst.components.edible.temperatureduration = data.temperatureduration or 0
		inst.components.edible:SetOnEatenFn(data.oneatenfn)

		inst:AddComponent("inspectable")
		inst.wet_prefix = data.wet_prefix

		-- 是否可以交易
		if data.goldvalue then
			inst:AddComponent("tradable")
			inst.components.tradable.goldvalue = data.goldvalue
		end

		-- 物品栏
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..data.name..".xml"

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		if data.perishtime ~= nil and data.perishtime > 0 then
			inst:AddComponent("perishable")
			inst.components.perishable:SetPerishTime(data.perishtime)
			inst.components.perishable:StartPerishing()
			inst.components.perishable.onperishreplacement = "spoiled_food"
		end
		
		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		MakeHauntableLaunchAndPerish(inst)
		AddHauntableCustomReaction(inst, function(inst, haunter)
			return false
		end, true, false, true)
		---------------------        

		inst:AddComponent("bait")

		------------------------------------------------
		inst:AddComponent("tradable")

		------------------------------------------------  

		return inst
	end

	local prefab = Prefab(name, fn, assets, prefabs)
	table.insert(prefabList, prefab)
end



return unpack(prefabList)