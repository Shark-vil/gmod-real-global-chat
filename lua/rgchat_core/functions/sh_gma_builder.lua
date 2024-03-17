local _table_remove = table.remove
local _string_char = string.char
local _util_TableToJSON = util.TableToJSON
local _util_JSONToTable = util.JSONToTable
local _pairs = pairs
local _tostring = tostring
local _table_insert = table.insert
local _string_GetExtensionFromFilename = string.GetExtensionFromFilename

local _skip_ext = {
	['lua'] = true,
	['wav'] = true,
	['mp3'] = true,
	['bsp'] = true,
	['png'] = true,
	['jpg'] = true,
	['jpeg'] = true,
	['bmp'] = true,
	['txt'] = true,
	['ttf'] = true,
	['html'] = true,
	['js'] = true,
	['css'] = true,
	['nav'] = true,
	['ain'] = true,
}

function RealGloabalChat:BuildGma(wsid, gma_file, gma_data)
	for i = #gma_data.files, 1, -1 do
		local file_meta = gma_data.files[i]

		if _skip_ext[file_meta.ext:lower()] then
			_table_remove(gma_data.files, i)
		end
	end

	local pos = 0

	local function add(n)
		pos = pos + n

		return pos
	end

	gma_file:Write('GMAD')
	add(4)
	gma_file:Write(_string_char(gma_data.gma_version))
	add(1)
	gma_file:WriteULong(gma_data.steamid[1])
	gma_file:WriteULong(gma_data.steamid[2])
	add(8)
	gma_file:WriteULong(gma_data.timestamp[1])
	gma_file:WriteULong(gma_data.timestamp[2])
	add(8)

	if gma_data.gma_version > 1 then
		gma_file:Write('\0')
		add(1)
	end

	local name = (gma_data.name or '') .. '\0'
	gma_file:Write(name)
	add(#name)
	local desc = (gma_data.description and _util_TableToJSON(gma_data.description) or '{"type":"model","tags":["fun"],"description":"description"}') .. '\0'
	gma_file:Write(desc)
	add(#desc)
	local author = (gma_data.author or '') .. '\0'
	gma_file:Write(author)
	add(#author)
	gma_file:WriteULong(gma_data.addon_version)
	add(4)
	local idx = 0

	for i, file_meta in _pairs(gma_data.files) do
		idx = idx + 1
		gma_file:WriteLong(idx)
		add(4)
		assert(idx == i)
		gma_file:Write(file_meta.filename .. '\0')
		add(#file_meta.filename + 1)
		assert(file_meta.size < 2 ^ 30)
		gma_file:WriteULong(file_meta.size)
		gma_file:WriteULong(0)
		add(8)
		gma_file:WriteULong(file_meta.crc or 0)
		add(4)
	end

	gma_file:WriteLong(0)
	add(4)

	for _, file_meta in _pairs(gma_data.files) do
		local fd = file_meta.fd or gma_data.fd
		fd:Seek(file_meta.offset)
		local data = fd:Read(file_meta.size)
		if not data or #data ~= file_meta.size then return end
		if no_crc ~= true and file_meta.crc and file_meta.crc ~= 0 and _tostring(util.CRC(data)) ~= _tostring(file_meta.crc) then return end
		file_meta.offset = gma_file:Tell()
		gma_file:Write(data)
		add(#data)
	end

	gma_file:Tell()
end

function RealGloabalChat:ReadGma(gma_file)
	if gma_file:Read(4) ~= 'GMAD' then return end

	local meta = {
		files = {},
		fd = gma_file
	}

	meta.gma_version = gma_file:ReadByte()
	if (meta.gma_version or math.huge) > 3 then return end

	meta.steamid = {gma_file:ReadULong(), gma_file:ReadULong()}

	meta.timestamp = {gma_file:ReadULong(), gma_file:ReadULong()}

	if meta.gma_version > 1 then
		meta.required_content = {}

		for i = 1, 2 ^ 14 do
			if i == 2 ^ 14 - 1 then return end
			str = gma_file:ReadString()
			if str and #str == 0 then break end
			if not str then return end
			_table_insert(meta.required_content, str)
		end
	end

	meta.name = gma_file:ReadString()
	meta.description = _util_JSONToTable(gma_file:ReadString())
	meta.author = gma_file:ReadString()
	meta.addon_version = gma_file:ReadULong()
	if not meta.addon_version then return end

	for n = 1, 2 ^ 14 do
		if n == 2 ^ 14 - 1 then return end
		local filenum = gma_file:ReadULong()
		if filenum == 0 then break end
		if filenum ~= n then return end
		local filename = gma_file:ReadString()
		local file_meta = {}
		file_meta.filename = filename
		file_meta.size = gma_file:ReadULong()
		if gma_file:ReadULong() ~= 0 then return end
		file_meta.crc = gma_file:ReadULong()
		file_meta.ext = _string_GetExtensionFromFilename(filename)
		if file_meta.size <= 0 then return end
		if file_meta.size >= (2 ^ 30) - 1 then return end
		_table_insert(meta.files, file_meta)
	end

	for _, file_meta in _pairs(meta.files) do
		file_meta.offset = gma_file:Tell()
		gma_file:Skip(file_meta.size)
	end

	return meta
end