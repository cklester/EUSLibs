




--// TSApp.e
--// Tone Škoda
--// Created on 9. November 2004.
--// Things which are needed in every application.



include std/error.e
include std/filesys.e

include TSError.e
include CType.e





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Copied stuff from other TS library files @@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

constant false = 0, true = 1
object Void

function is_char (object i)
    if not integer (i) then
        return false
    end if
    return i >= -1 and i <= 255
end function

type CHAR (integer i)
    return is_char (i)
end type

type char (integer i)
    return CHAR (i)
end type

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

--/*
-- trim_front [Created on 7. August 2002, 06:35]
-- The 'trim_front' function removes all characters
-- at back of string if they match character you specify.
--
-- Example:
-- "//string//" returns "//string"
--
-- PARAMETERS
-- 's'
--    .
-- 'c'
--    .
--
-- RETURN VALUES
-- .
--*/
function trim_back (STRING s, CHAR c)
    integer i
    i = length (s)
    while 1 do
        if i < 1 then
            exit
        end if
        if s [i] != c then
            exit
        end if
        i -= 1
    end while
    return s [1 .. i]
end function

--/*
-- are_all_spaces [Created on 11. November 2002, 00:29]
-- The 'are_all_spaces' function returns true
-- if all spaces in string are white space characters
-- ('\n', '', or tab).
-- If "" true is also returned.
--
-- PARAMETERS
-- 's'
--    .
--
-- RETURN VALUES
-- .
--*/
global function are_all_spaces (STRING s)
    for i = 1 to length (s) do
        if not isspace (s [i]) then
            return false
        end if
    end for
    return true
end function

function get_file_directory (sequence fname)
	integer c -- current char
	for i = length (fname) to 1 by -1 do
		c = fname [i]
		if c = '\\' or c = '/' then
			return fname [1 .. i - 1]
		elsif c = '.' then
			for j = i - 1 to 1 by -1 do
				c = fname [j]
				if c = '\\' or c = '/' then
					return fname [1 .. j - 1]
				end if
			end for
			return ""
		end if
	end for
	return fname
end function





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Global Routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--/*
-- get_program_directory [Created on 30. September 2001, 15:48]
-- The 'get_program_directory' function returns directory
-- where this program which is run is.
-- It gets it from parsing command line.
--
-- RETURN VALUES
-- Program directory, string. Like this: "C:\Directory"
--
--*/
global function get_program_directory ()
    --// Command line.
    sequence cmd
    --// Program path + name.
    STRING program_full_path
    --// Returned program directory
    STRING program_directory
    cmd = command_line ()
    if length  (cmd) >=  2 then --// Length of command line is long enough.
        program_full_path = cmd [2]
        program_directory = get_file_directory  (program_full_path)
    else                        --// Length of command line is too short.
        --// error ("Can't get program directory from command line.")
        program_directory = ""
    end if
    if are_all_spaces (program_directory) then
    --// Couldn't get program directory from command line.
        program_directory = current_dir()
    end if
    return program_directory
end function

global function get_full_fname (STRING directory, STRING file_name)
    if equal (directory, "") then
        return file_name
    else
        return trim_back (directory, '\\') & "\\" & file_name
    end if
end function

--/*
-- app_init [Created on 28. October 2004, 16:10]
-- The 'app_init' function initializes your program.
-- It does this:
-- It gets directory where your (.exw) program
-- is, it changes current directory to program
-- directory (with chdir) and sets crash file name
-- so that ex.err file is allways created in directory
-- where euphoria execution file is, not in current
-- system directory.
--
-- RETURN VALUES
-- STRING program directory.
--*/
global function app_init ()
    STRING program_directory
    STRING crash_full_file_name
    program_directory = get_program_directory ()
    Void = chdir (program_directory)
    crash_full_file_name = get_full_fname (program_directory, "ex.err")
    crash_file (crash_full_file_name)
    return program_directory
end function
