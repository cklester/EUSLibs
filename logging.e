include std/text.e

include registration.e

register_code("logging.e",{2008,5,26,0,0})

include std/filesys.e
include std/datetime.e as dt

public procedure logfile(object s, sequence fname = "logfile.txt")
object fn
sequence path

	if not sequence(dir("logs")) then
		if create_directory("logs") then end if
	end if

	if not sequence(s) then
		s = sprint(s)
	end if
		
	path = "logs/" & fname
	if length(s) > 0 then
		if atom(dir(path)) then -- it doesn't exist
			fn = open(path,"w")
		else
			fn = open(path,"a")
		end if
		if fn > 0 then
			puts(fn,"\n" & s)
			close(fn)
		end if
	end if
end procedure

public procedure logfile_ts(sequence s, sequence fname = "logfile.txt")
object fn
sequence path
	path = "logs/" & fname
	if length(s) > 0 then
		if atom(dir(path)) then -- it doesn't exist
			fn = open(path,"w")
		else
			fn = open(path,"a")
		end if
		if fn > 0 then
			puts(fn,"\n" & dt:format(dt:now_gmt(),"%Y-%m-%d %H:%M:%S") & "\t" & s)
			close(fn)
		end if
	end if
end procedure

public procedure logfile_custom(sequence fname, sequence s, integer new)
object fn
	if new or atom(dir("logs/" & fname)) then -- it doesn't exist
		fn = open("logs/" & fname,"w")
	else
		fn = open("logs/" & fname,"a")
	end if
	if fn > 0 then
		puts(fn,"\n" & s)
		close(fn)
	end if
end procedure

public procedure logfilex(sequence s)
object fn
	if atom(dir("logs/logfile.txt")) then -- it doesn't exist
		fn = open("logs/logfile.txt","w")
	else
		fn = open("logs/logfile.txt","a")
	end if
	if fn > 0 then
		puts(fn, s)
		close(fn)
	end if
end procedure

-- 2007.04.09 - added logfilex for logging without forced newline
-- 2008.05.26 - include all dependencies
