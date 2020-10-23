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

-- This function loops through the current buffs looking for "short_name maneuver"
-- if found, it returns the count of how many are active
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

-- this function finds the first maneuver in settings.maneuvers that is not active
-- and returns the long_name.
function cast.check_maneuver(maneuvers,buffs)
	-- convert current settings.maneuvers to a list
	local maneuver_list = get.maneuver_list(maneuvers)
	-- for each maneuver
	for maneuver_short_name,num in pairs(maneuver_list) do
		-- check how many of maneuver are active
		local count = cast.check_maneuver_count(maneuver_short_name, buffs)
		-- check how mant there are against how many are required
		if count < num then
			-- get the long name for the maneuver in proper case
			local maneuver_long_name = get.maneuver(get.maneuvers[maneuver_short_name][1])
			-- why do we check this is set if we just set it?
			if maneuver_long_name and windower.ffxi.get_ability_recasts()[210] <= 0 then -- 210 is Maneuvers JA
				-- why do we append .enl
				return maneuver_long_name.enl
			end
		end
	end
	return false
end

return cast
