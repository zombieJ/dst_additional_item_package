--[[
    Buffer 对象，因为动态创建的 component 的 replica 不会出现在 client 端。
    我们通过创建一个实体来同步数据。
]]

local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local assets = {
	Asset("ANIM", "anim/aip_buffer.zip")
}


----------------------------------- 注册 -----------------------------------
local function onRegisterParent(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil then
        inst._aipParentGUID = parent.GUID
        parent._aipBufferGUID = inst.GUID
    end
end

local function onUnregisterParent(inst)
    local parent = Ents[inst._aipParentGUID]
    if parent ~= nil then
        parent._aipBufferGUID = nil
    end
end

----------------------------------- 事件 -----------------------------------
local interval = 0.5

local function getParent(inst)
    local parentEntity = inst.entity:GetParent()
    return parentEntity and Ents[parentEntity.GUID] or nil
end

-- 【服务端】同步名称
local function syncNames(inst)
    local nameEndTimes = {}

    for key, info in pairs(inst._buffers) do
		table.insert(nameEndTimes, key..":"..info.endTime..":"..info.stack)
	end

    inst._aipBufferNames:set(
        -- aipJoin(aipTableKeys(inst._buffers), ",")
        aipJoin(nameEndTimes, ",")
    )
end

-- 【客户端】同步服务端 Buffer 信息
local function getBufferInfos(inst)
    local bufferKeys = aipSplit(inst._aipBufferNames:value(), ",")

    local bufferInfos = {}

    -- 遍历创建客户端特效
    for i, bufferNameEndTimeStack in ipairs(bufferKeys) do
        local nameEndTimeStack = aipSplit(bufferNameEndTimeStack, ":")
        local bufferName = nameEndTimeStack[1]
        local endTime = tonumber(nameEndTimeStack[2])
        local stack = tonumber(nameEndTimeStack[3])

        bufferInfos[bufferName] = {
            endTime = endTime,
            stack = stack,
        }
    end

    return bufferInfos
end

-- 【客户端】函数
local function clientRefresh(inst)
    local bufferInfos = getBufferInfos(inst)

    for bufferName, info in pairs(bufferInfos) do
        local clientFn = aipBufferFn(bufferName, "clientFn")
        if clientFn ~= nil then
            clientFn(getParent(inst))
        end
    end

    -- local bufferKeys = aipSplit(inst._aipBufferNames:value(), ",")

    -- -- 遍历创建客户端特效
    -- for i, bufferNameEndTime in ipairs(bufferKeys) do
    --     local nameEndTime = aipSplit(bufferNameEndTime, ":")
    --     local bufferName = nameEndTime[1]
    --     local endTime = tonumber(nameEndTime[2])

    --     local clientFn = aipBufferFn(bufferName, "clientFn")
    --     if clientFn ~= nil then
    --         clientFn(getParent(inst))
    --     end
    -- end
end

-- -- 【客户端】存在 Buffer
-- local function bufferExist(inst, name)
--     -- local bufferKeys = aipSplit(inst._aipBufferNames:value(), ",")
--     local bufferKeys = aipTableKeys(getBufferInfos(inst))

--     for i, bufferName in ipairs(bufferKeys) do
--         if bufferName == name then
--             return true
--         end
--     end

--     return false
-- end

local function getSource(GUID)
	return Ents[GUID]
end

-- 【服务端】函数
local function serverRefresh(inst)
    local allRemove = true
	local rmNames = {}
    local nextShowFX = false

    local now = GetTime()

	for name, info in pairs(inst._buffers) do
		info.tick = info.tick + 1

		-- 参数：源头，目标，间隔，时间差
		local fnData = {
			interval = interval,
			passTime = now - info.startTime,
			tick = info.tick,
            tickTime = info.tick * interval,
			data = info.data,
		}

		-- 全局函数
		local fn = aipBufferFn(name, "fn")
		if fn ~= nil then
			fn(getSource(info.srcGUID), getParent(inst), fnData)
		end

        nextShowFX = aipBufferFn(name, "showFX") or nextShowFX

		-- 清理过期的 buffer
		-- if info.duration <= 0 then
        if info.endTime <= now then
			table.insert(rmNames, name)
		else
			allRemove = false
		end
	end

    -- 决定是否需要展示光环
    if nextShowFX ~= inst._aipShowFX then
        inst._aipShowFX = nextShowFX

        if inst._aipShowFX then
            inst:Show()
        else
            inst:Hide()
        end
    end

	-- 清除的 buffer 需要一个退出事件处理收尾
	for i, name in ipairs(rmNames) do
		local info = inst._buffers[name]

		-- 全局结束函数
		local endFn = aipBufferFn(name, "endFn")
		if endFn ~= nil then
			endFn(getSource(info.srcGUID), getParent(inst), { data = info.data })
		end

        -- 移除 FX
        if info.fx ~= nil then
            inst:RemoveChild(info.fx)
        end
	end

	inst._buffers = aipFilterKeysTable(inst._buffers, rmNames)
	syncNames(inst)

    -- 没有 Buffer 直接删除实体
	if allRemove then
		inst:Remove()
	end
end

----------------------------------- 实例 -----------------------------------
local function fn(data)
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_buffer")
    inst.AnimState:SetBuild("aip_buffer")

    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(0.24, 0.27, 0.38, 1)

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst:AddTag("NOCLICK")
    inst:AddTag("fx")

    inst.entity:SetPristine()

    -- 打印一些数据
    -- if dev_mode then
    --     inst:DoTaskInTime(0.5, function()
    --         aipPrint("Create With GUID:", inst.GUID, inst.entity:GetParent() == Ents[inst.entity:GetParent().GUID])
    --         aipPrint("Same one?", inst.entity:GetParent() == ThePlayer)
    --     end)
    -- end

    -- 将自己注册给父节点
    inst:DoTaskInTime(0.01, onRegisterParent)

    -- 如果移除了，父节点也取消一下
    inst.OnRemoveEntity = onUnregisterParent

    -- 服务器不用展示特效
    if not TheNet:IsDedicated() then
        inst:DoPeriodicTask(interval, clientRefresh, 0.01)
    end

    inst._aipBufferNames = net_string(inst.GUID, "aipc_buffer", "aipc_buffer_dirty")
    -- inst._aipBufferExist = bufferExist
    inst._aipBufferInfos = getBufferInfos

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst._buffers = {}
    inst._aipSyncNames = syncNames
    inst._aipShowFX = nil

    inst:DoPeriodicTask(interval, serverRefresh, 0.01)

    return inst
end

----------------------------------- BUFF -----------------------------------
local function commonFn(anim)
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_buffer")
    inst.AnimState:SetBuild("aip_buffer")

    inst.AnimState:PlayAnimation(anim, true)

    inst:AddTag("NOCLICK")
    inst:AddTag("fx")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function paincFn()
    return commonFn("panic")
end

return  Prefab("aip_0_buffer", fn, assets),
        Prefab("aip_buffer_panic", paincFn, assets)
