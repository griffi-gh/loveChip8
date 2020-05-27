bit=require'bitty'
require'fn'
ROM=require'rom'
require'chip8'

local pixs=8

function love.load()
  chip8:run()
end

function love.update()
  chip8:loop()
end

function love.draw()
  for i=1,64 do
    for j=1,32 do
      if gfx[i][j]==true then
        love.graphics.rectangle('fill',(i-1)*pixs,(j-1)*pixs,pixs,pixs)
      end
    end
  end
  love.graphics.print(love.timer.getFPS())
  local t=tohex(opcode,4)..'\n'
  for i=0x200,#mem-1 do
    if pc==i then t=t..'>' else t=t..'  ' end
    t=t..mem[i]..' '
    if i%8==0 then t=t..'\n' end
  end
  love.graphics.print(t,64*8)
end

function love.keypressed(k)
  local h=hextonuber(k)
  if h then chip8:keyDown(h) end
end
function love.released(k)
  local h=hextonuber(k)
  if h then chip8:keyUp(h) end
end
