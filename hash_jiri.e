---------------------------------------------------------------------
--# Hash Tables, by Jiri Babor, modified by me
---------------------------------------------------------------------

--  htables.e : hash tables : version 1.00
--  jiri babor
--  jbabor@paradise.net.nz
--  03-Jan-04

-- Modified to support any objects as key, and simpler operations

sequence hash_s, hash_t
integer hash_index1, hash_index2          -- bucket index, collision index
atom rotate_left, rotate_left_param, hash_t_rol_1
integer hash_initted
hash_initted = 0

function rol(atom x)
	poke4(rotate_left_param, x)
	call(rotate_left)
	return peek4s(rotate_left_param)
end function

procedure hash_init()
	-- 32-bit left rotation : modified Tommy Carlie's code - thanks!
	rotate_left = allocate(13)
	rotate_left_param = rotate_left + 1
	
	poke(rotate_left, {
		#B8,#00,#00,#00,#00,                -- 0: mov eax, dword param (2)
		#D1,#C0,                            -- 5: rol eax, 1
		#A3,#00,#00,#00,#00,                -- 7: mov [@param]
		#C3})                               -- C: ret
	poke4(rotate_left+8, rotate_left_param) -- @param
	
	-- create an array of 256 32-bit random integer such that any
	-- bit column contains exactly 128 zeros and 128 ones
	hash_s = repeat(0,32)
	hash_t = repeat(0,128) & repeat(1,128)
	set_rand(24341)
	for i = 1 to 32 do
		hash_s[i] = shuffle(hash_t)
	end for
	
	-- exchange rows and columns : turn sequence s 90 degrees clockwise
	hash_t = repeat(repeat(0,32),256) -- init output sequence
	for r=1 to 32 do
		for c=1 to 256 do
			hash_t[c][32-r+1] = hash_s[r][c]
		end for
	end for
	
	-- turn bit sequences into 32-bit integers
	for i = 1 to 256 do
		hash_t[i] = bits_to_int(hash_t[i])
	end for
	
	hash_t_rol_1 = rol(hash_t[1])
end procedure

function hash_hash(object key)
	atom h
	object tmp
	integer n
	
	if atom(key) then
		if integer(key) then
			if key >= 0 and key <= 255 then
				h = xor_bits(hash_t_rol_1, hash_t[key+1])
			else
				if key < 0 then
					key += 4294967296
				end if
				key = int_to_bytes(key)
				
				h = hash_t[4]
				for i = 1 to 4 do
					h = xor_bits(rol(h), hash_t[key[i]+1])
				end for
			end if
		else
			key = atom_to_float64(key)
			h = hash_t[8]
			for i = 1 to 8 do
				h = xor_bits(rol(h), hash_t[key[i]+1])
			end for
		end if
	else
		n = and_bits(length(key), #FF)
		h = hash_t[n+1]
		for i = 1 to n do
			tmp = hash_hash(key[i])
			if tmp < 0 then
				tmp += 4294967296
			end if
			tmp = int_to_bytes(tmp)
			
			h = xor_bits(rol(h), hash_t[tmp[1]+1])
			h = xor_bits(rol(h), hash_t[tmp[2]+1])
			h = xor_bits(rol(h), hash_t[tmp[3]+1])
			h = xor_bits(rol(h), hash_t[tmp[4]+1])
		end for
	end if
	return h
end function


-- hash_new(atom number_of_buckets)
-- Creates a new hash table, with /number_of_buckets buckets.
-- If /number_of_buckets is not power of 2, 
-- the nearest larger power of 2 will be used.
-- Returns an empty HashTable.
global function hash_new(atom number_of_buckets)
	if not hash_initted then
		hash_init()
		hash_initted = 1
	end if
	
	if number_of_buckets > 4294967296 then
		number_of_buckets = 4294967296
	elsif number_of_buckets <= 1 then
		number_of_buckets = 2
	end if

	if and_bits(number_of_buckets,number_of_buckets-1) then
		for i = 3 to 32 do
			if number_of_buckets <= power(2, i) then
				number_of_buckets = power(2, i)
				exit
			end if
		end for
	end if
	
	return repeat({{}}, number_of_buckets)
end function

-- hash_find(HashTable table, object key)
-- Lets you know whether /key is exists on the /table.
-- Returns 0 if not exists, non-zero if exists
global function hash_find(sequence table, object key)
	sequence t

	hash_index1 = and_bits(hash_hash(key),length(table)-1)+1
	t = table[hash_index1]
	hash_index2 = find(key, t[length(t)])
	return hash_index2
end function

-- hash_get(HashTable table, object key, object default)
-- Returns the value of the /key.
-- If the /key cannot be found, /default is returned.
global function hash_get(sequence table, object key, object default)
	sequence t
	
	hash_index1 = and_bits(hash_hash(key),length(table)-1)+1
	t = table[hash_index1]
	hash_index2 = find(key, t[length(t)])
	
	if hash_index2 then
		return t[hash_index2]
	else
		return default
	end if
end function

-- hash_set(HashTable table, object key, object value)
-- If the /key is not on the /table, the /key and /value is stored in the
-- /table. If the /key already exists, the existing value will be updated.
-- Returns the modified HashTable.
global function hash_set(sequence table, object key, object value)
	sequence t

	hash_index1 = and_bits(hash_hash(key), length(table)-1) + 1
	t = table[hash_index1]
	hash_index2 = find(key, t[length(t)])

	if not hash_index2 then
		hash_index2 = length(t)
		t = append(t, append(t[hash_index2],key))
	end if
	
	t[hash_index2] = value
	table[hash_index1] = t
	
	return table
end function

-- hash_delete(HashTable table, object key)
-- Deletes the /key and corresponding value.
-- If the /key cannot be found, the /table is not modified.
-- Returns the (un)modified HashTable.
global function hash_delete(sequence table, object key)
	sequence t
	integer n

	hash_index1 = and_bits(hash_hash(key),length(table)-1) + 1
	t = table[hash_index1]
	n = length(t)
	hash_index2 = find(key, t[n])
	if hash_index2 then
		t[n] = t[n][1..hash_index2-1] & t[n][hash_index2+1..n-1]
		t = t[1..hash_index2-1] & t[hash_index2+1..n]
	end if
	table[hash_index1] = t

	return table
end function

