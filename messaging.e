-- include hirestime.e
-- HRT_start("messaging.e")
-- fast enough

include std/text.e
include std/filesys.e

include registration.e
include logging.e


-- 2008.04.04 - fixed error where fatal error wasn't adding appropriate sequence data to errors
-- 2008.05.30 - including all dependencies
register_code("messaging.e",{2008,5,30,0,0})

--------------------------------------------------
----------------ROUTINE TRACKING & TRACING--------
--------------------------------------------------

integer ROUTINE_DEBUG, ROUTINE_TRACE, FATAL_ERROR
sequence Routine_List
   Routine_List = {}
   FATAL_ERROR = (1=2)
   
public procedure routine_tracking(object a)
	ROUTINE_DEBUG = integer(a) and a = 1
end procedure

public procedure routine_tracing(object a)
	ROUTINE_TRACE = integer(a) and a = 1
end procedure

public function get_calling_routine()
	if length(Routine_List) > 1 then
		return Routine_List[$-1]
	else
		return "Unidentified Calling Routine"
	end if
end function

public function get_routine()
	if length(Routine_List) > 0 then
		return Routine_List[$]
	else
		return "Unidentified Routine"
	end if
end function

public function get_routines()
	return get_calling_routine() & " >> " & get_routine()
end function

-- You don't necessarily have to add every single routine...
public procedure add_routine(sequence s)
	if ROUTINE_DEBUG then
		Routine_List = append(Routine_List,s)
	end if
	if ROUTINE_TRACE then
   		logfile_custom( "routine_trace.txt", get_routines(), 0 )
	end if
end procedure

-- YOU MUST ALWAYS ALWAYS ALWAYS REMEMBER TO REMOVE YOUR ROUTINE FROM THE LIST

public procedure remove_routine(sequence s)
integer t
	-- a "remove_routine()" should ALWAYS be removing the last routine
	-- that is, it's always LIFO (last in, first out)
	if ROUTINE_DEBUG then
		if equal(Routine_List[$],s) then
			Routine_List = Routine_List[1..$-1]
		else
			-- remove EVERYTHING in the list from the LAST s found
			t = length(Routine_List)
			while t > 0 do
				if equal(Routine_List[t],s) then
					Routine_List = Routine_List[1..t-1]
					t = 0
				end if
				t -= 1
			end while
		end if
	end if
end procedure

public function get_routine_list()
   return Routine_List
end function

routine_tracking(1)
routine_tracing(0)

--------------------------------------------------
---------------------------------MESSAGING--------
--------------------------------------------------

sequence errors, warnings, sys_msg
errors = {}
warnings = {}
sys_msg = {}

public function time_stamp()
object tn
	tn = date()
	tn[1] += 1900
	return sprintf("\n%04d.%02d.%02d - %02d:%02d:%02d",tn)
end function

function add_breaks(sequence s, integer as_html = 1)
sequence br
	if as_html then
		br = "<br/>"
	else
		br = "\n"
	end if
	for t=length(s) to 1 by -1 do
		if s[t] = '\n' then
			s = s[1..t-1] & br & s[t+1..$]
		end if
	end for
	return s
end function

public procedure msg(object s, integer show_path = 1)
	if not sequence(s) then
		s = sprint(s)
	end if
	if show_path then
		sys_msg = append(sys_msg,{get_routines() & ":" & s,time_stamp()})
	else
		sys_msg = append(sys_msg,{s,""})
	end if
end procedure

public function getmsg(integer as_html = 1)
sequence 
	  br
	, result = ""
	
	if as_html then
		br = "<br/>"
	else
		br = "\n"
	end if

	for t=1 to length(sys_msg) do
		if length(sys_msg[t][2]) > 0 then
			result &= "\t" & sys_msg[t][2] & " + " & add_breaks( sys_msg[t][1], as_html ) & br
		else
			result &= "\t" & add_breaks( sys_msg[t][1], as_html ) & br
		end if
	end for
	return result
end function

integer SUPPRESS_ERROR
SUPPRESS_ERROR = (1=2)

public procedure suppress_error()
	SUPPRESS_ERROR = (1=1)
end procedure

public procedure report_errors()
	SUPPRESS_ERROR = (1=2)
end procedure

public procedure err(object s, integer show_path = 1)
	if not SUPPRESS_ERROR then
		if not sequence(s) then
			s = sprint(s)
		end if
		if show_path then
			errors = append(errors,{get_routines() & ":" & s,time_stamp()})
		else
			errors = append(errors,{s,""})
		end if
	else
		SUPPRESS_ERROR = (1=2)
	end if
end procedure

integer rid_path
public procedure set_rid_path(integer i)
	rid_path = i
end procedure
set_rid_path( 1 )

public procedure errx(object s)
	err(s, rid_path)
end procedure

public procedure set_fatal_error(sequence s)
	if not FATAL_ERROR then -- if there has NOT already been a fatal error...
		errors = append(errors,{get_routines() & ":" & s,time_stamp()})
		FATAL_ERROR = (1=1)
	else
		errors = append(errors,{get_routines() & ": FATAL ERROR already occurred.",time_stamp()} )
	end if
end procedure

public function fatal_error()
	return FATAL_ERROR
end function

public function geterr(integer as_html = 1,integer qty=-1)
sequence
	  br
	, result = ""
	, tab
	
	if as_html then
		br = "<br/>"
		tab = "\t"
	else
		br = "\n"
		tab = ""
	end if

	if qty = -1 or qty > length(errors) then
		qty = length(errors)
	else
		if qty = 0 then
			result &= "There are " & sprint(length(errors)) & " errors." & br
		end if
	end if

	for t=1 to qty do
		if length(errors[t][2]) > 0 then
			result &= tab & errors[t][2] & " - " & add_breaks( errors[t][1], as_html ) & br
		else
			result &= tab & add_breaks( errors[t][1], as_html ) & br
		end if
	end for
	return result
end function

public procedure add_warning(object s, integer show_path = 1)
	if not sequence(s) then
		s = sprint(s)
	end if
	if show_path then
		warnings = append(warnings,{get_routines() & ":" & s,time_stamp()})
	else
		warnings = append(warnings,{s,""})
	end if
end procedure

public function get_warning_msg()
sequence result
	result = ""
	for t=1 to length(warnings) do
		result &= "\t" & warnings[t][2] & " * " & add_breaks( warnings[t][1] )
	end for
	return result
end function

public procedure log_errors(sequence s)
object fn, tn
	tn = date()
	if atom(dir("logs/messages.txt")) then -- it doesn't exist
		fn = open("logs/messages.txt","w")
	else
		fn = open("logs/messages.txt","a")
	end if
	if fn > 0 then
		puts(fn,s)
		close(fn)
	end if
end procedure

-- HRT_stop("messaging.e")
