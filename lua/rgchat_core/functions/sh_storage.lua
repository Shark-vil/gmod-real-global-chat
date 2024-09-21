local _storage = {}

function RealGloabalChat:AddToStorage(name, key, value)
	_storage[name] = _storage[name] or {}
	_storage[name][key] = value
end

function RealGloabalChat:GetFromStorage(name, key)
	if not key or not name then return end
	if _storage[name] and _storage[name][key] then return _storage[name][key] end
end

function RealGloabalChat:GetStorage(name)
	if name and _storage[name] then return _storage[name] end
end