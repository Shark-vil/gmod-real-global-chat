local _storage = {}

function RealGloabalChat:AddToStorage(name, key, value)
	_storage[name] = _storage[name] or {}
	_storage[name][key] = value
end

function RealGloabalChat:GetFromStorage(name, key)
	if not key or not name then return end
	if not _storage[name] or not _storage[name][key] then return end
	return _storage[name]
end