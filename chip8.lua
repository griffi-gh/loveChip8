chip8={running=false}

debug1=true

local function oc(C)
  return bit.band(C,0xF000)
end
local function ec(C)
  return bit.band(C,0x0FFF)
end

function chip8:stop()
  self.running=false
  chip8.init()
  print'[STOP]'
end 

function chip8:run()
  self:init()
  self.running=true
end

function chip8.init()
  opcode = 0x00--current opcode (2 bytes)
  mem={} --(4096 byte)
  for i=0,0xFFF do mem[i]=0x00 end
  
  print'loading ROM...'
  for i=0x200,0xFFF do 
    local d=ROM[i-0x200] 
    if d then
      mem[i]=d
    else
      print'end'
      break
    end
  end
  
  V={[0]=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} --cpu registers V0 V1 V2 V3 V4 V5 V6 V7 V8 V9 VA VB VC VD VE (VF -carry)
  I,pc=0x000,0x200 --Index register,program counter (start 0x200)
  function chip8.cls()
    --64x32 screen
    gfx={}
    for i=1,64 do gfx[i]={} end 
  end
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

function chip8.loop()
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
    love.timer.sleep(0.2)
  end
  
  if opcode==0x0000 then
    --print('[WARN/LOW]\tNOP at',tohex(pc,3),pc)
    pc=pc+2 --nop
  elseif s==0x4000 then
    local xx,vv=xxvv()
    if xx~=vv then
      pc=pc+4
    else
      pc=pc+2
    end
  elseif s==0x3000 then
    local xx,vv=xxvv()
    if xx==vv then
      pc=pc+4
    else
      pc=pc+2
    end
  elseif s==0x5000 then
    local v1=V[bit.brshift(bit.band(opcode,0x0F00),8)]
    local v2=V[bit.brshift(bit.band(opcode,0x00F0),4)]
    if v1==v2 then
      pc=pc+4
    else 
      pc=pc+2
    end
  elseif opcode==0x00E0 then
    chip8.cls() --clear screen
    pc=pc+2
  elseif s==0xA000 then
    I=ec(opcode) --set index register
    pc=pc+2
  elseif s==0x1000 then
    pc=ec(opcode)
  elseif s==0x2000 then
    stack[sp]=pc --call
    sp=sp+1
    pc=ec(opcode)
  elseif s==0x6000 then
    V[bit.brshift(bit.band(opcode,0x0F00),8)]=bit.band(opcode,0x00FF)
    pc=pc+2
  elseif opcode==0x00EE then
    sp=sp-1 --ret
    pc=stack[sp]
  elseif s==0xD000 then
    print'draw'
    pc=pc+2
  elseif bit.band(opcode,0xF00F)==0x8004 then
    --adds the value of VY to VX
    local rh,lh=bit.band(opcode,0x00F0),bit.band(opcode,0x0F00)
    if V[bit.brshift(rh,4)] > (0xFF - V[bit.brshift(lh,8)]) then
      V[0xF] = 1 --carry
    else
      V[0xF] = 0
    end
    local va=bit.brshift(lh,8)
    V[va]=V[va]+V[bit.brshift(rh,4)];
    pc=pc+2
  elseif bit.band(opcode,0xF0FF)==0xF033 then
    local val=V[bit.brshift(bit.band(opcode,0x0F00),8)]
    if not val then
      print'[ERR]\t0xFX33 no value'
      chip8:stop()
      return
    end
    mem[I]=val/100
    mem[I+1]=(val/10)%10
    mem[I+2]=(val%100)%10
    pc=pc+2
  else
    print('[WARN/HIGH]\tUknown opcode',tohex(opcode,4),tohex(pc)) --chip8:stop()
    pc=pc+2
    return
  end
  
  if sound_timer==1 then print'BEEP' end
  delay_timer=math.max(0,delay_timer-1)
  sound_timer=math.max(0,sound_timer-1)
end
