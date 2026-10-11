-- Passive calibration from actual defensive pass commands and ball RAM.
-- No assumption that button presses were accepted by the game.
local M={}
function M.new(config,players)
 local obj={active=nil}
 local function direction_vec(direction,vertical)
  local dx,dy=0,0
  if direction=="Right" then dx=1 elseif direction=="Left" then dx=-1
  elseif direction=="Up" then dy=-1 elseif direction=="Down" then dy=1 end
  if vertical=="Up" then dy=-1 elseif vertical=="Down" then dy=1 end
  local n=math.sqrt(dx*dx+dy*dy)
  if n==0 then return nil,nil end
  return dx/n,dy/n
 end
 function obj.observe(frame,p,owner,bx,by,outcome)
  local events={}
  if not p then obj.active=nil;return events end
  if not obj.active or obj.active.sequence~=p.sequence then
   obj.active={sequence=p.sequence,start=p.frame,last_x=p.ball_x,
    last_y=p.ball_y,max_speed=0,travel=0,samples=0,release=nil,
    max_offset=0,observed_direction=nil,owner_left=false,physical_release=nil}
  end
  local a=obj.active
  local age=frame-p.frame
  local dx,dy=bx-a.last_x,by-a.last_y
  local speed=math.sqrt(dx*dx+dy*dy)
  a.max_speed=math.max(a.max_speed,speed)
  a.travel=a.travel+speed
  a.samples=a.samples+1
  if owner~=p.passer then
   a.owner_left=true
   if not a.release then a.release=frame end
  end
  -- Physical release is corroborated by owner departure and actual ball travel.
  -- Owner changes alone are not sufficient proof of a successful pass.
  local start_dx,start_dy=bx-p.ball_x,by-p.ball_y
  local displacement=math.sqrt(start_dx*start_dx+start_dy*start_dy)
  if not a.physical_release and a.owner_left and displacement>=8 then
   a.physical_release=frame
   events[#events+1]={kind="DEF_PASS_RELEASE_CONFIRMED",
    sequence=p.sequence,age=age,owner=owner,travel=a.travel,
    displacement=displacement,mode=p.intent,direction=p.direction,
    receiver=p.receiver}
  end
  local vx,vy=direction_vec(p.direction,p.vertical)
  local travel_x,travel_y=bx-p.ball_x,by-p.ball_y
  local along=vx and (travel_x*vx+travel_y*vy) or nil
  local cross=vx and math.abs(travel_x*vy-travel_y*vx) or nil
  if cross then a.max_offset=math.max(a.max_offset,cross) end
  if (age==1 or age==3 or age==6 or age==12) and not outcome then
   events[#events+1]={kind="DEF_PASS_FLIGHT_SAMPLE",sequence=p.sequence,
    age=age,owner=owner,speed=speed,travel=a.travel,along=along,
    cross=cross,mode=p.intent,direction=p.direction,receiver=p.receiver}
  end
  if outcome then
   events[#events+1]={kind="DEF_PASS_FLIGHT_OUTCOME",sequence=p.sequence,
    age=age,owner=owner,speed=speed,travel=a.travel,along=along,
    cross=cross,mode=p.intent,direction=p.direction,receiver=p.receiver,
    max_speed=a.max_speed,max_offset=a.max_offset,
    release_age=a.release and a.release-a.start or nil,
    samples=a.samples,outcome=outcome,
    physical_release_age=a.physical_release and a.physical_release-a.start or nil,
    release_confirmed=a.physical_release~=nil,
    disposition=a.physical_release and "RELEASE_OBSERVED"
     or (a.owner_left and "OWNER_LEFT_WITHOUT_TRAVEL" or "NO_RELEASE_EVIDENCE")}
   obj.active=nil
  end
  a.last_x=bx;a.last_y=by
  return events
 end
 return obj
end
return M
