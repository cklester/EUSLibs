include std/sequence.e
include std/get.e

sequence settings
	settings = {{},{}}
	
public function load_settings(sequence fname)
atom fn
object line
sequence txt
	fn = open(fname,"r")
	if fn > 0 then
	    line = gets(fn)
	    while not atom(line) do
		if length(line) != 0 then
			if line[1] != '#' then
			    txt = split(line,'=')
			    if length(txt[1]) > 0 and length(txt[2]) > 0 then
					settings[1] = append(settings[1],txt[1])
					if txt[2][$] = 10 then
					    txt[2] = txt[2][1..$-1]
					end if
					settings[2] = append(settings[2],txt[2])
				end if
		    end if
		end if
		line = gets(fn)
	    end while
	    close(fn)
	    return 1
	else
	    puts(1,"Could not open '" & fname & "'")
	    puts(1,"\nContact your IT department.")
	    puts(1,"\nPress any key to quit.")
	    return 0
	end if
end function

global function get_setting(sequence set, integer AS_NUMBER = 0)
integer i
	i = find(set,settings[1])
	if i > 0 then
		if AS_NUMBER then
			sequence TEMP = value( settings[2][i] )
			return TEMP[2]
		else
			return settings[2][i]
		end if
	end if
	return ""
end function
