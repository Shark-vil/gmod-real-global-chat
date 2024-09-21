list.Set(
	'DesktopWindows',
	'RealGlobalChat',
	{
		title = 'Real Global Chat',
		icon = 'icon64/rgchat.png',
		width = 1,
		height = 1,
		onewindow = false,
		init = function(icn, pnl)
			RunConsoleCommand('rgchat_menu')
			if IsValid(pnl) then pnl:Remove() end
		end
	}
)