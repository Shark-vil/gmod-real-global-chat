if file.Exists('autorun/outfitter.lua', 'LUA') and file.Exists('includes/modules/fileextras.lua', 'LUA') then
	return
end

local File = FindMetaTable('File')
local tmp = {}
local table_concat = table.concat

function File.ReadString(f, n, ch)
	n = n or 256
	ch = ch or '\0'
	local startpos = f:Tell()
	local offset = 0
	local tmpn = 0
	local sz = f:Size()

	for i = 1, 1048576 do
		if f:Tell() >= sz then return end
		local str = f:Read(n)
		local pos = str:find(ch, 1, true)

		if pos then
			f:Seek(startpos + offset + pos)
			tmp[tmpn + 1] = str:sub(1, pos - 1)

			return table_concat(tmp, '', 1, tmpn + 1)
		else
			tmpn = tmpn + 1
			tmp[tmpn] = str
			offset = offset + n
		end
	end
end