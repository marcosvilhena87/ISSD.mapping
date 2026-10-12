-- Controlled 4x4 directional action matrix for ISS Deluxe / BizHawk.
-- Run this script ALONE (not alongside main.lua) with a live match,
-- ball under MY individual control, and a reproducible starting position.
-- Each test reloads an in-memory savestate; no tactical behavior is changed.
local function script_dir()
 local src=debug.getinfo(1,"S").source
 if src:sub(1,1)=="@" then src=src:sub(2) end
 return src:match("^(.*[\\/])") or "./"
end
local DIR=script_dir()
local config=dofile(DIR.."../core/config.lua")
local Memory=dofile(DIR.."../core/memory.lua")
local mem=Memory.new(config)
local ReplaySnapshot=dofile(DIR.."../core/replay_snapshot.lua")
local directions={
 {"Right","Up"},{"Right","Down"},{"Left","Up"},{"Left","Down"}
}
local actions={"A","B","X","Y"} -- requested order
local OBSERVE_FRAMES=90
local TARGET_RECEIVER=0x0C00 -- set nil to disable targeted trace
local CONTACT_RADIUS=28
local SETTLE_FRAMES=3
local OUTFILE=DIR.."../diagonal_action_matrix.csv"
local function sample()
 return {
  x=mem.s16(config.ADDR.ball_x),
  y=mem.s16(config.ADDR.ball_y),
  owner=mem.u16(config.ADDR.possession),
  team=mem.u16(config.ADDR.team_possession),
  game_state=mem.u16(config.ADDR.game_state),
  selected=mem.u16(config.ADDR.my_ctrl)
 }
end
local function xy(base)
 return mem.s16(base+config.OFFSET.world_x),mem.s16(base+config.OFFSET.world_y)
end
local function distance(x,y,a,b)
 return math.sqrt((x-a)^2+(y-b)^2)
end
local function valid_my(base)
 return type(base)=="number" and base>=config.MY_FIRST
  and base<=config.MY_LAST and base%config.PLAYER_STRIDE==0
end
local function csv(v)
 if v==nil then return "" end
 local s=tostring(v)
 if s:find('[,\\"\n]') then return '"'..s:gsub('"','""')..'"' end
 return s
end
local function write(file,fields)
 local out={}
 for i=1,#fields do out[#out+1]=csv(fields[i]) end
 file:write(table.concat(out,",").."\n")
end
local function tick(pad)
 joypad.set(pad or {},config.PLAYER)
 emu.frameadvance()
end
local function run()
 local initial=sample()
 if initial.game_state~=0 or initial.owner<config.MY_FIRST
    or initial.owner>config.MY_LAST then
  error("Start with active play and ball held by MY player; no actions sent")
 end
 local snapshot=ReplaySnapshot.capture()
 local f=assert(io.open(OUTFILE,"w"))
 write(f,{"index","horizontal","vertical","button","command",
  "base_ball_x","base_ball_y","base_owner","base_team","base_selected",
  "action_dx","action_dy","action_owner","action_team",
  "end_dx","end_dy","end_owner","end_team","end_game_state",
  "max_displacement","first_owner_change_frame","first_ball_change_frame",
  "note","target_receiver","target_min_distance","target_min_frame",
  "first_target_owner_frame","first_cpu_owner_frame","outcome_observation"})
 local index=0
 for _,d in ipairs(directions) do
  for _,button in ipairs(actions) do
   index=index+1
   snapshot.restore()
   for i=1,SETTLE_FRAMES do tick({}) end
   local before=sample()
   local pad={[d[1]]=true,[d[2]]=true,[button]=true}
   tick(pad)
   local after=sample()
   local max_distance=math.sqrt((after.x-before.x)^2+(after.y-before.y)^2)
   local first_owner_change=after.owner~=before.owner and 0 or nil
   local first_ball_change=(after.x~=before.x or after.y~=before.y) and 0 or nil
   local target=valid_my(TARGET_RECEIVER) and TARGET_RECEIVER or nil
   if target==before.owner then target=nil end
   local min_distance=math.huge
   local min_frame=nil
   local target_owner_frame=nil
   local cpu_owner_frame=nil
   local function observe(snapshot,frame)
    if target then
     local tx,ty=xy(target)
     local gap=distance(snapshot.x,snapshot.y,tx,ty)
     if gap<min_distance then min_distance=gap;min_frame=frame end
     if snapshot.owner==target and target_owner_frame==nil then
      target_owner_frame=frame
     end
    end
    if snapshot.owner>=config.CPU_FIRST and snapshot.owner<=config.CPU_LAST
     and cpu_owner_frame==nil then cpu_owner_frame=frame end
   end
   observe(after,0)
   local final=after
   for n=1,OBSERVE_FRAMES do
    tick({})
    final=sample()
    observe(final,n)
    local distance=math.sqrt((final.x-before.x)^2+(final.y-before.y)^2)
    max_distance=math.max(max_distance,distance)
    if not first_owner_change and final.owner~=before.owner then first_owner_change=n end
    if not first_ball_change and
       (final.x~=before.x or final.y~=before.y) then first_ball_change=n end
   end
   write(f,{index,d[1],d[2],button,
    d[1].."+"..d[2].."+"..button,
    before.x,before.y,before.owner,before.team,before.selected,
    after.x-before.x,after.y-before.y,after.owner,after.team,
    final.x-before.x,final.y-before.y,final.owner,final.team,
    final.game_state,string.format("%.2f",max_distance),
    first_owner_change,first_ball_change,
    "OBSERVATION_ONLY_NOT_CONFIRMED_ACTION",
    target,target and string.format("%.2f",min_distance) or nil,
    min_frame,target_owner_frame,cpu_owner_frame,
    target_owner_frame and "TARGET_OWNER_SIGNAL_OBSERVED"
     or cpu_owner_frame and "CPU_OWNER_SIGNAL_OBSERVED"
     or target and min_distance<=CONTACT_RADIUS and "TARGET_PROXIMITY_ONLY"
     or "UNRESOLVED"})
   f:flush()
   print(string.format("Diagonal probe %d/16: %s+%s+%s",index,d[1],d[2],button))
  end
 end
 snapshot.restore()
 snapshot.close()
 joypad.set({},config.PLAYER)
 f:close()
 print("Diagonal matrix CSV: "..OUTFILE)
end
run()
