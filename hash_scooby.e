include fileio.e

global constant htSTRING = 1, htINDEX = 2

atom
	  NULL = 0
	, EOF = -1

global function new_hash_table(atom buckets)
 -- for best performance, buckets should be a prime number
 -- 1009 produces a good distribution
  return repeat({{},{}},buckets)
end function

global function hash_key(sequence ht, sequence s)
 integer len
 atom val
    
  len = length(s)
  val = s[len]
  if len > 4 then len = 4 end if
  for i = 1 to len - 1 do
	  val = val * 64 + s[i]  -- shift 6 bits and add
  end for
  return remainder(val, length(ht)) + 1
end function

global function hash_find(sequence ht, sequence s)
 integer key
  key = hash_key(ht,s)
  return {key,find(s,ht[key][htSTRING])}
end function

global function hash_add(sequence ht, sequence s, object x)
 sequence key,bucket
    
  -- which bucket to search?
  key = hash_find(ht,s)
  bucket = ht[key[1]]

  -- search this bucket for the string
  if key[2] then
	  bucket[htINDEX][key[2]] &={ x }
  else
	  bucket[htSTRING] &={ s }
	  bucket[htINDEX]  &={ {x} }
  end if
  ht[key[1]] = bucket
  return ht
end function

global function hash_remove(sequence ht, sequence s)
 sequence key
  key = hash_find(ht,s)
  if key[2] then
		for i = 1 to length(ht[key[1]]) do
			ht[key[1]][i] = ht[key[1]][i][1..key[2]-1] & ht[key[1]][i][key[2]+1..length(ht[key[1]][i])]
		end for
  end if
  return ht
end function

global procedure save_hash_table(sequence ht, sequence name)
 integer fn
  fn = open(name,"wb")
  put4(fn,length(ht)) -- store the number of buckets
  for i = 1 to length(ht) do
    put4(fn,length(ht[i][htSTRING])) -- store the number of entries in this bucket
    if length(ht[i][htSTRING]) then
      put_string(fn,ht[i][htSTRING])
      for j = 1 to length(ht[i][htINDEX]) do
        put4(fn,length(ht[i][htINDEX][j])) -- store the number of indices for this entry
        put4(fn,ht[i][htINDEX][j])
      end for
    end if
  end for
  close(fn)
end procedure

global function load_hash_table(sequence name)
 sequence table
 integer fn,len
  table = {}
  fn = open(name,"rb")
  if fn > EOF then
    table = new_hash_table(get4u(fn)) -- number of buckets
    for i = 1 to length(table) do
      len = get4u(fn) -- number of entries in the bucket
      if len then
        table[i][htSTRING] = get_string({fn,len})
        table[i][htINDEX]  = repeat(NULL,len)
        for j = 1 to len do
          table[i][htINDEX][j] = get4u({fn,get4u(fn)}) -- number of indices for the entry
        end for
      end if
    end for
    close(fn)
  end if
  return table
end function
