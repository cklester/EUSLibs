-- Library's Purpose:  Determining and changing a characters types

-- Copyright 1999 : Mathew Hounsell
-- Version : 1.0
-- Licence : FreeCode

-- For assistance of Euphoria Programmers.

-- Based on original 7 bit ASCII character set.
-- A boolean is an integer. Not 0 for True, 0 for False.

---------------------------------------------------------------------------
-- Routines
---------------------------------------------------------------------------
-- In C standard			Added
-- isascii
-- isdigit
-- isxdigit
--					isodigit
--					isbdigit
-- isalpha
-- isalnum
-- islower
-- isupper
-- iscntrl
-- ispunct
-- isspace
-- isgraph
-- isprint
-- toascii
-- tolower
-- toupper

---------------------------------------------------------------------------
-- Determining Types
---------------------------------------------------------------------------
-- NAME    : boolean isascii( integer c )
-- PURPOSE : Determines if an integer is a valid ASCII character
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if c is an ASCII character else false.
--
-- NOTE    : ASCII is between 0 and 127, the original set.
-- SEE     : isascii, toascii, toeascii
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isascii( integer c )
	return not ( and_bits( c, not_bits( #7F ) ) )
end function

---------------------------------------------------------------------------
-- NAME    : boolean iseascii( integer c )
-- PURPOSE : Determines if an integer is a valid Extended ASCII character
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if c is an ASCII character else false.
--
-- NOTE    : EASCII is between 0 and 255, the extended ASCII set.
-- SEE     : isascii, toeascii
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function iseascii( integer c )
	return not ( and_bits( c, not_bits( #FF ) ) )
end function


-----------------------------------------------------------------------------
-- NAME    : boolean isalpha( integer c )
-- PURPOSE : Determines is a character is alphabetic ie a letter
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if c is an upper or lower case english letter
--                     else false
--
-- NOTE    : Original ASCII, english, non accented forms only.
-- SEE     : isalnum, islower, isupper
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isalpha( integer c )
	return ( c >= 'A' and c <= 'Z' ) or ( c >= 'a' and c <= 'z' )
end function

-----------------------------------------------------------------------------
-- NAME    : boolean isdigit( integer c )
-- PURPOSE : Determines if a character is a decimal digit, ie 0 to 9
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if digit 0 to 9 else false
--
-- SEE     : isalnum, isxdigit, isodigit, isbdigit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isdigit( integer c )
	return c >= '0' and c <= '9'
end function

-----------------------------------------------------------------------------
-- NAME    : boolean isalnum( integer c )
-- PURPOSE : Determines if a character is alphabetic or a decimal digit
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if a letter or a decimal digit
--
-- NOTE    : Original ASCII, english, non accented forms only.
-- SEE     : isalpha, isdigit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isalnum( integer c )
	return isdigit( c ) or isalpha( c )
end function

-----------------------------------------------------------------------------
-- NAME    : boolean isgraph( integer c )
-- PURPOSE : Determines if a character is a graphical character, excluding
--               space and control characters.
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if so else false
--
-- NOTE    : True if ASCII character 33 to 126.
-- SEE     : isprint
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isgraph( integer c )
	return c > ' ' and c < #7F
end function

-----------------------------------------------------------------------------
-- NAME    : boolean islower( integer c )
-- PURPOSE : Determines if a character is a lower case letter
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if so else false
--
-- NOTE    : Original ASCII, english, non accented forms only.
-- SEE     : isalpha, isupper, tolower, toupper
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function islower( integer c )
	return c >= 'a' and c <= 'z'
end function

-----------------------------------------------------------------------------
-- NAME    : boolean isprint( integer c )
-- PURPOSE : Determines if a character is a printable character, including
--               space and excluding control characters.
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if so else false
--
-- NOTE    : True if ASCII character 32 to 126.
-- SEE     : isgraph
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isprint( integer c )
	return c >= ' ' and c < #7F
end function

-----------------------------------------------------------------------------
-- NAME    : boolean ispunct( integer c )
-- PURPOSE : Determines if a character is a punctuation character. 
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if so else false
--
-- NOTE    : True if graphical but not alpha-numeric
-- SEE     : isgraph
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function ispunct( integer c)
	return isgraph(c) and not isalnum(c)
end function

-----------------------------------------------------------------------------
-- NAME    : boolean isspace( integer c )
-- PURPOSE : Determines if a character is a whitespace character
-- ARGS    : integer c - the character to test
--
-- RETURNS : boolean - true if so else false
-- NOTE    : True if carriage return, line feed, form feed, horizontal tab,
--               vertical tab, or space.
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isspace( integer c )
	return ( c >= #09 and c <= #0D ) or c = #20
end function

-----------------------------------------------------------------------------
-- NAME    : boolean iscntrl( integer c )
-- PURPOSE : Determines if a character is an ASCII control character
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if so else false
--
-- NOTE    : ASCII control characters are 0 to 31 except white space chars
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function iscntrl( integer c )
	return (c >= #00 and c < #09) or (c > #0D and c < #20) or c = #7F
end function

-----------------------------------------------------------------------------
-- NAME    : boolean isupper( integer c )
-- PURPOSE : Determines if a character is an upper case letter
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if so else false
--
-- NOTE    : Original ASCII, english, non accented forms only.
-- SEE     : isalpha, islower, tolower, toupper
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isupper( integer c )
	return ( c >= 'A' and c <= 'Z' )
end function

-----------------------------------------------------------------------------
-- NAME    : boolean isxdigit( integer c )
-- PURPOSE : Determines if a character is a hexidecimal digit, ie 0-9 or a-f
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if so else false
--
-- NOTE    : True if a character 0 to 9, a to f or A to F
-- SEE     : isdigit, isodigit, isbdigit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isxdigit( integer c )
	return isdigit(c) or ( c >= 'a' and c <= 'f' ) or ( c >= 'A' and c <= 'F' )
end function

-----------------------------------------------------------------------------
-- NAME    : boolean isodigit( integer c )
-- PURPOSE : Determines if a character is an octal digit, ie 0 to 7
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if so else false
--
-- SEE     : isdigit, isxdigit, isbdigit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isodigit( integer c )
	return c >= '0' and c <= '7'
end function

-----------------------------------------------------------------------------
-- NAME    : boolean isbdigit( integer c )
-- PURPOSE : Determines if a character is a binary digit, ie 0 or 1
-- ARGS    : integer c - the character to test
-- RETURNS : boolean - true if so else false
--
-- SEE     : isdigit, isxdigit, isodigit
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function isbdigit( integer c )
	return c = '0' or c = '1'
end function

---------------------------------------------------------------------------
-- Changing Types
---------------------------------------------------------------------------
-- NAME    : integer toascii( integer c )
-- PURPOSE : Forces an integer to be an ASCII character.
-- ARGS    : integer c - the character to convert.
-- RETURNS : integer - the converted character
--
-- NOTES   : Strips of the high bits leaving only te last 7.
--           ASCII is between 0 and 127, the original set.
-- SEE     : isascii, iseascii, toeascii
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function toascii( integer c )
	return and_bits( c, #7F )
end function

---------------------------------------------------------------------------
-- NAME    : integer toeascii( integer c )
-- PURPOSE : Forces an integer to be an extended ASCII character.
-- ARGS    : integer c - the character to convert.
-- RETURNS : integer - the converted character
--
-- NOTES   : Strips of the high bits leaving only te last 8.
--           ASCII is between 0 and 255, the extended set.
-- SEE     : isascii, iseascii, toascii
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function toeascii( integer c )
	return and_bits( c, #FF )
end function

-----------------------------------------------------------------------------
-- NAME    : integer tolower( integer c )
-- PURPOSE : Converts an upper case letter to lower case
-- ARGS    : integer c - the character to convert
-- RETURNS : integer - the converted character
--
-- NOTE    : Could possiblely be faster
-- SEE     : isalpha, islower, isupper, toupper
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function tolower( integer c )
	if isupper( c ) then
		return c + #20
	end if
	return c
end function

-----------------------------------------------------------------------------
-- NAME    : integer toupper( integer c )
-- PURPOSE : Converts an lower case letter to upper case
-- ARGS    : integer c - the character to convert
-- RETURNS : integer - the converted character
--
-- NOTE    : Could possiblely be faster
-- SEE     : isalpha, islower, isupper, tolower
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --
global function toupper( integer c )
	if islower( c ) then
		return c - #20
	end if
	return c
end function

---------------------------------------------------------------------------
-- End Of File
---------------------------------------------------------------------------
