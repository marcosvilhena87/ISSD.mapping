-- Isolated trajectory calibration: replay Right+Down+B from $0800 to $0C00.
-- Run ALONE in BizHawk, with $0800 holding the ball, not alongside main.lua.
local function script_dir()
 local src=debug.getinfo(1,"S").source
 if src:sub(1,1)=="@" then src=src:sub(2) end
 return src:match("^(.*[\\/])") or "./"
end
local DIR=script_dir()
local cfg=dofile(DIR.."../core/config.lua")
local Memory=dofile(DIR.."../core/memory.lua")
local mem=Memory.new(cfg)
local CARRIER=0x0800
local RECEIVER=0x0C00
local OBSERVE_FRAMES=120
local BUTTON_FRAMES=1 -- adjust to match manually successful B input
local OUTFILE=DIR.."../diagonal_trajectory_frames.csv"
local function xy(base)
 return mem.s16(base+cfg.OFFSET.world_x),mem.s16(base+cfg.OFFSET.world_y)
end
local function dist(x,y,a,b)
 return math.sqrt((x-a)^2+(y-b)^2)
end
local function sample()
 return mem.s16(cfg.ADDR.ball_x),mem.s16(cfg.ADDR.ball_y),
        mem.u16(cfg.ADDR.possession),mem.u16(cfg.ADDR.team_possession),
        mem.u16(cfg.ADDR.game_state)
end
local function nearest_cpu(x,y)
 local best,minimum=nil,math.huge
 for base=cfg.CPU_FIRST+cfg.PLAYER_STRIDE,cfg.CPU_LAST,cfg.PLAYER_STRIDE do
  local ex,ey=xy(base)
  local d=dist(x,y,ex,ey)
  if d<minimum then best,minimum=base,d end
 end
 return best,minimum
end
local function run()
 if not savestate or not savestate.create or not savestate.save
    or not savestate.load then error("In-memory savestates unavailable") end
 local bx,by,owner,team,gs=sample()
 if owner~=CARRIER or gs~=0 then
  error("Load active match state with $0800 in individual possession") end
 local rx,ry=xy(RECEIVER)
 local dx,dy=rx-bx,ry-by
 local projection=(dx+dy)/math.sqrt(2)
 local theoretical_miss=math.abs(dy-dx)/math.sqrt(2)
 local ss=savestate.create()
 savestate.save(ss)
 local f=assert(io.open(OUTFILE,"w"))
 f:write("frame,ball_x,ball_y,ball_dx,ball_dy,owner,team,game_state,receiver_x,receiver_y,receiver_distance,nearest_cpu,nearest_cpu_ball_distance,nearest_cpu_receiver_distance,predicted_45deg_miss,predicted_projection,owner_signal_class\n")
 local function log(frame)
  local x,y,who,side,state=sample()
  local tx,ty=xy(RECEIVER)
  local cpu,ball_gap=nearest_cpu(x,y)
  local _,receiver_gap=nearest_cpu(tx,ty)
  local class=who==RECEIVER and "TARGET_OWNER_SIGNAL"
   or who>=cfg.CPU_FIRST and who<=cfg.CPU_LAST and "CPU_OWNER_SIGNAL"
   or who==0 and "UNOWNED_SIGNAL" or "OTHER_OWNER_SIGNAL"
  f:write(table.concat({frame,x,y,x-bx,y-by,who,side,state,
   tx,ty,string.format("%.3f",dist(x,y,tx,ty)),
   cpu or "",string.format("%.3f",ball_gap),
   string.format("%.3f",receiver_gap),
   string.format("%.3f",theoretical_miss),
   string.format("%.3f",projection),class},",").."\n")
 end
 local ok,err=pcall(function()
  log(0)
  for frame=1,OBSERVE_FRAMES do
   if frame<=BUTTON_FRAMES then
    joypad.set({Right=true,Down=true,B=true},cfg.PLAYER)
   else
    joypad.set({},cfg.PLAYER)
   end
   emu.frameadvance()
   log(frame)
  end
 end)
 joypad.set({},cfg.PLAYER)
 savestate.load(ss)
 f:close()
 if not ok then error(err) end
 print("Trajectory audit written to "..OUTFILE)
 print("Predicted 45deg miss: "..string.format("%.2f",theoretical_miss))
 print("Signals are observations, not physical pass verification.")
end
run()
