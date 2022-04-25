--[[
    Buffer 对象，因为动态创建的 component 的 replica 不会出现在 client 端。
    我们通过创建一个实体来同步数据。
]]

local assets = {
	Asset("ANIM", "anim/aip_buffer.zip")
}

----------------------------------- 事件 -----------------------------------
local interval = 0.5

-- 【服务端】同步名称
local function syncNames(inst)
    inst._aipBufferNames:set(
        aipJoin(aipTableKeys(inst._buffers), ",")
    )
    
end

-- 【客户端】函数
local function clientRefresh(inst)
    local bufferKeys = aipSplit(inst._aipBufferNames:(), ",")

    -- 遍历创建客户端特效
    for i, bufferName in ipairs(bufferKeys) do
        local clientFn = aipBufferFn(bufferName, "clientFn")
        if clientFn ~= nil then
            clientFn(inst)
        end
    end
end

local function getSource(GUID)
	return Ents[GUID]
end

-- 【服务端】函数
local function serverRefresh(inst)
    local allRemove = true
	local rmNames = {}

	for name, info in pairs(inst._buffers) do
		info.duration = info.duration - interval

		-- 参数：源头，目标，间隔，时间差
		local fnData = {
			interval = interval,
			passTime = GetTime() - info.startTime,
			data = info.data,
		}

		-- 全局函数
		local fn = aipBufferFn(name, "fn")
		if fn ~= nil then
			fn(getSource(info.srcGUID), inst, fnData)
		end

		-- 清理过期的 buffer
		if info.duration <= 0 then
			table.insert(rmNames, name)
		else
			allRemove = false
		end
	end

	-- 清除的 buffer 需要一个退出事件处理收尾
	for i, name in ipairs(rmNames) do
		local info = self.buffers[name]

		-- 全局结束函数
		local endFn = aipBufferFn(name, "endFn")
		if endFn ~= nil then
			endFn(getSource(info.srcGUID), inst, { data = info.data })
		end
	end

	inst._buffers = aipFilterKeysTable(inst._buffers, rmNames)
	syncNames(inst)

    -- 没有 Buffer 直接删除实体
	if allRemove then
		inst.parent:Remove()
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

    inst:DoPeriodicTask(interval, clientRefresh, 0.01)

    inst._aipBufferNames = net_string(inst.GUID, "aipc_buffer", "aipc_buffer_dirty")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst._buffers = {}
    inst._aipSyncNames = syncNames

    inst:DoPeriodicTask(interval, serverRefresh, 0.01)

    return inst
end

return Prefab("aip_0_buffer", fn, assets)
