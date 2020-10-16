_addon.author = 'sruon'
_addon.commands = {'autopup','pup'}
_addon.name = 'AutoPUP'
_addon.version = '1.0.0.0'

require('luau')
require('pack')
require 'logger'
packets = require('packets')
texts = require('texts')
config = require('config')

ids = require('pup_ids')
get = require('pup_get')
cast = require('pup_cast')

default = {
	delay=1,
	active=true,
	autocooldown=false,
	maneuvers={wind=1,light=1,fire=1},
	box={text={size=10}}
	}

settings = config.load(default)

del = 0
counter = 0
interval = 0.2

local display_box = function()
	local str
	if settings.actions then
			str = 'AutoPUP: Actions [On]'
	else
			str = 'AutoPUP: Actions [Off]'
	end
	if resting then
			str = 'AutoPUP: Actions [Paused]'
	end
	if not settings.active then return str end
	for k,v in pairs(settings.maneuvers) do
			str = str..'\n %s:[x%d]':format(k:ucfirst(),v)
	end
	return str
end

pup_status = texts.new(display_box(),settings.box,settings)
pup_status:show()

function do_stuff()
	-- stop if actions not set
	if not settings.actions then return end
	-- increment counter
	counter = counter + interval
	-- wtf is del?
	if counter > del then
		counter = 0
		del = interval
		local player = windower.ffxi.get_player()
		-- if can't get player, we're not PUP or status is not equal to 1 or 0 then end
		if not player or player.main_job ~= 'PUP' or (player.status ~= 1 and player.status ~= 0) then return end
		-- check we have a pet?
		if player ~= nil then
			local player_mob = windower.ffxi.get_mob_by_id(player.id)
			if player_mob ~= nil then
				local pet_index = player_mob.pet_index
				if pet_index == nil then return end
			end
		end
		-- get buffs
		local buffs = get.buffs(player.buffs)
		-- get recasts
		local ability_recasts = windower.ffxi.get_ability_recasts()
		if autocooldown and buffs.overload and ability_recasts[114] <= 0 then -- Cooldown
				cast.JA('input /ja "Cooldown" <me>')
		end
		if casting or resting or buffs.amnesia or buffs.stun or buffs.sleep or buffs.charm or buffs.terror or buffs.petrification or buffs.overload then return end
		local maneuver = cast.check_maneuver(settings.maneuvers,'AoE',buffs,ability_recasts)
		if maneuver then cast.maneuver(maneuver,'<me>',buffs,ability_recasts) return end
	end
end

do_stuff:loop(interval)

windower.register_event('incoming chunk', function(id,original,modified,injected,blocked)
		-- this checks if we're casting
	if id == 0x028 then
		local packet = packets.parse('incoming', original)
		if packet['Actor'] ~= windower.ffxi.get_mob_by_target('me').id then return false end
		if packet['Category'] == 8 then
			if (packet['Param'] == 24931) then
			-- Begin Casting
				casting = true
			elseif (packet['Param'] == 28787) then
			-- Failed Casting
				casting = false
				del = 2.5
			end
		elseif packet['Category'] == 4 then
			-- Finish Casting
			casting = false
			del = settings.delay
		elseif L{3,5}:contains(packet['Category']) then
			casting = false
		elseif L{7,9}:contains(packet['Category']) then
			casting = true
		end
	elseif id == 0x029 then
		local packet = packets.parse('incoming', original)
		--table.vprint(packet)
	end
end)

function addon_message(str)
	windower.add_to_chat(207, _addon.name..': '..str)
end

windower.register_event('addon command', function(...)
	local commandArgs = {...}
	for x=1,#commandArgs do commandArgs[x] = windower.convert_auto_trans(commandArgs[x]):lower() end
	-- handle toggle with addon name and on/off
	if not commandArgs[1] or S{'on','off'}:contains(commandArgs[1]) then
		if not commandArgs[1] then
			settings.actions = not settings.actions
		elseif commandArgs[1] == 'on' then
			settings.actions = true
		elseif commandArgs[1] == 'off' then
			settings.actions = false
		end
		addon_message('Actions %s':format(settings.actions and 'On' or 'Off'))
	else
		-- dunno how this works
		if commandArgs[1] == 'save' then
			settings:save()
			addon_message('settings Saved.')
		elseif get.maneuvers[commandArgs[1]] and commandArgs[2] then
			local n = tonumber(commandArgs[2])
			if n and n ~= 0 and n <= 3 then
				local total_man = 0
				for k,v in pairs(settings.maneuvers) do
					total_man = total_man + v
				end
				if total_man + n > 3 then
					addon_message('Total maneuvers count (%d) exceeds 3':format(total_man + n))
				else
					settings.maneuvers[commandArgs[1]] = n
					addon_message('%s x%d':format(commandArgs[1],n))
				end
			elseif commandArgs[2] == '0' or commandArgs[2] == 'off' then
				settings.maneuvers[commandArgs[1]] = nil
				addon_message('%s Off':format(commandArgs[1]))
			elseif n then
				addon_message('Error: %d exceeds the maximum value for %s.':format(n,commandArgs[1]))
			end
		elseif type(settings[commandArgs[1]]) == 'string' and commandArgs[2] then
			local maneuver = get.maneuver(table.concat(commandArgs, ' ',2))
			if maneuver then
				settings[commandArgs[1]] = maneuver.enl
				addon_message('%s is now set to %s':format(commandArgs[1],maneuver.enl))
			else
				addon_message('Invalid maneuver name.')
			end
		 elseif type(settings[commandArgs[1]]) == 'number' and commandArgs[2] and tonumber(commandArgs[2]) then
				settings[commandArgs[1]] = tonumber(commandArgs[2])
				addon_message('%s is now set to %d':format(commandArgs[1],settings[commandArgs[1]]))
		elseif type(settings[commandArgs[1]]) == 'boolean' then
			if (not commandArgs[2] and settings[commandArgs[1]] == true) or (commandArgs[2] and commandArgs[2] == 'off') then
				settings[commandArgs[1]] = false
			elseif (not commandArgs[2]) or (commandArgs[2] and commandArgs[2] == 'on') then
				settings[commandArgs[1]] = true
			end
			addon_message('%s %s':format(commandArgs[1],settings[commandArgs[1]] and 'On' or 'Off'))
		elseif commandArgs[1] == 'eval' then
			assert(loadstring(table.concat(commandArgs, ' ',2)))()
		end
	end
	pup_status:text(display_box())
end)

function event_change()
	settings.actions = false
	casting = false
	resting = false
	pup_status:text(display_box())
end

function status_change(new,old)
	casting = false
	if new == 2 or new == 3 then
		event_change()
	end
	if new == 'Resting' then
		resting = true
		addon_message('Paused.')
	end
end

windower.register_event('status change', status_change)
windower.register_event('zone change','job change','logout', event_change)
