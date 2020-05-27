chip8={running=false,w=64,h=32}
ROM={}
local BEEP = love.audio.newSource('beep.mp3','static')

local debug1=false --debug opcode
local debug2=false --debug draw

local function oc(C)
  return bit.band(C,0xF000)
end
local function ec(C)
  return bit.band(C,0x0FFF)
end

function chip8:keyDown(i)
  key[i]=true
end
function chip8:keyUp(i)
  key[i]=false
end

function chip8:stop(hide)
  self.running=false
  if not hide then print'[STOP]' end
end 

function chip8:loadFile(f)
  self:stop(1)
  local file = io.open(f, "rb")
  local str = file:read("*a")
  ROM = {str:byte(1, #str)}
  file:close()
end

function chip8:run()
  self:init()
  self.running=true
end

function chip8.cls()
  --64x32 screen
  gfx={}
  for i=1,chip8.w do 
    gfx[i]={} 
    for j=1,chip8.h do
      gfx[i][j]=false
    end
  end 
end

function bytel(n) --PLACEHOLDER
  local top=c or 255
  local l=l or 0
  if n>top then
    n=n-(top+1)
  elseif n<l then
    n=(top+1)-math.abs(n)-l
  end
  return n
end


chip8.font={
        0xF0, 0x90, 0x90, 0x90, 0xF0, -- 0
        0x20, 0x60, 0x20, 0x20, 0x70, -- 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, -- 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, -- 3
        0x90, 0x90, 0xF0, 0x10, 0x10, -- 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, -- 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, -- 6
        0xF0, 0x10, 0x20, 0x40, 0x40, -- 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, -- 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, -- 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, -- A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, -- B
        0xF0, 0x80, 0x80, 0x80, 0xF0, -- C
        0xE0, 0x90, 0x90, 0x90, 0xE0, -- D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, -- E
        0xF0, 0x80, 0xF0, 0x80, 0x80  -- F
    }
    
function chip8.init()
  opcode = 0x00--current opcode (2 bytes)
  mem={} --(4096 byte)
  for i=0,0xFFF do mem[i]=0x00 end
  
  print'Loading font...'
  for ii=0,0xFFFF do
    local d=chip8.font[ii+1]
    if d then
      mem[ii]=d
    else
      break 
    end
  end
  
  print'loading ROM...'
  ROM.start=ROM.start or 0x200
  for i=ROM.start,0xFFFF do 
    local d=ROM[i-ROM.start+1] 
    if d then
      mem[i]=d
    else
      break
    end
  end
  
  print'OK!'
  
  V={[0]=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} --cpu registers V0 V1 V2 V3 V4 V5 V6 V7 V8 V9 VA VB VC VD VE (VF -carry)
  I,pc=0x000,0x200 --Index register,program counter (start 0x200)
  chip8.cls()
  delay_timer,sound_timer=0,0
  stack={} --(16)
  sp=0 --stack pointer
  key={} --(16) keypad
end

local function xxvv()
  local vv=V[bit.brshift(bit.band(opcode,0x0F00),8)]
  local xx=bit.band(opcode,0x00FF)
  return xx,vv
end
local function v1v2()
  return V[bit.brshift(bit.band(opcode,0x0F00),8)],V[bit.brshift(bit.band(opcode,0x00F0),4)]
end
local function fkey()
  return key[V[bit.brshift(bit.band(opcode,0x0F00),8)]]
end

function chip8.loop()
  if chip8.running then
    if mem[pc]==nil or mem[pc+1]==nil then 
      print('[ERR]\tNo data at ',tohex(pc))
      chip8:stop()
      return 
    end
    
    opcode = bit.bor(
      bit.blshift(mem[pc],8),
      mem[pc+1]
    )
    local s=oc(opcode)
    
    if debug1 and ppc~=pc then
      ppc=pc
      print(tohex(pc,4),tohex(opcode,4))
      love.timer.sleep(0.3)
    end
    
    if opcode==0x0000 then
      pc=pc+2 --nop
    elseif s==0x1000 then
      pc=ec(opcode)
    elseif s==0x2000 then
      stack[sp]=pc --call
      sp=sp+1
      pc=ec(opcode)
    elseif s==0x3000 then
      local xx,vv=xxvv()
      if xx==vv then
        pc=pc+4
      else
        pc=pc+2
      end
    elseif s==0x4000 then
      local xx,vv=xxvv()
      if xx==vv then
        pc=pc+2
      else
        pc=pc+4
      end
    elseif s==0x5000 then
      local v1,v2=v1v2()
      if v1==v2 then
        pc=pc+4
      else 
        pc=pc+2
      end
    elseif s==0x6000 then
      V[bit.brshift(bit.band(opcode,0x0F00),8)]=bit.band(opcode,0x00FF)
      pc=pc+2
    elseif s==0x7000 then
      local i=bit.brshift(bit.band(opcode,0x0F00),8)
      local val=bit.band(opcode,0x00FF)
      V[i]=bytel(V[i]+val)
      pc=pc+2
    elseif s==0x9000 then
      local v1,v2=v1v2()
      if v1==v2 then
        pc=pc+2
      else 
        pc=pc+4
      end
    elseif s==0xD000 then --print'draw'
      local x = V[bit.brshift(bit.band(opcode,0x0F00),8)]
      local y = V[bit.brshift(bit.band(opcode,0x00F0),4)]
      local h = bit.band(opcode,0x000F)
      V[0xF]=0
      for i=0,h-1 do --y
        local p=mem[i+I]
        for j=0,7 do --x
          if bit.band(p,bit.brshift(0x80,j))~=0 then
            local ix=x+j+(y+i)*chip8.w
            if ix==1 then 
              V[0xF]=1 
            end
            local tdx,tdy=x+j+1,y+i+1
            local rx,ry=tdx%(chip8.w+1),tdy%(chip8.h+1)
            --math.max(math.min(tdx,chip8.w+1),0),math.max(math.min(tdy,chip8.h+1),0)
            if rx>0 and rx<chip8.w+1 and ry>0 and ry<chip8.h+1 then
              gfx[rx][ry]=not(gfx[rx][ry])
            end--true
            --else
              --print('[WARN]','drawing out of screen',tdx-1,tdy-1)
            --end
            if debug2 then 
              print('[DRAWPIX]',x+j,y+i) 
            end
          end
        end
      end
      pc=pc+2
    elseif bit.band(opcode,0xF0FF)==0xF007 then
      V[bit.brshift(bit.band(opcode,0x0F00),8)]=delay_timer
      pc=pc+2
    elseif bit.band(opcode,0xF0FF)==0xF015 then
      delay_timer=V[bit.brshift(bit.band(opcode,0x0F00),8)]
      pc=pc+2
    elseif bit.band(opcode,0xF0FF)==0xF018 then
      sound_timer=V[bit.brshift(bit.band(opcode,0x0F00),8)]
      pc=pc+2
    elseif bit.band(opcode,0xF0FF)==0xF029 then
      I=V[bit.brshift(bit.band(opcode,0x0F00),8)]*0x5;
      pc=pc+2
    elseif bit.band(opcode,0xF0FF)==0xF01E then
      local ii=bit.brshift(bit.band(opcode,0x0F00),8)
      if I+V[ii] > 0xFFF then
        V[0xF]=1
      else
        V[0xF]=0
      end
      I=I+V[ii]
      pc=pc+2
    elseif opcode==0x00E0 then
      chip8.cls() --clear screen
      pc=pc+2
    elseif s==0xA000 then
      I=ec(opcode) --set index register
      pc=pc+2
    elseif opcode==0x00EE then
      sp=sp-1 --ret
      pc=stack[sp]+2
    elseif bit.band(opcode,0xF00F)==0x8004 then
      --adds the value of VY to VX
      local rh,lh=bit.band(opcode,0x00F0),bit.band(opcode,0x0F00)
      if V[bit.brshift(rh,4)] > (0xFF - V[bit.brshift(lh,8)]) then
        V[0xF] = 1 --carry
      else
        V[0xF] = 0
      end
      local va=bit.brshift(lh,8)
      V[va]=bytel(V[va]+V[bit.brshift(rh,4)]);
      pc=pc+2
    elseif bit.band(opcode,0xF00F)==0x8000 then
      local a=bit.brshift(bit.band(opcode,0x0F00),8)
      local b=bit.brshift(bit.band(opcode,0x00F0),4)
      V[a]=V[b]
      pc=pc+2
    elseif bit.band(opcode,0xF0FF)==0xF033 then
      local val=V[bit.brshift(bit.band(opcode,0x0F00),8)]
      mem[I]=val/100
      mem[I+1]=(val/10)%10
      mem[I+2]=(val%100)%10
      pc=pc+2
    elseif bit.band(opcode,0xF0FF)==0xF065 then
      local v=bit.brshift(bit.band(opcode,0x00F0),4)
      for i=0,v do
        V[i]=mem[I+i]
      end
      pc=pc+2
    elseif bit.band(opcode,0xF0FF)==0xE09E then
      if fkey() then
        pc=pc+4
      else
        pc=pc+2
      end
    elseif bit.band(opcode,0xF0FF)==0xE0A1 then
      if fkey() then
        pc=pc+2
      else
        pc=pc+4
      end
    else
      print('[WARN/HIGH]\tUknown opcode',tohex(opcode,4),tohex(pc)) --chip8:stop()
      pc=pc+2
      return
    end
    
    if sound_timer==1 then
      BEEP:play()
    end
    delay_timer=math.max(0,delay_timer-1)
    sound_timer=math.max(0,sound_timer-1)
  end
end
