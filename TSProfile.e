--// TSProfile.e
--// Tone Škoda
--// Created on 30. October 2004.
--// Release date: 10. November 2004
--// Version: 0.1
--// 
--// Library for measuring speed of code and counting how many times it is called.
--// Profilers can be within profilers.
--// Another feature: If profiler is inside a function,
--// and this function is called from two different places,
--// and these two places are also profiled, then
--// profile results from that function won't be summed up from both
--// cases, but will be separated.
--// 
--// Usage:
--// 1.
--// start_profiler ("profiler name")
--// <code>
--// end_profiler ("profiler name")
--// write_profile_results (1) or write_last_profiler_results (1)
--// or:
--// 2.
--// profile_routines (routines names etc)

include TSError.e
include TSDateTime.e
include sprint.e
include std/text.e
include std/io.e
include std/sort.e
include std/sequence.e

with warning
without type_check

constant DEBUG = 0
constant EXTRA_DEBUG = 0

--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Copied stuff from TSType.e @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

constant false = 0, true = 1

--// Lowest/highest possible integer in Euphoria.
constant LOWEST_INTEGER = -1073741824
--// Default value.
constant DEFAULT = LOWEST_INTEGER

type sequence_ (object o)
    return sequence (o)
end type

type integer_ (object o)
    return integer (o)
end type

type atom_ (object o)
    return atom (o)
end type

type object_ (object o)
    return object (o)
end type

--/*
-- check_struc [Created on 27. October 2004, 23:05]
-- The 'check_struc' function checks if
-- a structure-like sequence is made of right
-- types of members.
-- It is meant to be used inside types.
--
-- PARAMETERS
-- 'struc_def'
--    1. Object which you wish to check
--       if it has the right structure.
--       I will call this member 'struc' from now on.
--    2. Of what type should 'struc' be.
--       Routine id of existing type.
--       Can be left out or 0 if you don't want to specify type for this member.
--    3. and all next members should have this format.
--       They can be not specified if 'struc' is not sequence
--       but atom, for example.
--      1. Structure member number. Where in 'struc' is this member.
--      2. Of what type should be the this member of structre.
--         Routine id of existing type.
--         Can be left out or 0 if you don't want to specify type for this member.
--
-- RETURN VALUES
-- bool.
--*/
function check_struc (sequence struc_def)
    object struc
    if length (struc_def) < 1 then
        return true
    end if
    struc = struc_def [1]
    if length (struc_def) >= 2
    and struc_def [2] > 0 then
        if not call_func (struc_def [2], {struc}) then
            return false
        end if
    end if
    if length (struc_def) >= 3 then
        if length (struc) != length (struc_def) - 2 then
            return false
        end if
        for i = 3 to length (struc_def) do
            if length (struc_def [i]) >= 2
            and struc_def [i] [2] > 0 then
                if not call_func (struc_def [i] [2],
                    {struc [struc_def [i] [1]]}) then
                    return false
                end if
            end if
        end for
    end if    
    return true
end function

type STRING (object s)
    if not sequence (s) then
        return false
    end if
    for i = 1 to length (s) do
        if not integer (s [i]) then
            return false
        end if
        if s [i] < 0 or s [i] > 255 then
            return false
        end if
    end for
    return true
end type

--// sequence with strings
type STRINGS (sequence s)
    for i = 1 to length (s) do
        if not STRING (s [i]) then
            return false
        end if
    end for
    return true
end type

type bool (integer i)
    if i = true or i = false then
        return true
    else
        return false
    end if
end type

type BOOL (integer i)
    if i = true or i = false then
        return true
    else
        return false
    end if
end type

--/*
-- PERCENT [Created on 25. May 2002, 03:40]
-- The 'PERCENT' type:
-- Must be atom between 0 and 1 (inclusive).
--*/
type PERCENT (object a)
    if not atom (a) then
        return false
    end if
    return a >= 0 and a <= 1
end type

--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Variables, types and constants. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--// In no particular order. should be PROFILERS type.
sequence All_profilers
--//
--// PROFID type. Profiler index.
--//=>
    type PROFID (object profid)
        if not integer (profid) then
            return false
        end if
        if profid < 0 or profid > length (All_profilers) then
            return false
        end if
        return true
    end type
    type PROFIDS (object profids)
        if not sequence (profids) then
            return false
        end if
        if EXTRA_DEBUG then
            for i = 1 to length (profids) do
                if not PROFID (profids [i]) then
                    return false
                end if
            end for
        end if
        return true
    end type
--//
--// PROFILER type:
--//=>
    --// Name of this profiler. Not needed to be unique name. STRING.
    constant PROFILER_NAME = 1
    --// Number of times code was run.
    constant PROFILER_NUM_RUNS = 2
    --// Sum of time code took to execute.
    constant PROFILER_RUNTIME_SUM = 3
    --// What was time() when profile_start() was called for this name.
    constant PROFILER_STARTTIME = 4
    --// Sequence of profilers ids
    --// which profile code in which is also start
    --// and end of this profiler.
    constant PROFILER_PARENTS = 5
    --// names of child profilers, in no particular order
    constant PROFILER_CHILDREN_NAMES = 6
    --// for every member in 'PROFILER_CHILDREN_NAMES':
    --// PROFID
    constant PROFILER_CHILDREN_IDS = 7
    type PROFILER (object profiler)
        if not check_struc ({
            profiler, routine_id ("sequence_"),
            {PROFILER_NAME, routine_id ("STRING")},
            {PROFILER_NUM_RUNS, routine_id ("atom")},
            {PROFILER_RUNTIME_SUM, routine_id ("atom")},
            {PROFILER_STARTTIME, routine_id ("atom")},
            {PROFILER_PARENTS, routine_id ("PROFIDS")},
            {PROFILER_CHILDREN_NAMES, routine_id ("STRINGS")},
            {PROFILER_CHILDREN_IDS, routine_id ("PROFIDS")}
            }) then
            return false
        end if
        if length (profiler [PROFILER_CHILDREN_NAMES]) != length (profiler [PROFILER_CHILDREN_IDS]) then
            return false
        end if
        return true
    end type
    function new_profiler ()
        return {"", 0, 0, -1, {}, {}, {}}
    end function
    type PROFILERS (object profilers)
        if not sequence (profilers) then
            return false
        end if
        for i = 1 to length (profilers) do
            if not PROFILER (profilers [i]) then
                return false
            end if
        end for
        return true
    end type
STRINGS Root_profilers_names
--// For every member in 'Root_profilers_names'.
PROFIDS Root_profilers_ids
--// time() when results were last written
--// with write_profile_results() routine.
atom Last_write_time
--// Ids of profilers for which start_profoiler()
--// was called but end_profiler() was not called yet.
PROFIDS Inside_profilers_ids
--// Profiler of last start_profiler() call.
PROFID Prev_profid
    

    
    
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Copied stuff from other TS library files. @@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- returns file extension
-- example: "C:\dir\file.txt" returns "txt"
function get_file_ext (sequence fname)
	for i = length (fname) to 1 by -1 do
		if fname [i] = '.' then
			return fname [i + 1 .. length (fname)]
		elsif fname [i] = '\\' or fname [i] = '/' then
			return ""
		end if
	end for
	return ""
end function

--/*
-- get_member_default [Created on 2. August 2002, 02:32]
-- The 'get_member_default' function tries to get member from sequence
-- at specified position. If position is out of bounds
-- it returns default value which you specified.
-- Also, if value as position in sequence is equal to
-- value of 'must_not_be' then 'default_value' is returned.
--
-- PARAMETERS
-- 's'
--    sequence to get one member from.
-- 'pos'
--    At this position in sequence is member we will get.
-- 'must_not_be'
--    If value which would be returned is equal to this then
--    default value is returned.
--    This can be UNDEFINED, then it's ignored.
-- 'default_value'
--    Default value to return if no member is at that position
--    in sequence or if member value is not right.
--
-- RETURN VALUES
-- Member at position or default value.
--*/
function get_member_default (sequence s, integer pos,
    object must_not_be, object default_value)
    if pos >= 1 and pos <= length (s) then
        if not equal (s [pos], must_not_be) then
            return s [pos]
        else
            return default_value
        end if
    else
        return default_value
    end if
end function

--/*
-- repeat_add [Created on 11. November 2002, 00:21]
-- The 'repeat_add' function is similar to builtin
-- 'repeat ()', this is difference:
-- 
-- repeat ("ABC", 3) returns {"ABC", "ABC", "ABC"}
--
-- repeat_add ("ABC", 3) returns "ABCABCABC"
--
-- PARAMETERS
-- 'o'
--    .
-- 'count'
--    .
--
-- RETURN VALUES
-- .
--*/
function repeat_add (object o, integer count)
    sequence res
    res = ""
    for i = 1 to count do
        res &= o
    end for
    return res
end function

--/*
-- number_to_string [Created on 22. June 2002, 16:55]
-- The 'number_to_string' function converts number (atom or integer)
-- to string.
--
-- PARAMETERS
-- 'number'
--    .
--
-- RETURN VALUES
-- STRING.
--*/
function number_to_string (atom number)
    if integer (number) then --// whole number
        return sprintf ("%d", number)
    else --// floating point number
        return sprintf ("%f", number)
    end if
end function

--/*
-- abs_ [Created on 30. December 2001, 01:00]
-- The 'abs_' function calculates absolute value of argument.
--
-- PARAMETERS
-- 'a'
--    integer or atom.
--
-- RETURN VALUES
-- Absolute value of 'a'.
--*/
function abs_ (atom a)
    if a < 0 then
	return -a
    else
	return a
    end if
end function

--/*
-- ceil [Created on 29. December 2001, 18:58]
-- The 'ceil' function calculates the ceiling of a value.
--
-- PARAMETERS
-- 'a'
--    atom or integer.
--
-- RETURN VALUES
-- The ceil function returns a double value representing the smallest integer
-- that is greater than or equal to x. There is no error return.
--*/
function ceil (atom a)
    if floor (a) = a then   --// A is not floating value.
	return a
    else                    --// A is floating value.
	return floor (a + 1)
    end if
end function

--/*
-- round [Created on 29. December 2001, 19:00]
-- The 'round' function returns the closest integer to the argument.
--
-- PARAMETERS
-- 'a'
--    atom or integer.
--
-- RETURN VALUES
-- The value of the argument rounded to the nearest integer value.
--*/
function round (atom a)
    --// A floored.
	atom a_floor
    if floor (a) = a then   --// A is not floating value.
	return a
    else                    --// A is floating value.
	    a_floor = floor (a)
	    if abs_ (a - a_floor) < 0.5 then --// 'a' is closer to floor (a) than to ceil (a).
	    return a_floor
	    else                            --// 'a' is closer to ceil (a) than to floor (a).
	    return ceil (a)
	    end if
    end if
end function

--/*
-- max [Created on 12. December 2001, 21:11]
-- The 'max' function is regualr max number.
-- It returns the one of two numbers that is bigger.
--
-- PARAMETERS
-- 'a1'
--    Number 1.
-- 'a2'
--    Number 2.
--
-- RETURN VALUES
-- 'a1' or 'a2'.
--
--*/
function max (atom a1, atom a2)
    if a1 > a2 then
	return a1
    else
	return a2
    end if
end function

--/*
-- number_to_str_places [Created on 10. August 2002, 19:19, Saturday]
-- The 'number_to_str_places' function converts
-- a number to string.
-- Resulting number has at least that many digits
-- before dot as number 'places'.
-- 0's are added if not enough.
--
-- Example:
-- number_to_str_places (1, 3) returns "001"
-- number_to_str_places (1000, 3) returns "1000"
-- number_to_str_places (2.5, 3) returns "02.5"
--
-- 'number'
--    Number to convert to string.
-- 'places'
--    How many digits before dot should there be, at least,
--    in returned value.
-- 
-- RETURN VALUES
-- String.
--*/
function number_to_str_places (atom number, integer places)
    integer dot_pos
    STRING ret
    if integer (number) then --// whole number
        ret = sprintf ("%d", number)
        ret = repeat ('0', max (0, places - length (ret))) & ret
    else --// floating point number
        ret = sprintf ("%f", number)
        dot_pos = find ('.', ret)
        ret = repeat ('0', max (0, places - dot_pos)) & ret
    end if
    return ret
end function

constant MONTHS = {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"}

constant WEEKDAYS_NAMES = {
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"}

--/*
-- get_english_month_name [Created on 6. August 2002, 22:31]
-- The 'get_english_month_name' function gets
-- english name for month number.
--
-- PARAMETERS
-- 'month_number'
--    January = 1.
--
-- RETURN VALUES
-- String, month name.
--*/
function get_english_month_name (integer month_number)
    return MONTHS [month_number]
end function

--/*
-- pretty_format_time [Created on 22. August 2002, 17:28]
-- The 'pretty_format_time' function pretty formats time
-- to be read by humans.
-- Examples:
--
-- pretty_format_time ({0, 11, 23}) returns "11:23"
-- pretty_format_time ({1, 13, 4}) returns "1:13:04"
-- pretty_format_time ({20, 9, 11}) returns "20:09:10""
-- pretty_format_time ({0, 3, 1}) returns "03:01"
--
-- PARAMETERS
-- 'the_time'
--    datetime.e time, it can be {} to get current time.
--    Difference from Time type: hours can be bigger than 24.
-- 'params'
--    It can be {} then default values are used.
--    It can sequence of this format:
--    Any member can be 'DEFAULT' to use default value for it.
--    1. True if to show seconds.
--       Default is false.
--    2. True if to show hours.
--       If hours are not shown hours are added to minutes.
--       Default is true,
--    3. True if to show seconds as decimals.
--       Default is false.
--
-- RETURN VALUES
-- String, formatted time.
--*/
function pretty_format_time (sequence the_time,
    sequence params)
    STRING ret
    sequence real_time
    BOOL do_show_seconds, do_show_hours, do_show_secs_as_decimals
	atom minutes
    if length (the_time) then
        real_time = the_time
    else
        real_time = nowTime ()
    end if
    --// printf (1, "%f\n", real_time [SECONDS])
    --// showw ("real_time", real_time)    
    do_show_seconds = get_member_default (params, 1, DEFAULT, false)
	do_show_hours = get_member_default (params, 2, DEFAULT, true)	
    do_show_secs_as_decimals = get_member_default (params, 3, DEFAULT, false)	
	ret = ""
	if do_show_hours then
		ret = number_to_string (round (real_time [HOURS])) & ":"
		minutes = real_time [MINUTES]
	else		
		minutes = real_time [MINUTES] + real_time [HOURS] * 60
	end if
    ret &= number_to_str_places (round (minutes), 2)
    if do_show_seconds then
        if do_show_secs_as_decimals then
            ret &= ":" & sprintf ("%f", real_time [SECONDS])--// TODO: precision of seconds in datetime.e is rounded up.
        else
            ret &= ":" & number_to_str_places (round (real_time [SECONDS]), 2)
        end if
    end if
    return ret
end function

--/*
-- pretty_format_datetime [Created on 2. August 2002, 02:29]
-- The 'pretty_format_datetime' function pretty formats date and time
-- so that it's easily readable by humans.
--
-- PARAMETERS
-- 'date_and_time'
--    Date and time, DateTime type from datetime.e.
--    It can be {} to get current date and time.
-- 'params'
--    It can be {} then default values are used.
--    It can sequence of this format:
--    Any member can be 'DEFAULT' to use default value for it.
--    1. True if to show year, false if not to show it.
--       This is true by default.
--    2. True if to use relative names for days,
--       that means, if day is today, tomorrow or yesterday
--       write it like that.
--       This is true by default
--    3. True if to use month names (english) instead of month numbers.
--       If month numbers are used they are written after day, like this:
--       24.6
--       24. June
--       This is true by default.
--    4. True if to show seconds for time.
--       Default is false.
--    5. True if to show weekday name.
--       Default is false.
--
-- RETURN VALUES
-- String, pretty formatted date and time.
-- Something lke this: "12. January 2004 12:58, Tuesday"
--*/
function pretty_format_datetime (sequence date_and_time,
    sequence params)
    --//
    --// Variables:
    --//=>
        sequence real_date_and_time
        sequence dt_date
        sequence dt_time
        sequence now_date
        STRING result --// returned
        bool do_show_year, do_use_relative_day_names
        bool do_use_month_names, do_show_seconds, do_show_weekday
        --// if date is today, tomorrow, yesterday
        bool is_date_humanword
        integer weekday_num
        STRING weekday_name
    --//
    --// Get customization info, params:
    --//=>
        do_show_year = get_member_default (params, 1, DEFAULT, true)
        do_use_relative_day_names = get_member_default (params, 2, DEFAULT, true)
        do_use_month_names = get_member_default (params, 3, DEFAULT, true)
        do_show_seconds = get_member_default (params, 4, DEFAULT, false)
        do_show_weekday = get_member_default (params, 5, DEFAULT, false)        
    --//
    --// Get some data:
    --//=>
        if length (date_and_time) then
            real_date_and_time = date_and_time
        else
            real_date_and_time = nowDateTime ()
        end if
        dt_date = real_date_and_time [DT_DATE]
        dt_time = real_date_and_time [DT_TIME]
        now_date =  nowDate ()
    --//
    --// Date:
    --//=>
        if do_use_relative_day_names then
            if equal (dt_date, now_date) then
                is_date_humanword = true
                result = "Today "
            elsif equal (dt_date, addToDate (now_date, 1)) then
                is_date_humanword = true
                result = "Tomorrow "
            elsif equal (dt_date, addToDate (now_date, -1)) then
                is_date_humanword = true
                result = "Yesterday "
            end if
        else
            is_date_humanword = false
        end if
        if is_date_humanword = false then
            if do_use_month_names then
                result = sprintf ("%d. %s",
                    {dt_date [DAY], get_english_month_name (dt_date [MONTH])})
            else
                result = sprintf ("%d.%d",
                    {dt_date [DAY], dt_date [MONTH]})
            end if
            if do_show_year then
                result &= sprintf (" %d", dt_date [YEAR])
            end if
        end if
    --//
    --// Time:
    --//=>
        if is_date_humanword then
            result &= "at"
        end if
        result &= " " & pretty_format_time (dt_time, {do_show_seconds})
    --//
    --// Weekday:
    --//=>
        if do_show_weekday then 
            weekday_num = dayOfWeek (date_and_time [DT_DATE])
            weekday_name = WEEKDAYS_NAMES [weekday_num]
            result &= ", " & weekday_name
        end if
    return result
end function




--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Local and global routines @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--// returns PROFILER type or 0 if profiler has no parent
function get_parent_profiler (PROFILER profiler)
    PROFID parent_profid
    if length (profiler [PROFILER_PARENTS]) = 0 then
        return 0
    end if
    parent_profid = profiler [PROFILER_PARENTS] [length (profiler [PROFILER_PARENTS])]
    return All_profilers [parent_profid]
end function

--// returns PROFILER type or 0 if profiler has no parent
function get_root_parent_profiler (PROFILER profiler)
    PROFID root_profid
    if length (profiler [PROFILER_PARENTS]) = 0 then
        return 0
    end if
    root_profid = profiler [PROFILER_PARENTS] [1]
    return All_profilers [root_profid]
end function

--// 'comparison_avg_time': -1 if to not compare
--//  else average run time with which to comapre all profilers average run times.
procedure local_write_profile_results (PROFILERS profilers, object out,
    bool do_show_hierarchy, atom comparison_avg_time,
    STRING custom_message)
    STRING filename
    integer fn
    sequence fns
    object cur_out
    PROFILER profiler
    STRING indent_str
    integer indent_size
    object tmp
    PROFILER parent_profiler, root_parent_profiler
    PERCENT percent
    bool is_html
    STRING file_ext, line_break, file_ext_lower
    --//
    --// Get 'indent_size':
    --//=>
        if do_show_hierarchy then
            indent_size = 4 --// TO IMPROVE: add it to params
        else
            indent_size = 0
        end if
    --//
    --// Get 'fns':
    --//=>
        if atom (out) then
            fns = {out}
        else
            fns = repeat (0, length (out))
            for i = 1 to length (out) do
                cur_out = out [i]
                if integer (cur_out) then
                    fn = cur_out
                else
                    filename = cur_out
                    --// rename_if_file_already_exists ()
                    file_ext_lower = lower (get_file_ext (filename))
                    if find (file_ext_lower, {"pro", "htm", "html"}) = 0 then
                        filename &= ".pro"
                    end if
                    fn = open (filename, "w")
                end if
                fns [i] = fn 
            end for
        end if
    --//
    --// Write:
    --//=>
        for j = 1 to length (fns) do
            fn = fns [j]
            --//
            --// Get 'is_html':
            --//=>
                if not integer (out) then
                    if not integer (out [j]) then
                        file_ext = get_file_ext (out [j])
                        is_html = find (file_ext, {"htm", "html"}) != 0
                    else
                        is_html = false
                    end if
                else
                    is_html = false
                end if
            if is_html then
                line_break = "<BR>\n"
            else
                line_break = "\n"
            end if
            if is_html then
                puts (fn, "<HTML><BODY nowrap>\n")
            end if
            puts (fn, "===========================================================================" & line_break)
            puts (fn, "===========================================================================" & line_break)
            printf (fn, "Profiling on %s" & line_break, {pretty_format_datetime ({}, {true, false, true, true, false})})
            if length (custom_message) then
                puts (fn, custom_message & line_break)
            end if
            for i = 1 to length (profilers) do
                profiler = profilers [i]
                if DEBUG then
                    assert (not equal (profiler [PROFILER_NAME], ""))
                end if
                --//
                --// Get 'indent_str':
                --//=>
                    if fn != 1 then
                        if is_html then
                            --// indent_str = repeat_add (repeat_add ("&nbsp;&nbsp;", indent_size),
                                --// length (profiler [PROFILER_PARENTS]))
                        else
                            indent_str = repeat_add (repeat (' ', indent_size),
                                length (profiler [PROFILER_PARENTS]))
                        end if
                    else
                        indent_str = ""
                    end if
                if is_html then
                    puts (fn, repeat_add ("<BLOCKQUOTE>", length (profiler [PROFILER_PARENTS])))
                    puts (fn, "\n")
                end if
                puts (fn, indent_str & "---------------------------------------------------------------------------" & line_break)
                --// printf (fn, indent_str & "%s", {join_with (profiler [PROFILER_PARENTS], "->")})
                --// if length (profiler [PROFILER_PARENTS]) then
                --//     puts (fn, "->")
                --// end if
                --// if equal (indent_str, "") then
                if do_show_hierarchy then
                    printf (fn, indent_str & "%d" & line_break, length (profiler [PROFILER_PARENTS]) + 1)
                end if
                    --// for m = 1 to length (profiler [PROFILER_PARENTS]) do
                    --//     printf (fn, "%d", m + 1)
                    --// end for
                    --// puts (fn, "\n" & line_break)
                --// end if
                printf (fn, indent_str & "%s" & line_break, {profiler [PROFILER_NAME]})
                if profiler [PROFILER_NUM_RUNS] > 0 then
                    printf (fn, indent_str & "Total run time   : %f seconds" & line_break,
                        {profiler [PROFILER_RUNTIME_SUM]})
                    printf (fn, indent_str & "Average run time : %f seconds" & line_break,
                        {profiler [PROFILER_RUNTIME_SUM] / profiler [PROFILER_NUM_RUNS]})
                else
                    puts (fn, indent_str & "Total run time   : N/A" & line_break)
                    puts (fn, indent_str & "Average run time : N/A" & line_break)
                end if
                printf (fn, indent_str & "Times run        : %d" & line_break,
                        {profiler [PROFILER_NUM_RUNS]})
                --//
                --// Write "% of parent":
                --//=>
                    tmp = get_parent_profiler (profiler)
                    if not atom (tmp) then
                        parent_profiler = tmp
                        if parent_profiler [PROFILER_RUNTIME_SUM] then
                            printf (fn, indent_str & "%% of parent      : %d%%" & line_break,
                                {floor (100 * profiler [PROFILER_RUNTIME_SUM] / parent_profiler [PROFILER_RUNTIME_SUM])})
                        else
                            if parent_profiler [PROFILER_NUM_RUNS] = 0 then
                                puts (fn, indent_str & "% of parent      : N/A" & line_break)
                            else
                                puts (fn, indent_str & "% of parent      : 100%" & line_break)
                            end if
                        end if
                    --// else
                        --// puts (fn, indent_str & "% of parent      : N/A" & line_break)
                    end if
                --//
                --// Write "% of root parent":
                --//=>
                    tmp = get_root_parent_profiler (profiler)
                    if not atom (tmp) then
                        root_parent_profiler = tmp
                        if root_parent_profiler [PROFILER_RUNTIME_SUM] then
                            printf (fn, indent_str & "%% of root parent : %d%%" & line_break,
                                {floor (100 * profiler [PROFILER_RUNTIME_SUM] / root_parent_profiler [PROFILER_RUNTIME_SUM])})
                        else
                            if root_parent_profiler [PROFILER_NUM_RUNS] = 0 then
                                puts (fn, indent_str & "% of root parent : N/A" & line_break)
                            else
                                puts (fn, indent_str & "% of root parent : 100%" & line_break)
                            end if
                        end if
                    --// else
                        --// puts (fn, indent_str & "% of parent      : N/A" & line_break)
                    end if
                --//
                --// Write % of xxx:
                --//=>
                    if comparison_avg_time != -1 then
                        if profiler [PROFILER_NUM_RUNS] > 0 then
                            percent = comparison_avg_time / (profiler [PROFILER_RUNTIME_SUM] / profiler [PROFILER_NUM_RUNS])
                            printf (fn, indent_str & "%% of %.9f : %f%%" & line_break,
                                {comparison_avg_time,
                                100 * percent})
                        else
                            printf (fn, indent_str & "%% of %.9f : N/A" & line_break,
                                comparison_avg_time)
                        end if
                    end if
                puts (fn, indent_str & "---------------------------------------------------------------------------" & line_break)
                if is_html then
                    puts (fn, repeat_add ("</BLOCKQUOTE>", length (profiler [PROFILER_PARENTS])))
                    puts (fn, "\n")
                end if
            end for
            puts (fn, "===========================================================================" & line_break)
            puts (fn, "===========================================================================" & line_break & line_break)
            if is_html then
                puts (fn, "</BODY></HTML>\n")
            end if
            flush (fn)
        end for
    --//
    --// Clean up:
    --//=>
        if not atom (out) then
            for i = 1 to length (fns) do
                cur_out = out [i]
                if not integer (cur_out) then
                    close (fns [i])
                end if
            end for
        end if
end procedure

--// gets all children of profiler, including all grand-grand... children.
--// returns PROFILERS
function get_all_children (PROFILER profiler)
    PROFID child_profid
    PROFILER child
    PROFILERS children
    children = {}
    for j = 1 to length (profiler [PROFILER_CHILDREN_IDS]) do
        child_profid = profiler [PROFILER_CHILDREN_IDS] [j]
        child = All_profilers [child_profid]
        children = append (children, child)
        children &= get_all_children (child)
    end for
    return children
end function

--// returns PROFILERS.
--// returns All_profilers, but ordered the way they follow each
--// other in tree from top to bottom.
function get_all_profilers_in_tree_order ()
    PROFILERS all_profilers
    PROFID profid
    PROFILER profiler
    if DEBUG then
        if length (Root_profilers_names) >= 1 then
            assert (length (All_profilers) >= 1)
        else
            assert (length (All_profilers) = 0)
        end if
    end if
    all_profilers = {}
    for i = 1 to length (Root_profilers_ids) do
        profid = Root_profilers_ids [i]
        profiler = All_profilers [profid]
        all_profilers = append (all_profilers, profiler)
        all_profilers &= get_all_children (profiler)
    end for
    return all_profilers
end function

--// Writes (shows) times (results) of all profilers which are set up.
--// 'params': can be empty to use default values.
--//           any value can be also left out or DEFAULT
--//           to use default values.
--//           1. 'out': Where to write.
--//              If atom, then file number.
--//              If sequence, then:
--//              For every member:
--//              - If it is STRING then it should be name of file, 
--//                which will be created and where results will be written.
--//                If file with this name already exists then that file is overwritten.
--//                If file extension is "htm" or "html" then
--//                html page is created. For now it doesn't differ from text file,
--//                but there is potential to add some highlighting etc.
--//              - If it is integer then it should be file number,
--//                same as 1st arg. of puts().
--//              Default is 1 - to write on screen only.
--//           2. 'wait_between'
--//              How many seconds to wait between two writes.
--//              Ie how many seconds should pass
--//              when results are allowed to be written again.
--//              0 to write every time.
--//              atom. Default is 0.
export procedure write_profile_results (sequence params)
    PROFILERS profilers
    object out
    atom wait_between
    if DEBUG then
        assert (length (params) <= 2)
    end if
    wait_between = get_member_default (params, 2, DEFAULT, 0)
    --// show ("wait_between", wait_between)
    --// show ("Last_write_time", Last_write_time)
    --// show ("Last_write_time + wait_between", Last_write_time + wait_between)
    --// show ("time ()", time ())
    --// wait ()
    if wait_between = 0
    or Last_write_time = -1
    or Last_write_time + wait_between < time () then
        --//
        --// Read 'params':
        --//=>
		out = get_member_default (params, 1, DEFAULT, 1)
        profilers = get_all_profilers_in_tree_order ()
        local_write_profile_results (profilers, out, true, -1, "")
        Last_write_time = time ()
    end if
end procedure

public function HRT_results()
	write_profile_results({{"index.esp"}})
	return ""
end function

--// returns: same as measure_routine_speed()
function measure_function_speed (integer rout_id, sequence rout_params, atom bench_time)
-- 	object Void
    integer num_runs
    atom t
    num_runs = 0
    t = time()
    while time() < t + bench_time do
        call_func (rout_id, rout_params)
        num_runs += 1
    end while
    t = time() - t
    return {t, num_runs}
end function

--// returns: same as measure_routine_speed()
function measure_procedure_speed (integer rout_id,
    sequence rout_params, atom bench_time)
    integer num_runs
    atom t
    num_runs = 0
    t = time()
    while time() < t + bench_time do
        call_proc (rout_id, rout_params)
        num_runs += 1
    end while
    t = time() - t
    return {t, num_runs}
end function

--// returns: {total run time, number of runs}
function measure_routine_speed (integer rout_type, integer rout_id,
    sequence rout_params, atom bench_time)
    if rout_type = 1 then
        return measure_function_speed (rout_id, rout_params, bench_time)
    else
        return measure_procedure_speed (rout_id, rout_params, bench_time)
    end if
end function

--// used for sorting
function compare_profilers_speeds (PROFILER profiler1, PROFILER profiler2)
    if profiler1 [PROFILER_NUM_RUNS] != 0
    and profiler2[PROFILER_NUM_RUNS] != 0 then
        return compare (profiler1 [PROFILER_RUNTIME_SUM] / profiler1 [PROFILER_NUM_RUNS],
            profiler2 [PROFILER_RUNTIME_SUM] / profiler2 [PROFILER_NUM_RUNS])
    elsif profiler1 [PROFILER_NUM_RUNS] != 0
    and profiler2[PROFILER_NUM_RUNS] = 0 then
        return 1
    elsif profiler1 [PROFILER_NUM_RUNS] = 0
    and profiler2[PROFILER_NUM_RUNS] != 0 then
        return -1
    elsif profiler1 [PROFILER_NUM_RUNS] = 0
    and profiler2[PROFILER_NUM_RUNS] = 0 then
        return 0
    else assert (false)
    end if
end function

--// procedure shuffle_ram ()
--//     --// sequence s
--//     integer max_size
--//     atom buffer
--//     max_size = floor (megabytes_to_bytes (5))
--//     buffer = allocate (max_size)
--//     for i = 0 to max_size do
--//         poke(buffer+i, rand (1000))
--//     end for
--//     free (buffer)
--//     --// max_size = megabytes_to_bytes (0.5)
--//     --// s = {}
--//     --// while 1 do
--//     --//     if bytes_needed (s) >= max_size then
--//     --//         exit
--//     --//     end if
--//     --//     s = append (s, rand (10000))
--//     --// end while
--// end procedure
--// 
--// procedure empty_procedure ()
--// end procedure

--// gets profiler average run time.
--// returns atom or -1 if not available
function get_profiler_avg_time (PROFILER profiler)
    if profiler [PROFILER_NUM_RUNS] then
        return profiler [PROFILER_RUNTIME_SUM] / profiler [PROFILER_NUM_RUNS]
    else
        return -1
    end if
end function

--/*
-- profile_routines [Created on 31. October 2004, 13:13]
-- The 'profile_routines' procedure 
-- measures speed of routines and compares their speeds.
--
-- PARAMETERS
-- 'one_rout_bench_time'
--    What's the maximal time we should spend on one routine 
--    when profiling it. In seconds.
-- 'out'
--    See write_results().
-- 'routs'
--    Routines to profile. Each member has this structure:
--    1. routine type. 1 = function or type, 2 = procedure
--    2. routine name, string
--    3. routine id
--    4. routine parameters
--*/
export procedure profile_routines (atom one_rout_bench_time, object out, sequence routs)
    sequence routs_data, one_rout_data
    PROFILERS profilers
    PROFILER profiler
    sequence tmp
    atom t
    t = time ()
    puts (1, sprintf ("Profiling %d routines. This will take around %d seconds. Wait...\n",
        {length (routs),
        one_rout_bench_time * length (routs) + 2 * length (routs)}))
    --//
    --// Get 'profilers':
    --//=>
        --//
        --// Get 'routs_data':
        --//=>
            routs_data = {}
            for i = 1 to length (routs) do
                profiler = new_profiler ()
                profiler [PROFILER_NAME] = routs [i] [2]
                routs_data = append (routs_data, append (routs [i], profiler))
            end for
            --// routs_data = Scramble (routs_data)
        --//
        --// Fill 'one_rout_data':
        --//=>
            --// for j = 1 to 2 do
                for i = 1 to length (routs_data) do
                    one_rout_data = routs_data [i]
                    --//
                    --// Run once without measuring speed,
                    --// just so that we get more accurate results,
                    --// ie memory allocating is second time sometimes faster,
                    --// so we will with all functions measure only second run,
                    --// which should give more accurate relations of
                    --// speed between routines.
                    --//=>
                        --// shuffle_ram ()
                        --// Void = measure_routine_speed (2, routine_id ("empty_procedure"),
                        --//     {}, 2)
                        measure_routine_speed (one_rout_data [1], one_rout_data [3],
                            one_rout_data [4], 2)
                    --//
                    --// Now measure speed of routine:
                    --//=>
                        tmp = measure_routine_speed (one_rout_data [1], one_rout_data [3],
                            one_rout_data [4], one_rout_bench_time)
                        --// show ("tmp", tmp)
                        routs_data [i] [5] [PROFILER_RUNTIME_SUM] += tmp [1]
                        routs_data [i] [5] [PROFILER_NUM_RUNS] += tmp [2]
                        --// show ("one_rout_data [5]", one_rout_data [5])
                    --// printf (1, "%d/%d ", {i + (j - 1) * length (routs_data),
                        --// 2 * length (routs_data)})
                    printf (1, "%d/%d ", {i, length (routs_data)})
                end for
                --// routs_data = reverse (routs_data)
            --// end for
            puts (1, "\n")
        --//
        --// Get 'profilers' from 'one_rout_data':
        --//=>
            profilers = {}
            for i = 1 to length (routs_data) do
                profilers = append (profilers, routs_data [i] [5])
            end for
            profilers = custom_sort (routine_id ("compare_profilers_speeds"), profilers)
    --//
    --// Write 'profilers':
    --//=>
        printf (1, "Profiling took %f seconds\n", {time () - t})
        local_write_profile_results (profilers, out, false,
            get_profiler_avg_time (profilers [1]),
            "Profilers are sorted by fastest.")
        puts (1, "Done.\n")
        wait ()
end procedure

--// Put it at start of block of code you want to profile.
--// 'name' has to be uniqeu only among sibling profilers,
--// ie some other profiler can have same name
--// as long as it's not sibling of our profiler,
--// ie profilers with same parent should have different names.
--// At end of block of code put end_profiler(),
--// which should have same 'name'.
-- global procedure start_profiler (STRING name)
public procedure HRT_start(STRING name)
    PROFILER profiler, parent_profiler
    PROFID profid, parent_profid
    integer index
    --//
    --// Get 'profid':
    --//=>
        if length (Inside_profilers_ids) >= 1 then
            parent_profid = Inside_profilers_ids [length (Inside_profilers_ids)]
            parent_profiler = All_profilers [parent_profid]
            index = find (name, parent_profiler [PROFILER_CHILDREN_NAMES])
            if index then
                profid = parent_profiler [PROFILER_CHILDREN_IDS] [index]
            else
                --//
                --// Create new profiler (repeated code):
                --//=>
                    profiler = new_profiler ()
                    profiler [PROFILER_NAME] = name
                    profiler [PROFILER_PARENTS] = Inside_profilers_ids
                    All_profilers = append (All_profilers, profiler)
                    profid = length (All_profilers)
                --//
                --// Update what children has parent profiler:
                --//=>
                    All_profilers [parent_profid] [PROFILER_CHILDREN_NAMES] =
                        append (All_profilers [parent_profid] [PROFILER_CHILDREN_NAMES], name)
                    All_profilers [parent_profid] [PROFILER_CHILDREN_IDS] =
                        append (All_profilers [parent_profid] [PROFILER_CHILDREN_IDS], profid)
            end if
        else --// has no parent, this is root profiler.
            index = find (name, Root_profilers_names)
            if index then
                profid = Root_profilers_ids [index]
            else
                --//
                --// Create new profiler (repeated code):
                --//=>
                    profiler = new_profiler ()
                    profiler [PROFILER_NAME] = name
                    profiler [PROFILER_PARENTS] = Inside_profilers_ids
                    All_profilers = append (All_profilers, profiler)
                    profid = length (All_profilers)
                Root_profilers_names = append (Root_profilers_names, name)
                Root_profilers_ids = append (Root_profilers_ids, profid)
            end if
        end if
    --//
    --// Get 'profiler':
    --//=>
        profiler = All_profilers [profid]
    --//
    --// Error checking and debugging:
    --//=>
        if profiler [PROFILER_STARTTIME] != -1 then
            error (sprintf ("start_profiler() with name \"%s\" was called "
                & "and profile start time is not undefined. "
                & "This means that two start_profiler() with same name exist "
                & "or that end_profiler() with this name wasn't called yet.", {name}))
            return
        end if
        if DEBUG then
            assert (equal (name, profiler [PROFILER_NAME]))
        end if
    --//
    --// Update 'Inside_profilers_ids':
    --//=>
        if DEBUG then
            assert (find (profid, Inside_profilers_ids) = 0)
        end if    
        Inside_profilers_ids = append (Inside_profilers_ids, profid)
    --//
    --// Misc:
    --//=>
        Prev_profid = profid
    --//
    --// Record profile start time:
    --//=>
        All_profilers [profid] [PROFILER_STARTTIME] = time ()
end procedure

--// Put it at end of block of code you want to profile.
--// At start of block of code put start_profiler(),
--// which should have same name.
-- global procedure end_profiler (STRING name)
public procedure HRT_stop( STRING name )
    PROFID profid
    PROFILER profiler
    --//
    --// Error checking:
    --//=>
        if (length (Inside_profilers_ids) = 0) then
            error (sprintf ("end_profiler(\"%s\") was called, "
                & "but it has no start profiler. ",
                {name}))
            return
        end if
    --//
    --// Get 'profid' and 'profiler':
    --//=>
        profid = Inside_profilers_ids [length (Inside_profilers_ids)]
        profiler = All_profilers [profid]
    --//
    --// Error checking:
    --//=>
        if not equal (profiler [PROFILER_NAME], name) then
            show ("profiler [PROFILER_NAME]", profiler [PROFILER_NAME])
            show ("name", name)
            error (sprintf ("end_profiler(\"%s\") was called, "
                    & "but its start profiler is: start_profiler(\"%s\"). "
                    & "Start profiler should have same parameters as end profiler.",
                    {name, profiler [PROFILER_NAME]}))
            return
        end if
        if profiler [PROFILER_STARTTIME] = -1 then
            error (sprintf ("end_profiler(\"%s\") was called, "
                    & "but profiler's start time is undefined. "
                    & "This means that start_profiler() with this name and unique string wasn't called yet.",
                    {name}))
            return
        end if
    --//
    --// Update 'profiler' and save it in 'All_profilers':
    --//=>
        profiler [PROFILER_NUM_RUNS] += 1
        profiler [PROFILER_RUNTIME_SUM] += time () - profiler [PROFILER_STARTTIME]
        profiler [PROFILER_STARTTIME] = -1
        All_profilers [profid] = profiler
    --//
    --// Update 'Inside_profilers_ids':
    --//=>
        if DEBUG then
            assert (equal (Inside_profilers_ids [length (Inside_profilers_ids)], profid))
        end if
        Inside_profilers_ids = Inside_profilers_ids [1 .. length (Inside_profilers_ids) - 1]
end procedure

--// Writes results for the last (previous) profiler.
export procedure write_last_profiler_results (object out)
    PROFILER last_profiler
    if Prev_profid = 0 then
        error ("There's no previous profiler for which to write results.")
    end if
    last_profiler = All_profilers [Prev_profid]
    local_write_profile_results ({last_profiler}, out, false, -1, "")
end procedure

public function HRT_gettime(object o)
atom result
	result = 0.0
	for t=1 to length( All_profilers ) do
		if equal(All_profilers[t][1],o) then
			result = All_profilers[t][3]
		end if
	end for
	return result
end function

public procedure HRT_killtimer(object o) -- remove timer info for a named timer
integer i
	for t=length( All_profilers ) to 1 by -1 do
		i = find( o, All_profilers[t][6] ) -- remove it from parent
		if i > 0 then
			All_profilers[t][6] = remove(All_profilers[t][6],i)
			All_profilers[t][7] = remove(All_profilers[t][7],i)
		end if
		if equal(All_profilers[t][1],o) then
			All_profilers = remove(All_profilers,t)
		end if
	end for
end procedure

procedure init_file ()
    All_profilers = {}
    Root_profilers_names = {}
    Root_profilers_ids = {}
    Last_write_time = -1
    Inside_profilers_ids = {}
    Prev_profid = 0
end procedure

--// Clear profile results,
--// so that if write_profile_results() is called more times
--// same results are not written again.
export procedure clear_profilers ()
    init_file ()
end procedure

init_file ()
