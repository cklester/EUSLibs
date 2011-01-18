--/topic Introduction
--/info
--
--stringhash.e: A simple library for maintaining a hash table using string keys.
--
--by Matt Lewis
--
--LICENSE AND DISCLAIMER
--
--The MIT License
--
--Copyright (c) 2007 Matt Lewis
--
--Permission is hereby granted, free of charge, to any person obtaining a copy of this 
--software and associated documentation files (the "Software"), to deal in the Software 
--without restriction, including without limitation the rights to use, copy, modify, merge,
--publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
--to whom the Software is furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all copies or 
--substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
--INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
--PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
--FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
--OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
--DEALINGS IN THE SOFTWARE.


--/topic API
--/info
--
--Using hashes is very simple.  There are only 4 functions, for creating, adding or
--changing data, retrieving data, and checking to see if a key has been added to the hash.
--

constant 
H_SEED  = 1,
H_KEY   = 2,
H_VALUE = 3

constant DEFAULT_SEED = #0809

function hashval( sequence string, integer seed )
	integer val
	
	val = seed
	for i = 1 to length( string ) do
		val = xor_bits( val, string[i] )
		val *= 2
		val += and_bits( #10000, val ) != 0
		val = and_bits( #FFFF, val )
	end for
	
	if not val then
		val = #10000  -- sequences are 1-based
	end if
	return val
end function

--/topic API
--/func hash( integer seed )
--
--Returns a new string hash using the seed provided, or using a 
--default seed if seed = 0.
global function hash( integer seed )
	if not seed then
		seed = DEFAULT_SEED
	else
		seed = and_bits( #FFFF, seed )
	end if
	
	return { 
		seed, 
		repeat( 0, #10000 ), 
		repeat( {}, #10000 ) }
	
end function

--/topic API
--/func has( sequence hash, sequence string )
--
--Checks the hash to see if the string has been added to the hash.  Returns
--1 if it has, or 0 if the string has not been added to the hash.
global function has( sequence hash, sequence string )
	integer hash_val
	object bucket
	
	hash_val = hashval( string, hash[H_SEED] )
	
	bucket = hash[H_KEY][hash_val]
	if sequence( bucket ) and find( string, bucket ) then
		return 1
	else
		return 0
	end if
end function

--/topic API
--/func set( sequence hash, sequence string, object val )
--
--Adds or replaces the entry with key string with val.  The updated hash
--is returned.
global function set( sequence hash, sequence string, object val )
	integer hash_val
	integer ix
	object bucket
	
	hash_val = hashval( string, hash[H_SEED] )
	bucket = hash[H_KEY][hash_val]
	if atom( bucket ) then
		hash[H_KEY][hash_val] = { string }
		hash[H_VALUE][hash_val] = { val }
		return hash
	end if
	
	ix = find( string, bucket )
	if ix then
		hash[H_VALUE][ix] = val
	else
		hash[H_KEY][hash_val]   = append( hash[H_KEY][hash_val] ,string )
		hash[H_VALUE][hash_val] = append( hash[H_VALUE][hash_val], val )
	end if
	return hash
end function

--/topic API
--/func get_safe( sequence hash, sequence string )
--
--Returns a sequence with two values.  The first element of the sequence will
--be 1 if the string was in the hash, or 0 if the string was not found.  If the
--string was found, then the second element will be the value passed in /set().
--If the first element is zero, then the value of the second element of the 
--returned sequence is undefined.
global function get_safe( sequence hash, sequence string )
	integer hash_val
	integer ix
	
	hash_val = hashval( string, hash[H_SEED] )
	ix = find( string, hash[H_KEY][hash_val] )
	if ix then
		return { 1, hash[H_VALUE][hash_val][ix] }
	else
		return { 0, 0 }
	end if
end function

--/topic API
--/func get( sequence hash, sequence string )
--
--Returns the value associated with the string.  Crashes if the string is not in the hash.
global function get( sequence hash, sequence string )
	integer hash_val
	integer ix
	
	hash_val = hashval( string, hash[H_SEED] )
	ix = find( string, hash[H_KEY][hash_val] )
	if ix then
		return hash[H_VALUE][hash_val][ix]
	else
		return 1/0
	end if
end function

--/topic API
--/func keys( sequence hash )
--
--Returns a sequence of all of the keys added to the hash.
global function keys( sequence hash )
	sequence k, hk
	hk = hash[H_KEY]
	k = {}
	for i = 1 to length( hk ) do
		k &= hk[i]
	end for
	return k
end function
