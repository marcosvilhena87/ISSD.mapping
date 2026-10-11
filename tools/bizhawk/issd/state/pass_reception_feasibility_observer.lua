-- Passive model, not a claim about verified ROM ball speed or controls.
local M={}
function M.new(config,players)
 local c=config.PASS_RECEPTION_FEASIBILITY
 local o={}
 local function distance(x,y,a,b)
  local dx=x-a;local dy=y-b
  return math.sqrt(dx*dx+dy*dy)
 end
 function o.evaluate(carrier,result)
  local events={}
  local x,y=players.xy(carrier)
  for sector,candidate in pairs(result.sectors) do
   if candidate then
    local rx,ry=players.xy(candidate.base)
    local ux,uy=0,0
    local command=candidate.command or ""
    if string.find(command,"Right",1,true) then ux=1 end
    if string.find(command,"Left",1,true) then ux=-1 end
    if string.find(command,"Up",1,true) then uy=-1 end
    if string.find(command,"Down",1,true) then uy=1 end
    local norm=math.sqrt(ux*ux+uy*uy)
    if norm>0 then ux=ux/norm;uy=uy/norm end
    local along=(rx-x)*ux+(ry-y)*uy
    local max_dist=math.min(c.max_throw_distance,math.max(0,along+c.reception_lead))
    local best=nil
    for i=1,c.samples do
     local d=max_dist*i/c.samples
     if d>=c.min_throw_distance then
      local bx,by=x+ux*d,y+uy*d
      local ball_eta=d/c.assumed_ball_speed
      local my_eta=distance(rx,ry,bx,by)/c.assumed_my_speed
      local cpu_eta=math.huge
      players.each_cpu(function(base)
       if base~=config.CPU_FIRST then
        local px,py=players.xy(base)
        local eta=distance(px,py,bx,by)/c.assumed_cpu_speed
        if eta<cpu_eta then cpu_eta=eta end
       end
      end)
      local advantage=cpu_eta-my_eta
      local can_receive=my_eta<=ball_eta+c.arrival_grace
      if can_receive and (not best or advantage>best.advantage) then
       best={point_x=bx,point_y=by,my_eta=my_eta,cpu_eta=cpu_eta,
        ball_eta=ball_eta,advantage=advantage,miss=distance(rx,ry,bx,by)}
      end
     end
    end
    local kind="PASS_RECEPTION_UNSAFE"
    if best then
     if best.advantage>=c.safe_eta_margin then
      kind="PASS_RECEPTION_FEASIBLE"
     elseif best.advantage>=-c.contested_eta_margin then
      kind="PASS_RECEPTION_CONTESTED"
     end
    end
    events[#events+1]={kind=kind,sector=sector,receiver=candidate.base,
     geometric_eligible=candidate.executable,best=best,
     false_negative=not candidate.executable and kind=="PASS_RECEPTION_FEASIBLE"}
   end
  end
  return events
 end
 return o
end
return M
