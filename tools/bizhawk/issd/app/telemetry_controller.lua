-- Passive telemetry controller extracted from orchestrator (v76).
-- Dependencies are explicit; tactical commands are not issued here.
local M={}
function M.new(d)
    local obj={}
    local report=d.report
    local config=d.config
    local gameplay_active=d.gameplay_active
    local defensive_midfield_transition=d.defensive_midfield_transition
    local mid_attack_transition=d.mid_attack_transition
    local five_direction_pass_observer=d.five_direction_pass_observer
    local defensive_clearance_outcome=d.defensive_clearance_outcome
    local long_pass_position_observer=d.long_pass_position_observer
    local long_pass_receiver_selection=d.long_pass_receiver_selection
    local movement=d.movement
    local restart_origin_tracker=d.restart_origin_tracker
    local gk_throw_outcome_tracker=d.gk_throw_outcome_tracker
    local opportunity_tracker=d.opportunity_tracker

function obj.observe_pass_window_outcome(state)
    for _,ev in ipairs(opportunity_tracker.outcome(report.frame,state)) do
        report:write(ev.kind,true,state,"OBSERVE_PASS_WINDOW",
            "receiver="..tostring(ev.receiver)..";sector="..tostring(ev.sector)
            ..";duration="..tostring(ev.duration)..";reason="..tostring(ev.reason)
            ..";status="..tostring(state.status))
    end
end

function obj.observe_field_transitions(state)
        local transition_events=defensive_midfield_transition.update(state,report.frame)
        for _,event in ipairs(transition_events) do
            report:write("DEF_MID_TRANSITION_"..event.kind,true,state,
                "OBSERVE_TRANSITION",
                "reason="..tostring(event.reason)
                ..";sequence="..tostring(event.sequence)
                ..";age="..tostring(event.age)
                ..";route="..tostring(event.route)
                ..";boundary="..tostring(event.boundary)
                ..";game_state="..tostring(event.game_state)
                ..";gameplay_active="..tostring(event.gameplay_active)
                ..";possession="..tostring(event.possession)
                ..";selected="..tostring(event.selected)
                ..";status="..tostring(event.status)
                ..";direction="..tostring(event.direction)
                ..";zone="..tostring(event.zone)
                ..";owner_changes="..tostring(event.owner_changes)
                ..";loose_frames="..tostring(event.loose_frames)
                ..";source="..tostring(event.source)
                ..";action_count="..tostring(event.action_count)
                ..";action_kind="..tostring(event.action_kind)
                ..";action_age="..tostring(event.action_age)
                ..";action_owner="..tostring(event.action_owner)
                ..";action_saw_loose="..tostring(event.action_saw_loose)
                ..";first_receiver="..tostring(event.first_receiver)
                ..";receive_age="..tostring(event.receive_age)
                ..";received_zone="..tostring(event.received_zone)
                ..";progress_after_receive="..tostring(event.progress_after_receive)
                ..";max_progress_after_receive="..tostring(event.max_progress_after_receive)
                ..";reception_kind="..tostring(event.reception_kind)
                ..";grace_deadline="..tostring(event.grace_deadline)
                ..";grace_granted="..tostring(event.grace_granted))
        end
        for _,event in ipairs(mid_attack_transition.update(state,report.frame)) do
            report:write("MID_ATTACK_TRANSITION_"..event.kind,true,state,
                "OBSERVE_TRANSITION",
                "reason="..tostring(event.reason)
                ..";sequence="..tostring(event.sequence)
                ..";age="..tostring(event.age)
                ..";route="..tostring(event.route)
                ..";start_progress="..tostring(event.start_progress)
                ..";max_progress="..tostring(event.max_progress)
                ..";progress_gain="..tostring(event.progress_gain)
                ..";net_progress="..tostring(event.net_progress)
                ..";remaining="..tostring(event.remaining)
                ..";first_cross_age="..tostring(event.first_cross_age)
                ..";entries="..tostring(event.entries)
                ..";stability_resets="..tostring(event.returns)
                ..";retreats="..tostring(event.retreats)
                ..";unowned_frames="..tostring(event.unowned_frames)
                ..";deadline="..tostring(event.deadline)
                ..";extensions="..tostring(event.extensions)
                ..";recent_gain="..tostring(event.recent_gain)
                ..";grace_granted="..tostring(event.grace_granted)
                ..";grace_frames="..tostring(event.grace_frames))
        end
end

-- Keep passive pass observation outside step_bot to conserve Lua registers.
function obj.observe_five_direction_pass(my_base,outlet,diagnostic)
    local result=five_direction_pass_observer.evaluate(report.frame,my_base,
        outlet and outlet.receiver or nil)
    if not result then return end
    for _,ev in ipairs(opportunity_tracker.sample(report.frame,my_base,result,outlet)) do
        report:write(ev.kind,true,{my_base=my_base},"OBSERVE_PASS_WINDOW",
            "receiver="..tostring(ev.receiver)..";sector="..tostring(ev.sector)
            ..";duration="..tostring(ev.duration)..";reason="..tostring(ev.reason)
            ..";selected="..tostring(ev.selected))
    end
    local best=result.best
    local pieces={"best_sector="..tostring(result.best_sector),
        "best_base="..tostring(best and best.base),
        "best_score="..tostring(best and best.score),
        "best_distance="..tostring(best and best.distance),
        "best_lane="..tostring(best and best.lane),
        "best_receiver_clearance="..tostring(best and best.receiver_clearance),
        "best_progress="..tostring(best and best.progress),
        "actual_receiver="..tostring(result.actual)}
    for _,name in ipairs({"FRONT","LEFT","RIGHT","DIAG_LEFT","DIAG_RIGHT"}) do
        local candidate=result.sectors[name]
        pieces[#pieces+1]=name.."_count="..tostring(result.counts[name])
        pieces[#pieces+1]=name.."_base="..tostring(candidate and candidate.base)
        pieces[#pieces+1]=name.."_score="..tostring(candidate and candidate.score)
    end
    report:write(result.kind,true,{my_base=my_base},
        "OBSERVE_FIVE_DIRECTION_PASS",table.concat(pieces,";"))
    -- The intended target and the commanded ray can disagree substantially.
    for _,sector in ipairs({"FRONT","LEFT","RIGHT","DIAG_LEFT","DIAG_RIGHT"}) do
        local candidate=result.sectors[sector]
        if candidate then
            report:write("FIVE_DIRECTION_COMMAND_GEOMETRY",true,
                {my_base=my_base},"OBSERVE_COMMAND_GEOMETRY",
                "sector="..sector
                ..";receiver="..tostring(candidate.base)
                ..";command="..tostring(candidate.command)
                ..";angular_error="..tostring(candidate.command_angle)
                ..";lateral_miss="..tostring(candidate.command_miss)
                ..";command_lane="..tostring(candidate.command_lane)
                ..";receiver_clearance="..tostring(candidate.receiver_clearance)
                ..";eligible="..tostring(candidate.executable)
                ..";selected_by_policy="..tostring(result.actual==candidate.base))
        end
    end
    -- Passive comparison between proposed candidate and real pass-policy veto.
    if best and not outlet then
        local diag=diagnostic or {}
        local counts={
            {"GEOMETRY",diag.geometry_rejected or 0},
            {"RECEIVER_PRESSURE",diag.clearance_rejected or 0},
            {"LANE_BLOCKED",diag.lane_rejected or 0},
            {"FORWARD",diag.rejected_forward or 0},
            {"DISTANCE",diag.rejected_distance or 0},
            {"LATERAL",diag.rejected_lateral or 0},
            {"DEEP_LATERAL",diag.deep_lateral_rejected or 0}
        }
        local largest="NONE"
        local max_count=0
        for _,entry in ipairs(counts) do
            if entry[2]>max_count then
                largest=entry[1];max_count=entry[2]
            end
        end
        report:write("FIVE_DIRECTION_OUTLET_VETO",true,
            {my_base=my_base},"OBSERVE_PASS_VETO",
            "best_sector="..tostring(result.best_sector)
            ..";candidate="..tostring(best.base)
            ..";score="..tostring(best.score)
            ..";lane="..tostring(best.lane)
            ..";receiver_clearance="..tostring(best.receiver_clearance)
            ..";policy_reason="..tostring(diag.reason)
            ..";dominant_rejection="..largest
            ..";dominant_count="..max_count
            ..";candidates="..tostring(diag.candidate_count)
            ..";valid="..tostring(diag.valid_count)
            ..";geometry="..tostring(diag.geometry_rejected)
            ..";receiver_pressure="..tostring(diag.clearance_rejected)
            ..";lane_blocked="..tostring(diag.lane_rejected)
            ..";rejected_forward="..tostring(diag.rejected_forward)
            ..";rejected_distance="..tostring(diag.rejected_distance)
            ..";rejected_lateral="..tostring(diag.rejected_lateral)
            ..";diagonal_safe="..tostring(diag.diagonal_safe))
    end
end

-- Keep reporting and its expression registers outside the tactical step.
function obj.observe_clearance_and_long_pass(state)
        local clearance=defensive_clearance_outcome.update(state,report.frame)
        if clearance then
            report:write("DEF_CLEAR_OUTCOME_"..clearance.kind,true,state,
                "OBSERVE_CLEARANCE",
                "reason="..tostring(clearance.reason)
                ..";sequence="..clearance.sequence
                ..";age="..clearance.age
                ..";progress="..tostring(clearance.progress)
                ..";start_x="..tostring(clearance.start_x)
                ..";end_x="..tostring(clearance.end_x)
                ..";variant="..tostring(clearance.variant)
                ..";charge_frames="..clearance.frames
                ..";owner="..tostring(clearance.owner)
                ..";receiver="..tostring(clearance.receiver)
                ..";receiver_x="..tostring(clearance.receiver_x)
                ..";inactive_frames="..tostring(clearance.inactive_frames)
                ..";game_state="..tostring(clearance.game_state)
                ..";gameplay_active="..tostring(clearance.gameplay_active))
        end
        for _,event in ipairs(long_pass_position_observer.update(
            state,report.frame,movement.last_command) or {}) do
            report:write("LONG_PASS_POSITION_"..event.kind,true,state,
                "OBSERVE_LONG_PASS",
                "reason="..tostring(event.reason)
                ..";sequence="..tostring(event.sequence)
                ..";age="..tostring(event.age)
                ..";neutral_frames="..tostring(event.neutral_frames)
                ..";neutral_distance="..tostring(event.neutral_distance)
                ..";directional_frames="..tostring(event.directional_frames)
                ..";directional_distance="..tostring(event.directional_distance)
                ..";switches="..tostring(event.switches)
                ..";initial_ball_distance="..tostring(event.initial_ball_distance)
                ..";min_ball_distance="..tostring(event.min_ball_distance)
                ..";gameplay_active="..tostring(event.gameplay_active)
                ..";game_state="..tostring(event.game_state))
        end
        for _,event in ipairs(long_pass_receiver_selection.update(state,report.frame,movement.last_command) or {}) do
            report:write("LONG_PASS_RECEIVER_"..event.kind,true,state,
                "OBSERVE_LONG_PASS",
                "sequence="..tostring(event.sequence)
                ..";age="..tostring(event.age)
                ..";previous="..tostring(event.previous)
                ..";current="..tostring(event.current)
                ..";travel="..tostring(event.travel)
                ..";straight="..tostring(event.straight)
                ..";ball_distance="..tostring(event.ball_distance)
                ..";height="..tostring(event.height)
                ..";switches="..tostring(event.switches)
                ..";source="..tostring(event.source)
                ..";band="..tostring(event.band)
                ..";selected="..tostring(event.selected)
                ..";neutral_frames="..tostring(event.neutral_frames)
                ..";neutral_movement="..tostring(event.neutral_movement)
                ..";direction_frames="..tostring(event.direction_frames)
                ..";direction_movement="..tostring(event.direction_movement)
                ..";intervention_frames="..tostring(event.intervention_frames)
                ..";intervention_movement="..tostring(event.intervention_movement)
                ..";closest="..tostring(event.closest)
                ..";closest_distance="..tostring(event.closest_distance)
                ..";previous_distance="..tostring(event.previous_distance)
                ..";selected_distance="..tostring(event.selected_distance)
                ..";available="..tostring(event.available)
                ..";gameplay_active="..tostring(event.gameplay_active)
                ..";game_state="..tostring(event.game_state))
        end
end

function obj.observe_throw_in_origin(gs,taker_team,taker,owner,fallback,logical,effective)
    local events=restart_origin_tracker.update(report.frame,gs,taker_team,taker,
        owner,fallback,logical,effective)
    for _,ev in ipairs(events) do
        report:write(ev.kind,true,
            {possession=owner,game_state=gs},
            "OBSERVE_THROW_IN_ORIGIN",
            "sequence="..tostring(ev.sequence)
            ..";team="..tostring(ev.team)
            ..";taker="..tostring(ev.taker)
            ..";age="..tostring(ev.age)
            ..";owner="..tostring(ev.owner)
            ..";fallback="..tostring(ev.fallback)
            ..";logical="..tostring(ev.logical)
            ..";effective="..tostring(ev.effective)
            ..";reason="..tostring(ev.reason))
    end
end

-- Keeper throw observations stay outside step_bot's register-heavy scope.
function obj.observe_gk_throw_fire(action,plan)
    local ev=gk_throw_outcome_tracker.fire(report.frame,action,plan)
    if ev then
        report:write(ev.kind,true,
            {my_base=config.MY_FIRST},"OBSERVE_GK_THROW",
            "sequence="..ev.sequence..";mode="..tostring(action.mode)
            ..";direction="..tostring(action.direction)
            ..";planned_receiver="..tostring(action.receiver or plan.receiver)
            ..";lane="..tostring(plan.lane_clearance)
            ..";receiver_clearance="..tostring(plan.receiver_clearance))
    end
end

function obj.observe_gk_throw_outcome(gameplay_value,gs,owner)
    local ev=gk_throw_outcome_tracker.update(report.frame,
        gameplay_active.is_active(gameplay_value),gs,owner)
    if not ev then return end
    report:write(ev.kind,true,
        {possession=owner,game_state=gs},"OBSERVE_GK_THROW",
        "sequence="..ev.sequence
        ..";mode="..tostring(ev.mode)
        ..";direction="..tostring(ev.direction)
        ..";planned_receiver="..tostring(ev.planned_receiver)
        ..";actual_receiver="..tostring(ev.receiver)
        ..";age="..tostring(ev.age)
        ..";release_age="..tostring(ev.release_age)
        ..";lane="..tostring(ev.lane)
        ..";receiver_clearance="..tostring(ev.clearance)
        ..";reason="..tostring(ev.reason))
end

    return obj
end
return M
