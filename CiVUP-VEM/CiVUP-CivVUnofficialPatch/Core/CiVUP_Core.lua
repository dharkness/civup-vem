-- CiVUP_Core
-- Author: Thalassicus
-- DateCreated: 12/21/2010 10:00:43 AM
--------------------------------------------------------------

include("YieldLibrary.lua")

--print("INFO   Loading CiVUP_Core.lua")

if Game == nil then
	return
end

local log = Events.LuaLogger:New()
log:SetLevel("WARN")

if GameInfo.Units[1].PopCostMod == nil then
	log:Fatal("'CiVUP - General.sql' did not load!")
end