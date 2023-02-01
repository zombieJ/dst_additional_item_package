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
}

local function getPrefab(inst)
	local prefab = inst.prefab
	local subPrefab = nil

	------------------------- 兔子 -------------------------
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

	return prefab, subPrefab
end

return {
	PREFABS = PREFABS,
	getPrefab = getPrefab,
}