local _coroutine_resume = coroutine.resume
local _coroutine_create = coroutine.create
local _isstring = isstring
local _tostring = tostring
local _registred_workers = {}

function RealGloabalChat:AddBackgroundWorker(name, handler)
	local task

	hook.Add('Think', 'RGChatBackgroundWorker.' .. name, function()
		if not task then
			task = _coroutine_create(handler)
		end

		local ok, err = _coroutine_resume(task)

		if not ok then
			if _isstring(err) then
				RealGloabalChat:LogError(name .. ' | ' .. _tostring(err))
			end

			task = _coroutine_create(handler)
			_coroutine_resume(task)
		end
	end)
end