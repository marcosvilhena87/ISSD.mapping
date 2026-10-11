-- Observe actual territorial outcome after charged defensive clearances.
local M={}
function M.new(config,players,field_side)
 local c=config.DEFENSIVE_CLEARANCE_OUTCOME
 local o={pending=nil,sequence=0}
 function o.start(frame,x,y,carrier,frames,dir,variant)
  local old=o.pending
  local superseded=old and {sequence=old.sequence,age=frame-old.frame,
    frames=old.frames,variant=old.variant} or nil
  o.sequence=o.sequence+1
  o.pending={frame=frame,x=x,y=y,carrier=carrier,frames=frames,
    dir=dir,sequence=o.sequence,variant=variant,
    inactive_frames=0, first_receiver=nil,
    last_sample_frame=-99999, second_ball_seen=false, second_ball_samples=0,
    best_my_distance=nil,best_cpu_distance=nil,selected_distance=nil,
    max_travel=0,max_forward=0,max_step_speed=0,
    prev_x=x,prev_y=y,first_release_age=nil,first_owner=nil}
  return o.pending.sequence,superseded
 end
 function o.update(state,frame)
  local p=o.pending
  if not p then return nil end
  local age=frame-p.frame
  local dir=field_side.attack_direction()
  local progress=dir*(state.ball_x-p.x)
  local travel=math.sqrt((state.ball_x-p.x)^2+(state.ball_y-p.y)^2)
  local step=math.sqrt((state.ball_x-p.prev_x)^2+(state.ball_y-p.prev_y)^2)
  p.max_travel=math.max(p.max_travel,travel)
  p.max_forward=math.max(p.max_forward,progress)
  p.max_step_speed=math.max(p.max_step_speed,step)
  p.prev_x,p.prev_y=state.ball_x,state.ball_y
  if age>0 and p.first_release_age==nil and state.possession~=p.carrier then
   p.first_release_age=age
   p.first_owner=state.possession
  end
  local kind,reason=nil,nil
  local second_ball=nil
  local h=state.ball_height
  if age>0 and state.game_state==0 and state.possession==0
      and type(h)=="number" and h<=c.second_ball_close_height
      and age-p.last_sample_frame>=c.second_ball_sample_frames then
    local my_dist,cpu_dist,selected=math.huge,math.huge,math.huge
    players.each_my(function(base)
      if base~=config.MY_FIRST then
        local x,y=players.xy(base)
        local d=math.sqrt((state.ball_x-x)^2+(state.ball_y-y)^2)
        if d<my_dist then my_dist=d end
        if base==state.my_base then selected=d end
      end
    end)
    players.each_cpu(function(base)
      if base~=config.CPU_FIRST then
        local x,y=players.xy(base)
        cpu_dist=math.min(cpu_dist,
          math.sqrt((state.ball_x-x)^2+(state.ball_y-y)^2))
      end
    end)
    p.last_sample_frame=age
    p.second_ball_samples=p.second_ball_samples+1
    p.best_my_distance=my_dist
    p.best_cpu_distance=cpu_dist
    p.selected_distance=selected
    if math.min(my_dist,cpu_dist)<=c.second_ball_max_distance then
      second_ball={sequence=p.sequence,age=age,
        my_distance=my_dist,cpu_distance=cpu_dist,
        selected_distance=selected,margin=cpu_dist-my_dist,
        height=h,first=not p.second_ball_seen}
      p.second_ball_seen=true
    end
  end
  if state.gameplay_active~=1 then p.inactive_frames=p.inactive_frames+1 end
  if state.game_state~=0 then
   kind="UNRESOLVED";reason="GAME_STATE_STOPPAGE"
  elseif dir~=p.dir then
   kind="UNRESOLVED";reason="ATTACK_DIRECTION_CHANGED"
  elseif age>0 and players.valid_my_base(state.possession)
       and state.possession~=p.carrier then
   kind="RECEIVED";reason="MY_POSSESSION"
  elseif age>0 and players.valid_cpu_base(state.possession) then
   kind="INTERCEPTED";reason="CPU_POSSESSION"
  elseif age>=c.max_frames then
   kind="UNRESOLVED";reason="TIMEOUT"
  end
  if kind then
   o.pending=nil
   return {kind=kind,reason=reason,sequence=p.sequence,age=age,
    progress=progress,start_x=p.x,end_x=state.ball_x,
    max_travel=p.max_travel,max_forward=p.max_forward,
    max_step_speed=p.max_step_speed,
    first_release_age=p.first_release_age,first_owner=p.first_owner,
    frames=p.frames,variant=p.variant,owner=state.possession,
    receiver=kind=="RECEIVED" and state.possession or nil,
    receiver_x=kind=="RECEIVED" and players.xy(state.possession) or nil,
    inactive_frames=p.inactive_frames,game_state=state.game_state,
    second_ball_seen=p.second_ball_seen,second_ball_samples=p.second_ball_samples,
    best_my_distance=p.best_my_distance,best_cpu_distance=p.best_cpu_distance,
    selected_distance=p.selected_distance,
    gameplay_active=state.gameplay_active}
  end
  return nil,second_ball
 end
 return o
end
return M
