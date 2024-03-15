local _registred_workers, _coroutine_resume, _coroutine_create, _isstring, _tostring

_registred_workers = {}
_coroutine_resume = coroutine.resume
_coroutine_create = coroutine.create
_isstring = isstring
_tostring = tostring

function RealGloabalChat:AddBackgroundWorker(name, handler)
	local task
	hook.Add('Think', 'RGChatBackgroundWorker.' .. name, function()
		if not task then task = _coroutine_create(handler) end
		local ok, err = _coroutine_resume(task)
		if not ok then
			task = _coroutine_create(handler)
			_coroutine_resume(task)
			if _isstring(err) then
				RealGloabalChat:LogError(name .. ' | ' .. _tostring(err))
			end
		end
	end)
end