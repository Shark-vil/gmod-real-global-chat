local _string_Split = string.Split
local _Vector = Vector
local _math_sqrt = math.sqrt
local _Angle = Angle
local _Color = Color
local _tonumber = tonumber

function RealGloabalChat:ColorStringToColor(col_string)
	if not col_string then return _Color(255, 255, 255, 255) end
	local col_data = _string_Split(col_string, ',')
	if not col_data[1] or not col_data[2] or not col_data[3] or not col_data[4] then return _Color(255, 255, 255, 255) end

	return _Color(_tonumber(col_data[1]), _tonumber(col_data[2]), _tonumber(col_data[3]), _tonumber(col_data[4]))
end

function RealGloabalChat:PosStringToVector(pos_string)
	if not pos_string then return _Vector(0, 0, 0) end
	local vector_data = _string_Split(pos_string, ',')
	if not vector_data[1] or not vector_data[2] or not vector_data[3] then return _Vector(0, 0, 0) end

	return _Vector(_tonumber(vector_data[1]), _tonumber(vector_data[2]), _tonumber(vector_data[3]))
end

function RealGloabalChat:PosStringToAngle(ang_string)
	if not ang_string then return _Angle(0, 0, 0) end
	local angle_data = _string_Split(ang_string, ',')
	if not angle_data[1] or not angle_data[2] or not angle_data[3] then return _Angle(0, 0, 0) end

	return _Angle(_tonumber(angle_data[1]), _tonumber(angle_data[2]), _tonumber(angle_data[3]))
end

function RealGloabalChat:Magnitude(vec)
	local magnitude = vec
	magnitude = magnitude.x ^ 2 + magnitude.y ^ 2 + magnitude.z ^ 2
	magnitude = _math_sqrt(magnitude)

	return magnitude
end

function RealGloabalChat:MoveTowards(current_vector, target_vector, delta_time)
	local direction_vector = target_vector - current_vector
	local magnitude = self:Magnitude(direction_vector)
	if magnitude <= delta_time or magnitude == 0 then return target_vector end

	return current_vector + direction_vector / magnitude * delta_time
end