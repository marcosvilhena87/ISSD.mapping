-- Passive keeper hand-distribution outcome observer.
-- Starts on the first B pulse, confirms release only after owner leaves GK.
local M={}
function M.new(config,players)
 local o={pending=nil,sequence=0}
 function o.update(frame,active,gs,owner)
  local e=o.pending
  if not e then return nil end
  local kind,reason
  if not active or gs~=0 then kind="GK_THROW_UNRESOLVED";reason="STOPPAGE"
  elseif not e.released then
   if owner~=config.MY_FIRST then
    e.released=frame
   elseif frame-e.start>=45 then
    kind="GK_THROW_NOT_RELEASED";reason="GK_STILL_OWNER"
   end
  end
  if e.released and not kind then
   if owner==e.last_owner and owner~=0 then
    e.streak=e.streak+1
   else
    e.last_owner=owner;e.streak=owner~=0 and 1 or 0
   end
   if e.streak>=2 and players.valid_my_base(owner) then
    kind="GK_THROW_MY_RECEIVED";reason="INDIVIDUAL_OWNER_CONFIRMED"
   elseif e.streak>=2 and players.valid_cpu_base(owner) then
    kind="GK_THROW_CPU_INTERCEPTED";reason="INDIVIDUAL_OWNER_CONFIRMED"
   elseif frame-e.released>=150 then
    kind="GK_THROW_UNRESOLVED";reason="RECEPTION_TIMEOUT"
   end
  end
  if not kind then return nil end
  o.pending=nil
  return {kind=kind,sequence=e.sequence,reason=reason,age=frame-e.start,
   release_age=e.released and e.released-e.start or nil,
   receiver=owner,planned_receiver=e.receiver,mode=e.mode,
   direction=e.direction,clearance=e.clearance,lane=e.lane}
 end
 function o.fire(frame,action,plan)
  if not action or action.button~="B" then return nil end
  if o.pending then return nil end
  o.sequence=o.sequence+1
  o.pending={sequence=o.sequence,start=frame,mode=action.mode,
   receiver=action.receiver or plan.receiver,direction=action.direction,
   clearance=plan.receiver_clearance,lane=plan.lane_clearance,
   streak=0,last_owner=0}
  return {kind="GK_THROW_START",sequence=o.sequence}
 end
 return o
end
return M
