local Player = FindMetaTable('Player')

function Player:RgcPrint(...)
	RealGloabalChat:PrintForPlayer(self, ...)
end

function Player:RgcPrintWarning(...)
	RealGloabalChat:PrintForPlayerWarning(self, ...)
end

function Player:RgcPrintError(...)
	RealGloabalChat:PrintForPlayerError(self, ...)
end