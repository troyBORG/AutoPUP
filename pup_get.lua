local get = {}

get.maneuvers = {
	fire = {'Fire Maneuver'},
	ice = {'Ice Maneuver'},
	wind = {'Wind Maneuver'},
	earth = {'Earth Maneuver'},
	thunder = {'Thunder Maneuver'},
	water = {'Water Maneuver'},
	light = {'Light Maneuver'},
	dark = {'Dark Maneuver'},
	}

get.ids  = L{
	[299] = 'Overload',
	[300] = 'Fire Maneuver',
	[301] = 'Ice Maneuver',
	[302] = 'Wind Maneuver',
	[303] = 'Earth Maneuver',
	[304] = 'Thunder Maneuver',
	[305] = 'Water Maneuver',
	[306] = 'Light Maneuver',
	[307] = 'Dark Maneuver',
	}

function get.maneuver_list(maneuvers)
	local list = {}
	for k,v in pairs(maneuvers) do
		list[k] = v
	end
	return list
end

-- Takes maneuver short name and returns the long name for the maneuver (in proper case) as .enl and JA id to .id
function get.maneuver(name)
	name = string.lower(name)
	-- ids from get.ids
	for k,v in pairs(get.ids) do
		-- why would k be equal to 'n'?
		if k ~= 'n' and string.lower(v) == name then
			return {id=k,enl=v}
		end
	end
	return nil
end

-- Index buffs by lowercase name and store a count as value
function get.buffs()
  local set_buff = {}
  for _, buff_id in ipairs(windower.ffxi.get_player().buffs) do
    local buff_en = res.buffs[buff_id].en:lower()
		-- sets the value for index buff_en to the value of buff_en if it already exists OR 0, then adds 1
		-- effectively increments existing indexes and sets new indexes to 1
    set_buff[buff_en] = (set_buff[buff_en] or 0) + 1
  end
  return set_buff
end

return get
