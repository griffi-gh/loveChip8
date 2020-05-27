bit=require'bitty'
require'fn'
require'rom'
require'chip8'

function love.load()
  chip8:run()
end

function love.update()
  if chip8.running then
    chip8.loop()
  end
end
