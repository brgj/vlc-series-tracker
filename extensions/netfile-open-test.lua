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
				 capabilities = { "input-listener", "meta-listener" } }
	end

--[[ Global vars ]]
	path = nil
	target = nil
	stopwords = nil

--[[ Hooks ]]

	-- Activation hook
	function activate()
		vlc.msg.info("[NETFILE OPEN TEST] Activated")
		stopwords = build_stopwords_set()
		startNetFilePlay()
	end

	-- Deactivation hook
	function deactivate()
		vlc.msg.info("[NETFILE OPEN TEST] Deactivated")
	end

	function input_changed()
		fileInfo()
		find_similar()
		-- local dialog = vlc.dialog( "My VLC Extension" )
		-- dialog:add_label("test", 1, 1, 5, 10)
		-- dialog:add_button("OK", function () dialog:delete(); test(); return nil end, 3, 20, 1, 5)
	end

	-- function test()
	-- 	vlc.msg.info("cool")
	-- end

	function meta_changed()
		-- related to capabilities={"meta-listener"} in descriptor()
		-- triggered by available media input meta data?
	end

	function Log(lm)
		vlc.msg.info("[NETFILE OPEN TEST] " .. lm)
	end

--[[ Start ]]

	function fileInfo()
		Log("Name: "..vlc.input.item():name())
		Log("URI: "..vlc.input.item():uri())
		Log("Duration: "..vlc.input.item():duration())
		Log(inspect(getmetatable(vlc.input.item())))
	end

	function startNetFilePlay()
		local path = "192.168.0.3/share/TV_Shows/It's Always Sunny in Philadelphia/Season 12/"
		local target = "Its.Always.Sunny.In.Philadelphia.S12E06.Hero.or.Hate.Crime.1080p.AMZN.WEB-DL.DD+2.0.H.264-CtrlHD.mkv"

		local new_item = {}
			new_item.path = "file://"..((path..target):gsub(" ", "%%20"))
			new_item.name = file
		Log("NET new_item="..new_item.path)
		vlc.playlist.enqueue({new_item})
		vlc.playlist.play()
	end

	function startLocalFilePlay()
		local new_item = {} 
			new_item.path = "file:///C:\\Users\\Brad\\Downloads\\test.mkv"
			new_item.name = file
		Log("LOCAL new_item="..new_item.path)
		vlc.playlist.enqueue({new_item})
		vlc.playlist.play()
	end