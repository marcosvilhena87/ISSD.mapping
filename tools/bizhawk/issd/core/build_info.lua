-- Read current local checkout identity without shelling out to Git.
-- Unknown is deliberate: never claim that an old hardcoded build is current.
local M={}
local function read_file(path)
    local f=io.open(path,"r")
    if not f then return nil end
    local value=f:read("*a")
    f:close()
    return value
end
local function trim(s)
    return s and s:match("^%s*(.-)%s*$") or nil
end
local function git_dir_from(app_dir)
    local root=app_dir.."../../../../"
    local dotgit=root..".git"
    local pointer=read_file(dotgit)
    if pointer then
        local dir=pointer:match("^gitdir:%s*(.-)%s*$")
        if dir then
            if dir:match("^%a:[/\\]") or dir:sub(1,1)=="/" then
                return dir:gsub("\\","/").."/"
            end
            return root..dir:gsub("\\","/").."/"
        end
    end
    return dotgit.."/"
end
function M.read(app_dir,config)
    local gitdir=git_dir_from(app_dir)
    local head=trim(read_file(gitdir.."HEAD"))
    local commit=nil
    local ref=head and head:match("^ref:%s*(%S+)$")
    if ref then
        commit=trim(read_file(gitdir..ref))
        if not commit then
            local packed=read_file(gitdir.."packed-refs") or ""
            for line in packed:gmatch("[^\r\n]+") do
                local sha,name=line:match("^(%x+)%s+(%S+)$")
                if name==ref then commit=sha;break end
            end
        end
    else commit=head end
    if not commit or not commit:match("^%x+$")
        or #commit~=40 then commit="unknown" end
    local branch=ref and (ref:match("^refs/heads/(.+)$") or ref)
        or (commit=="unknown" and "unknown" or "detached")
    local checks={
        {"aerial_lock_revalidation",config.AERIAL_LOCK_TARGET_REVALIDATION},
        {"aerial_target_revalidation",config.AERIAL_RECEIVER_TARGET_REVALIDATION},
        {"pre_reception_pressure",config.PRE_RECEPTION_PRESSURE_LOCK},
        {"post_loss_counterpress",config.POST_LOSS_COUNTERPRESS},
        {"defensive_corridor_escape",config.DEFENSIVE_CORRIDOR_ESCAPE},
        {"cross_second_ball_cover",config.CROSS_SECOND_BALL_COVER},
    }
    local flags={}
    for _,entry in ipairs(checks) do
        flags[#flags+1]=entry[1].."="..tostring(
            entry[2]~=nil and entry[2].enabled==true)
    end
    local detail="commit="..commit..";branch="..branch
        ..";source="..(commit=="unknown" and "UNKNOWN" or "LOCAL_GIT")
        ..";"..table.concat(flags,";")
    return {commit=commit,branch=branch,detail=detail}
end
return M
