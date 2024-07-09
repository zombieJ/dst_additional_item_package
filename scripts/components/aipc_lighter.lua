-- 做一个双端组件，用于当为着火状态时可以点燃
local Lighter = Class(function(self, inst)
    self.inst = inst

    self.enabled = false
end)

function Lighter:Enabled(enabled)
    self.enabled = enabled

    if self.enabled then
        self.inst:AddTag("aip_lighter")
    else
        self.inst:RemoveTag("aip_lighter")
    end
end

function Lighter:Light(target, doer)
    if target.components.burnable ~= nil and not ((target:HasTag("fueldepleted") and not target:HasTag("burnableignorefuel")) or target:HasTag("INLIMBO")) then
        target.components.burnable:Ignite(nil, self.inst, doer)
    end
    target:PushEvent("onlighterlight")
end

return Lighter
