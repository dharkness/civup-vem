-- WWGD - Events
-- Author: Thalassicus
-- DateCreated: 6/6/2011 2:11:50 PM
--------------------------------------------------------------

include("CiVUP_Core.lua")

local log = Events.LuaLogger:New();
log:SetLevel("DEBUG");

local query = ""

function AIHandicapPromotions(  playerID,
								unitID,
								hexVec,
								unitType,
								cultureType,
								civID,
								primaryColor,
								secondaryColor,
								unitFlagIndex,
								fogState,
								selected,
								military,
								notInvisible )
	local player = Players[playerID]
    if not player or not player:IsAlive() or player:IsHuman() then
		return
	end

	local unit = Players[ playerID ]:GetUnitByID( unitID )
	if unit == nil or unit:IsDead() then
        return
    end

	local handicapInfo = GameInfo.HandicapInfos[Players[Game.GetActivePlayer()]:GetHandicapType()]
	local freePromotion = handicapInfo.AIFreePromotion

	if freePromotion then
		unit:SetHasPromotion(GameInfo.UnitPromotions[freePromotion].ID, true)
	end

	if (1 + handicapInfo.ID) >= 5 then -- king
		-- The AI is not good at using siege units
		unit:SetHasPromotion(GameInfo.UnitPromotions.PROMOTION_CITY_PENALTY.ID, false)
		unit:SetHasPromotion(GameInfo.UnitPromotions.PROMOTION_SMALL_CITY_PENALTY.ID, false)
	end

	if player:IsMinorCiv() then
		unit:SetHasPromotion(GameInfo.UnitPromotions.PROMOTION_FREE_UPGRADES.ID, true)
	end
end

Events.SerialEventUnitCreated.Add( AIHandicapPromotions )

---------------------------------------------------------------------
---------------------------------------------------------------------

function AIHandicapPromotionsPart2()
	if Game.GetGameTurn() > 50 then
		return
	end
	local promotionID = GameInfo.UnitPromotions.PROMOTION_EMBARKATION.ID
	for playerID,player in pairs(Players) do
		if IsValidPlayer(player) and not player:IsHuman() and not player:IsMinorCiv() then
			local capital = player:GetCapitalCity()
			if capital then
				local plot = capital:Plot()
				if plot:IsCoastalLand() and GetAreaWeights(plot, 1, 8).SEA >= 0.5 then
					for unit in player:Units() do
						if unit and isCoastal then
							unit:SetHasPromotion(promotionID, true)
						end
					end
				end
			end
		end
	end
end

Events.ActivePlayerTurnStart.Add( AIHandicapPromotionsPart2 )

---------------------------------------------------------------------
---------------------------------------------------------------------

function PlayerStartingDefenders(player)
	if Game.GetGameTurn() == 1 then
		local activePlayer = Players[Game.GetActivePlayer()]

		local capitalCity = player:GetCapitalCity()
		if capitalCity == nil then
			log:Warn("PlayerStartingDefenders %s has no capital", player:GetName())
			return
		end

		local plot = capitalCity:Plot()
		log:Info("PlayerStartingDefenders %s", player:GetName())
			
		local isCoastal = false
		if plot:IsCoastalLand() then
			if GetAreaWeights(plot, 1, 8).SEA >= 0.5 then
				isCoastal = true
			end
		end

		local handicapInfo = GameInfo.HandicapInfos[Players[Game.GetActivePlayer()]:GetHandicapType()]
		local handicapID = 1 + handicapInfo.ID
		local worldInfo = GameInfo.Worlds[Map.GetWorldSize()]

		if player:IsMinorCiv() then
			-- 1 settler
			-- 2 chieftain
			-- 3 warlord
			player:ChangeGold(10*handicapID)
			if handicapID >= 4 then -- prince
				Player_InitUnitClass(player, "UNITCLASS_ARCHER", plot)
			end
			if handicapID >= 5 then -- king
				Player_InitUnitClass(player, "UNITCLASS_WARRIOR", plot)
				capitalCity:SetNumRealBuilding(GetUniqueBuildingID(player, "BUILDINGCLASS_MARKET"), 1) -- finances unit maintenance
			end
			if handicapID >= 6 then -- emperor
				if isCoastal then
					Player_InitUnitClass(player, "UNITCLASS_TRIREME", plot)
				else
					Player_InitUnitClass(player, "UNITCLASS_WARRIOR", plot)
				end
			end
			if handicapID >= 7 then -- immortal
				if isCoastal then
					Player_InitUnitClass(player, "UNITCLASS_TRIREME", plot)
				else
					Player_InitUnitClass(player, "UNITCLASS_WARRIOR", plot)
				end
			end
			if handicapID >= 8 then -- deity
				Player_InitUnitClass(player, "UNITCLASS_SPEARMAN", plot)
			end

		elseif not player:IsHuman() then
			local isBold = (GameInfo.Leaders[player:GetLeaderType()].Boldness > 5)
			local teamID = player:GetTeam()
			local team   = Teams[teamID]
				
			if isBold then
				player:ChangeGold(handicapInfo.Gold)
			end
				
			query = string.format("Goody = 1 AND TilesPerGoody > 0")
			local ruinsID = GameInfo.Improvements.IMPROVEMENT_GOODY_HUT.ID
			local nearPlots = GetPlotsInCircle(plot, 1, worldInfo.AICapitalRevealRadius)
			for _, adjPlot in pairs(nearPlots) do
				adjPlot:SetRevealed(teamID, true)
				local improvementID = adjPlot:GetImprovementType()
				if improvementID ~= -1 and not adjPlot:IsVisible(Game.GetActiveTeam()) then
					for impInfo in GameInfo.Improvements(query) do
						if improvementID == impInfo.ID then
							adjPlot:SetImprovementType(-1)
							Player_ChangeYieldStored(player, YieldTypes.YIELD_GOLD, 10)
							Player_ChangeYieldStored(player, YieldTypes.YIELD_SCIENCE, 10)
							Player_ChangeYieldStored(player, YieldTypes.YIELD_CULTURE, 10)
							break
						end
					end
				end
			end
				
			-- 1 settler
			-- 2 chieftain
			-- 3 warlord
			if handicapID >= 4 then -- prince
				if isCoastal then
					log:Debug("Is Coastal")
					--team:SetHasTech(GameInfo.Technologies.TECH_SAILING.ID, true)
				end
				Player_InitUnitClass(player, "UNITCLASS_WORKER", plot)
				Player_InitUnitClass(player, "UNITCLASS_ARCHER", plot)
			end
			if handicapID >= 5 then -- king
				if isCoastal then
					Player_InitUnitClass(player, "UNITCLASS_WORKBOAT", plot)
					Player_InitUnitClass(player, "UNITCLASS_TRIREME", plot)
				elseif isBold then
					Player_InitUnitClass(player, "UNITCLASS_WORKER", plot)
				end
				capitalCity:SetNumRealBuilding(GetUniqueBuildingID(player, "BUILDINGCLASS_MARKET"), 1)
			end
			if handicapID >= 6 then -- emperor
				if isCoastal then
					--team:SetHasTech(GameInfo.Technologies.TECH_OPTICS.ID, true)
				end
				if isBold then
					Player_InitUnitClass(player, "UNITCLASS_WORKER", plot)
				end
				Player_InitUnitClass(player, "UNITCLASS_ARCHER", plot)
			end
			if handicapID >= 7 then -- immortal
				if isCoastal then
					Player_InitUnitClass(player, "UNITCLASS_WORKBOAT", plot)
					Player_InitUnitClass(player, "UNITCLASS_TRIREME", plot)
				elseif isBold then
					Player_InitUnitClass(player, "UNITCLASS_WORKER", plot)
				end
			end
			if handicapID >= 8 then -- deity
				if isBold then
					Player_InitUnitClass(player, "UNITCLASS_CATAPULT", plot)
				else
					Player_InitUnitClass(player, "UNITCLASS_ARCHER", plot)
				end
			end
		end
	end
end

LuaEvents.ActivePlayerTurnStart_Player.Add(PlayerStartingDefenders)

---------------------------------------------------------------------
---------------------------------------------------------------------

function AIPerTurnBonuses(player)
	local capitalCity = player:GetCapitalCity()
	if capitalCity == nil then
		return
	end
	local activePlayer = Players[Game.GetActivePlayer()]
	if not player:IsMinorCiv() and not player:IsHuman() then
		local handicapInfo		= GameInfo.HandicapInfos[activePlayer:GetHandicapType()]
		local yieldStored		= Player_GetYieldStored(player, YieldTypes.YIELD_SCIENCE)
		local yieldRate			= Player_GetYieldRate(player, YieldTypes.YIELD_SCIENCE)
		local yieldMod			= handicapInfo.AIResearchPercent/100
		local yieldModPerEra	= handicapInfo.AIResearchPercentPerEra/100 * activePlayer:GetCurrentEra()
		Player_ChangeYieldStored(player, YieldTypes.YIELD_SCIENCE, Round(yieldRate * (yieldMod + yieldModPerEra)))
		log:Warn("Sci bonus for %-25s: %5s + %4s * (%4s + %-4s) = %5s (+%s)",
			player:GetName(),
			yieldStored,
			yieldRate,
			Round(yieldMod, 2),
			Round(yieldModPerEra, 2),
			Player_GetYieldStored(player, YieldTypes.YIELD_SCIENCE),
			Round(yieldRate * (yieldMod + yieldModPerEra))
		)
	end
end

LuaEvents.ActivePlayerTurnEnd_Player.Add(AIPerTurnBonuses)

---------------------------------------------------------------------
---------------------------------------------------------------------

--[[
stateTable[state][condition?] = actionToTake()

table = 
{
	condition1 = "action",
	condition2 = "action",
	condition3 = "action",
	condition4 = "action",
}
assert(loadstring(table[condition]))
--]]

function AISpendExcessGold(player)
	local gold = 500
	local goldThreshold = 1500
	local playerTeam = Teams[player:GetTeam()]
	local playerID = player:GetID()
	if not player:IsMinorCiv() and not player:IsHuman() and Player_GetYieldStored(player, YieldTypes.YIELD_GOLD) > goldThreshold then
		log:Info("Check AISpendExcessGold %s %sg", player:GetName(), Player_GetYieldStored(player, YieldTypes.YIELD_GOLD))
		local mostInfluence = -1
		local mostInfluenceCS = nil
		for minorCivID, minorCiv in pairs(Players) do
			if IsValidPlayer(minorCiv) and minorCiv:IsMinorCiv() then
				local minorTeamID = minorCiv:GetTeam()
				local influence = minorCiv:GetMinorCivFriendshipWithMajor(playerID)
				log:Debug("%20s has %4s influence with %20s: IsHasMet=%5s IsAtWar=%5s mostInfluence=%s",
					player:GetName(),
					influence,
					minorCiv:GetName(),
					playerTeam:IsHasMet(minorTeamID),
					playerTeam:IsAtWar(minorTeamID),
					mostInfluence
				)
				if playerTeam:IsHasMet(minorTeamID) and not playerTeam:IsAtWar(minorTeamID) and influence > mostInfluence then
					if IsBetween(GameDefines.FRIENDSHIP_THRESHOLD_NEUTRAL, influence, GameDefines.FRIENDSHIP_THRESHOLD_ALLIES) then
						mostInfluence = influence
						mostInfluenceCS = minorCiv
					end
				end
			end
		end
		if mostInfluenceCS then
			local influence = mostInfluenceCS:GetFriendshipFromGoldGift(playerID, gold)
			mostInfluenceCS:ChangeMinorCivFriendshipWithMajor(playerID, influence)
			Player_ChangeYieldStored(player, YieldTypes.YIELD_GOLD, -1 * gold)
			log:Debug("AISpendExcessGold %20s %sg on citystate %20s for %s influence", player:GetName(), gold, mostInfluenceCS:GetName(), influence)
		end
	end
end

LuaEvents.ActivePlayerTurnEnd_Player.Add(AISpendExcessGold)