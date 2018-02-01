function GLOBAL.aipPrint(...)
	local str = "[AIP] "
	for i,v in ipairs(arg) do
		str = str .. tostring(v) .. " "
	end
	print(str)
end
