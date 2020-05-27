function tohex(n,b)
  b=b or '2'
  return '0x'..string.format('%0'..b..'X',n)
end
function hextonuber(hex)
  return tonumber(hex,16)
end
