function GLOBAL.aipCommonPrint(showType, ...)
	local str = "[AIP] "
	for i,v in ipairs(arg) do
		local parsed = v
		local vType = type(v)

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

		if showType then
			str = str .. "[" .. type(v) .. ": " .. tostring(parsed) .. "] "
		else
			str = str .. tostring(parsed) .. " "
		end
	end
	print(str)
end

function GLOBAL.aipPrint(...)
	return GLOBAL.aipCommonPrint(false, ...)
end

function GLOBAL.aipTypePrint(...)
	return GLOBAL.aipCommonPrint(true, ...)
end