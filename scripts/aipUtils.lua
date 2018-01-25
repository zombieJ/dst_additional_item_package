function GLOBAL.aipPrint(...)
	local str = ""
	for i,v in ipairs(arg) do
		str = str .. tostring(v) .. " "
	end
	print(str)
end