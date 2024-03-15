local meta = FindMetaTable('Entity')

function meta:RgChatSetValue(name, value)
	self['_RGCHATVALUE_' .. name] = value
end

function meta:RgChatGetValue(name)
	return self['_RGCHATVALUE_' .. name]
end