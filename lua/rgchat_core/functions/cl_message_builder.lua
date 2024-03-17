local _assert = assert
local _isstring = isstring
local _table_insert = table.insert
local _table_remove = table.remove
local _unpack = unpack

function RealGloabalChat:GetChatMessageBuilder()
	local builder = {}
	local text_sequence = {}

	function builder:Add(value, unique_id)
		if _isstring(unique_id) then
			for index = #text_sequence, 1, -1 do
				local data = text_sequence[index]
				if _isstring(data.unique_id) and data.unique_id == unique_id then
					data.value = value
					return
				end
			end
		end
		_table_insert(text_sequence, { unique_id = unique_id, value = value })
	end

	function builder:Delete(unique_id)
		_assert(_isstring(unique_id), 'The value of "unique_id" must be a string')

		for index = #text_sequence, 1, -1 do
			local data = text_sequence[index]
			if _isstring(data.unique_id) and data.unique_id == unique_id then
				_table_remove(text_sequence, index)
				break
			end
		end
	end

	function builder:GetResult()
		local result_sequence = {}
		for i = 1, #text_sequence do
			_table_insert(result_sequence, text_sequence[i].value)
		end
		return _unpack(result_sequence)
	end

	return builder
end