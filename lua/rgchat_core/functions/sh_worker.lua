local _registred_workers = {}

function RealGloabalChat:AddBackgroundWorker(name, handler)
	local workerFunction = function()
		while true do
			handler()
			coroutine.yield()
		end
	end

	local task = coroutine.create(workerFunction)
	hook.Add('Think', 'RGChatBackgroundWorker.' .. name, function()
		local ok, err = coroutine.resume(task)
		if not ok then
			task = coroutine.create(workerFunction)
			ErrorNoHalt(name, err)
		end
	end)
end