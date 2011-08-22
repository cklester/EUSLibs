include std/sequence.e
include std/get.e
include std/map.e

sequence fname = "settings.txt"

map:map settings

public procedure save_settings()
	save_map( settings, fname )
end procedure
	
public procedure mod_setting( sequence set, object newval )
	map:put( settings, set, newval )
end procedure

public function load_settings()
object s = load_map( fname )
	if not equal(s,-1) then
		settings = s
	else
		settings = map:new()
		mod_setting( "DB", "SQLite" )
		save_settings() -- write the new file
	end if
	return not equal(s,-1)
end function

public function get_setting(sequence item, integer AS_NUMBER = 0)
object obj
	if AS_NUMBER then
		obj = map:get( settings, item, -1 )
		obj = value( obj )
		return obj[2]
	else
		return map:get( settings, item, "" )
	end if
end function
