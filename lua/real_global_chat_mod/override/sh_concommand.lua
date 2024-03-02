local cmd_list, _ = concommand.GetTable()
print('CMD', cmd_list['act'])

-- local concommand_Add = concommand.Add

-- function concommand.Add(name, callback, autoComplete, helpText, flags)
-- 	print('cmd', name)
-- 	return concommand_Add(name, callback, autoComplete, helpText, flags)
-- end