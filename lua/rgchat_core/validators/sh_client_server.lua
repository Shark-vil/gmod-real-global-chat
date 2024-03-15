function RealGloabalChat.Validator:CheckClientside()
	assert(CLIENT, 'This client function')
end

function RealGloabalChat.Validator:CheckServerside()
	assert(SERVER, 'This server function')
end