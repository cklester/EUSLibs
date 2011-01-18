--// TSError.e
--// Tone �koda
--// Created on 27. December 2001.
--// Generic error handling and debugging library.

-- 2008.05.31
--		modifications for integration with BBCMF by c.k.lester

--// TSLibrary include files.
--// include TSTypes.e
--// Standard include files.
--// include msgbox.e as win32msgbox --// Once it caused name collision with win32lib.
include std/pretty.e
-- include std/machine.e
include std/os.e
include std/eds.e
include std/get.e
include std/wildcard.e

with warning
--// without type_check

--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Copied stuff from TSTypes.e @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

constant false = 0, true = 1
object Void

--/*
-- STRING [Created on 6. October 2001, 17:13]
-- The 'STRING' type: every member should be a letter (integer in range 0-255).
--
-- PARAMETERS
-- 's'
--    sequence.
--*/
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
-- bool [Created on 6. October 2001, 17:10]
-- The 'bool' type: type should be 'false' or 'true'.
--
-- PARAMETERS
-- 'i'
--    integer.
--*/
type bool (integer i)
    if i = true or i = false then
        return true
    else
        return false
    end if
end type

--/*
-- BOOL [Created on 27. December 2001, 20:14]
-- The 'BOOL' type.
--
-- PARAMETERS
-- 'i'
--    true or false.
--*/
type BOOL (integer i)
    if i = true or i = false then
        return true
    else
        return false
    end if
end type

--/*
-- is_letter [Created on 22. November 2001, 03:03]
-- The 'is_letter' function returns true if integer is a letter.
--
-- PARAMETERS
-- 'i'
--    Numer to test.
--
-- RETURN VALUES
-- True - It is letter.
--
-- False - It is not letter.
--
--*/
function is_letter (atom a)
    if integer (a) = false or (a < ' ' or a > '}') then --// Not letter.
    --// if integer (a) = false then
        return false
    else                                        --// It is letter!
        return true
    end if
end function

--/*
-- is_string [Created on 9. December 2001, 02:43]
-- The 'is_string' function checks if sequence is string.
--
-- PARAMETERS
-- 's'
--    Sequence to be checked.
--
-- RETURN VALUES
-- If it is string true is returned.
--
-- If it is not string false is returned.
--
--*/
function is_string (object s)
    if not sequence (s) then
        return false
    end if
    for i = 1 to length (s) do
        if sequence (s [i]) = true or is_letter (s [i]) = false then --// Current member of 's' is not atom or letter.
            return false
        end if
    end for
    return true
end function





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Error local variables. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--// True if to report errors to user, false if not.
BOOL Do_report_errors
Do_report_errors = true
--// Used by 'restore_error_reporting ()'.
BOOL Prev_do_report_errors
Prev_do_report_errors = Do_report_errors
--// Id of user defined error routine. If its -1 then use default routine.
integer My_error_routine_id
My_error_routine_id = -1
--// How to report errors:
--// 1 = win32 message box (only valid in win32 programs)
--// 2 = console window
integer Error_mode
Error_mode = 1





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Debug local variables. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

integer Text_file_number
STRING Eds_file_name
--//
--// These integers tell where will debug info will be written/shown.
--//=>
    integer Do_show_on_screen
    integer Do_write_to_file
    integer Do_write_to_database
    Do_show_on_screen = true
    Do_write_to_file = false
    Do_write_to_database = false
    
    
    
    
    
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Copied stuff from TSSeq.e @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function print_format( object o )

    -- returns object formatted for wPrint
    sequence s

    if integer( o ) then
        -- number
		if o >= ' ' and o <= '}' then
			return sprintf( "%d'%s'", {o,o} )
			--return sprintf( "%s", o )
		else			
			return sprintf( "%d", o )
		end if
    elsif atom (o) then --// floating point number
        return sprintf ("%f", o)
    else
        -- list
        s = "{"
        for i = 1 to length( o ) do
            s = s & print_format( o[i] )
            if i < length( o ) then
                s = s & ","
            end if
        end for
        s = s & "}"
        return s
    end if

end function

--// If string it doesn't display ascii characters for it.
function print_format_smart( object o )

    -- returns object formatted for wPrint
    sequence s

    if integer( o ) then
        -- number
		if o >= ' ' and o <= '}' then
			return sprintf( "%d'%s'", {o,o} )
			--return sprintf( "%s", o )
		else			
			return sprintf( "%d", o )
		end if
    elsif atom (o) then --// floating point number
        return sprintf ("%f", o)
    else
        if is_string (o) then
            return "\"" & o & "\""
        else
            -- list
            s = "{"
            for i = 1 to length( o ) do
                s = s & print_format_smart( o[i] )
                if i < length( o ) then
                    s = s & ","
                end if
            end for
            s = s & "}"        
            return s
        end if
    end if

end function





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ message_box.e inlined @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- message_box() function

include std/dll.e
include std/machine.e
include std/console.e

without warning

-- Possible style values for message_box() style sequence
constant 
    MB_ABORTRETRYIGNORE = #02, --  Abort, Retry, Ignore
    MB_APPLMODAL = #00,       -- User must respond before doing something else
    MB_DEFAULT_DESKTOP_ONLY = #20000,    
    MB_DEFBUTTON1 = #00,      -- First button is default button
    MB_DEFBUTTON2 = #100,      -- Second button is default button
    MB_DEFBUTTON3 = #200,      -- Third button is default button
    MB_DEFBUTTON4 = #300,   -- Fourth button is default button
    MB_HELP = #4000,            -- Windows 95: Help button generates help event
    MB_ICONASTERISK = #40,
    MB_ICONERROR = #10, 
    MB_ICONEXCLAMATION = #30, -- Exclamation-point appears in the box
    MB_ICONHAND = MB_ICONERROR,        -- A hand appears
    MB_ICONINFORMATION = MB_ICONASTERISK,-- Lowercase letter i in a circle appears
    MB_ICONQUESTION = #20,    -- A question-mark icon appears
    MB_ICONSTOP = MB_ICONHAND,
    MB_ICONWARNING = MB_ICONEXCLAMATION,
    MB_OK = #00,              -- Message box contains one push button: OK
    MB_OKCANCEL = #01,        -- Message box contains OK and Cancel
    MB_RETRYCANCEL = #05,     -- Message box contains Retry and Cancel
    MB_RIGHT = #80000,        -- Windows 95: The text is right-justified
    MB_RTLREADING = #100000,   -- Windows 95: For Hebrew and Arabic systems
    MB_SERVICE_NOTIFICATION = #40000, -- Windows NT: The caller is a service 
    MB_SETFOREGROUND = #10000,   -- Message box becomes the foreground window 
    MB_SYSTEMMODAL  = #1000,    -- All applications suspended until user responds
    MB_TASKMODAL = #2000,       -- Similar to MB_APPLMODAL 
    MB_YESNO = #04,           -- Message box contains Yes and No
    MB_YESNOCANCEL = #03      -- Message box contains Yes, No, and Cancel

-- possible values returned by MessageBox() 
-- 0 means failure
constant IDABORT = 3,  -- Abort button was selected.
		IDCANCEL = 2, -- Cancel button was selected.
		IDIGNORE = 5, -- Ignore button was selected.
		IDNO = 7,     -- No button was selected.
		IDOK = 1,     -- OK button was selected.
		IDRETRY = 4,  -- Retry button was selected.
		IDYES = 6    -- Yes button was selected.

atom lib
integer msgbox_id, get_active_id

if platform() = WIN32 then
    lib = open_dll("user32.dll")
    msgbox_id = define_c_func(lib, "MessageBoxA", {C_POINTER, C_POINTER, 
						   C_POINTER, C_INT}, C_INT)
    if msgbox_id = -1 then
	puts(2, "couldn't find MessageBoxA\n")
	abort(1)
    end if

    get_active_id = define_c_func(lib, "GetActiveWindow", {}, C_LONG)
    if get_active_id = -1 then
	puts(2, "couldn't find GetActiveWindow\n")
	abort(1)
    end if
end if

function message_box(sequence text, sequence title, object style)
    integer or_style
    atom text_ptr, title_ptr, ret
    
    text_ptr = allocate_string(text)
    if not text_ptr then
	return 0
    end if
    title_ptr = allocate_string(title)
    if not title_ptr then
	free(text_ptr)
	return 0
    end if
    if atom(style) then
	or_style = style
    else
	or_style = 0
	for i = 1 to length(style) do
	    or_style = or_bits(or_style, style[i])
	end for
    end if
    ret = c_func(msgbox_id, {c_func(get_active_id, {}), 
			     text_ptr, title_ptr, or_style})
    free(text_ptr)
    free(title_ptr)
    return ret
end function





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Error local routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

function or_all(sequence s)
-- or together all elements of a sequence
    atom result
    
    result = 0
    for i = 1 to length(s) do
        result = or_bits(result, s[i])
    end for
    return result
end function





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Error global routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--/*
-- error [Created on 30. September 2001, 12:56]
-- The 'error' procedure tells to the user an error which happended in the program.
--
-- PARAMETERS
-- 'in_routine'
--    Name of the Euphoria routine in which error happened. Without braces: ().
-- 'message'
--    Message string to tell.
--*/
global procedure error (STRING message)
    --// Message shown in message box. Different in Debug versus Release mode.
    STRING built_message
    --// Title of error message box.
    STRING message_box_title
    --// User response.
    integer response
    if Do_report_errors = false then
        return
    end if
    if My_error_routine_id != -1 then
    --// Call user defined error routine
        call_proc (My_error_routine_id, {message})
        return
    end if
    built_message = message
    --// if equal (APP_NAME, "") = true then --// 'Application_name' is "".
        message_box_title = "Error"
    --// else                                        --// 'Application_name' is NOT "".
    --//     message_box_title = " Error"
    --// end if
    if platform () != WIN32
    or Error_mode = 2 then
        puts (1, "\n" & message_box_title & ": \n" & built_message & "\n")
        --// if DEBUG then    --//  In debug mode.
            puts (1, "\nPress ESCAPE to abort application,\n    ENTER key to debug\n    or any other key to continue.\n")
        --// else                    --// In release mode.
        --//     puts (1, "\nPress ESCAPE to abort application or any other key to continue.\n")
        --// end if
        response = wait_key ()
        if response = 27 then                                           --// User wants to abort program.
            puts (1, "Aborting...\n")
            sleep (1)
            abort (0)
        --// elsif DEBUG = true and response = 13 then    --// In debug mode and user wants to debug program.
        elsif response = 13 then
            --// --// trace (1)  --// If you have full Euphoria then use trace
            --// ?1/0            --// Use this if you have poublic domain of Euphoria.
        else                                                            --// User wants to continue program.
            puts (1, "Continuing...")
            sleep (1)
            puts (1, "\n")
        end if
        --// TODO:
    elsif platform () = WIN32 then
        --// if DEBUG = true then    --// In debug mode.    
            response = message_box (built_message &
                "\n\n" &
                "Press\n" &
                "  [ YES ]  to continue,\n" &
                "  [ NO ] to debug, or\n" &
                "  [ Cancel ]  to quit.",
                message_box_title, or_all ({MB_ICONEXCLAMATION, MB_YESNOCANCEL}))
            if response = IDCANCEL then --// Exit program.
                --// w32Proc (xExitProcess, {0})
                abort (0)
            elsif response = IDNO then  --// Debug program.
                --// trace (1)  --// If you have full Euphoria then use trace
                ?1/0            --// Use this if you have poublic domain of Euphoria.
            end if
        --// else                    --// Not in debug mode.
        --//     response = message_box (built_message & "\n\nPress Yes to continue, Cancel to abort application.", message_box_title, or_all ({MB_ICONEXCLAMATION, MB_OKCANCEL}))
        --//     if response = IDCANCEL then --// Exit program.
        --//         --// w32Proc (xExitProcess, {0})
        --//         abort (0)
        --//     end if
        --// end if
    end if
end procedure

--/*
-- TS_fatal_error [Created on 26. August 2002, 00:57]
-- The 'TS_fatal_error' procedure should be called when
-- fatal program error happens and program can't continue.
-- Program is terminated.
--
-- PARAMETERS
-- 'message'
--    Message to tell to user.
--*/
global procedure TS_fatal_error (STRING message)
    --// Title of error message box.
    STRING message_box_title
    --// User response.
    integer response
    --// if equal (APP_NAME, "") = true then --// 'Application_name' is "".
        message_box_title = "Fatal Error"
    --// else                                        --// 'Application_name' is NOT "".
    --//     message_box_title = APP_NAME & " Fatal Error"
    --// end if
    if platform () != WIN32 then
        puts (1, "\n" & message_box_title & ": \n" & message & "\n")
        --// if DEBUG then
            puts (1, "Press ENTER to debug, any other key to exit...\n")
        --// else
        --//     puts (1, "Press any key to exit...\n")
        --// end if
        response = wait_key ()
        --// if DEBUG and response = 13 then
        if response = 13 then
            ? 1 / 0
        --// else
        --//     abort (0)
        end if
    elsif platform () = WIN32 then
        --// if DEBUG then
            response = message_box (message &
                "\n\n" &
                "Press\n" &
                "  [ YES ]  to quit, or\n" &
                "  [ NO ] to debug.",
                message_box_title, or_all ({MB_ICONEXCLAMATION, MB_YESNO}))
            if response = IDYES then --// Exit program.
                --// w32Proc (xExitProcess, {0})
                abort (0)
            elsif response = IDNO then  --// Debug program.
                --// trace (1)  --// If you have full Euphoria then use trace
                ?1/0            --// Use this if you have poublic domain of Euphoria.
            end if
        --// else --// Release mode.
        --//     Void = message_box (message &
        --//         "\n\nPress OK to quit.",
        --//         message_box_title, or_all ({MB_ICONEXCLAMATION}))
        --//     abort (0)
        --// end if
    end if
end procedure

--/*
-- turn_error_reporting_off [Created on 27. August 2002, 06:33]
-- The 'turn_error_reporting_off' procedure
-- turns error reporting off.
-- It can be called as many times as you want,
-- to turn off error reporting temporary,
-- for example.
--*/
global procedure turn_error_reporting_off ()
    Prev_do_report_errors = Do_report_errors
    Do_report_errors = false
end procedure

--/*
-- restore_error_reporting [Created on 27. August 2002, 06:38]
-- The 'restore_error_reporting' procedure resets
-- error reporting to the state it was before
-- last call to 'turn_error_reporting_off ()'
-- or 'turn_error_reporting_on ()'.
--*/
global procedure restore_error_reporting ()
    Do_report_errors = Prev_do_report_errors
end procedure

--/*
-- turn_error_reporting_on [Created on 27. August 2002, 06:33]
-- The 'turn_error_reporting_on' procedure 
-- turns error reporting on.
-- It can be called as many times as you want.
--*/
global procedure turn_error_reporting_on ()
    Prev_do_report_errors = Do_report_errors
    Do_report_errors = true
end procedure

--/*
-- set_error_routine [Created on 25. December 2002, 23:56]
-- The 'set_error_routine' procedure sets which
-- routine should be called when any 'error ()'
-- routine was called in any library file.
-- Use 'restore_default_error_routine ()'
-- to restore default error routine.
--
-- PARAMETERS
-- 'error_routineid'
--    Id of error routine.
--    It should have this format:
--    procedure (STRING error_message)
--*/
global procedure set_error_routine (integer error_routineid)
    My_error_routine_id = error_routineid
end procedure

--/*
-- restore_default_error_routine [Created on 25. December 2002, 23:56]
-- The 'restore_default_error_routine' procedure resets default
-- error routine, if it was set by 'set_error_routine ()'.
--*/
global procedure restore_default_error_routine ()
    My_error_routine_id = -1
end procedure

--/*
-- set_error_mode [Created on 9. November 2004, 18:48]
-- The 'set_error_mode' procedure 
-- sets how erros will be reported
--
-- PARAMETERS
-- 'error_mode'
--    1 = win32 message box (only valid in win32 programs)
--    2 = console window
--*/
global procedure set_error_mode (integer error_mode)
    Error_mode = error_mode
end procedure





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Debug local routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

--/*
-- db_create_or_open_safe [Created on 29. December 2001, 01:22]
-- The 'db_create_or_open_safe' function opens database file if it exists.
-- If it doesn't exist it tries to create new file.
-- If that also fails error message box is displayed.
--
-- PARAMETERS
-- 'filename'
--    File name of database to open.
-- 'lock'
--    Same as with 'db_create ()'.
--
--*/
procedure db_create_or_open_safe (STRING filename, integer lock)
    --// Result of 'db_open ()'.
    integer fn_open
    --// Result of 'db_create ()'.
    integer fn_create
    fn_open = db_open (filename, lock)
    if fn_open != DB_OK then --// Couldn't open
        fn_create = db_create (filename, lock)
        if fn_create != DB_OK then --// Couldn't create.
            error ("Couldn't open or create database file \"" & filename & "\".")
        end if
    end if
end procedure

procedure db_insert_safe (object key, object data)
    --// Return value of 'db_insert ()'.
    integer success 
    success = db_insert (key, data)
    if success != DB_OK then
        if success = DB_EXISTS_ALREADY then
            error ("Inserting new record into database failed. Key " & print_format (key) & " already exists in current table.")
        else
            error ("Inserting new record into database failed.")
        end if
    end if
end procedure

procedure db_select_safe (STRING name)
    if db_select (name) != DB_OK then
        error ("Selecting database " & name & " failed.")
    end if
end procedure

procedure db_select_table_safe (STRING name)
    if db_select_table (name) != DB_OK then
        error ("Selecting table " & name & " in database failed.")
    end if
end procedure

procedure puts1 (sequence s)
    puts (1, s & "\n")
end procedure





--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@ Debug global routines. @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

global procedure wait ()
    integer key
    key = wait_key ()
    if key = 27 then --// escape character
        abort (0)
    end if
    puts1 ("")
end procedure

--// wait and tell user to press a key
global procedure wait_tell ()
    puts (1, "Press any key to continue, ESC to exit...\n")
    wait ()
end procedure

--/*
-- assert [Created on 29. November 2001, 19:35]
-- The 'assert' procedure is similar to C's assert ().
-- If its parameter is not true error message box is displayed.
-- Use it to test for program errors.
-- Should only be called if DEBUG is true.
--
-- PARAMETERS
-- 'better_be_true'
--    If it is true nothing happens.
--    If it is false then error message box is displayed.
--*/
global procedure assert (integer better_be_true)    
    integer old_error_mode
    --// if DEBUG = false then
    --//     puts (1, "assert() should be called only if DEBUG is true.")
    --// end if
    --// if DEBUG then
	    if better_be_true = false then --// Program error.
            old_error_mode = Error_mode
            Error_mode = 2
            error ("ASSERT!!! There's a bug in program. Assert was called.")
            Error_mode = old_error_mode
	    end if
    --// end if
end procedure

--/*
-- assert2 [Created on 29. November 2001, 19:35]
-- The 'assert2' procedure is similar to C's assert ().
-- If two parameters are not equal it displays warning message.
-- Use it to test for program errors.
--
-- PARAMETERS
-- 'better_be_true'
--    If it is true nothing happens.
--    If it is false then error message box is displayed.
--*/
global procedure assert2 (object o1, object o2)    
    --// if DEBUG then
	    if not equal (o1, o2) then
            error ("ASSERT2!!!\n"
                & "There's a bug in program. Assert was called:\n"
                & print_format_smart (o1) & " != " & print_format_smart (o2))
	    end if
    --// end if
end procedure

--/*
-- show [Created on 6. December 2001, 16:01]
-- The 'show' procedure shows Euphoria object in output.
--
-- PARAMETERS
-- 'name'
--    Name for variable.
-- 'o'
--    Value of variable, euphoria object to be shown.
--
-- EXAMPLE
--
-- Ussualy you would use this routine like this:
-- show ("var_name", var_name)
-- so it's good to automate this process in 
-- you editor with macro so that you just press one hotkey
-- and it displays you inputbox where you input name of your 
-- variable and then it automatically generates call for this function.
--*/
global procedure show (STRING name, object o)
    STRING prev_database_name
    --//
    --// Show on screen :
    --//=>
        if Do_show_on_screen then    
            --// printf (1, "%s = %s\n", {name, print_format_smart (o)})
            puts (1, name & " = ")
            pretty_print (1, o, {2})
            puts (1, "\n")
        end if
    --//
    --// Write to text file:
    --//=>
        if Do_write_to_file then
            --// printf (Text_file_number, "%s = %s\n", {name, print_format_smart (o)})
            puts (Text_file_number, name & " = ")
            pretty_print (Text_file_number, o, {2})
            puts (1, "\n")
        end if
    --//
    --// Write to database:
    --//=>
        if Do_write_to_database then
            prev_database_name = db_current ()
            db_select_safe (Eds_file_name)
            db_select_table_safe ("Misc")
            db_insert_safe (name & " (id=" & sprintf ("%f", time ()) & ")" , o)
            --// Void = db_insert (name, o)
            if length (prev_database_name) then
            --// There was previous database which we need to select back.
                db_select_safe (prev_database_name)
            end if
        end if
end procedure

--// show () and wait ()
global procedure showw (STRING name, object o)
    show (name, o)
    wait ()
end procedure

--/*
-- blankln [Created on 6. December 2001, 16:24]
-- The 'blankln' procedure puts one blank line to output.
--*/
global procedure blankln ()
    if Do_show_on_screen then
        printf (1, "%s", "\n")
    end if
    if Do_write_to_file then
        printf (Text_file_number, "%s", "\n")
    end if
end procedure

--/*
-- assert_if_members_not_equal [Created on 6. December 2001, 14:37]
-- The 'assert_if_members_not_equal' procedure checks if members of a sequence 
-- are all same. If they are not error message is displayed.
--
-- PARAMETERS
-- 's'
--    Sequence with members which should all be the same.
--*/
global procedure assert_if_members_not_equal (sequence s)
    --// Compare each member with each member.
    --// This is rather slow but it's perfect.
    for i = 1 to length (s) do
        for j = 1 to length (s) do
            if equal (s [i], s [j]) = false then
                error ("Members of sequence " & print_format_smart (s) & " are not equal.\n" &
                    print_format_smart (s [i]) & " is not " & print_format_smart (s [j]) & ".")
            end if
        end for
    end for
end procedure

--/*
-- test_function [Created on 28. August 2002, 05:01]
-- The 'test_function' procedure is used to test new functions
-- you write, to debug them.
-- 
-- You tell it for what parameters
-- passed to tested functions should return what
-- results, and this function evaluates that.
-- It shows you results and alerts if result
-- is not equal to what you told it it must be.
--
-- At end it aborts program.
--
-- Put this function directly under newly
-- written routine. When you know that your new
-- function works correct comment out debug code
-- which you put below your function.
--
-- PARAMETERS
-- 'routineid'
--    Id of routine you wish to test/debug.
-- 'benchmark'
--    If it's zero then we simply debug function.
--    If it's not zero we benchmark function,
--    we run it for this many times, with each example set.
-- 'params_and_results'
--    Parameters and expected results for the parameters
--    tested function should return.
--    Each member should have this format:
--    1. sequence with parameters, should have lenght 
--       equal to number of arguments
--       that tested function takes.
--    2. object, result you expect for given parameters.
--
-- EXAMPLE
-- test_function (routine_id ("power"),
--     {
--         -- arguments and result 1
--          {
--              -- arguments
--              {
--                  -- argument 1
--                  3,
--                  -- argument 2
--                  2
--              },
--              -- result
--              9
--           },
--         -- arguments and result 2
--          {
--              -- arguments
--              {
--                  -- argument 1
--                  8,
--                  -- argument 2
--                  2
--              },
--              -- result
--              64
--           }
--     })
--*/
global procedure test_function (integer routineid,
    integer benchmark, sequence params_and_results)
    sequence params
    object expected_result, real_result
    atom time1, time2
    if benchmark then
    --// We are going to benchmark the function.
        printf (1, "Benchmarking %d times...\n", length (params_and_results) * benchmark)
        time1 = time ()
        for benchmark_num = 1 to benchmark do
            for i = 1 to length (params_and_results) do
                params = params_and_results [i] [1]
                expected_result = params_and_results [i] [2]
                Void = call_func (routineid, params)
            end for
        end for
        time2 = time ()
        printf (1, "\n%f seconds\n%f average\n\nPress any key to exit...\n",
            {
            time2 - time1,
            (time2 - time1) / (length (params_and_results) * benchmark)
            })
        wait ()
        abort (0)
    else
    --// We are going to debug the function.
        for i = 1 to length (params_and_results) do
            params = params_and_results [i] [1]
            expected_result = params_and_results [i] [2]
            real_result = call_func (routineid, params)
            show ("params", params)
            show ("expected_result", expected_result)
            if sequence (expected_result) then
                printf (1, "Length is %d\n\n", length (expected_result))
            end if
            show ("real_result    ", real_result)
            if sequence (real_result) then
                printf (1, "Length is %d\n\n", length (real_result))
            end if
            blankln ()
            if (equal (real_result, expected_result) = 0) then
                puts (1, "Function failed at member "
                    & sprintf ("%d", i) & "\n")
                wait_tell ()
            end if
        end for
        puts (1, "Function works correct.\nPress any key to quit...\n")
        wait ()
        abort (0)
    end if
end procedure
--//
--// Test for 'test_function()':
--//=>
    --// function test_sum (integer a, integer b)
    --//     return a + b
    --// end function
    --// test_function (routine_id ("test_sum"), 
    --//     {
    --//         {
    --//             {1, 2},
    --//             3
    --//         },
    --//         {
    --//             {10, 5},
    --//             15
    --//         },
    --//         {
    --//             {4, 8},
    --//             12
    --//         },
    --//         {
    --//             {1, 1}, --// intentionally make it wrong
    --//             2
    --//         }
    --//     }
    --//     )
--/*
-- set_debug_params [Created on 29. December 2001, 00:39]
-- The 'set_debug_params' procedure sets some parameters in for debug functions.
-- It is not neccessary to call it. You can call it as many times as you want.
--
-- PARAMETERS
-- 'do_show_on_screen'
--    If to show debug info on screen in console window.
--    This is true by default.
-- 'text_file'
--    If to write debug info to text file.
--    - If this is sequence then it should be full file name.
--      If file exists it is overwritten.
--   -  If this is integer then:
--      If it is 0 then no writing to text file
--      else it should be file number.
--    This is 0 by default.
-- 'database_file'
--    If to write debug info to edb file.
--    If it is atom then no writing to database file.
--    If it is sequence then it should be full file name
--    of database file. If file already exists it is not overwritten.
--    This is 0 by default.
--*/
global procedure set_debug_params (bool do_show_on_screen, object text_file,
    object database_file)
    Do_show_on_screen = do_show_on_screen
    --//
    --// Text file:
    --//=>
        if integer (text_file) then
            if text_file > 0 then
                Text_file_number = text_file
                Do_write_to_file = true
            else
                Do_write_to_file = false
            end if
        elsif sequence (text_file) then
            Do_write_to_file = true
            if Do_write_to_file then
                Text_file_number = open (text_file, "w")
            end if
        end if
    --//
    --// Database file:
    --//=>
        if integer (database_file) then
            Do_write_to_database = false
        elsif sequence (database_file) then
            Do_write_to_database = true
            Eds_file_name = database_file
            db_create_or_open_safe (Eds_file_name, DB_LOCK_NO)
            db_delete_table ("Misc")
            Void = db_create_table ("Misc")
        end if
    --// --//
    --// --// Display warnings:
    --// --//=>
    --//     if Do_show_on_screen = false then
    --//         puts (1, "Debug Library Warning: debug variables won't be shown on screen, only written to files.\n")
    --//     end if
end procedure
