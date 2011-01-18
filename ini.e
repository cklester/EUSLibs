--------------------------
--            ini.e            
--------------------------

-- This code will manage an ini file in a very easy-to-use manner. For small ini files
-- it is probably (much) better than standard MS functions because it is so much more comprehensive
-- and it allows the pre-defined data types to be created/retrieved at will without any
-- annoying intermediate processing step. 

-- Basically, this code provides a powerful way to access ini files and the user does not
-- have to worry about the ini file itself because all parsing, whitespace issues bla la blah
-- have been dealt with. The only real concern the application writer should have is that
-- they use the correct name to access either Groups of Elements, otherwise the program
-- will complain. Other than that it will not matter if an ini file is accidentally deleted,
-- trashed or corrupted because the very next program shutdown will renew the data,
-- albeit using default values. If an ini file was corrupted then what data could be salvaged
-- ..would be. Also, if a user wants to manually edit an ini file and doesn't know the correct
-- whitespace format that too will not matter because this code will take care of it such things.

-- Errors: If the user makes a mistake with accessing either Groups or Elements this code
-- will crash (see halt() for details). This is not really a problem because of the cyclical
-- nature of ini use. If a typing mistake by the user exists then the code will crash on the
-- first run because the load/modify/save cycle forces an implicit verification of all
-- entries, be they Groups or Elements. Another sort of error could happen where an illegal
-- data type is set and, because of the nature of Euphoria, might not be detected straight
-- away. This is a highly unlikely situation and indicates a fatal user programming mistake.
-- Perhaps someone can suggest a way to deal with such a latent effect. The only routine involved
-- is setValue(). Possibly a global variable could be created to flag instances of such errors
-- and the user would need to check it periodically ...

-- Errors (cont): If the initialization & shutdown code is encapsulated in 2 routines (see below)
-- then it is childs play to locate user ini-programming errors, if any.

-- I note that the INT & SEQ constants are common to Derek Parnell's
-- Structure library (dStruct.e)
-- *and* have identical values so compatibility will not be a problem.

-- Please feel free to offer any suggestions as to how improvements can be made to this file.
-- Bug reports are <ahem> always welcomed.

-- Mike
-- vulcan@win.co.nz

-- 10th July 2002

---------------------
-- INTRODUCTION
---------------------
-- There are 2 categories of lines in the ini file: Groups and Entries

-- A Group heading is the name of particular set of entries and is defined by
-- bracketed text, eg:

-- [dummy group]

-- NB: Whitespace is allowed *within* the name of a group

-- Elements (entries) within groups are defined as:

-- heading = data

-- ..here are 3 representative examples..

-- My fav book = Wind in the willows
-- isMainMax = 1
-- window size = 600, 400

-- The only exception to this Element format are variable length text lists and these are described shortly.

-- The heading part of an Element is any name you want except it should be unique
-- amongst the other names in that particular Group. It too can have whitespace *within* the name.

-- The data part of an Element entry can be:
-- an integer (with or without sign),
-- or a boolean value 0 or 1,
-- or a string of TWO OR MORE integers separated by commas( whitespace ignored)
-- or plain text, eg:

-- variable x = 1234
-- auto complete mode = 1
-- window pos = 1,1, 300 ,200
-- param string = c:\rds\bin\ed.e

-- NB: if the 'text' consists of digits (and separators) then it will be
-- interpreted as an integer or string of integers

-- Variable length text lists are also possible. Basically these are made
-- of a special type of element which consist only of text data and access to them
-- is via setTextValue() & getTextValues(). I think probably these should have
-- their own group. These Elements do not need to be defined unlike those that you
-- attach a TYPE specifier to (usually the case). Below is an example
-- of a group with such elements:

-- [previous session files]
-- c:\euphoria\bin\ed.ex
-- c:\euphoria\project\enh_ed.ex
-- c:\borland\prj\crash_ms.cpp


-- NB: Any whitespace on the ends of text or headings or even ascii text lists are removed
-- Eu-type comments can be put anywhere (manually) but will be viewed as part of the closest
-- preceding group declaration in the ini file. Any comments that precede the
-- first group declaration will stay in that area. Any group with all redundant entries
-- in it will be removed.
-- Any non-ascii lines (OR BLANK LINES)loaded in will be ignored (dumped).

-- There are a few restrictions for group & entry names:
--    (i)   Each group name must be unique amongst the other group names
--    (ii)  An entry name must be unique amongst the other entry names within it's group
--    (iii) Whitespace on the ends of any group or entry name are removed
--    (iv)  Whitespace within the bounds of a name are retained

        --=======
        -- TO USE
        --=======
-- I think the best way to use ini.e is to follow this formula:

-- A. Put this line near the start of the program (and each object file that requires ini access)
-- include ini.e as ini

-- NB: It is not necessary to have a namespace qualifier but it probably is a good idea

-- B. Load the desired ini file with:
-- loadIniFile("my_prog.ini")

-- NB: if no file name is given ini.e will assume a name, see below for details

-- C. Make an initializing routine somewhere which can be called during your program initialization stage.

--     global procedure loadIniSettings()

--     -- i) make group definition heading
--     ini:defineGroup("hi scores")

--     -- ii) define Elements for this group
--     ini:defineElements("Highest Score #1", INT) -- note TYPE specifiers
--     ini:defineElements("Highest Score #2", INT)
--     ini:defineElements("Highest Score #3", INT)

--     -- iii) initialize local variables and populate Elements with the default data
--     -- If ini file exists then the prev saved data will be returned, not default values
--        hi_score1 = ini:getValue("Highest Score #1", 0) -- [note default values]
--        hi_score2 = ini:getValue("Highest Score #2", 0)
--        hi_score = ini:getValue("Highest Score #3", 0)

         -- iv) start next group definition here
--        end procedure

-- NB: Stages A. and B. could be amalgamated with stage C. if desired.
-- If more than 1 group is to be defined & initialized then it can be done
-- so long as each 'clump' (comprising stages i to iii) relates to the same group.
-- In the above example a new group definition would start at iv.

-- D. Make a routine to store the local variables that you use in your program to
-- the ini entries as previously defined. This is usually done near the program end (shutdown)

--     procedure store_hi_scores()

--     changeGroup("hi scores") -- This line is only needed where more than 1 group has been defined
--        ini:setValue("Highest Score #1", hi_score1)
--        ini:setValue("Highest Score #2", hi_score2)
--        ini:setValue("Highest Score #3", hi_score3)
    
--     end procedure

-- E. Now, finally, write the ini file to disk (no name is needed) when your program
-- shuts down using saveIniFile(). This routine call could be amalgamated with stage D. in
-- a lightweight application.

-- When the program is run the next time then the ini structure will
-- be populated with the groups, elements & values and a call to getValue() will
-- retrieve the saved items and ignore any default values


-- Further usage notes:
-- Access to/from the ini can be spread around several object files in an app but
-- when the saveIniFile() routine is invoked only one object should do this because the whole ini structure is saved.
-- When loadIniFile() is invoked it will use whatever pathname is given. But,
-- if no target file is named then the name of the disk ini file to be read is deemed to be the same as
-- the executable program (I stole this idea from ee:cs Hehehe...)
-- so, "editor.exw" will have "editor.ini" created etc..
-- Comments (EU-style) can only be externally edited into the *.ini file but they will remain there over each execution cycle.
-- The lines in the ini file are re-written during each save so any group or entry names can be edited in the
-- object/program file with impunity and the ini system will absorb these while quietly disposing
-- of the redundant names - very clever methinks!
-- Decimal values (eg, ATOM) are not allowed as a native ini type but could be implemented using the TEXT type specifier. This
-- would mean the application has to check the numerical format and convert the returned text string to an atomic value.
-- Multi-dimensional Euphoria sequences are also not allowed as a native type but a user
-- could still capture them by using setTextValue() & getTextValues() which deal with *single* lines
-- of random text. Some user processing must then be done to import this into the application as a true sequence.
-- When an entry is initially defined, a flag is added to specify what TYPE of value will be set into it
-- and if an attempt is made to set the value using illegal data then ini.e will !!crash!!
-- thereby alerting the programmer to correct the situation
-- An entry defined as SEQ must have 2 or more integer elements but the calling routine
-- should check that the length of the retrieved sequence is correct because ini.e will not know if it is or not.
-- Some routines could probably benefit by having an error code returned. Feel free to modify this library etc..
-- When a call to loafIniFile() is made then the data structure (if any)held by ini.e will
-- be reset to blankness. This means only one ini file should be accessed in its open/modify/close cycle.
-- Other ini files can be then be accessed the same way, one at a time.
-- Whitespace formatting of *.ini is done automatically, pretty!

include std/filesys.e
include std/os.e

--- data types
global constant
    BOOL = 1, -- boolean type 0 or 1
    INT = 2, -- integer
    SEQ = 3, -- sequence of integers
    TEXT = 4  -- string of text
constant
    ASC = 5, -- text line (used for variable length 'pure' text lists/lines)
    COM = 6, -- comment
    GRP = 7  -- group

-- Attribute lists
sequence
    DATATYPE,
    HEADING,
    RESFLAG,
    VALUE,
    RAWLINE

-- keep track of ini file name
sequence completeinipath

procedure resetIniLists()
    DATATYPE = {}
    HEADING = {}
    RESFLAG = {}
    VALUE = {}
    RAWLINE = {}

    completeinipath = {}
    end procedure


-- keep track of current group & entry
integer
    currententry,
    groupstart,
    groupend

    currententry = 0
    groupstart = 0
    groupend = 0



procedure halt()
--This routine is called at those palces where some error has happened because..
    -- The application writer has used the wrong name to access a Group or Element OR
    -- attempting to set an illegal value to an Element OR
    -- attempting to retrieve a value previously saved but the default value is an illegal type OR
    -- (finally) in a couple of places this code might have caused the crash because of an
    -- internal corruption
    
    ? 9/0
    end procedure


type isLetter(integer c)
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')
    end type

type isNumber(integer c)
    return c >= '0' and c <= '9'
    end type

type isWhiteSpace(integer c)
    return c = ' ' or c = '\t' or c = '\n'
    end type

type isArithmeticSign(integer c)
    return c = '-' or c = '+'
    end type

type isTitleChar(integer c)
    return isLetter(c) or isNumber(c) or c = ' ' or c = '_'
    end type

function splitTitleAndData(sequence line)
    integer e, len

    len = length(line)
    e = find('=', line)

    if e then
        for i = 1 to e do
            if not isTitleChar(line[i]) then
                exit
            end if
        end for
        return { line[1..e-1], line[e+1..len] }
    end if

    return { {}, line }

    end function

function allNumbersAndSeparators(sequence line)
    integer c
    for i = 1 to length(line) do
        c = line[i]
        if not (isArithmeticSign(c) or isNumber(c) or c = ',' or isWhiteSpace(c)) then
            return 0    
        end if
    end for
    return 1
    end function


function allAsciiValues(sequence line)
    integer c
    for i = 1 to length(line) do
        c = line[i]
        if not ( (c >= ' ' and c <= 127)  or  ( c='\t' or c='\n' ) ) then
            return 0    
        end if
    end for
    return 1    
    end function    


function convertTextNumberToInteger(sequence number)
    integer r, len, pwr, c, neg
    sequence s

    neg = 0
    pwr = 1

    -- remove any sign symbols
    s = ""
    for i = 1 to length(number) do
        if isArithmeticSign(number[i]) then
            if number[i] = '-' then
                neg = 1
            end if
        else
            s &= number[i]
        end if
    end for
    number = s
        
    len = length(number)
    r = number[len] - '0'

    -- calculate number
    for i = len-1 to 1 by -1 do
        c = number[i]
        pwr *= 10
        r += (c - '0') * pwr
    end for

    -- take care of negative number
    if neg then
        r = 0 - r
    end if

    -- exit
    return r
    end function

function removeEndWhiteSpace(sequence line)
    integer len, a, b

    len = length(line)

    if not len then
        return line
    end if

    a = 0
    b = 0

    -- establish first non-whitespace char
    for i = 1 to len do
        if not isWhiteSpace( line[i] ) then
            a = i
            exit
        end if
    end for

    -- exit if all whitespace
    if a = 0 then
        return {}
    end if

    -- establish last non-whitespace char
    for i = len to 1 by -1 do
        if not isWhiteSpace( line[i] ) then
            b = i
            exit
        end if
    end for

    return line[a .. b]

    end function


function removeAllWhiteSpace(sequence line)
    sequence s
    integer c

    s = {}

    for i = 1 to length(line) do
        c = line[i]
        if not isWhiteSpace(c) then
            s &= c
        end if
    end for

    return s
    end function


function extractDataValue(sequence line)
    sequence result, number
    integer char

    result = {}
    number = {}

    -- remove any whitespace
    line = removeAllWhiteSpace( line )

    -- accumulate number chars and convert at each separator
    for i = 1 to length(line) do
        char = line[i]
        if char = ',' then -- separator found
            if length(number) then -- ok, convert to integer
                result &= convertTextNumberToInteger(number)
                number = {}
            end if
        elsif isNumber(char) or isArithmeticSign(char) then
            number &= char
        else -- error, oops, my code did this, sorry! Please send me a bug report, Thanks.
            halt()
        end if
    end for

    -- tidy last piece
    if length(number) then -- ok, convert to integer
        result &= convertTextNumberToInteger(number)
    end if

    -- return integer if only one numeric element
    if length(result) = 1 then
        return result[1]
    end if

    return result

    end function


function parseLine(sequence line) -- returns {type, data [, title]}
    integer len
    sequence junk, heading
    object data

    -- prepare line
    line = removeEndWhiteSpace(line)
    len = length(line)

    -- corrupted line?
    if not allAsciiValues(line) or len = 0 then
        return 0
    end if

    -- group line?
    if line[1] = '[' then
        if line[len] = ']' then
            junk = line[2 .. len - 1]
            junk = removeEndWhiteSpace(junk)
            if equal("", junk) then
                return 0
            else
                return { GRP, junk, 0, {} }
            end if
        else -- corrupted line
            return { ASC, {}, 0, line }    
        end if
    end if

    -- comment line?
    if len > 1 then
        if equal(line[1..2], "--") then
            return { COM, line, 1, line }
        end if
    end if

    -- can we split title from data?
    junk = splitTitleAndData(line)
    heading = removeEndWhiteSpace( junk[1] )
    line = removeEndWhiteSpace( junk[2] )

    -- if no title then assume line is ascii
    if equal("", heading) then
        if equal("", line) then
            return 0
        else
            return {ASC, {}, 0, line }
        end if
    end if

    -- now, deal to 'assignment' lines
    if allNumbersAndSeparators(line) then -- integer or string of integers
        data = extractDataValue(line)
        if integer(data) then
            return { INT, heading, 0, data }
        elsif sequence(data) then
            return { SEQ, heading, 0, data }
        end if

    else 
        return { TEXT, heading, 0, line }

    end if

    end function

function checkData(integer vEntry, object value)
    integer flag

    flag = DATATYPE[vEntry]

    if flag = BOOL then
        if integer(value) and (value = 1 or value = 0) then
            return 1
        end if

    elsif flag = INT then
        if integer(value) then
            return 1
        end if

    elsif flag = SEQ then
        if sequence(value) and length(value) >= 2 then
            return 1
        end if
    elsif flag = TEXT then
        if sequence(value) and length(value) >= 0 then
            return 1
        end if

    else -- flag = ASC
        return 1

    end if

    return 0

    end function

function getWriteString(integer vEntry)
    integer flag
    object value
    sequence result

    flag = DATATYPE[vEntry]
    value = VALUE[vEntry]

    if flag < ASC then
        result = "  " & HEADING[vEntry] & " = "
    end if

    if flag <= INT then -- covers BOOL as well
        result &= sprintf("%d", value)

    elsif flag = SEQ then
        for i = 1 to length(value) do
            result &= sprintf("%d", value[i])
            if i < length(value) then
                result &= ", "
            end if
        end for

    elsif flag = TEXT then
        result &= value

    elsif flag = ASC then
        result = "  " & value

    elsif flag = COM then
        result = value

    elsif flag = GRP then
        result = "[" & HEADING[vEntry] & "]"

    else -- oops, my code has failed. Please send a full bug report.
        halt()

    end if

    return result
    end function


procedure set_groupend()
    groupend = length(DATATYPE)
    for i = groupstart+1 to length(DATATYPE) do
        if DATATYPE[i] = GRP then
            groupend = i-1
            return
        end if
    end for
    end procedure


function findGroup(sequence groupname)
    for i = 1 to length(DATATYPE) do
        if DATATYPE[i] = GRP then
            if equal( groupname, HEADING[i] ) then
                return i
            end if
        end if
    end for
    return 0
    end function


function findEntry(sequence entryname) -- from the current group find the entry
    set_groupend()
    for i = groupstart+1 to groupend do
        if equal( entryname, HEADING[i] ) then
            return i
        end if
    end for
    return -1 - groupend
    end function

function findGroupOwner(integer vEntry)
    for i = vEntry-1 to 1 by -1 do
        if DATATYPE[i] = GRP then
            return i
        end if
    end for
    return vEntry -- this line will occur where a comment precedes the first group
    end function

procedure insertBlankEntry(integer insert)
    integer len

    DATATYPE &= 0
    HEADING &= 0
    RESFLAG &= 0
    VALUE &= 0
    len = length(DATATYPE)

    -- move entries beyond insertion point along 1
    DATATYPE[insert + 1 .. len] = DATATYPE[insert .. len - 1]
    HEADING[insert + 1 .. len] = HEADING[insert .. len - 1]
    RESFLAG[insert + 1 .. len] = RESFLAG[insert .. len - 1]
    VALUE[insert + 1 .. len] = VALUE[insert .. len - 1]

    end procedure

procedure setEntry
(integer insert, integer datatype, sequence heading, integer flag, object val)
    DATATYPE[insert] = datatype
    HEADING[insert] = heading
    RESFLAG[insert] = flag
    VALUE[insert] = val
    end procedure


global procedure changeGroup( object group )

-- The relationship between Groups and Elements is simple. Groups are like folders 
-- and Elements are like files within the folder. No sub-groups are available but in
-- 99% of cases this will probably not be a problem. This library uses the concept
-- of a current Group (EDB uses a similar idea with it's current database). Only where more
-- than one Group is defined will it be necessary to change the current Group before
-- performing any Element accesses. This routine simply changes the pointer to the new
-- current Group.
    if sequence(group) then
        group = findGroup(group)
        if group = 0 then
            halt()
        end if
    elsif DATATYPE[group] != GRP then
        halt()
    end if

    groupstart = group
    set_groupend()

    end procedure


procedure resolveEntry(integer vEntry)
    RESFLAG[vEntry] = 1
    RESFLAG[groupstart] = 1
    end procedure

global procedure defineGroup(sequence groupname)
    integer grp

-- This routine will create a Group entry that can then have Elements defined in it.
-- NB: The new Group defined becomes the current Group and so it will not be
-- necessary to invoke changeGroup() even if you are working with more than one Group. 

    -- test grp already exists
    grp = findGroup(groupname)

    -- if not then add new one & switch to it
    if grp = 0 then
        grp = length(DATATYPE) + 1
        insertBlankEntry( grp ) -- add to end of list
        setEntry(grp, GRP, groupname, 0, {})
    end if

    -- set to unresolved
    RESFLAG[grp] = 0

    -- switch to this group
    changeGroup(grp)

    end procedure


global procedure defineElement(sequence entryname, integer entrytype)
-- This routine defines the identifier(heading) of an Element within the current Group.
-- It also attaches a type code so that future accesses to this Element are correct.
-- Possible types are:

-- BOOL -- boolean type 1 or 0
-- INT  -- integer
-- SEQ  -- sequence of integers
-- TEXT -- a line of ascii text

    integer vEntry

    vEntry = findEntry(entryname)

    if vEntry < 0 then -- have to insert
        vEntry = 0 - vEntry
        insertBlankEntry( vEntry )
        HEADING[vEntry] = entryname

        -- ensure that 'blank' value not mistaken for the real thing
        -- by setting a definitely faulty type-value
        if entrytype = INT or entrytype = BOOL then
            VALUE[vEntry] = {}
        else
            VALUE[vEntry] = 0
        end if

    end if

    -- update these flags for all
    DATATYPE[vEntry] = entrytype
    RESFLAG[vEntry] = 0

    end procedure


global procedure setValue(sequence entryname, object value)

-- This routine attempts to set the particular value into the identified Element of the
-- current Group. If an illegal value is used then the program will crash.
-- Please note that such an error will only occur where there is a mistake in the
-- program setting the value and not where the ini file is corrupted.
-- If you don't like the way this works then you could change this routine to a function
-- and return an error code. If you do this then replace each line that has halt()
-- with an appropriate return 0 etc..

    integer vEntry

    -- if heading string is null then act as if for text (ASC) line, etc..
    if equal(entryname, "") then -- ascii line
        vEntry = findEntry({{}}) -- unique construction to find insertion point
        vEntry = 0 - vEntry
        insertBlankEntry( vEntry )
        DATATYPE[vEntry] = ASC
        if integer(value) then -- have to convert this to string
            value = { value }
        end if

    else
        -- test that heading is in current group
        vEntry = findEntry(entryname)
        if vEntry < 0 then -- oops, not there
            halt()
        end if

    end if

    -- abort if value does not agree with type
    if not checkData(vEntry, value) then
        halt()
    end if

    -- set value
    VALUE[vEntry] = value

    -- set resolved
    resolveEntry(vEntry)

    end procedure

global procedure setTextValue(object value)
-- This routine wraps setValue() and forces a non-typed text line to be inserted
-- into the current Group. Any data stored this way must be accessed
-- with GetTextValues() which will return *all* the lines interpreted as raw ascii
-- within the current Group.
    setValue("", value)
    end procedure

global function getValue(sequence entryname, object defaultvalue)
-- This function is used to retrieve the value to be placed into the local variable
-- that you will actually use in the program execution. You would invoke this at the
-- initialization stage of your program. If the ini file loaded does not have any entry
-- in the Group with the same name then a fresh Element entry will be defined and
-- the default value will be returned. If an Element does exist but has been interpreted
-- to a different type by loadIniFile() then the type code will be overwritten
-- with the new type code defined earlier by defineElement(). This approach will ensure
-- that entries within a corrupt ini file do not cause any corruption of the program
-- and only the program can cause a crash by attempting to set an illegal value.
    integer vEntry

    -- test that heading is in current grp
    vEntry = findEntry(entryname)

    -- halt if not
    if vEntry < 0 then
        halt()
    end if

    -- if unresolved then test value against type, then default value against type
    if RESFLAG[vEntry] = 0 then
        if not checkData(vEntry, VALUE[vEntry]) then
            if checkData(vEntry, defaultvalue) then
                VALUE[vEntry] = defaultvalue
            else
                halt() -- default value is wrong type
            end if
        end if

    end if

    resolveEntry(vEntry)

    return VALUE[vEntry]

    end function


global function getTextValues()
-- This function will return all Elements within the current Group that were
-- interpreted by LoadIniFile() as ascii text lines or were set using setTextValue().
-- I use this facility to keep a record of all the files still open in my editor
-- at shutdown. With a little imagination almost any datatype could be stored this way.
    sequence result

    set_groupend()
    result = {}

    for i = groupstart to groupend do
        if DATATYPE[i] = ASC then
            result = append( result, VALUE[i] )
        end if
    end for

    if length(result) then
        resolveEntry(groupstart)
    end if

    return result

    end function

--------------------------------------------------------------------------------
-- MWL: added platform specific slash
integer slash
if platform() = LINUX then
    slash = '/'
else
    slash = '\\'
end if

global function extractPathAndName(sequence pathname)
-- This is a useful utility which takes a fully qualified disk file and
-- separates the path & name information. I don't know how this might work for Linux.
-- Eg, "c:\windows\config.sys" becomes {"c:\windows\", "config.sys"}
    sequence path, name
    integer len, pos

    len = length(pathname)
    pos = 0

    for i = len to 1 by -1 do
        -- MWL: changed to use platform specific delimiter
        if pathname[i] = slash then -- delimiter found, must always exist
            pos = i
            exit
        end if
    end for

    path = pathname[1..pos]
    name = pathname[pos+1..len]

    return {path, name}
    end function


global function applicationDirectory()
-- Returns the directory that the executable program is residing in.
-- Does *not* return the Euphoria interpreter path. I have found this
-- routine useful because an application's ini file should be in the same directory.
    sequence s
    s = command_line()
    s = extractPathAndName(s[2])
    return s[1]
    end function

--------------------------------------------------------------------------------

function extractNameAndExtn(sequence filename)
    sequence name, extn

    name = filename
    extn = ""

    for i=length(filename) to 1 by -1 do
        if filename[i] = '.' then
            name = filename[1 .. i-1]
            extn = filename[i + 1 .. length(filename)]
            exit
        end if
    end for

    return { name, extn }
    end function



function getIniPathName(sequence pathname)
    sequence path, name

    if not length(pathname) then -- empty string, have to construct artificial target
        path = command_line()
        path = extractPathAndName(path[2]) -- look at executable file dir
        name = path[2]
        path = path[1]
        name = extractNameAndExtn(name)
        name = name[1] & ".ini" -- ini file will have same name as executable

    else -- string not empty but check for full target all the same
        path = extractPathAndName(pathname)
        name = path[2]
        if not length(path[1]) then
            path = applicationDirectory()
        else
            path = path[1]
        end if

    end if

    return path & name

    end function



global function loadIniFile(sequence pathname)
-- This function will load the file identified and attempted to build an ini
-- structure of Groups & Elements & values. If an empty string is used then the code
-- will construct a file name based on the name of the executing program. This could be
-- useful in some situations. The file pointed to by this artificial name will try to be
-- loaded by ini.e and the ini structure materialized etc. If no file is loaded then the function
-- will return 0. If a file is loaded then the name of this file will be used to save
-- the data to disk at program shutdown.

-- if pathname is the file name only then the application directory will be attached
-- to form a complete disk target.

    integer id, p
    object line

    resetIniLists()

    -- Verify the likely ini file path and name
    pathname = getIniPathName(pathname)

    -- Create ini file if it does not exist
    if atom(dir(pathname)) then -- file dont exist
        id = open( pathname, "w" ) -- can create file anyway?
        if id = -1 then -- cannot create file either
            return 0
        end if
        close(id)
    end if

    -- open the file now known to exist
    id = open( pathname, "r" )
    if id = -1 then -- file not present or disk error
        return 0
    end if

    -- loop through each line and parse for ini information
    while 1 do
        line = gets(id)
        if integer(line) then
            exit
        end if
        line = parseLine(line)
        if sequence (line) then

            p = length(DATATYPE) + 1
            insertBlankEntry( p )
            setEntry( p, line[1], line[2], line[3], line[4] )

            if line[1] = COM then -- assert group as true
                p = findGroupOwner(p)
                RESFLAG[p] = 1
            end if

        end if
    end while

    close(id)

    -- store *successful* file name so that saveIniFile() knows the target
    completeinipath = pathname

    return 1

    end function



function getIniWriteData()
    sequence result

    result = {}
    groupstart = 1

    while 1 do

        set_groupend()

        if DATATYPE[groupstart] = GRP
        and RESFLAG[groupstart] = 0 then -- skip

        else

            -- add space between groups
            if groupstart != 1 then
                result = append(result, "" )
            end if

            -- cycle through group extracting all resolved entries
            for i = groupstart to groupend do
                if RESFLAG[i] = 1 then
                    result = append(result, getWriteString(i) )
                end if
            end for
        
        end if

        groupstart = groupend + 1
        if groupstart > length(DATATYPE) then
            exit
        end if

    end while

    return result

    end function


global procedure saveIniFile()
-- This routine will save the ini structure to disk (using the name used to load
-- the data in the first place) in the usual ini file format - formatted slightly.
-- No provision has been made for any disk save failure but anyone could easily
-- modify the code to return an error code should they wish.
    integer id
    sequence lines

    -- attempt to open the file
    id = open(completeinipath, "w")

    -- exit on error
    if id = -1 then -- error has occurred
        return
    end if

    -- write out data to file
    lines = getIniWriteData()
    for i = 1 to length(lines) do
        puts(id, lines[i] & '\n')
    end for

    -- exit
    close(id)

    end procedure

--global procedure putini()
--    for i = 1 to length(DATATYPE) do
--        if RESFLAG[i]=0 then
--            if DATATYPE[i] = ASC then
--                puts(1,"\n" & VALUE[i] )
--            else
--                puts(1,"\n" & HEADING[i] )
--            end if
--        end if
--    end for
--puts(1, "\n")
--    end procedure

-- putini()
