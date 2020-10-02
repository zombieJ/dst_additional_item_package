local function countTable(tbl)
	local count = 0
	for k, v in pairs(tbl) do
		count = count + 1
	end
	return count
end

-- 打平表格，去除中间的空格并且保持顺序
function GLOBAL.aipFlattenTable(originTbl)
	local targetTbl = {}
	local tbl = originTbl or {}
	local count = countTable(tbl)

	local i = 1
	for i = 1, 10000 do
		local current = tbl[i]
		if current ~= nil then
			table.insert(targetTbl, current)
		end

		if #targetTbl >= count then
			break
		end
	end

	return targetTbl
end

function GLOBAL.aipCommonStr(showType, split, ...)
	local str = ""
	local count = countTable(arg)
	for i = 1, count do
		local v = arg[i]
		local parsed = v
		local vType = type(v)

		if showType then
			-- 显示类别
			if parsed == nil then
				parsed = "(nil)"
			elseif parsed == true then
				parsed = "(true)"
			elseif parsed == false then
				parsed = "(false)"
			elseif parsed == "" then
				parsed = "(empty)"
			elseif vType == "table" then
				local isFirst = true
				parsed = "{"
				for v_k, v_v in pairs(v) do
					if not isFirst then
						parsed = parsed .. ", "
					end
					isFirst = false

					parsed = parsed .. tostring(v_k) .. ":" ..tostring(v_v)
				end
				parsed = parsed .. "}"
			end

			str = str .. "[" .. vType .. ": " .. tostring(parsed) .. "]" .. split
		else
			-- 显示文字
			str = str .. tostring(parsed) .. split
		end

	end

	return str
end

function GLOBAL.aipCommonPrint(showType, split, ...)
	local str = "[AIP] "..GLOBAL.aipCommonStr(showType, split, ...)

	print(str)

	return str
end

function GLOBAL.aipStr(...)
	return GLOBAL.aipCommonStr(false, "", ...)
end

function GLOBAL.aipPrint(...)
	return GLOBAL.aipCommonPrint(false, " ", ...)
end

function GLOBAL.aipTypePrint(...)
	return GLOBAL.aipCommonPrint(true, " ", ...)
end

GLOBAL.aipGetModConfig = GetModConfigData

function GLOBAL.aipGetAnimState(inst)
	local match = false
	local data = {}

	if inst then
		local str = inst.GetDebugString and inst:GetDebugString()
		if str then
			local bank, build, anim

			bank, build, anim = string.match(str, "AnimState: bank: (.*) build: (.*) anim: (.*) anim")
			if not anim then
				bank, build, anim = string.match(str, "AnimState: bank: (.*) build: (.*) anim: (.*) ..")
			end

			data.bank = string.split(bank or "", " ")[1]
			data.build = string.split(build or "", " ")[1]
			data.anim = string.split(anim or "", " ")[1]

			if data.bank and data.build and data.anim then
				match = true
			end
		end
	end

	return match and data or nil
end