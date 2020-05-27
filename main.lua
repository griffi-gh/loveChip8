bit=require'bitty'
require'fn'
require'chip8'

local pixs=8
local steps=8
local limit=true

function love.load()
  love.window.setMode(pixs*chip8.w,pixs*chip8.h,{vsync=limit})
end

function love.filedropped(file)
  chip8:loadFile(file:getFilename())
  chip8:run()
end

function love.update()
  for i=1,steps do
    chip8:loop()
  end
end

function love.draw()
  if chip8.running then
    for i=1,chip8.w do
      for j=1,chip8.h do
        if gfx[i][j]==true then
          love.graphics.rectangle('fill',(i-1)*pixs,(j-1)*pixs,pixs,pixs)
        end
      end
    end
  else
    love.graphics.print'Drop .ch8 ROM File'
  end
  love.graphics.print(love.timer.getFPS()..' FPS',0,love.graphics.getHeight()-12)
end

function love.keypressed(k)
  local h=hextonuber(k)
  if h then chip8:keyDown(h) end
end
function love.released(k)
  local h=hextonuber(k)
  if h then chip8:keyUp(h) end
end
