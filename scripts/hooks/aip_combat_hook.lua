local _G = GLOBAL
local language = _G.aipGetModConfig("language")
local dev_mode = _G.aipGetModConfig("dev_mode") == "enabled"

-- 伤害允许翻倍
AddComponentPostInit("combat", function(self)
	-- 各种 buff 会通过注册添加伤害倍数
	-- 当值为正：每个 BUFF 提供百分比 相加，最终算出一个 总和伤害
	-- 当值为负：基于 总和伤害，不断乘以 (100% - BUFF 百分比) 获得最终伤害
	self._aipAddDamages = {}

	-- 数值增减则总是在每个阶段的最后计算，不会添加给 specialDamage
	self._aipMultiDamages = {}

    self._aipAddDefenses = {}

    -- 伤害减免，总是不断乘以 (100% - BUFF 百分比)
    self._aipMultiDefenses = {}

	-- 通过注册添加伤害加成
	function self:aipAddDamages(name, val)
		self._aipAddDamages[name] = ptg
    end
	function self:aipMultiDamages(name, ptg)
		self._aipMultiDamages[name] = ptg
    end
    function self:aipAddDefenses(name, val)
        self._aipAddDefenses[name] = val
    end
    function self:aipMultiDefenses(name, ptg)
        self._aipMultiDefenses[name] = ptg
    end

    --[[ ===================================================================
         ==                           受到伤害                             ==
         ===================================================================]]
    local originGetAttacked = self.GetAttacked

	function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
		-- 额外添加一个代理事件
		local data = { damage = damage, spdamage = spdamage or {} }
		self.inst:PushEvent("aipAttacked", data)

		spdamage = data.spdamage
		local dmg = data.damage

		-- 素罗汉 免疫黑暗伤害
		if stimuli == "darkness" and _G.aipBufferExist(self.inst, "veg_lohan") then
			dmg = 0
			_G.aipBufferRemove(self.inst, "veg_lohan")
		end

		-- 樱桃肉 概率免疫伤害
		if _G.aipBufferExist(self.inst, "aip_food_cherry_meat") then
			local ptg = dev_mode and 1 or 0.1
			if _G.aipChance(ptg, self.inst) then
				dmg = 0
			end
		end

		-- Owner 被攻击（被攻击时，是乘法叠加伤害减免）
		if self.inst ~= nil and self.inst.components.aipc_pet_owner ~= nil then
			-- 幸运则免疫 查理 攻击
			local luckyInfo, luckyLv = self.inst.components.aipc_pet_owner:GetSkillInfo("lucky")
			if luckyInfo ~= nil and stimuli == "darkness" then
				dmg = 0
			end

			-- 淋雨声 用潮湿度减少伤害
			if dmg > 0 and self.inst.components.moisture ~= nil then
				local skillInfo, skillLv = self.inst.components.aipc_pet_owner:GetSkillInfo("rainbow")
				local moisture = self.inst.components.moisture:GetMoisture()

				if skillInfo ~= nil and moisture > 0 then
					local minVal = math.min(dmg, moisture)
					dmg = dmg - minVal
					self.inst.components.moisture:DoDelta(-minVal)

					_G.aipSpawnPrefab(self.inst, "waterstreak_burst")
				end
			end

			-- 执念W
			local resonanceInfo, resonanceLv = self.inst.components.aipc_pet_owner:GetSkillInfo("resonance")
			if resonanceInfo ~= nil and self.inst.components.sanity ~= nil and self.inst.components.sanity:IsCrazy() then
				dmg = dmg * (1 - resonanceInfo.def * resonanceLv)
			end
		end

		-- 被 Owner 攻击
		if attacker ~= nil and attacker.components.aipc_pet_owner ~= nil then
			local petDmgMulti = 0

			-- 亵渎 伤害加倍
			local blasphemyInfo = attacker.components.aipc_pet_owner:GetSkillInfo("blasphemy")

			if blasphemyInfo ~= nil then
				petDmgMulti = petDmgMulti + (dev_mode and 999 or 1)
			end

			-- 虾拳
			local shrimpInfo, shrimpLv = attacker.components.aipc_pet_owner:GetSkillInfo("shrimp")

			if shrimpInfo ~= nil then
				local inv = attacker.components.inventory
				if inv == nil or inv:GetEquippedItem(_G.EQUIPSLOTS.HANDS) == nil then
					petDmgMulti = petDmgMulti + shrimpInfo.multi * shrimpLv
				end
			end

			-- 执念W
			local resonanceInfo, resonanceLv = attacker.components.aipc_pet_owner:GetSkillInfo("resonance")
			if resonanceInfo ~= nil and attacker.components.sanity ~= nil and attacker.components.sanity:IsCrazy() then
				petDmgMulti = petDmgMulti + resonanceInfo.atk * resonanceLv
			end

			dmg = dmg * (1 + petDmgMulti)
		end

        ----------------------------------------------------------------
        --                          减伤累积                          --
        ----------------------------------------------------------------
		-- 遍历 aipMultiDefenses 计算百分比减伤
        local multiPtgPositives = 0
		local multiPtgNegatives = 1
		for name, ptg in pairs(self._aipMultiDefenses) do
			if ptg ~= nil then
                if ptg > 0 then -- 受到伤害增加
                    multiPtgPositives = multiPtgPositives + ptg
                else -- 受到伤害减少
				    multiPtgNegatives = multiPtgNegatives * (1 + ptg)
                end
			end
		end

		-- 遍历 aipAddDefenses 计算叠加减伤
        local addSum = 0
		for name, val in pairs(self._aipAddDefenses) do
			if val ~= nil then
                addSum = addSum + val
			end
		end

        -- 只有伤害大于 0 才会计算减伤
        if dmg > 0 then
		    dmg = dmg * (1 + multiPtgPositives) * multiPtgNegatives + addSum
            if dmg < 0 then
                dmg = 0
            end
        end

		return originGetAttacked(self, attacker, dmg, weapon, stimuli, spdamage, ...)
	end

	--[[ ===================================================================
         ==                           计算伤害                             ==
         ===================================================================]]
	local originCalcDamage = self.CalcDamage

	function self:CalcDamage(target, weapon, multiplier, ...)
		local oriDmg, oriSpDmg = originCalcDamage(self, target, weapon, multiplier, ...)
		local dmg = oriDmg
		local spDmg = oriSpDmg

		local petDmgMulti = 1	-- 伤害倍数
		local petDmgPlus = 0	-- 伤害加成
		local petDmgDiv = 1		-- 伤害除数（减免伤害都是乘法计算，防止变成负数）

		-- 古神 攻击 buff
		if
			_G.aipBufferExist(
				self.inst,
				"aip_oldone_smiling_attack"
			)
		then
			petDmgMulti = petDmgMulti + 1
		end

		-- 攻击者有 嬉闹 BUFF，将会减少伤害
		local playBuffInfo = _G.aipBufferInfo(
			self.inst,
			"aip_pet_play"
		)
		if playBuffInfo ~= nil and playBuffInfo.data ~= nil then
			local desc = playBuffInfo.data.desc or 0
			-- dmg = dmg * (1 - desc)
			petDmgDiv = petDmgDiv * (1 - desc)
		end

		-- 杀神 增加伤害
		local johnWickInfo = _G.aipBufferInfo(
			self.inst,
			"aip_pet_johnWick"
		)
		if dmg ~= 0 and johnWickInfo ~= nil and johnWickInfo.data ~= nil then
			local atk = johnWickInfo.data.dmg or 0
			-- dmg = dmg + atk
			petDmgPlus = petDmgPlus + atk
		end

		-- 怪物精华 buff
		if
			_G.aipBufferExist(
				self.inst,
				"monster_salad"
			)
		then
			dmg = dmg * (dev_mode and 999 or 1.05)
		end

		-- 宠物主人攻击 buff
		if self.inst.components.aipc_pet_owner ~= nil then
			-- 好斗
			local skillInfo, skillLv = self.inst.components.aipc_pet_owner:GetSkillInfo("aggressive")

			if skillInfo ~= nil then
				local multi = skillInfo.multi * skillLv
				petDmgMulti = petDmgMulti + multi
			end

			-- 逐月
			local lunaInfo, lunaLv = self.inst.components.aipc_pet_owner:GetSkillInfo("luna")
			if lunaInfo ~= nil then
				-- 月岛地皮
				local tile = _G.TheWorld.Map:GetTileAtPoint(
					self.inst.Transform:GetWorldPosition()
				)

				if tile == _G.GROUND.METEOR then
					petDmgMulti = petDmgMulti + lunaInfo.land * lunaLv
				end

				-- 满月
				if _G.TheWorld.state.isfullmoon then
					petDmgMulti = petDmgMulti + lunaInfo.full * lunaLv
				end
			end

			-- 米糕 闪避增加伤害
			local migaoInfo, migaoLv, migaoSkill = self.inst.components.aipc_pet_owner:GetSkillInfo("migao")

			if migaoInfo ~= nil then
				petDmgMulti = petDmgMulti + (migaoSkill._multi or 0) * migaoInfo.multi
			end

			-- 好斗
			local skillInfo, skillLv = self.inst.components.aipc_pet_owner:GetSkillInfo("aggressive")

			if skillInfo ~= nil then
				local multi = skillInfo.multi * skillLv
				petDmgMulti = petDmgMulti + multi
			end

			-- 青尘 增加伤害
			local balrogInfo, balrogLv = self.inst.components.aipc_pet_owner:GetSkillInfo("balrog")
			if
				balrogInfo ~= nil and (
					-- 如果是受到火焰伤害
					(
						self.inst.components.health ~= nil and
						self.inst.components.health.takingfiredamage == true
					) or
					-- 如果有 火莲 的 BUFF
					_G.aipBufferExist(self.inst, "aip_balrog")
				)
				
			then
				petDmgPlus = petDmgPlus + balrogInfo.atk * balrogLv
			end
		end

		-- 目标如果是宠物主人
		if target ~= nil and target.components.aipc_pet_owner ~= nil then
			-- 伤害减少
			local skillInfo, skillLv = target.components.aipc_pet_owner:GetSkillInfo("conservative")

			if skillInfo ~= nil then
				-- local multi = 1 - skillInfo.multi * skillLv
				-- dmg = dmg * multi
				petDmgDiv = petDmgDiv * (1 - skillInfo.multi * skillLv)
			end

			-- 蝶舞有概率免疫
			local dancerInfo, dancerLv = target.components.aipc_pet_owner:GetSkillInfo("dancer")

			if dancerInfo ~= nil then
				if _G.aipChance(dancerInfo.multi * dancerLv, target) then
					dmg = 0

					-- 播放音效
					if target.SoundEmitter ~= nil then
						target.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
					end

					-- 播放特效
					local fx = _G.SpawnPrefab("shadow_shield2")
					fx.entity:SetParent(target.entity)
				end
			end

			-- 米糕 会增加伤害
			local migaoInfo, migaoLv, migaoSkill = target.components.aipc_pet_owner:GetSkillInfo("migao")

			if migaoInfo ~= nil then
				-- local multi = 1 + migaoInfo.pain
				-- dmg = dmg * multi
				petDmgMulti = petDmgMulti + migaoInfo.pain

				-- 重置伤害倍数计数
				migaoSkill._multi = 0
			end

			-- 陵卫斗篷
			local graveInfo, graveLv = target.components.aipc_pet_owner:GetSkillInfo("graveCloak")
			if graveInfo ~= nil and target.components.aipc_grave_cloak ~= nil and dmg > 0 then
				local cnt = target.components.aipc_grave_cloak:GetCurrent()
				local diffPTG = cnt * (graveInfo.def + graveInfo.defMulti * graveLv)
				-- local multi = 1 - diffPTG
				-- dmg = dmg * math.max(0, multi)
				petDmgDiv = petDmgDiv * math.max(0, 1 - diffPTG)

				-- 破坏一层
				target.components.aipc_grave_cloak:Break()
			end
		end

		-- 如果有 火莲 buff 就加伤害
		if _G.aipBufferExist(self.inst, "aip_balrog") then
			petDmgPlus = petDmgPlus + 10
			_G.aipBufferRemove(self.inst, "aip_balrog")
		end

		-- 计算伤害
		dmg = (dmg * petDmgMulti + petDmgPlus) * petDmgDiv

		-- 如果 dmg 被变为 0，则也避免特殊伤害。如果没有变化则保留
		if dmg == 0 and dmg ~= oriDmg then
			spDmg = nil
		end

        ----------------------------------------------------------------
        --                          伤害累积                          --
        ----------------------------------------------------------------
		-- 遍历 aipMultiDamages 计算百分比减伤
        local multiPtgPositives = 0
		local multiPtgNegatives = 1
		for name, ptg in pairs(self._aipMultiDamages) do
			if ptg ~= nil then
                if ptg > 0 then
                    multiPtgPositives = multiPtgPositives + ptg
                else
				    multiPtgNegatives = multiPtgNegatives * (1 + ptg)
                end
			end
		end

		-- 遍历 aipAddDamages 计算叠加减伤
        local addSum = 0
		for name, val in pairs(self._aipAddDamages) do
			if val ~= nil then
                addSum = addSum + val
			end
		end

        -- 只有伤害大于 0 才会计算减伤
        if dmg > 0 then
		    dmg = dmg * (1 + multiPtgPositives) * multiPtgNegatives + addSum
            if dmg < 0 then
                dmg = 0
            end
        end

		return dmg, spDmg
	end

	-- 为攻击额外添加事件
	local originDoAttack = self.DoAttack

	function self:DoAttack(targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos, ...)
		-- 给 miss 的目标也添加一个事件
		if targ ~= nil and (not self:CanHitTarget(targ, weapon) or self.AOEarc) then
			targ:PushEvent("aipMissAttack", { source = self.inst, weapon = weapon })
		end

		return originDoAttack(self, targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos, ...)
	end
end)