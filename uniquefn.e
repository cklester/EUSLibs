-- uniquefn.e v1.0 by cklester
-- call newFilename(directory) to obtain a filename unique
-- to the specified directory

-- by default, there are 2,821,109,907,456 different
-- names available, making it impossible to dupe a name
-- but also extremely fast because it doesn't have to
-- read in directory information, sort, etc...

-- there really should be no reason to ever
-- change any of the default values

-- at a minimum, you'll want a filename length of 5
-- and all 26 letters of the English alphabet
-- that provides for over 11 million unique filenames

include std/filesys.e

sequence validChars
integer vc, fnl
    validChars = "abcdefghijklmnopqrstuvwxyz0123456789"
    vc = length(validChars)
    fnl = 8 -- default filename length

global procedure setFilenameLength(integer a)

-- call this procedure if you want a filename with a
-- length other than the default 8 (for DOS compatibility)
-- limited to 10 because that allows for
-- 3,656,158,440,062,976 different filenames!!!!

-- a length of 1 allows for 36 unique filenames using the default validChars set
-- a length of 2 allows for 1,296 unique filenames using the default validChars set
-- 3 -- 46,656
-- 4 -- 1,679,616
-- etc...

    if a >= 5 and a <= 10 then -- yes, hard-coding a minimum (for your own good)
        fnl = a
    else
        fnl = 8
    end if
    
end procedure
        
global procedure setValidChars(sequence s)

-- call this procedure to use a different set of
-- valid possible characters for the filename
-- for example, all numbers: setValidChars("0123456789")

    if length(s) >= 10 then -- yes, hard-coding a minimum (for your own good)
        validChars = s
    else
        validChars = "abcdefghijklmnopqrstuvwxyz0123456789"
    end if
    vc = length(validChars)
    
end procedure

function random_string(integer len)
-- build a random string from validChars of length len
sequence result
    result = ""
    for t=1 to len do
        result &= validChars[rand(vc)]
    end for
    return result
end function

global function uniquefn(sequence currentDir)
sequence fname
atom failmax, counter, possible

    possible = power( vc, fnl )

    if fnl = 1 then -- special case which should never happen unless you cheat
        for t=1 to vc do
            if atom(dir(currentDir & "/" & validChars[t])) then
                return { validChars[t] }
            end if
        end for
        return -1
    end if

    -- failmax is a sort of timeout error. if it can't get a unique filename
    -- in this many tries, it fails out. this probably should be based on possible.
    if possible < 100 then
        failmax = possible
    else
        failmax = 100
    end if
    
    counter = 0
    if not length(currentDir) then
        currentDir=current_dir()
    end if
    if atom(dir(currentDir)) then
        return 0 -- if the supplied directory doesn't exist, return an error
    end if
    fname = random_string(fnl)
    while sequence(dir(currentDir & "/" & fname)) do
        counter += 1
        if counter = failmax then
            fname = ""
            exit
        end if
        fname = random_string(fnl)
    end while
    if length(fname) = 0 then
        return -1
    else
        return fname
    end if
end function

global function newFilename(sequence dir)
object fname
atom fn, timer
integer maxTries
    fn = -1
    timer = time() + 3
    while fn = -1 and time() < timer do
        fname = dir & uniquefn( dir )
        if sequence(fname) then
            fn = open(fname,"w")
            if fn > 0 then
                close(fn)
                return fname
            end if
        end if
    end while
    return -1
end function
