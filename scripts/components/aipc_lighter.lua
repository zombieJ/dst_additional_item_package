-- 做一个双端组件，用于当为着火状态时可以点燃
local Lighter = Class(function(self, inst)
    self.inst = inst

    self.enableType = nil
end)

function Lighter:Enabled(type)
    if type == self.enableType then
        return
    end

    -- 移除旧的标签
    if self.enableType then
        self.inst:RemoveTag("aip_lighter_"..self.enableType)

        if not type then
            self.inst:RemoveTag("aip_lighter")
        end
    end

    -- 添加新的标签
    self.enableType = type
    if self.enableType then
        self.inst:AddTag("aip_lighter_"..self.enableType)
        self.inst:AddTag("aip_lighter")
    end
end

function Lighter:Light(target, doer)
    -- 普通点燃
    if
        self.enableType == "hot" and
        target.components.burnable ~= nil and
        not ((target:HasTag("fueldepleted") and not target:HasTag("burnableignorefuel")) or target:HasTag("INLIMBO"))
    then
        target.components.burnable:Ignite(nil, self.inst, doer)

    -- 特殊火焰
    elseif self.enableType and target:HasTag("aip_can_lighten") and target.components.aipc_type_fire then
        target.components.aipc_type_fire:StartFire(self.enableType)
    end

    target:PushEvent("onlighterlight")
end

return Lighter
