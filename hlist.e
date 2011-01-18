--  hlist.e : hybrid list implementation
--  jiri_babor@hotmail.com
--  00-10-26
--  version 1.00

----------------------------------------------------------------------
--  form: {{key1, key2, ...keyN}, {value, value2, ...valueN}}
----------------------------------------------------------------------
--  to improve performance, the binary search is used only when the
--  the list length >=  bsearch_length
----------------------------------------------------------------------

without warning
without type_check
without trace

include std/error.e
include std/machine.e                       -- crash_message()
include std/wildcard.e                      -- wildcard_match()
                                        -- Matt Lewis

global constant EMPTY = {{}, {}}        -- empty list

global integer bsearch_length

global function sort_list(sequence s)
    -- shell sort list s

    object t1i,t1j,t2i,t2j      -- temporary objects
    sequence s1,s2
    integer gap, j, first, last

    s1 = s[1]
    s2 = s[2]
    last = length(s1)
    gap = floor(last / 3) + 1
    while 1 do
            first = gap + 1
            for i = first to last do
                t1i = s1[i]
                t2i = s2[i]
                j = i - gap
                while 1 do
                        t1j = s1[j]
                        t2j = s2[j]
                        if compare(t1i, t1j) >= 0 then
                            j += gap
                            exit
                        end if
                        s1[j+gap] = t1j
                        s2[j+gap] = t2j
                        if j <= gap then
                            exit
                        end if
                        j -= gap
                end while
                s1[j] = t1i
                s2[j] = t2i
            end for
            if gap = 1 then
                return {s1,s2}
            else
                gap = floor(gap / 3) + 1
            end if
    end while
end function -- sort_list

global function index(sequence list, object key)
    -- return *key* index, or zero if key not found

    sequence s
    integer lo, hi, mid, c

    s = list[1]
    if length(s) >= bsearch_length then
        lo = 1
        hi = length(s)

        while lo <= hi do
            mid = floor((lo + hi) / 2)
            c = compare(key, s[mid])
            if c < 0 then       -- key < s[mid]
                hi = mid - 1
            elsif c > 0 then    -- key > s[mid]
                lo = mid + 1
            else                -- key = s[mid]
                return mid
            end if
        end while
        return 0
    end if

    return find(key, s)             -- unsorted, or short sorted list
end function -- index

    
global function index_wild(sequence list, sequence key)
    -- return *key* index, or zero if key not found

    sequence s
    integer lo, hi, mid, c, ast, que, wc, len

    ast = find( '*', key )
    que = find( '?', key )
    
    if ast then
        if que then
            if ast < que then
                wc = ast
            else
                wc = que
            end if
        else
            wc = ast
        end if
    else
        wc = que
    end if
    
    if not wc then
        return 0
    end if
    
    s = list[1]
    if length(s) >= bsearch_length then
        lo = 1
        hi = length(s)

        while lo <= hi do
            mid = floor((lo + hi) / 2)
            
            if atom( s[mid] ) then
                return 0
            end if
            
            len = length( s[mid] )
            if len > wc then
                len = wc - 1
            end if
            
            -- added to search for wild cards
--             c = wildcard_match( key, s[mid] )
            c = is_match( key, s[mid] )
            if c = 1 then
                return mid
            end if
            
            -- this doesn't seem right:
            
            c = compare(key[len], s[mid][len])
            if c < 0 then       -- key < s[mid]
                hi = mid - 1
            elsif c > 0 then    -- key > s[mid]
                lo = mid + 1
            else                -- key = s[mid]
                --return mid
                c = index_wild( list[mid..hi], key )
                if c then
                    return c + mid - 1
                else
                    c = index_wild( list[lo..mid], key )
                    if c then
                        c = c + lo - 1
                    end if
                    
                    return c
                end if
            end if
        end while
        return 0
    end if

    return find(key, s)             -- unsorted, or short sorted list
end function -- index

global function fetch_list(sequence list, object key)
    integer i

    i = index(list, key)
    if i then
        return list[2][i]
    end if
    crash_message("fetch error: key \"" & key & "\" not found...\n")
end function -- fetch

global function safe_fetch_list(sequence list, object key)
    integer i

    i = index(list, key)
    if i then
        return list[2][i]
    end if
    return {}
    crash_message("fetch error: key \"" & key & "\" not found...\n")
end function -- fetch


global function set_list(sequence list, sequence key, object new_value)
    integer i

    i = index(list, key)            -- key index
    if i then
        list[2][i] = new_value
        return list
    end if
    crash_message("set error: key \"" & key & "\" not found...\n")
end function -- set

global function insert(sequence list, object key, object val)
    sequence s,t
    integer lo,hi,i,c,len

    s = list[1]
    t = list[2]
    len = length(s)
    hi = len
    if not hi then                  -- empty list
        return {{key}, {val}}
    end if

    lo = 1
    i = 1
    while lo <= hi do
        i = floor((lo + hi) / 2)
        c = compare(key, s[i])
        if c < 0 then               -- key < s[i]
            hi = i - 1
        else                        -- key > s[i]
            lo = i + 1
        end if
    end while

    s = append(s, 0)
    s[lo+1..len+1] = s[lo..len]
    s[lo] = key
    t = append(t, 0)
    t[lo+1..len+1] = t[lo..len]
    t[lo] = val
    list = {s,t}
    return list
end function -- insert

global function merge(sequence s1, sequence s2)
    -- concatenate lists s1 and s2

    return sort_list({s1[1] & s2[1], s1[2] & s2[2]})
end function -- merge

global function delete(sequence s, object key)
    --  delete item with the specified key from the list s

    integer i,l

    i = index(s, key)               -- key index
    if i then
        l = length(s[1])
        return {s[1][1..i-1] & s[1][i+1..l], s[2][1..i-1] & s[2][i+1..l]}
    end if
    crash_message("sdelete error: key \"" & key & "\" not found...\n")
end function -- delete

global function dups(sequence s)
    -- return sequence of duplicated keys

    sequence d
    integer len

    d = {}
    s = s[1]                        -- we are interested in keys only
    len = length(s)
    if len > 1 then
        for i=2 to len do
            if equal(s[i], s[i-1]) then
                d = append(d, s[i])
            end if
        end for
    end if
    return d
end function -- dups

-- initialize:
bsearch_length = 100

