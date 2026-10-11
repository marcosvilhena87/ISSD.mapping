-- Passive five-direction outlet evaluation. No controller actions.
local M={}
function M.new(config,players,field_side)
 local c=config.FIVE_DIRECTION_PASS_OBSERVER
 local o={last_frame=-99999}
 local function clearance(ax,ay,bx,by)
  local dx,dy=bx-ax,by-ay
  local length2=dx*dx+dy*dy
  local nearest=math.huge
  players.each_cpu(function(base)
   if base~=config.CPU_FIRST then
    local cx,cy=players.xy(base)
    local t=length2>0 and math.max(0,math.min(1,
        ((cx-ax)*dx+(cy-ay)*dy)/length2)) or 0
    local d=math.sqrt((cx-ax-t*dx)^2+(cy-ay-t*dy)^2)
    nearest=math.min(nearest,d)
   end
  end)
  return nearest
 end
 function o.evaluate(frame,carrier,actual)
  if frame-o.last_frame<c.sample_frames then return nil end
  if not players.valid_my_base(carrier) or carrier==config.MY_FIRST then return nil end
  local dir=field_side.attack_direction()
  if dir~=1 and dir~=-1 then return nil end
  o.last_frame=frame
  local x,y=players.xy(carrier)
  local sectors={FRONT=nil,LEFT=nil,RIGHT=nil,DIAG_LEFT=nil,DIAG_RIGHT=nil}
  local counts={FRONT=0,LEFT=0,RIGHT=0,DIAG_LEFT=0,DIAG_RIGHT=0}
  local all_diagonal={}
  players.each_my(function(base)
   if base~=carrier and base~=config.MY_FIRST then
    local tx,ty=players.xy(base)
    local forward=(tx-x)*dir
    local lateral=ty-y
    local dist=math.sqrt((tx-x)^2+lateral*lateral)
    -- Log every teammate as a potential diagonal receiver, including
    -- players filtered out before sector ranking.
    local sx=dir/math.sqrt(2)
    local sy=lateral<0 and -1/math.sqrt(2) or 1/math.sqrt(2)
    local diag_projection=(tx-x)*sx+lateral*sy
    local diag_miss=math.abs((tx-x)*sy-lateral*sx)
    local diag_angle=dist>0 and math.deg(math.acos(
      math.max(-1,math.min(1,diag_projection/dist)))) or 180
    local diag_lane=diag_projection>0
      and clearance(x,y,x+sx*diag_projection,y+sy*diag_projection) or 0
    local within_range=dist>=c.min_distance and dist<=c.max_distance
    local within_backward=forward>=-c.max_backward
    local diag_receiver=math.huge
    players.each_cpu(function(cpu)
     if cpu~=config.CPU_FIRST then
      local cx,cy=players.xy(cpu)
      diag_receiver=math.min(diag_receiver,
       math.sqrt((cx-tx)^2+(cy-ty)^2))
     end
    end)
    local diag_reason="OK"
    if not within_range then diag_reason="DISTANCE"
    elseif not within_backward then diag_reason="BACKWARD_LIMIT"
    elseif diag_projection<=0 then diag_reason="BEHIND_RAY"
    elseif diag_miss>c.command_max_miss then diag_reason="COMMAND_MISS"
    elseif diag_angle>c.command_max_angle then diag_reason="COMMAND_ANGLE"
    elseif diag_lane<c.safe_command_lane then diag_reason="COMMAND_LANE"
    elseif diag_receiver<c.safe_command_receiver then diag_reason="RECEIVER_PRESSURE" end
    all_diagonal[#all_diagonal+1]={
      base=base,command=(dir==1 and "Right" or "Left")
       .."+"..(lateral<0 and "Up" or "Down"),
      distance=dist,forward=forward,lateral=lateral,
      projection=diag_projection,miss=diag_miss,angle=diag_angle,
      lane=diag_lane,receiver_clearance=diag_receiver,
      eligible=diag_reason=="OK",reason=diag_reason
    }
    if within_range and within_backward then
     local sector
     if forward>=c.min_forward and math.abs(lateral)<=forward*c.front_ratio then
      sector="FRONT"
     elseif forward>=c.min_forward then
      sector=lateral<0 and "DIAG_LEFT" or "DIAG_RIGHT"
     else sector=lateral<0 and "LEFT" or "RIGHT" end
     local lane=clearance(x,y,tx,ty)
     local receiver=math.huge
     players.each_cpu(function(cpu)
      if cpu~=config.CPU_FIRST then
       local cx,cy=players.xy(cpu)
       receiver=math.min(receiver,math.sqrt((cx-tx)^2+(cy-ty)^2))
      end
     end)
     local score=0.45*math.min(1,lane/c.safe_lane)
       +0.35*math.min(1,receiver/c.safe_receiver)
       +0.20*math.min(1,math.max(0,forward)/c.good_progress)
     -- Compare actual receiver geometry with executable cardinal/diagonal rays.
     local candidate_direction
     local ray_x,ray_y
     if sector=="FRONT" then
      candidate_direction=dir==1 and "Right" or "Left";ray_x=dir;ray_y=0
     elseif sector=="LEFT" or sector=="RIGHT" then
      candidate_direction=lateral<0 and "Up" or "Down"
      ray_x=0;ray_y=lateral<0 and -1 or 1
     else
      candidate_direction=(dir==1 and "Right" or "Left")
        .."+"..(lateral<0 and "Up" or "Down")
      ray_x=dir/math.sqrt(2)
      ray_y=(lateral<0 and -1 or 1)/math.sqrt(2)
     end
     local projection=(tx-x)*ray_x+(ty-y)*ray_y
     local miss=math.abs((tx-x)*ray_y-(ty-y)*ray_x)
     local cosang=dist>0 and projection/dist or 0
     local angular_error=math.deg(math.acos(math.max(-1,math.min(1,cosang))))
     local commanded_lane=clearance(x,y,x+ray_x*projection,y+ray_y*projection)
     local executable=projection>0 and miss<=c.command_max_miss
       and angular_error<=c.command_max_angle
       and commanded_lane>=c.safe_command_lane
       and receiver>=c.safe_command_receiver
     local candidate={base=base,score=score,distance=dist,
       lane=lane,receiver_clearance=receiver,progress=forward,
       command=candidate_direction,command_miss=miss,
       command_angle=angular_error,command_lane=commanded_lane,
       executable=executable}
     counts[sector]=counts[sector]+1
     if not sectors[sector] or score>sectors[sector].score then
      sectors[sector]=candidate
     end
    end
   end
  end)
  local best_sector,best=nil,nil
  for _,name in ipairs({"FRONT","LEFT","RIGHT","DIAG_LEFT","DIAG_RIGHT"}) do
   local candidate=sectors[name]
   if candidate and (not best or candidate.score>best.score) then
    best=candidate;best_sector=name
   end
  end
  return {kind="FIVE_DIRECTION_PASS_EVALUATION",best=best,
   best_sector=best_sector,sectors=sectors,counts=counts,actual=actual,
   all_diagonal=all_diagonal}
 end
 return o
end
return M
