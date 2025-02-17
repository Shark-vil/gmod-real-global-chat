local _hook_name = 'user_data_init'
local _coroutine_wait = coroutine.wait
local _IsValid = IsValid

function _Handler()
    local code, res
    local ply = LocalPlayer()

    while true do
        if not _IsValid(ply) or not ply.RGChatReady then
            _coroutine_wait(1)
            continue
        end

        code, response = RealGloabalChat.WebApi.User:MakeOrUpdateWait()
        if code == 200 and response.user then
            RealGloabalChat.USER = response.user
            RealGloabalChat:RemoveBackgroundWorker(_hook_name)
            break
        end

        _coroutine_wait(1)
    end
end

RealGloabalChat:AddBackgroundWorker(_hook_name, _Handler)