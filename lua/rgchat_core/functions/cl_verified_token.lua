local _verified_token
local _verified_file = 'rgchat_data/verified.txt'
local _verified_token_last_file_update
local _file_Size = file.Size
local _file_Exists = file.Exists
local _file_Read = file.Read
local _file_Time = file.Time 
local _string_Trim = string.Trim

function RealGloabalChat:ReadLocalVerifiedToken()
    if (not _verified_token
        and _file_Exists(_verified_file, 'DATA')
        and _file_Size(_verified_file, 'DATA') > 0
    ) or (_verified_token_last_file_update
        and _file_Time(_verified_file, 'DATA') > _verified_token_last_file_update
    ) then
        local verified_token = _file_Read(_verified_file, 'DATA')
        if _string_Trim(verified_token) ~= '' then
            _verified_token = verified_token
            _verified_token_last_file_update = _file_Time(_verified_file, 'DATA')
        end
    end
    return _verified_token
end

function RealGloabalChat:IsExistsLocalVerifiedToken()
    local verified_token = RealGloabalChat:ReadLocalVerifiedToken()
    return verified_token ~= nil
end