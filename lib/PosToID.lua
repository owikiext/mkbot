function PosToID(pos)
	return pos.x .. "," .. pos.y .. "," .. pos.z
end

function IDToPos(id)
	local t = id:split(',')
	return { x = t[1], y = t[2], z = t[3] }
end