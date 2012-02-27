-- Example events
-- Author: veyDer
--------------------------------------------------------------

include("Trigger.lua")
include("CiVUP_Core.lua")

local log = Events.LuaLogger:New()
log:SetLevel("DEBUG")

----------------------------------------------------------------

Game.TrigCondition = Game.TrigCondition or {}
Game.TrigAction = Game.TrigAction or {}

function Game.TrigCondition.UnitUnownedTerritory(playerID, trigID, targetID, outID)
	return (Players[playerID]:GetUnitByID(targetID):GetPlot():GetOwner() == -1)
end

----------------------------------------------------------------

function Game.TrigAction.FortExpansion2(playerID, trigID, targetID, outID)
	Map.GetPlotByIndex(targetID):SetImprovementType(GameInfoTypes.IMPROVEMENT_CITADEL)
end

function Game.TrigAction.GranaryPopulationBoom1(playerID, trigID, targetID, outID)
	Player_InitUnitClass(Players[playerID], "UNITCLASS_SETTLER", Map_GetCityByID(targetID))
end

function Game.TrigAction.GranaryPopulationBoom2(playerID, trigID, targetID, outID)
	Player_InitUnitClass(Players[playerID], "UNITCLASS_WORKER", Map_GetCityByID(targetID))
	Player_InitUnitClass(Players[playerID], "UNITCLASS_WORKER", Map_GetCityByID(targetID))
end

function Game.TrigAction.BarracksRecruitment2(playerID, trigID, targetID, outID)
	local city			= Map_GetCityByID(targetID)
	local availableIDs	= GetAvailableUnitIDs(city)
	for i = 1, 2 do
		local newUnitID	= availableIDs[1 + Map.Rand(#availableIDs, "DoBarracksRecruitment2")]
		local exp		= City_GetUnitExperience(city, newUnitID)
		Player_InitUnit(Players[playerID], newUnitID, city:Plot(), exp)
	end
end

----------------------------------------------------------------

function Game.TrigAction.ScoutSavior1(playerID, trigID, targetID, outID)
	local unit = Players[playerID]:GetUnitByID(targetID)
	unit:ChangeExperience(15)
	unit:SetPromotionReady(unit:GetExperience() >= unit:ExperienceNeeded())
end

function Game.TrigAction.ScoutSavior2(playerID, trigID, targetID, outID)
	local newUnit = Unit_Replace(Players[playerID]:GetUnitByID(targetID), "UNITCLASS_ARCHER")
	newUnit:SetHasPromotion(GameInfo.UnitPromotions.PROMOTION_IGNORE_TERRAIN_COST_NOUPGRADE.ID, true)
end

function Game.TrigCondition.ScoutSavior3(playerID, trigID, targetID, outID)
	return (
		Game.TrigCondition.UnitUnownedTerritory(playerID, trigID, targetID, outID)
		and not Players[playerID]:GetUnitByID(targetID):IsHasPromotion(GameInfo.UnitPromotions.PROMOTION_MORALE.ID)
	)
end

function Game.TrigAction.ScoutSavior3(playerID, trigID, targetID, outID)
	Players[playerID]:GetUnitByID(targetID):SetHasPromotion(GameInfo.UnitPromotions.PROMOTION_MORALE.ID, true)
end