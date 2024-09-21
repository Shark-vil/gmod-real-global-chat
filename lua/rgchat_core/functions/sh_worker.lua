local _coroutine_resume = coroutine.resume
local _coroutine_create = coroutine.create
local _isstring = isstring
local _tostring = tostring
local _registred_workers = {}
local _workers = {}

function RealGloabalChat:RemoveBackgroundWorker(name)
	if not _workers[name] then return end
	hook.Remove('Think', _workers[name])
end

function RealGloabalChat:IsExistsBackgroundWorker(name)
	return _workers[name] ~= nil
end

function RealGloabalChat:AddBackgroundWorker(name, handler)
	local task

	_workers[name] = 'RGChatBackgroundWorker.' .. name

	hook.Add('Think', _workers[name], function()
		if not task then
			task = _coroutine_create(handler)
		end

		local ok, _ = _coroutine_resume(task)

		if not ok then
			-- if _isstring(err) then
			-- 	RealGloabalChat:LogError(name .. ' | ' .. _tostring(err))
			-- end

			task = _coroutine_create(handler)
			_coroutine_resume(task)
		end
	end)
end