local _G = GLOBAL
local dev_mode = _G.aipGetModConfig("dev_mode") == "enabled"

if not dev_mode then
	return
end

-------------------- 警告信息 --------------------
_G.aipPrint("!!! 你正在使用《额外物品包》开发模式，如果是正式游玩请在设置中关闭该设置 !!!")

----------------- 锁定玩家 3 值 -----------------
local function PlayerPrefabPostInit(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    if not inst.components.aipc_timer then
        inst:AddComponent("aipc_timer")
    end

    -- 开发模式下移除失眠效果
    inst:RemoveTag("insomniac")

    inst.components.aipc_timer:Interval(0.3, function()
        if not inst.components.health:IsDead() and inst.components.health.currenthealth < 50 then
            inst.components.health:SetCurrentHealth(50)
        end
        if inst.components.sanity.current < 30 then
            inst.components.sanity.current = 30
            inst.components.sanity:DoDelta(0)
        end
    end)

    -- 不要淹死
    inst:DoTaskInTime(1, function()
        if inst.components.drownable then
            inst.components.drownable.enabled = false
        end
    end)
end

AddPlayerPostInit(PlayerPrefabPostInit)

-------------------- 警告信息 --------------------
--[[
AddPrefabPostInit("world", function (inst)
    -- 更新次数统计
    inst._aipDevUpdateList = {}
    inst._aipDevUpdateListTotal = {}

    -- 更新时长统计
    inst._aipDevUpdateTimesList = {}
    inst._aipDevUpdateTimesListTotal = {}

    -- 活动组件统计
    inst._aipDevWalkingList = inst._aipDevWalkingList or {}

    -- 每 2 秒统计一次
    inst:DoPeriodicTask(2, function()
        -- 更新总量
        for k, v in pairs(inst._aipDevUpdateList) do
            inst._aipDevUpdateListTotal[k] = (inst._aipDevUpdateListTotal[k] or 0) + v
        end

        -- 更新时长总量
        for k, v in pairs(inst._aipDevUpdateTimesList) do
            inst._aipDevUpdateTimesListTotal[k] = (inst._aipDevUpdateTimesListTotal[k] or 0) + v
        end

        -- 重置一下统计
        inst._aipDevUpdateList = {}
        inst._aipDevUpdateTimesList = {}
    end)
end)

-- 注入 OnUpdate 函数，查看哪些正在实时更新
AddGlobalClassPostConstruct("entityscript", "EntityScript", function(self)
    local old_add = self.AddComponent
    local old_start = self.StartUpdatingComponent
    local old_stop = self.StopUpdatingComponent

    local function getCmpName(cmp)
        for k,v in pairs(self.components) do
            if v == cmp then
                return k
            end
        end
    end

    function self:AddComponent(name, ...)
        local ret = old_add(self, name, ...)

        -- 注入 Component 的 OnUpdate 函数
        local cmp = self.components[name]
        if cmp.OnUpdate then
            local old_update = cmp.OnUpdate
            function cmp:OnUpdate(dt)
                local now = _G.os.clock()
                old_update(cmp, dt)
                local cost = _G.os.clock() - now

                _G.TheWorld._aipDevUpdateList[name] = (_G.TheWorld._aipDevUpdateList[name] or 0) + 1
                _G.TheWorld._aipDevUpdateTimesList[name] = (_G.TheWorld._aipDevUpdateTimesList[name] or 0) + cost
            end
        end

        return ret
    end

    function self:StartUpdatingComponent(cmp, ...)
        old_start(self, cmp, ...)

        _G.TheWorld._aipDevWalkingList = _G.TheWorld._aipDevWalkingList or {}

        local cmpName = getCmpName(cmp)
        if cmpName ~= nil then
            _G.TheWorld._aipDevWalkingList[cmpName] = (_G.TheWorld._aipDevWalkingList[cmpName] or {})
            _G.TheWorld._aipDevWalkingList[cmpName][self] = true
        end
    end

    function self:StopUpdatingComponent(cmp, ...)
        old_stop(self, cmp, ...)

        _G.TheWorld._aipDevWalkingList = _G.TheWorld._aipDevWalkingList or {}

        local cmpName = getCmpName(cmp)
        if cmpName ~= nil then
            _G.TheWorld._aipDevWalkingList[cmpName] = (_G.TheWorld._aipDevWalkingList[cmpName] or {})
            _G.TheWorld._aipDevWalkingList[cmpName][self] = nil
        end
    end
end)
]]