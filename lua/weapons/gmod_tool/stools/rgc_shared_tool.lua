if CLIENT then
	language.Add('tool.rgc_shared_tool.name', 'Shared tool')
	language.Add('tool.rgc_shared_tool.desc', 'Allows you to show entities to other players. (THIS TOOL DOESN\'T WORK YET.)')
	language.Add('tool.rgc_shared_tool.0', 'LMB - Marks the object as shared. RMB - Deletes the marking of a publicly accessible object')
end

TOOL.Category = 'RGChat'
TOOL.Name = '#tool.rgc_shared_tool.name'

function TOOL:LeftClick(tr)
	local ent = tr.Entity
	if IsValid(ent) then
		local is_shared = ent:GetNWBool('RgChatShared', false)
		if not is_shared then
			if SERVER then
				ent:SetNWBool('RgChatShared', true)
				ent:SetNW2Int('RgChatId', os.time())
			end

			return true
		end
	end

	return false
end

function TOOL:RightClick(tr)
	local ent = tr.Entity
	if IsValid(ent) then
		local is_shared = ent:GetNWBool('RgChatShared', false)
		if is_shared then
			if SERVER then
				ent:SetNWBool('RgChatShared', false)
				ent:SetNW2Int('RgChatId', nil)
			end

			return true
		end
	end

	return false
end