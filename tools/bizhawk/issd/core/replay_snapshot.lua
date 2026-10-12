-- Portable BizHawk replay snapshot: prefer raw in-memory core states,
-- fall back to a uniquely named on-disk temporary savestate.
local M={}
function M.capture()
 if memorysavestate
   and type(memorysavestate.savecorestate)=="function"
   and type(memorysavestate.loadcorestate)=="function" then
  local key=memorysavestate.savecorestate()
  if not key then error("memorysavestate.savecorestate failed") end
  return {
   restore=function() memorysavestate.loadcorestate(key) end,
   close=function()
    if type(memorysavestate.removestate)=="function" then
     memorysavestate.removestate(key)
    end
   end
  }
 end
 if not savestate or type(savestate.save)~="function"
   or type(savestate.load)~="function" then
  error("BizHawk snapshot unavailable: need memorysavestate or savestate.save/load")
 end
 if not os or type(os.tmpname)~="function" then
  error("disk savestate fallback requires os.tmpname")
 end
 local path=os.tmpname()..".State"
 local ok=savestate.save(path,true)
 if ok==false then error("savestate.save failed: "..path) end
 return {
  restore=function()
   local loaded=savestate.load(path,true)
   if loaded==false then error("savestate.load failed: "..path) end
  end,
  close=function() if os.remove then os.remove(path) end end,
 }
end
return M
