local pcall = pcall
local clock = os.clock

function SafeCall(func, name)
	local timer = clock()
	local status, result = pcall(func)
	if not status then
		print("[ERROR]", name, ":\n", result .. "\n")
	end
	timer = math.floor((clock() - timer) * 1000)
	if timer > 10 then
		print("[SLOW]", name, timer, 'ms')
	end
end