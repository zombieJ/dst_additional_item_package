function GLOBAL.aipCommonStr(showType, split, ...)
	local str = ""
	for i,v in ipairs(arg) do
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

			str = str .. "[" .. type(v) .. ": " .. tostring(parsed) .. "]" .. split
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