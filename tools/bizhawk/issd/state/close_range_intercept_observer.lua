-- Passive close-range corner interception telemetry, no control changes.
local M={}
function M.new(config,players)
 local o={last=nil}
 function o.observe(frame,base,bx,by,px,py,command)
  local dx,dy=bx-px,by-py
  local dist=math.sqrt(dx*dx+dy*dy)
  local nearest=nil;local cpu_dist=math.huge
  players.each_cpu(function(cpu)
   if cpu~=config.CPU_FIRST then
    local x,y=players.xy(cpu)
    local d=math.sqrt((bx-x)^2+(by-y)^2)
    if d<cpu_dist then cpu_dist=d;nearest=cpu end
   end
  end)
  local old=o.last
  local my_delta=nil;local cpu_delta=nil;local ball_delta=nil
  if old and old.base==base and frame-old.frame==1 then
   my_delta=old.distance-dist
   cpu_delta=old.cpu_distance-cpu_dist
   ball_delta=math.sqrt((bx-old.bx)^2+(by-old.by)^2)
  end
  o.last={base=base,frame=frame,distance=dist,cpu_distance=cpu_dist,bx=bx,by=by}
  if dist>30 then return nil end
  return {kind="CORNER_CLOSE_RANGE_INTERCEPT",player=base,frame=frame,
   distance=dist,cpu_distance=cpu_dist,cpu=nearest,
   my_closing=my_delta,cpu_closing=cpu_delta,ball_delta=ball_delta,
   command=command,dx=dx,dy=dy}
 end
 return o
end
return M
