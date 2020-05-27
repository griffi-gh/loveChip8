bit=require'bitty'
require'fn'
require'chip8'

local pixs=8
local steps=2
local limit=true

local controls=love.graphics.newImage('defaultControls.jpg')
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
  local g=love.graphics
  g.setColor(1,1,1)
  if chip8.running then
    for i=1,chip8.w do
      for j=1,chip8.h do
        if gfx[i][j]==true then
          g.rectangle('fill',(i-1)*pixs,(j-1)*pixs,pixs,pixs)
        end
      end
    end
  else
    g.print'Drop .ch8 ROM File'
    g.draw(controls,8,20)
  end
  g.setColor(1,0,0)
  g.print(love.timer.getFPS()..' FPS, x'..steps..'(use shift/ctrl)',0,love.graphics.getHeight()-12)
end

local binds={
  ['kp0']=0x0,
  ['kp1']=0x7,
  ['kp2']=0x8,
  ['kp3']=0x9,
  ['kp4']=0x4,
  ['kp5']=0x5,
  ['kp6']=0x6,
  ['kp7']=0x1,
  ['kp8']=0x2,
  ['kp9']=0x3,
  ['kp.']=0xA,
  ['kpenter']=0xB,
  ['kp+']=0xC,
  ['kp-']=0xD,
  ['kp*']=0xE,
  ['kp/']=0xF,
}

function love.keypressed(k)
  if k=='lshift' or k=='rshift' then steps=steps+1 return end
  if k=='lctrl'  or k=='rctrl'  then steps=steps-1 return end
  chip8:keyDown(binds[k])
end
function love.keyreleased(k)
  --print(binds[k],'UP')
  chip8:keyUp(binds[k])
end
