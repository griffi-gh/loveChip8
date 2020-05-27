function tohex(n,b)
  b=b or '2'
  return '0x'..string.format('%0'..b..'X',n)
end
function hextonuber(hex)
  return tonumber(hex,16)
end
function fsbase(h)
  if love and not(h) then
    if love.filesystem.isFused() then
      return love.filesystem.getSourceBaseDirectory()
    else
      return love.filesystem.getSource()
    end
  else 
    return io.popen"cd":read'*l'
  end
end
