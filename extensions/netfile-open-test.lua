--[[
 NETFILE OPEN, testing version

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
--]]

--[[ Extension description ]]
	local inspect = require 'inspect'

	function descriptor()
		return { title = "NetFile Open Test" ;
				 version = "alpha" ;
				 author = "Brad Johnson" ;
				 shortdesc = "Test Netfile Open";
				 description = "";
				 capabilities = { "menu", "meta-listener" } }
	end

--[[ Global vars ]]
	path = nil
	target = nil
	stopwords = nil

--[[ Hooks ]]

	function activate()
		profiles = {}
		config_file = vlc.config.configdir() .. "/series-tracker.conf"

		local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
		trigger_menu() 
		-- if not ti or VLC_luaintf~=intf_script then else trigger_menu(1) end
	end

	function deactivate()
	dlg:delete()
	-- vlc.deactivate()
	end

	function close()
	dlg:hide()
	end

	function menu()
	return {"Set Interface"}
	end

	function trigger_menu()
	if dlg then dlg:delete() end
	open_dialog()
	end

	--------------  Save Profiles Dialog --------------------

	function open_dialog()
	dlg = vlc.dialog(descriptor().title)

	dlg:add_label("<center><h3>Interface</h3></center>", 1, 1, 4, 1)
	cb_extraintf = dlg:add_check_box("Enable interface: ", true, 1, 3, 1, 1)
	ti_luaintf = dlg:add_text_input(intf_script, 2, 3, 2, 1)
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()
	lb_message = dlg:add_label("Current status: " .. (ti and "ENABLED" or "DISABLED") .. ". Interface: " .. tostring(VLC_luaintf), 1, 4, 3, 1)

	dlg:add_label("<center><h3>Series Tracker Location</h3></center>", 1, 5, 4, 1)
	series_tracker_dd = dlg:add_dropdown(1, 7, 4, 1)
		series_tracker_dd:add_value("Track Series In Media Folder", 1)
		series_tracker_dd:add_value("Track Series In Config File", 2)

	dlg:add_button("Save", save_series_tracker_settings, 1, 8, 2, 1)
	dlg:show()
	end

	function save_series_tracker_settings()
	local tracker_option = series_tracker_dd:get_value()
	
	io.output(config_file)
	io.write("tracker_option="..tracker_option)
	io.close()
		
	local VLC_extraintf, VLC_luaintf, t, ti = VLC_intf_settings()

	if cb_extraintf:get_checked() then
		--vlc.config.set("extraintf", "luaintf")
		if not ti then table.insert(t, "luaintf") end
		vlc.config.set("lua-intf", ti_luaintf:get_text())
	else
		--vlc.config.set("extraintf", "")
		if ti then table.remove(t, ti) end
	end
	vlc.config.set("extraintf", table.concat(t, ":"))

	lb_message:set_text("Please restart VLC for changes to take effect!")
	end

	function SplitString(s, d) -- string, delimiter pattern
	local t = {}
	local i = 1
	local ss, j, k
	local b = false
	while true do
		j, k = string.find(s, d, i)
		if j then
		ss = string.sub(s, i, j - 1)
		i = k + 1
		else
		ss = string.sub(s, i)
		b = true
		end
		table.insert(t, ss)
		if b then break end
	end
	return t
	end

	function VLC_intf_settings()
	local VLC_extraintf = vlc.config.get("extraintf") -- enabled VLC interfaces
	local VLC_luaintf = vlc.config.get("lua-intf") -- Lua Interface script name
	local t = {}
	local ti = false
	if VLC_extraintf then
		t = SplitString(VLC_extraintf, ":")
		for i, v in ipairs(t) do
		if v == "luaintf" then
			ti = i
			break
		end
		end
	end
	return VLC_extraintf, VLC_luaintf, t, ti
	end