-- Zone-aware ground B passes: progressive in thirds 1/2, lateral in third 3.
-- World field coordinates are candidates; fail closed on invalid geometry.
local M={}
function M.new(config,players,field_side,mem)
    local obj={cooldown=0,last_carrier=nil}
    local c=config.FORWARD_PASS
    local function distance(x,y,a,b)
        return math.sqrt((x-a)^2+(y-b)^2)
    end
    local function zone_for(x,dir)
        local len=mem.u16(config.ADDR.field_length)
        local center=mem.u16(config.ADDR.center_field_x)
        if len<500 or len>4000 or center<100 or dir==0 then return nil end
        local start=center-dir*len/2
        local forward=(x-start)*dir
        if forward<0 or forward>len then return nil end
        return math.min(3,1+math.floor(forward/(len/3)))
    end
    local function deep_lateral_safe(px,py,rx,ry,dir,receiver_clearance)
     local cfg=config.DEEP_DEFENSIVE_LATERAL
     local length=mem.u16(config.ADDR.field_length)
     local center=mem.u16(config.ADDR.center_field_x)
     if length<500 or length>4000 or center<100 then return false end
     local own_goal=center-dir*length/2
     if (px-own_goal)*dir>cfg.max_own_goal_distance then return true end
     -- Direction+B follows the cardinal vertical lane at the passer's X,
     -- not the diagonal segment to a teammate offset horizontally.
     if math.abs(rx-px)>cfg.max_receiver_axis_offset
        or receiver_clearance<cfg.min_receiver_clearance then return false end
     local lane=math.huge
     local cpu_landing=math.huge
     local bx,by=px,ry
     players.each_cpu(function(base)
      local ex,ey=players.xy(base)
      local t=(ey-py)/(ry-py)
      if t>=0 and t<=1 then
       lane=math.min(lane,math.abs(ex-px))
      end
      cpu_landing=math.min(cpu_landing,distance(ex,ey,bx,by))
     end)
     local my_landing=distance(rx,ry,bx,by)
     return lane>=cfg.min_lane_clearance
        and cpu_landing-my_landing>=cfg.min_cpu_arrival_margin
    end
    -- Ball offset is only a facing proxy; ranking never overrides safety.
    local function facing_adjustment(px,py,rx,ry,dst)
        local cfg=config.PASS_FACING_PREFERENCE
        if not cfg or not cfg.enabled then return 0,"DISABLED" end
        local ox=mem.s16(config.ADDR.ball_x)-px
        local oy=mem.s16(config.ADDR.ball_y)-py
        local length=math.sqrt(ox*ox+oy*oy)
        if length<cfg.min_ball_offset or length>cfg.max_ball_offset
            or dst<1 then return 0,"UNKNOWN" end
        local cosine=(ox*(rx-px)+oy*(ry-py))/(length*dst)
        if cosine>=cfg.front_cosine then return cfg.front_bonus,"FRONT" end
        if cosine<=cfg.back_cosine then
            if dst<=cfg.short_backward_distance then return 0,"BACK_SHORT" end
            return -cfg.long_back_penalty,"BACK_LONG"
        end
        return 0,"SIDE"
    end
    function obj.tick()
        if obj.cooldown>0 then obj.cooldown=obj.cooldown-1 end
    end
    function obj.reset()
        obj.cooldown=0;obj.last_carrier=nil
    end
    function obj.plan(carrier, prefer_central, early_defensive)
        local diag={candidate_count=0,geometry_rejected=0,
            clearance_rejected=0,lane_rejected=0,
            deep_lateral_rejected=0,valid_count=0,reason="NONE",
            rejected_forward=0,rejected_distance=0,
            rejected_lateral=0,near_lateral=0,mid_lateral=0,
            far_lateral=0,closest_lateral_excess=nil,
            closest_receiver=nil,closest_forward=nil,
            closest_lateral=nil,closest_distance=nil,
            closest_cardinal_lane=nil,closest_receiver_clearance=nil,
            longitudinal={BEHIND=0,TOO_CLOSE=0,IN_RANGE=0,TOO_FAR=0},
            in_range_aligned=0,near_short=0,near_far=0,
            near_longitudinal_safe=0,near_longitudinal_unsafe=0,
            near_longitudinal_receiver=nil,near_longitudinal_gap=nil,
            near_longitudinal_forward=nil,near_longitudinal_lateral=nil,
            near_longitudinal_clearance=nil,near_longitudinal_lane=nil,
            diagonal_candidates=0,diagonal_safe=0,diagonal_unsafe=0,
            diagonal_receiver=nil,diagonal_forward=nil,
            diagonal_lateral=nil,diagonal_distance=nil,
            diagonal_lane=nil,diagonal_receiver_clearance=nil}
        if obj.cooldown>0 then diag.reason="COOLDOWN";return nil,diag end
        if not players.valid_my_base(carrier)
            or carrier==config.MY_FIRST then
            diag.reason="INVALID_CARRIER";return nil,diag
        end
        local dir=field_side.attack_direction()
        if dir~=1 and dir~=-1 then
            diag.reason="INVALID_DIRECTION";return nil,diag
        end
        local px,py=players.xy(carrier)
        local _,goal_y=players.xy(config.CPU_FIRST)
        local zone=zone_for(px,dir)
        if not zone then diag.reason="INVALID_ZONE";return nil,diag end
        local best=nil
        local best_diagonal=nil
        local best_eight_way=nil
        local early_cfg=config.EARLY_DEFENSIVE_OUTLET
        local early_enabled=early_defensive and early_cfg and early_cfg.enabled
        local effective_min_forward=early_enabled and zone==1
            and math.min(c.min_forward,early_cfg.min_forward) or c.min_forward
        players.each_my(function(base)
            if base~=carrier and base~=config.MY_FIRST then
                diag.candidate_count=diag.candidate_count+1
                local rx,ry=players.xy(base)
                local forward=(rx-px)*dir
                local vertical=ry-py
                local lateral=math.abs(vertical)
                local d=distance(px,py,rx,ry)
                -- Passive counterfactual: diagonal ground pass to a teammate
                -- rejected by the cardinal progressive geometry. Segment
                -- clearance is not proof that diagonal+B works in the ROM.
                if zone<3 and forward>=c.min_forward
                    and forward<=c.max_forward
                    and lateral>c.max_lateral
                    and lateral<=c.max_lateral+100
                    and d<=c.max_distance then
                    diag.diagonal_candidates=diag.diagonal_candidates+1
                    local receiver_space=99999
                    local lane=99999
                    local dx,dy=rx-px,ry-py
                    players.each_cpu(function(cpu)
                        local ex,ey=players.xy(cpu)
                        receiver_space=math.min(receiver_space,
                            distance(rx,ry,ex,ey))
                        local t=((ex-px)*dx+(ey-py)*dy)/(d*d)
                        if t>0.05 and t<1.05 then
                            local q=math.max(0,math.min(1,t))
                            lane=math.min(lane,
                                distance(ex,ey,px+q*dx,py+q*dy))
                        end
                    end)
                    local safe=receiver_space>=c.min_receiver_clearance
                        and lane>=c.min_lane_clearance
                    if safe then
                        diag.diagonal_safe=diag.diagonal_safe+1
                        -- Conservative experiment: require a true diagonal
                        -- rather than an almost horizontal/vertical pass.
                        local ratio=lateral/forward
                        if ratio>=0.60 and ratio<=1.55
                            and receiver_space>=c.min_receiver_clearance+18
                            and lane>=c.min_lane_clearance+15
                            and zone_for(rx,dir)~=nil
                            and not prefer_central then
                            local candidate={
                                receiver=base,carrier=carrier,zone=zone,
                                distance=d,forward=forward,lateral=lateral,
                                receiver_clearance=receiver_space,
                                lane_clearance=lane,
                                direction=dir==1 and "Right" or "Left",
                                vertical=vertical<0 and "Up" or "Down",
                                button=c.button,intent="SHORT_DIAGONAL",
                                score=math.min(receiver_space,180)*c.weight_clearance
                                    +math.min(lane,180)*c.weight_lane
                                    +forward*c.weight_progress-d*0.12+select(1,facing_adjustment(px,py,rx,ry,d))}
                            if not best_diagonal
                                or candidate.score>best_diagonal.score then
                                best_diagonal=candidate
                            end
                        end
                    else diag.diagonal_unsafe=diag.diagonal_unsafe+1 end
                    if not diag.diagonal_receiver or
                        (safe and diag.diagonal_receiver_clearance<c.min_receiver_clearance)
                        or (safe==(diag.diagonal_receiver_clearance>=c.min_receiver_clearance
                                  and diag.diagonal_lane>=c.min_lane_clearance)
                            and d<diag.diagonal_distance) then
                        diag.diagonal_receiver=base
                        diag.diagonal_forward=forward
                        diag.diagonal_lateral=lateral
                        diag.diagonal_distance=d
                        diag.diagonal_lane=lane
                        diag.diagonal_receiver_clearance=receiver_space
                    end
                end
                if zone<3 then
                    local category=forward<0 and "BEHIND"
                        or forward<c.min_forward and "TOO_CLOSE"
                        or forward>c.max_forward and "TOO_FAR" or "IN_RANGE"
                    diag.longitudinal[category]=diag.longitudinal[category]+1
                    if category=="IN_RANGE" and lateral<=c.max_lateral
                       and d<=c.max_distance then
                        diag.in_range_aligned=diag.in_range_aligned+1
                    end
                    -- Counterfactual only: a short movement along X might
                    -- put the receiver into range. Never authorize a pass.
                    local gap=category=="TOO_CLOSE" and c.min_forward-forward
                        or category=="TOO_FAR" and forward-c.max_forward or nil
                    if gap and gap<=40 and forward>=0
                       and lateral<=c.max_lateral then
                        if category=="TOO_CLOSE" then
                            diag.near_short=diag.near_short+1
                        else diag.near_far=diag.near_far+1 end
                        local lane=99999
                        local rc=99999
                        local target_x=category=="TOO_CLOSE"
                            and px-dir*gap or px+dir*gap
                        players.each_cpu(function(cpu)
                            local ex,ey=players.xy(cpu)
                            rc=math.min(rc,distance(rx,ry,ex,ey))
                            local along=(ex-target_x)*dir
                            local span=(rx-target_x)*dir
                            if along>=0 and along<=span then
                                lane=math.min(lane,math.abs(ey-ry))
                            end
                        end)
                        local safe=rc>=c.min_receiver_clearance
                            and lane>=c.min_lane_clearance
                        if safe then
                            diag.near_longitudinal_safe=diag.near_longitudinal_safe+1
                        else
                            diag.near_longitudinal_unsafe=diag.near_longitudinal_unsafe+1
                        end
                        if not diag.near_longitudinal_gap
                            or gap<diag.near_longitudinal_gap then
                            diag.near_longitudinal_receiver=base
                            diag.near_longitudinal_gap=gap
                            diag.near_longitudinal_forward=forward
                            diag.near_longitudinal_lateral=lateral
                            diag.near_longitudinal_clearance=rc
                            diag.near_longitudinal_lane=lane
                        end
                    end
                end
                -- Fail-safe directional fallback: check where an 8-way
                -- B input would travel (ray), not just teammate segment.
                -- Receptor must be near the ray AND beat CPU to that point.
                local eight=config.EIGHT_WAY_PASS
                if eight and eight.enabled and zone<3 and not prefer_central
                    and forward>=eight.min_forward and d<=eight.max_distance
                    and zone_for(rx,dir)~=nil then
                    local dirs={{dir,0},{0,-1},{0,1},
                        {dir,-1},{dir,1}}
                    for _,vec in ipairs(dirs) do
                        local ux,uy=vec[1],vec[2]
                        local norm=math.sqrt(ux*ux+uy*uy)
                        ux,uy=ux/norm,uy/norm
                        local projection=(rx-px)*ux+(ry-py)*uy
                        local off=math.abs((rx-px)*uy-(ry-py)*ux)
                        local diagonal=vec[1]~=0 and vec[2]~=0
                        local extra=diagonal and eight.diagonal_extra_margin or 0
                        if projection>=eight.min_ray_projection
                            and projection<=eight.max_ray_projection
                            and off<=eight.max_receiver_ray_offset
                            and (not diagonal or forward>=effective_min_forward) then
                            local tx,ty=px+ux*projection,py+uy*projection
                            local corridor,receiver_space,cpu_eta=math.huge,math.huge,math.huge
                            players.each_cpu(function(cpu)
                                if cpu~=config.CPU_FIRST then
                                    local ex,ey=players.xy(cpu)
                                    receiver_space=math.min(receiver_space,
                                        distance(rx,ry,ex,ey))
                                    local along=(ex-px)*ux+(ey-py)*uy
                                    if along>=0 and along<=projection then
                                        corridor=math.min(corridor,
                                            math.abs((ex-px)*uy-(ey-py)*ux))
                                    end
                                    cpu_eta=math.min(cpu_eta,
                                        distance(tx,ty,ex,ey)/eight.cpu_speed)
                                end
                            end)
                            local my_eta=off/eight.receiver_speed
                            local margin=(cpu_eta-my_eta)*eight.receiver_speed
                            if receiver_space>=eight.min_receiver_clearance+extra
                                and corridor>=eight.min_corridor_clearance+extra
                                and margin>=eight.min_cpu_arrival_margin+extra then
                                local candidate={
                                    receiver=base,carrier=carrier,zone=zone,
                                    distance=d,forward=forward,lateral=lateral,
                                    receiver_clearance=receiver_space,
                                    lane_clearance=corridor,
                                    direction=vec[1]==0 and (vec[2]<0 and "Up" or "Down")
                                        or (vec[1]==1 and "Right" or "Left"),
                                    vertical=diagonal and (vec[2]<0 and "Up" or "Down") or nil,
                                    button=c.button,intent=diagonal and "EIGHT_WAY_DIAGONAL"
                                        or "EIGHT_WAY_CARDINAL",
                                    ray_offset=off,arrival_margin=margin,
                                    score=forward*c.weight_progress
                                        +receiver_space*c.weight_clearance
                                        +corridor*c.weight_lane-off*1.5+select(1,facing_adjustment(px,py,rx,ry,d))}
                                if not best_eight_way or candidate.score>best_eight_way.score then
                                    best_eight_way=candidate
                                end
                            end
                        end
                    end
                end
                local suitable=false
                local direction=nil
                local intent=nil
                if zone<3 then
                    suitable=forward>=effective_min_forward
                        and forward<=c.max_forward
                        and lateral<=c.max_lateral and d<=c.max_distance
                    direction=dir==1 and "Right" or "Left"
                    intent="PROGRESSIVE"
                else
                    suitable=lateral>=c.lateral_min
                        and lateral<=c.lateral_max
                        and math.abs(forward)<=c.lateral_max_forward
                        and d<=c.lateral_max_distance
                    direction=vertical<0 and "Up" or "Down"
                    intent="LATERAL"
                end
                -- In the final third, a centralizing lateral outlet must
                -- move the ball closer to the goalkeeper's lateral coordinate.
                if prefer_central then
                    suitable=suitable and zone==3
                        and math.abs(ry-goal_y)+20<math.abs(py-goal_y)
                end
                if not suitable or zone_for(rx,dir)==nil then
                    diag.geometry_rejected=diag.geometry_rejected+1
                    if zone<3 then
                        if forward<c.min_forward or forward>c.max_forward then
                            diag.rejected_forward=diag.rejected_forward+1
                        end
                        if d>c.max_distance then
                            diag.rejected_distance=diag.rejected_distance+1
                        end
                        if lateral>c.max_lateral and forward>=c.min_forward
                            and forward<=c.max_forward and d<=c.max_distance then
                            diag.rejected_lateral=diag.rejected_lateral+1
                            local excess=lateral-c.max_lateral
                            if excess<=24 then diag.near_lateral=diag.near_lateral+1
                            elseif excess<=56 then diag.mid_lateral=diag.mid_lateral+1
                            else diag.far_lateral=diag.far_lateral+1 end
                            if not diag.closest_lateral_excess
                                or excess<diag.closest_lateral_excess then
                                diag.closest_lateral_excess=excess
                                diag.closest_receiver=base
                                diag.closest_forward=forward
                                diag.closest_lateral=lateral
                                diag.closest_distance=d
                                -- A Right/Left+B pass follows y=py, not the
                                -- diagonal towards the rejected receiver.
                                local lane=99999
                                local receiver_clearance=99999
                                players.each_cpu(function(cpu)
                                    local ex,ey=players.xy(cpu)
                                    receiver_clearance=math.min(
                                        receiver_clearance,distance(rx,ry,ex,ey))
                                    local along=(ex-px)*dir
                                    if along>=0 and along<=forward then
                                        lane=math.min(lane,math.abs(ey-py))
                                    end
                                end)
                                diag.closest_cardinal_lane=lane
                                diag.closest_receiver_clearance=receiver_clearance
                            end
                        end
                    end
                else
                    local receiver_clearance=99999
                    local corridor=99999
                    local dx,dy=rx-px,ry-py
                    players.each_cpu(function(cpu)
                        local ex,ey=players.xy(cpu)
                        receiver_clearance=math.min(receiver_clearance,
                            distance(rx,ry,ex,ey))
                        local t=((ex-px)*dx+(ey-py)*dy)/(d*d)
                        if t>0.05 and t<1.1 then
                            local q=math.max(0,math.min(1,t))
                            corridor=math.min(corridor,
                                distance(ex,ey,px+q*dx,py+q*dy))
                        end
                    end)
                    local min_rc=zone==3 and c.lateral_receiver_clearance
                        or c.min_receiver_clearance
                    local min_lc=zone==3 and c.lateral_lane_clearance
                        or c.min_lane_clearance
                    local early_short=early_enabled and zone==1
                        and forward<c.min_forward and intent=="PROGRESSIVE"
                    if early_short then
                        min_rc=min_rc+early_cfg.min_receiver_extra
                        min_lc=min_lc+early_cfg.min_lane_extra
                    end
                    local lateral_safe=intent~="LATERAL"
                        or deep_lateral_safe(px,py,rx,ry,dir,receiver_clearance)
                    if receiver_clearance<min_rc then
                        diag.clearance_rejected=diag.clearance_rejected+1
                    elseif corridor<min_lc then
                        diag.lane_rejected=diag.lane_rejected+1
                    elseif not lateral_safe then
                        diag.deep_lateral_rejected=diag.deep_lateral_rejected+1
                    else
                        diag.valid_count=diag.valid_count+1
                        local score=math.min(receiver_clearance,180)*c.weight_clearance
                            +math.min(corridor,180)*c.weight_lane
                        if zone<3 then
                            score=score+forward*c.weight_progress-lateral*c.weight_lateral
                        else
                            score=score+0.2*math.max(forward,0)
                                -0.5*math.abs(forward)
                                -0.1*lateral
                        end
                        if prefer_central then
                            score=score+0.7*(math.abs(py-goal_y)-math.abs(ry-goal_y))
                        end
                        -- Rank secure progressive outlets higher without
                        -- bypassing any existing pass feasibility guard.
                        local priority=config.PROGRESSIVE_PASS_PRIORITY
                        local progress_bonus=0
                        if priority and priority.enabled and zone<3
                            and intent=="PROGRESSIVE"
                            and forward>=priority.min_forward
                            and receiver_clearance>=min_rc+priority.min_receiver_margin
                            and corridor>=min_lc+priority.min_lane_margin then
                            progress_bonus=math.min(
                                forward-priority.min_forward,
                                priority.max_forward_bonus)*priority.forward_bonus
                            score=score+progress_bonus
                        end
                        local facing_bonus,facing_class=
                            facing_adjustment(px,py,rx,ry,d)
                        score=score+facing_bonus
                        if not best or score>best.score then
                            best={facing_class=facing_class,
                                facing_adjustment=facing_bonus,
                                receiver=base,distance=d,forward=forward,
                                lateral=lateral,receiver_clearance=receiver_clearance,
                                lane_clearance=corridor,score=score,
                                progress_bonus=progress_bonus,
                                early_short=early_short,
                                direction=direction,button=c.button,
                                carrier=carrier,zone=zone,intent=intent}
                        end
                    end
                end
            end
        end)
        -- Preserve existing cardinal priority and fallback behavior.
        if not best and best_eight_way then best=best_eight_way end
        if not best and best_diagonal then best=best_diagonal end
        if best then diag.reason="OUTLET_AVAILABLE"
        elseif diag.candidate_count==0 then diag.reason="NO_TEAMMATE"
        elseif diag.geometry_rejected==diag.candidate_count then
            diag.reason="NO_CARDINAL_LANE"
        else diag.reason="SAFETY_FILTER" end
        return best,diag
    end
    -- Safe defensive support pass: a teammate slightly behind the carrier
    -- may be an excellent intermediate outlet. Use only the physical
    -- vertical B lane; do not mistake a diagonal segment for a cardinal pass.
    function obj.support_plan(carrier)
        local cfg=config.DEFENSIVE_SUPPORT_PASS
        if not cfg or not cfg.enabled or obj.cooldown>0
            or not players.valid_my_base(carrier)
            or carrier==config.MY_FIRST then return nil,"DISABLED_OR_COOLDOWN" end
        local dir=field_side.attack_direction()
        if dir~=1 and dir~=-1 then return nil,"NO_DIRECTION" end
        local px,py=players.xy(carrier)
        if zone_for(px,dir)~=1 then return nil,"NOT_DEFENSIVE_THIRD" end
        local best=nil
        local observed=0
        players.each_my(function(base)
            if base~=carrier and base~=config.MY_FIRST then
                local rx,ry=players.xy(base)
                local back=(px-rx)*dir
                local lateral=math.abs(ry-py)
                local axis=math.abs(rx-px)
                if back>=0 and back<=cfg.max_backward
                    and lateral>=cfg.min_lateral and lateral<=cfg.max_lateral
                    and axis<=cfg.max_axis_offset then
                    observed=observed+1
                    local receiver_space=math.huge
                    local corridor=math.huge
                    local cpu_landing=math.huge
                    players.each_cpu(function(cpu)
                        if cpu~=config.CPU_FIRST then
                            local ex,ey=players.xy(cpu)
                            receiver_space=math.min(receiver_space,
                                distance(rx,ry,ex,ey))
                            local t=(ey-py)/(ry-py)
                            if t>=0 and t<=1 then
                                corridor=math.min(corridor,math.abs(ex-px))
                            end
                            cpu_landing=math.min(cpu_landing,
                                distance(px,ry,ex,ey))
                        end
                    end)
                    local receiver_landing=axis
                    local margin=cpu_landing-receiver_landing
                    if receiver_space>=cfg.min_receiver_clearance
                        and corridor>=cfg.min_lane_clearance
                        and margin>=cfg.min_arrival_margin then
                        local score=receiver_space+0.65*corridor
                            +0.45*margin-back*0.20
                        if not best or score>best.score then
                            best={carrier=carrier,receiver=base,zone=1,
                                intent="DEFENSIVE_SUPPORT",button=c.button,
                                direction=ry<py and "Up" or "Down",
                                distance=distance(px,py,rx,ry),
                                forward=-back,lateral=lateral,
                                receiver_clearance=receiver_space,
                                lane_clearance=corridor,score=score,
                                arrival_margin=margin}
                        end
                    end
                end
            end
        end)
        return best,best and "SAFE_SUPPORT" or
            (observed>0 and "UNSAFE_SUPPORT" or "NO_ALIGNED_SUPPORT")
    end
    -- Conservative feet-to-feet goalkeeper recycle. Only a straight
    -- backward B lane is executable; a diagonal GK pass is not assumed.
    function obj.gk_backpass_plan(carrier)
        local cfg=config.GK_BACKPASS_SUPPORT
        if not cfg or not cfg.enabled or obj.cooldown>0
            or not players.valid_my_base(carrier)
            or carrier==config.MY_FIRST then return nil,"DISABLED_OR_COOLDOWN" end
        local dir=field_side.attack_direction()
        if dir~=1 and dir~=-1 then return nil,"NO_DIRECTION" end
        local px,py=players.xy(carrier)
        if zone_for(px,dir)~=1 then return nil,"NOT_DEFENSIVE_THIRD" end
        local gx,gy=players.xy(config.MY_FIRST)
        local back=(px-gx)*dir
        local offset=math.abs(gy-py)
        if back<cfg.min_backward or back>cfg.max_backward
            or offset>cfg.max_axis_offset then
            return nil,"NO_EXECUTABLE_BACKWARD_LANE"
        end
        local receiver_space=math.huge
        local lane=math.huge
        local cpu_arrival=math.huge
        players.each_cpu(function(base)
            if base~=config.CPU_FIRST then
                local ex,ey=players.xy(base)
                receiver_space=math.min(receiver_space,distance(gx,gy,ex,ey))
                local fraction=(ex-px)/(gx-px)
                if fraction>=0 and fraction<=1 then
                    lane=math.min(lane,math.abs(ey-py))
                end
                cpu_arrival=math.min(cpu_arrival,distance(gx,py,ex,ey))
            end
        end)
        local margin=cpu_arrival-offset
        if receiver_space<cfg.min_receiver_clearance
            or lane<cfg.min_lane_clearance
            or margin<cfg.min_arrival_margin then
            return nil,"UNSAFE_GK_BACKPASS"
        end
        return {
            carrier=carrier,receiver=config.MY_FIRST,zone=1,
            intent="GK_BACKPASS_SUPPORT",button=c.button,
            direction=dir==1 and "Left" or "Right",
            distance=distance(px,py,gx,gy),
            forward=-back,lateral=offset,
            receiver_clearance=receiver_space,
            lane_clearance=lane,arrival_margin=margin,
            score=receiver_space+lane*0.65+margin*0.45-back*0.20
        },"SAFE_GK_BACKPASS"
    end
    function obj.fire(plan,movement)
        if not plan or obj.cooldown>0 then return false end
        if plan.intent=="SHORT_DIAGONAL" or plan.intent=="EIGHT_WAY_DIAGONAL" then
            movement.press_diagonal_button(plan.direction,plan.vertical,plan.button)
        else
            movement.press_direction_button(plan.direction,plan.button)
        end
        obj.cooldown=c.cooldown_frames
        obj.last_carrier=plan.carrier
        return true
    end
    return obj
end
return M
