-- Passive persistence and outcome of geometrically eligible pass windows.
local M={}
function M.new(config,players)
 local o={active={},last_carrier=nil}
 local function event(kind,p,frame,reason,selected)
  return {kind=kind,receiver=p.receiver,sector=p.sector,
   duration=frame-p.start,reason=reason,selected=selected}
 end
 function o.sample(frame,carrier,result,outlet)
  local events={}
  local current={}
  if o.last_carrier and o.last_carrier~=carrier then
   for _,p in pairs(o.active) do
    events[#events+1]=event("PASS_WINDOW_END",p,frame,"CARRIER_CHANGED",false)
   end
   o.active={}
  end
  o.last_carrier=carrier
  for sector,candidate in pairs(result.sectors) do
   if candidate and candidate.executable then
    local key=sector..":"..candidate.base
    current[key]=true
    local p=o.active[key]
    if not p then
     p={start=frame,last=frame,receiver=candidate.base,sector=sector,
       carrier=carrier,selected=false}
     o.active[key]=p
     events[#events+1]=event("PASS_WINDOW_START",p,frame,"GEOMETRY_ELIGIBLE",false)
    end
    p.last=frame
    if outlet and outlet.receiver==p.receiver then
     p.selected=true
     events[#events+1]=event("PASS_WINDOW_SELECTED",p,frame,"PASS_POLICY_SELECTED",true)
     o.active[key]=nil
    end
   end
  end
  for key,p in pairs(o.active) do
   if not current[key] and frame-p.last>=config.FIVE_DIRECTION_PASS_OBSERVER.sample_frames then
    events[#events+1]=event("PASS_WINDOW_END",p,frame,"NOT_ELIGIBLE_AT_NEXT_SAMPLE",p.selected)
    o.active[key]=nil
   end
  end
  return events
 end
 function o.outcome(frame,state)
  local events={}
  local owner=state.possession
  local reason=nil
  if players.valid_cpu_base(owner) then reason="CPU_POSSESSION"
  elseif state.game_state~=0 then reason="STOPPAGE"
  elseif o.last_carrier and players.valid_my_base(owner)
      and owner~=o.last_carrier then reason="MY_OWNER_CHANGED"
  end
  if reason then
   for key,p in pairs(o.active) do
    events[#events+1]=event("PASS_WINDOW_OUTCOME",p,frame,reason,p.selected)
    o.active[key]=nil
   end
   o.last_carrier=nil
  end
  return events
 end
 return o
end
return M
