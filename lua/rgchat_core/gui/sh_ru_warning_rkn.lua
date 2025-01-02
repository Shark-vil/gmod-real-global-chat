if SERVER then
    util.AddNetworkString('RGChat_DisableECH')

    -- -- https://wiki.facepunch.com/gmod/GM:PlayerInitialSpawn
    -- local load_queue = {}
    -- hook.Add('PlayerInitialSpawn', 'RGChatLoaderRuRKNWarning', function(ply) load_queue[ply] = true end)
    -- hook.Add('StartCommand', 'RGChatLoaderRuRKNWarning', function(ply, cmd)
    --     if load_queue[ply] and not cmd:IsForced() then
    --         load_queue[ply] = nil
    --         timer.Simple(1, function()
    --             if not IsValid(ply) then return end
    --             ply:ConCommand('rgchat_russian_warning_rkn')
    --         end)
    --     end
    -- end)

    net.Receive('RGChat_DisableECH', function(_, ply)
        if not ply:IsAdmin() then return end
        RunConsoleCommand('sv_disable_ech', 1)
    end)
else
    surface.CreateFont('RgChatRKN_CustomHeader', {
        font = 'Roboto',
        size = 24,
        weight = 700
    })

    surface.CreateFont('RgChatRKN_CustomText', {
        font = 'Roboto',
        size = 20,
        weight = 500
    })

    -- local function open_menu()
    --     local frame = vgui.Create('DFrame')
    --     frame:SetSize(500, 300)
    --     frame:Center()
    --     frame:SetTitle('RGChat - Проблемы в работе')
    --     frame:MakePopup()
    --     frame:SetDraggable(false)
    --     frame:ShowCloseButton(true)
    --     frame.Paint = function(self, w, h)
    --         draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 40, 255)) -- Тёмный цвет
    --     end

    --     local header = vgui.Create('DLabel', frame)
    --     header:SetText('Сайт может не работать для пользователей из РФ')
    --     header:SetFont('RgChatRKN_CustomHeader')
    --     header:SetTextColor(Color(220, 220, 220))
    --     header:SetWrap(true)
    --     header:SetContentAlignment(5)
    --     header:SetPos(10, 35)
    --     header:SetSize(frame:GetWide() - 20, 50)
    --     local label = vgui.Create('DLabel', frame)
    --     label:SetText('Роскомнадзор заблокировал протокол ECH от Cloudflare, который использует чат для работы сайта. К сожалению, сделать с этим ничего нельзя.')
    --     label:SetFont('RgChatRKN_CustomText')
    --     label:SetTextColor(Color(220, 220, 220))
    --     label:SetWrap(true)
    --     label:SetContentAlignment(5)
    --     label:SetPos(10, 70)
    --     label:SetSize(frame:GetWide() - 20, frame:GetTall() - 120)
    --     local closeButton = vgui.Create('DButton', frame)
    --     closeButton:SetText('Закрыть')
    --     closeButton:SetSize(100, 30)
    --     closeButton:SetPos(frame:GetWide() / 2 - 50, frame:GetTall() - 40)
    --     closeButton.DoClick = function() frame:Close() end
    -- end

    local function open_question()
        local questionFrame = vgui.Create('DFrame')
        questionFrame:SetSize(300, 150)
        questionFrame:Center()
        questionFrame:SetTitle('RGChat - Настройка параметров региона')
        questionFrame:MakePopup()
        questionFrame:SetDraggable(false)
        questionFrame:ShowCloseButton(true)
        questionFrame.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 40, 255)) -- Тёмный цвет
        end

        local questionLabel = vgui.Create('DLabel', questionFrame)
        questionLabel:SetText('Вы проживаете на территории РФ?')
        questionLabel:SetFont('DermaDefaultBold')
        questionLabel:SetTextColor(Color(220, 220, 220))
        questionLabel:SetContentAlignment(5)
        questionLabel:SetPos(10, 30)
        questionLabel:SetSize(questionFrame:GetWide() - 20, 30)

        local yesButton = vgui.Create('DButton', questionFrame)
        yesButton:SetText('Да')
        yesButton:SetSize(100, 30)
        yesButton:SetPos(40, 90)
        yesButton.DoClick = function()
            questionFrame:Close()
            chat.AddText(Color(255, 100, 100), 'ECH от Cloudflare будет отключён для стабильной работы API.')
            RunConsoleCommand('cl_disable_ech', 1)
            if LocalPlayer():IsAdmin() then
                net.Start('RGChat_DisableECH')
                net.SendToServer()
            end
            -- open_menu()
        end

        local noButton = vgui.Create('DButton', questionFrame)
        noButton:SetText('Нет')
        noButton:SetSize(100, 30)
        noButton:SetPos(160, 90)
        noButton.DoClick = function()
            questionFrame:Close()
            chat.AddText(Color(255, 100, 100), 'Для вашей игры не требуется отключать ECH от Cloudflare.')
            -- chat.AddText(Color(255, 100, 100), 'Информационный блок скрыт, так как он вас не затрагивает.')
        end
    end
    concommand.Add('rgchat_russian_warning_rkn', open_question)

    hook.Add('RGchat.FirstStart', 'RussianWarningRKN', function()
        if GetConVar('cl_language'):GetString() ~= 'russian' then return end
        local data_path = 'rgchat_data/ru_ech_check.txt'
        if file.Exists(data_path, 'DATA') and file.Read(data_path, 'DATA') == '1' then
            return
        end
        RunConsoleCommand('rgchat_russian_warning_rkn')
        file.Write(data_path, '1')
    end)
end