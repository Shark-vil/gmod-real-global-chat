local coroutine_resume = coroutine.resume
local coroutine_create = coroutine.create
local player_GetAll = player.GetAll
local IsValid = IsValid
local coroutine_wait = coroutine.wait
local coroutine_yield = coroutine.yield
local service_has_running = false

local function task()
	local players = player_GetAll()

	for i = #players, 1, -1 do
		local ply = players[i]
		if not IsValid(ply) then continue end
		RealGloabalChat:UpdateGameInfo(ply)
		coroutine_wait(1)
	end

	coroutine_yield()
end

local co

hook.Add('Think', 'RealGlobalChat.GameInfo.Check', function()
	if not service_has_running then return end

	if not co or not coroutine_resume(co) then
		co = coroutine_create(task)
		coroutine_resume(co)
	end
end)

hook.Add('RGchat.FirstStart', 'RGChat.StartGameInfoService', function()
	service_has_running = true
end)