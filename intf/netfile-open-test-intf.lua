--[[ -- Skipper Interface 1.0.0
-------  By Trezdog44
------- Inspired By TIME ------------------------
"skipper_intf.lua" > Put this VLC Interface Lua script file in \lua\intf\ folder
--------------------------------------------
*** Requires "super-skipper.lua" > Put the VLC Extension Lua script file in \lua\extensions\ folder ***

Simple instructions:
1) "super-skipper.lua" > Copy the VLC Extension Lua script file into \lua\extensions\ folder
2) "skipper_intf.lua" > Copy the VLC Interface Lua script file into \lua\intf\ folder
3) Start the Extension in VLC menu "View > Super Skipper" on Windows/Linux or "Vlc > Extensions > Super Skipper" on Mac and configure your profiles & settings.

Alternative activation of the Interface script:
* The Interface script can be activated from the CLI (batch script or desktop shortcut icon): vlc.exe --extraintf=luaintf --lua-intf=skipper_intf
* VLC preferences for automatic activation of the Interface script: Tools > Preferences > Show settings=All > Interface >
  * > Main interfaces: Extra interface modules [luaintf] (add to the interface list)
  * > Main interfaces > Lua: Lua interface [skipper_intf]

INSTALLATION directory (\lua\intf\):
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\intf\
* Windows (current user): %APPDATA%\VLC\lua\intf\
* Linux (all users): /usr/lib/vlc/lua/intf/
* Linux (current user): ~/.local/share/vlc/lua/intf/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/intf/
* Mac OS X (current user): /Users/%your_name%/Library/Application Support/org.videolan.vlc/lua/intf/
**** Create directory if it does not exist! ****
--]]----------------------------------------

os.setlocale("C", "all") -- fixes numeric locale issue on Mac

-- Global Variables
VLC_version = vlc.misc.version()
config = {}
profile_name = ""
function Testing()
		local dialog = vlc.dialog( "My VLC Extension" )
		dialog:add_label("test", 1, 1, 5, 10)
    local btn = dialog:add_button("OK", function () dialog:delete(); test(); return nil end, 3, 20, 1, 5)
    Sleep(5)
    dialog:del_widget(btn)
    dialog:delete()
end

	function test()
		vlc.msg.info("cool")
	end

-- The Main Function Loop
function Looper()
  local curi = nil
  while true do
    if vlc.volume.get() == -256 then break end -- inspired by syncplay.lua; kills vlc.exe process in Task Manager
    if vlc.playlist.status() == "stopped" then -- no input or stopped input
      if curi then -- input stopped
        Log("stopped")
        curi = nil
      end
    else -- playing, paused
      local uri = nil
      if vlc.input.item() then uri = vlc.input.item():uri() end
      if not uri then --- WTF (VLC 2.1+): status playing with nil input? Stopping? O.K. in VLC 2.0.x
        Log("WTF??? " .. vlc.playlist.status())
      elseif not curi or curi ~= uri then -- new input (first input or changed input)
        curi = uri
        similar_media = find_similar(curi)

        if #similar_media == 0
          Log("[Add Similar] didn't find similar files")
        else
          Log("[Add Similar] found similar files")


          for _,fullPath in pairs(similar_media) do 
            local new_item = {}
            new_item.path = "file:///"..fullPath
            new_item.name = file
            
            Log("[Add Similar] adding: "..fullPath)
            vlc.playlist.enqueue({new_item})
            -- vlc.playlist.sort('title')
          end
        end
        find_similar(curi)
      end
    end
    Sleep(1)
  end
end

function Log(lm)
  vlc.msg.info("[NETFILE OPEN TEST] " .. lm)
end

function Sleep(st) -- seconds
  vlc.misc.mwait(vlc.misc.mdate() + st * 1000000)
end

-------------   SKIPPER   ---------------

function Get_sk_config()
  profiles = {}
  config_file = vlc.config.configdir() .. "/series-tracker.conf"

  if (file_exists(config_file)) then
    load_all_profiles()
  end
end

function playing_loop()
  local input = vlc.object.input()
  if vlc.input.is_playing() then
  end
end

-- -- XXXX -- -- SKIPPER -- -- XXXX -- --

-- Looper() --start
Testing()

function find_similar(uri)
  Log("Checking if file is localfile or not")
  if string.find(uri, "file:///%w") then
    Log("LOCALFILE: "..uri)
    similar_media = find_files(uri, false)
  elseif string.find(uri, "file://%w") or string.find(uri, "file://///%w") then
    Log("NETFILE: "..uri)
    similar_media = find_files(uri, true)
  else
    Log("NOT SURE")
    similar_media = {}
  end

  -- Did it return anything?
  if #similar_media == 0 then -- If nothing was returned, inform the user
  else -- Add the files
  end

  return similar_media
end

function find_files(uri, is_netfile)
  local fullPath = uri:gsub("file:[/]+", is_netfile and "//" or "")
  local fileNameLength = string.find(string.reverse(uri), "/", 0, true)

  -- Scour the directory for files
  path = vlc.strings.decode_uri(string.sub(fullPath, 0, -fileNameLength))
  target = vlc.strings.decode_uri(string.sub(fullPath, -fileNameLength+1))

  local paths = find_paths(path)

  Log("Target file: "..target)
  Log("Loading directory: "..path)

  local cutoff = 50 -- arbitrary value

  -- Return similar media
  local similar_media = {}

  for _,path in pairs(paths) do
    score = calc_scores(path, target)
    for file,p in pairs(score) do 
      if p > cutoff then
        table.insert(similar_media,file)
        table.sort(similar_media)
      end
    end
  end

  return similar_media
end

function find_paths(path)
  -- Get Parent directory
  local parent_dir = vlc.strings.decode_uri(string.sub(path, 0, -string.find(string.reverse(path), "/", 2, true)))
  local file = io.open(parent_dir.."test.txt", "w")
  file:write("Hello World")
  file:close()

  local paths = {}

  if parent_dir == nil then
    Log("No Parent folder found, using original")
    table.insert(paths, path)
    return paths
  end

  local contents = vlc.net.opendir(parent_dir)

  table.sort(contents, compare_seasons)

  for _, dir in pairs(contents) do
    Log("dir: "..dir)
    if string.find(dir:upper(), "^SEASON[ _-]?%d+$", 0) or string.find(dir:upper(), "^S[ _-]?%d+$", 0) then
      table.insert(paths, parent_dir..dir)
    end
  end

  if #paths == 0 then
    Log("No Season folders found, using original")
    table.insert(paths, path)
  end

  return paths
end

function compare_seasons(a, b)
  a_cap = a and a:match("%d+") or 0
  b_cap = b and b:match("%d+") or 99999
  Log("a="..(a or "nil").."..b="..(b or "nil"))
  Log("a_cap="..a_cap.."..b_cap="..b_cap)
  if tonumber(a_cap) < tonumber(b_cap) then
    return true
  else
    return false
  end
end	

function calc_scores(path, target)
  -- Load directory contents into a table
  -- local contents = vlc.io.open(path)
  local contents = vlc.net.opendir(path)
  -- Split the filename into words
  local keywords = split(target,"[%p%s]")
  
  Log("Keywords: "..table.concat(keywords," \\ "))
  
  -- Analyze the filename to find its structure
  local structure = split(target,"[^%p]+")
  
  Log("Structure: "..table.concat(structure))
  -- Look for keywords (second pass)
  score= {} 

  for _, file in pairs(contents) do 
    local fullPath = path..file

    Log(file)
    if not (file == target or file == '.' or file == '..') then		
    
      -- TEST 1: Look for matches in words in the file
      local file_keywords = split(file,"[%p%s]")
      local matches = 0	
      
        for _,key in pairs(keywords) do
          for _,file_key in pairs(file_keywords) do
            if (file_key == key) then
              matches = matches + key:len()
            end
          end
        end
        
        Log("      Matches: "..matches)
        Log("      Probability: "..(matches/#keywords))
          
        increment = ((matches/#keywords)*100)*0.6
        score[fullPath] = score[fullPath] or 0
        score[fullPath] = score[fullPath] + increment
        Log("      Score added: "..increment)
            
      -- TEST 2: Look for similarities in file structure		
      local file_structure = split(file,"[^%p]+")
        if table.concat(file_structure)==table.concat(structure) then 
          increment = 30
          Log("      Structure match: true")
          score[fullPath] = score[fullPath] or 0
          score[fullPath] = score[fullPath] + increment
          Log("      Score added: "..increment)
        end
        
        score[fullPath] = score[fullPath] or 0
        
        Log("      Final score: "..score[fullPath])
    else 
      Log("      Not analyzed")
    end
  end

  return score
end

-- Splits a string into a table, based on a patterns (from: http://http://lua-users.org/wiki/SplitJoin )

function split(str, pat)
  local str_upper = str:upper()
  local t = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pat
  local last_end = 1
  local s, e, cap = str_upper:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      if not stopwords[cap] then
        table.insert(t,cap)
      end
    end
    last_end = e+1
    s, e, cap = str_upper:find(fpat, last_end)
  end
  if last_end <= #str_upper then
    cap = str_upper:sub(last_end)
    if not stopwords[cap] then
      table.insert(t,cap)
    end
  end
  return t
end

function build_stopwords_set()
  local stopwords = {"WEB", "WEBDL", "WEBRIP", "RIP", "HDTV", "4K", "1080P", "1080", "720P", "720", "480P", "480", "2", "0", "BLURAY", "BRRIP", "DVD", "DVDRIP", "H264", "X264", "264", "H", "X", "DL", "DD", "AAC2", "AAC", "AC3", "AUDIO", "AMZN", "MP4", "MOV", "WMV", "FLV", "AVI", "WEBM", "MKV"}
  local set = {}
  for _, l in ipairs(stopwords) do set[l] = true end
  return set
end
