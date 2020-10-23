local cast = {}

function cast.JA(str)
	windower.send_command(str)
	del = 1.2
end

function cast.MA(str,ta)
	windower.send_command('input /ja "%s" <me>':format(str))
	del = settings.delay
end

function cast.maneuver(str,target)
	cast.MA(str,target)
end

function cast.check_maneuver_count(man, buffs)
	-- cycle through all current buffs
	for k,v in pairs(buffs) do
		-- match maneuver short name e.g. thunder
		if (k == "%s maneuver":format(man)) then
			-- return number of active maneuver buffs
			return v
		end
	end
	-- return 0 if no maneuver buffs
	return 0
end

function cast.check_maneuver(maneuvers,buffs,ability_recasts)
	local maneuver_list = get.maneuver_list(maneuvers)
	for buff,num in pairs(maneuver_list) do
		local count = cast.check_maneuver_count(buff, buffs)
		if count < num then
			local maneuver = get.maneuver(get.maneuvers[buff][1])
			if maneuver and ability_recasts[210] <= 0 then -- 210 is Maneuvers JA
				return maneuver.enl
			end
		end
	end
	return false
end

return cast
