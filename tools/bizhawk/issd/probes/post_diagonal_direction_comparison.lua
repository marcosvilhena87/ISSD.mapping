-- Controlled A/B test from a single $0A00 possession savestate.
-- Run alone, not concurrently with main.lua.
local function dir()
 local s=debug.getinfo(1,"S").source
 if s:sub(1,1)=="@" then s=s:sub(2) end
 return s:match("^(.*[\\/])") or "./"
end
local D=dir()
local cfg=dofile(D.."../core/config.lua")
local mem=dofile(D.."../core/memory.lua").new(cfg)
local ReplaySnapshot=dofile(D.."../core/replay_snapshot.lua")
-- Select the experiment according to the current ball carrier.
-- 0x0A00 compares diagonal directions toward $0C00.
local CARRIER=0x0A00
local actions={
 {id="LEFT_UP_B",pad={Left=true,Up=true,B=true},held=1,target=0x0C00},
 {id="LEFT_DOWN_B",pad={Left=true,Down=true,B=true},held=1,target=0x0C00},
 {id="RIGHT_A",pad={Right=true,A=true},held=5,target=nil},
}
-- Used only if neither savestate API is exposed in this Lua environment.
-- Reload the SAME savestate from the EmuHawk UI before every manual run.
local MANUAL_ACTION="LEFT_UP_B" -- change to LEFT_DOWN_B, then RIGHT_A
local FRAMES=120
local FILE=D.."../post_diagonal_direction_comparison.csv"
local SUMMARY=D.."../post_diagonal_outcomes.csv"
local function xy(b)
 return mem.s16(b+cfg.OFFSET.world_x),mem.s16(b+cfg.OFFSET.world_y)
end
local function dist(x,y,u,v)
 return math.sqrt((x-u)^2+(y-v)^2)
end
local function ball()
 return mem.s16(cfg.ADDR.ball_x),mem.s16(cfg.ADDR.ball_y)
end
local function owner() return mem.u16(cfg.ADDR.possession) end
local function nearest_cpu(x,y)
 local d=math.huge
 for b=cfg.CPU_FIRST+cfg.PLAYER_STRIDE,cfg.CPU_LAST,cfg.PLAYER_STRIDE do
  local u,v=xy(b)
  d=math.min(d,dist(x,y,u,v))
 end
 return d
end
local function run()
 if mem.u16(cfg.ADDR.game_state)~=0 or owner()~=CARRIER then
  error("Load active gameplay with $0A00 individually possessing the ball")
 end
 local has_memory=type(memorysavestate)=="table"
     and type(memorysavestate.savecorestate)=="function"
     and type(memorysavestate.loadcorestate)=="function"
 local has_disk=type(savestate)=="table"
     and type(savestate.save)=="function"
     and type(savestate.load)=="function"
 local manual=not has_memory and not has_disk
 local snapshot=not manual and ReplaySnapshot.capture() or nil
 local selected={}
 if manual then
  for _,action in ipairs(actions) do
   if action.id==MANUAL_ACTION then selected[1]=action end
  end
  if #selected~=1 then error("Unknown MANUAL_ACTION: "..tostring(MANUAL_ACTION)) end
  print("MANUAL MODE: run "..MANUAL_ACTION.." ONLY; reload the identical state before another run")
 else
  selected=actions
 end
 local output=manual and (D.."../post_diagonal_"..MANUAL_ACTION..".csv") or FILE
 local f=assert(io.open(output,"w"))
 f:write("action,frame,held_frames,ball_x,ball_y,ball_displacement,owner,team,game_state,target,target_distance,nearest_cpu_ball,nearest_cpu_target,signal\n")
 local summaries={}
 local ok,err=pcall(function()
  for _,action in ipairs(selected) do
   if snapshot then snapshot.restore() end
   local ox,oy=ball()
   local first_target,first_cpu,first_other_my,first_state_exit=nil,nil,nil,nil
   local min_target,max_displacement=math.huge,0
   for frame=0,FRAMES do
    if frame>0 then
     joypad.set(frame<=action.held and action.pad or {},cfg.PLAYER)
     emu.frameadvance()
    end
    local x,y=ball()
    local who=owner()
    local signal=action.target and who==action.target and "TARGET_OWNER_SIGNAL"
      or who>=cfg.CPU_FIRST and who<=cfg.CPU_LAST and "CPU_OWNER_SIGNAL"
      or who==0 and "UNOWNED_SIGNAL" or "OTHER_OWNER_SIGNAL"
    local tx,ty=nil,nil
    if action.target then tx,ty=xy(action.target) end
    max_displacement=math.max(max_displacement,dist(ox,oy,x,y))
    if tx then min_target=math.min(min_target,dist(x,y,tx,ty)) end
    if frame>0 then
     if action.target and who==action.target and not first_target then first_target=frame end
     if who>=cfg.CPU_FIRST and who<=cfg.CPU_LAST and not first_cpu then first_cpu=frame end
     if who>=cfg.MY_FIRST and who<=cfg.MY_LAST and who~=CARRIER
       and who~=action.target and not first_other_my then first_other_my=frame end
     if mem.u16(cfg.ADDR.game_state)~=0 and not first_state_exit then first_state_exit=frame end
    end
    local values={action.id,frame,action.held,x,y,
     string.format("%.3f",dist(ox,oy,x,y)),who,
     mem.u16(cfg.ADDR.team_possession),mem.u16(cfg.ADDR.game_state),
     action.target or "",tx and string.format("%.3f",dist(x,y,tx,ty)) or "",
     string.format("%.3f",nearest_cpu(x,y)),
     tx and string.format("%.3f",nearest_cpu(tx,ty)) or "",signal}
    f:write(table.concat(values,",").."\n")
   end
   local earliest=math.huge
   local outcome="UNRESOLVED"
   for _,candidate in ipairs({
       {first_target,"TARGET_RECEIVED"},
       {first_cpu,"CPU_INTERCEPTED"},
       {first_other_my,"OTHER_MY_RECEIVED"}
   }) do
    if candidate[1] and candidate[1]<earliest then
     earliest=candidate[1];outcome=candidate[2]
    end
   end
   summaries[#summaries+1]={action.id,outcome,first_target or "",
     first_cpu or "",first_other_my or "",first_state_exit or "",
     action.target and string.format("%.3f",min_target) or "",
     string.format("%.3f",max_displacement)}
   f:flush()
  end
 end)
 joypad.set({},cfg.PLAYER)
 if snapshot then snapshot.restore();snapshot.close() end
 f:close()
 if ok then
  local summary_path=manual and (D.."../post_diagonal_outcomes_"..MANUAL_ACTION..".csv") or SUMMARY
  local sf=assert(io.open(summary_path,"w"))
  sf:write("action,outcome,first_target_frame,first_cpu_frame,first_other_my_frame,first_game_state_exit,min_target_distance,max_ball_displacement\n")
  for _,values in ipairs(summaries) do sf:write(table.concat(values,",").."\n") end
  sf:close()
 end
 if not ok then error(err) end
 print("A/B CSV: "..output)
end
run()
