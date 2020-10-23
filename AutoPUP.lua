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

get = require('pup_get')
cast = require('pup_cast')

default = {
	-- set the delay
	delay=1,
	-- show active manuevers in display_box
	active=true,
	-- toggle automatic cooldown on overload
	autocooldown=false,
	-- toggle actions off on overload
	autooff=true,
	-- default maneuvers
	maneuvers={wind=1,light=1,fire=1},
	-- text size
	box={text={size=10}}
	}

settings = config.load(default)

-- no idea
del = 0
-- a counter?
counter = 0
-- how often to run do_stuff()
interval = 0.2

local display_box = function()
	local str
	-- set the status string
	if settings.actions then
			str = _addon.name..': Actions [On]'
	else
			str = _addon.name..': Actions [Off]'
	end
	if paused then
			str = _addon.name..': Actions [Paused]'
	end
	-- return the string now if show active maneuvers is Off
	if not settings.active then return str end
	-- show active maneuvers
	for k,v in pairs(settings.maneuvers) do
			str = str..'\n %s:[x%d]':format(k:ucfirst(),v)
	end
	-- return the string
	return str
end

pup_status = texts.new(display_box(),settings.box,settings)
pup_status:show()

function do_stuff()
	-- stop if actions not set
	if not settings.actions then return end
	-- update the interval since do_stuff last run
	counter = counter + interval
	-- if the interval since last do_stuff is more than some delay (del - 0 by default) then try and run again
	if counter > del then
		-- enough time has elapsed so reset the counter
		counter = 0
		-- del is now interval so need at least two loops to trigger do_stuff
		del = interval
		-- get player
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
		local buffs = get.buffs()
		-- are we overloaded?
		if buffs.overload then
			-- if autocooldown is true and cooldown is off recast then use it
			if autocooldown and windower.ffxi.get_ability_recasts()[114] <= 0 then -- Cooldown
				cast.JA("Cooldown")
				-- set a longer delay than usual? Give time for JA to fire?
				del = 1.2
			-- if autooff is true then switch off actions
			elseif autooff then
				settings.actions = false
			end
		end
		-- do nothing if we can't do anything
		if casting or paused or buffs.amnesia or buffs.stun or buffs.sleep or buffs.charm or buffs.terror or buffs.petrification or buffs.overload then return end
		-- cast from pup_cast.lua
		local maneuver = cast.check_maneuver(settings.maneuvers,buffs)
		-- there could be no inactive maneuvers so check not false
		if maneuver then
			cast.JA(maneuver)
			-- set standard delay
			del = settings.delay
			return
		end
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
	-- convert any autotrans in Args and overwrite Arg
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
		-- get.maneuvers from pup_get.lua - check commandArgs[1] is a valid short maneuver name
		elseif get.maneuvers[commandArgs[1]] and commandArgs[2] then
			-- store this int to n so we can validate
			local n = tonumber(commandArgs[2])
			-- check n is between 1 and 3
			if n > 0 and n <= 3 then -- surely we just set n so why check?
				-- count how many maneuvers are currently set
				local total_man = 0
				for k,v in pairs(settings.maneuvers) do
					-- if manuevers already set for this element, ignore that count and use the new count
					if k == commandArgs[1] then
						total_man = total_man + n
						-- since n is accounted for in total_man
						n = 0
					else
						total_man = total_man + v
					end
				end
				-- store or error if too many
				if total_man + n > 3 then
					addon_message('Total maneuvers count (%d) exceeds 3':format(total_man + n))
				else
					settings.maneuvers[commandArgs[1]] = tonumber(commandArgs[2])
					addon_message('%s x%d':format(commandArgs[1],commandArgs[2]))
				end
			-- remove all commandArgs[1] maneuvers
			elseif commandArgs[2] == '0' or commandArgs[2] == 'off' then
				settings.maneuvers[commandArgs[1]] = nil
				addon_message('%s Off':format(commandArgs[1]))
			-- throw an error
			-- elseif n then  -- we set n so why check?
			else
				addon_message('Error: %d exceeds the min/max value for %s.':format(commandArgs[2],commandArgs[1]))
			end
		-- commandArgs[1] doesn't match a short maneuver name so check it's a string
		elseif type(settings[commandArgs[1]]) == 'string' and commandArgs[2] then
			local maneuver = get.maneuver(table.concat(commandArgs, ' ',2))
			-- check string matches a long maneuver name
			if maneuver then
				-- store if it does
				settings[commandArgs[1]] = maneuver.enl
				addon_message('%s is now set to %s':format(commandArgs[1],maneuver.enl))
			else
				-- otherwise error
				addon_message('Invalid maneuver name.')
			end
		-- wtf does this do?!
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
		-- some debug option!
		elseif commandArgs[1] == 'eval' then
			assert(loadstring(table.concat(commandArgs, ' ',2)))()
		end
	end
	pup_status:text(display_box())
end)

function event_change()
	settings.actions = false
	casting = false
	paused = false
end

function status_change(new,old)
	casting = false
	if new == 2 or new == 3 then
		event_change()
	elseif new == 33 then
		paused = true
		addon_message('Actions Paused')
	elseif old == 33 then
		paused = false
		addon_message('Actions Resumed')
	end
	pup_status:text(display_box())
end

windower.register_event('status change', status_change)
windower.register_event('zone change','job change','logout', event_change)
