DEG_TO_RAD = (math.acos(-1)/180.0)
RAD_TO_DEC = (180.0/math.acos(-1))

--[[
    static double getAngleFromPositions(const Position& fromPos, const Position& toPos) {
        // Returns angle in radians from 0 to 2Pi. -1 means positions are equal.
        int dx = toPos.x - fromPos.x;
        int dy = toPos.y - fromPos.y;
        if(dx == 0 && dy == 0)
            return -1;

        float angle = std::atan2(dy * -1, dx);
        if(angle < 0)
            angle += 2 * Fw::pi;

        return angle;
    }
}]]

function getAngleFromPositions(fromPos, toPos)
	-- Returns angle in radians from 0 to 2Pi. -1 means positions are equal.
	local dx = toPos.x - fromPos.x
	local dy = toPos.y - fromPos.y
	if dx == 0 and dy == 0 then
		return -1
	end
	local angle = math.atan2(dy * -1, dx)
	if angle < 0 then
		angle = angle + 2 * math.pi
	end
	
	return angle
end

--[[
    static Otc::Direction getDirectionFromPositions(const Position& fromPos,
                                                    const Position& toPos)
    {
        float angle = getAngleFromPositions(fromPos, toPos) * RAD_TO_DEC;

        if(angle >= 360 - 22.5 || angle < 0 + 22.5)
            return Otc::East;
        else if(angle >= 45 - 22.5 && angle < 45 + 22.5)
            return Otc::NorthEast;
        else if(angle >= 90 - 22.5 && angle < 90 + 22.5)
            return Otc::North;
        else if(angle >= 135 - 22.5 && angle < 135 + 22.5)
            return Otc::NorthWest;
        else if(angle >= 180 - 22.5 && angle < 180 + 22.5)
            return Otc::West;
        else if(angle >= 225 - 22.5 && angle < 225 + 22.5)
            return Otc::SouthWest;
        else if(angle >= 270 - 22.5 && angle < 270 + 22.5)
            return Otc::South;
        else if(angle >= 315 - 22.5 && angle < 315 + 22.5)
            return Otc::SouthEast;
        else
            return Otc::InvalidDirection;
    }
]]

function getDirectionFromPositions(fromPos, toPos)
	local angle = getAngleFromPositions(fromPos, toPos) * RAD_TO_DEC
	if angle >= 360 - 22.5 or angle < 0 + 22.5 then
		return East
	elseif angle >= 45 - 22.5 and angle < 45 + 22.5 then
		return NorthEast
	elseif angle >= 90 - 22.5 and angle < 90 + 22.5 then
		return North
	elseif angle >= 135 - 22.5 and angle < 135 + 22.5 then
		return NorthWest
	elseif angle >= 180 - 22.5 and angle < 180 + 22.5 then
		return West
	elseif angle >= 225 - 22.5 and angle < 225 + 22.5 then
		return SouthWest
	elseif angle >= 270 - 22.5 and angle < 270 + 22.5 then
		return South
	elseif angle >= 315 - 22.5 and angle < 315 + 22.5 then
		return SouthEast
	else
		return -1
	end
end
getDirectionFromPos = getDirectionFromPositions