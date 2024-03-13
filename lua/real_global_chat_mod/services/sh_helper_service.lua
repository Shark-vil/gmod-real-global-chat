local string_Split = string.Split
local Vector = Vector
local math_sqrt = math.sqrt
local Angle = Angle
local Color = Color
local tonumber = tonumber

function RealGloabalChat:ColorStringToColor(col_string)
	if not col_string then return Color(255, 255, 255, 255) end
	local col_data = string_Split(col_string, ',')
	if not col_data[1] or not col_data[2] or not col_data[3] or not col_data[4] then return Color(255, 255, 255, 255) end

	return Color(tonumber(col_data[1]), tonumber(col_data[2]), tonumber(col_data[3]), tonumber(col_data[4]))
end

function RealGloabalChat:PosStringToVector(pos_string)
	if not pos_string then return Vector(0, 0, 0) end
	local vector_data = string_Split(pos_string, ',')
	if not vector_data[1] or not vector_data[2] or not vector_data[3] then return Vector(0, 0, 0) end

	return Vector(tonumber(vector_data[1]), tonumber(vector_data[2]), tonumber(vector_data[3]))
end

function RealGloabalChat:PosStringToAngle(ang_string)
	if not ang_string then return Angle(0, 0, 0) end
	local angle_data = string_Split(ang_string, ',')
	if not angle_data[1] or not angle_data[2] or not angle_data[3] then return Angle(0, 0, 0) end

	return Angle(tonumber(angle_data[1]), tonumber(angle_data[2]), tonumber(angle_data[3]))
end

function RealGloabalChat:Magnitude(vec)
	local magnitude = vec
	magnitude = magnitude.x ^ 2 + magnitude.y ^ 2 + magnitude.z ^ 2
	magnitude = math_sqrt(magnitude)

	return magnitude
end

function RealGloabalChat:MoveTowards(current_vector, target_vector, delta_time)
	local direction_vector = target_vector - current_vector
	local magnitude = self:Magnitude(direction_vector)
	if magnitude <= delta_time or magnitude == 0 then return target_vector end

	return current_vector + direction_vector / magnitude * delta_time
end