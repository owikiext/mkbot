local autoloot_tokens = { 'gold coin', 'platinum coin', 'crystal coin', 'token', 'gold token' }
local autoloot_best = { 'boots of haste', 'steel boots', 'guardian boots', 'magic plate armor', 'golden legs' }
local autoloot_say = function(autoloot_area)
	local delay = 0
	say('!autoloot clear')
	for _, item in ipairs(autoloot_tokens) do
		delay = delay + 2000
		schedule(delay, function() say('!autoloot add, ' .. item) end)
	end
	for _, item in ipairs(autoloot_area) do
		delay = delay + 2000
		schedule(delay, function() say('!autoloot add, ' .. item) end)
	end
end
local autoloot_normal = addButton('autoloot_normal', 'AutoLoot Normal', function() autoloot_say({}) end)
local autoloot_grass = addButton('autoloot_grass', 'AutoLoot Grass', function() autoloot_say({}) end)
local autoloot_shadow = addButton('autoloot_shadow', 'AutoLoot Shadow', function() autoloot_say({}) end)