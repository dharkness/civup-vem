-- CiVUP_General
-- Author: Thalassicus
-- DateCreated: 12/21/2010 10:00:43 AM
--------------------------------------------------------------

include("YieldLibrary.lua")

local log = Events.LuaLogger:New()
log:SetLevel("WARN")

--
-- Default Conditions and Actions
--

Game.TrigCondition = Game.TrigCondition or {}
Game.TrigAction = Game.TrigAction or {}

function Game.TrigAction.ChangePlotYield (playerID, trigID, targetID, outID)
	local plot		= Map.GetPlotByIndex(targetID)
	local yieldType	= GameInfo.Yields[GameInfo.Outcomes[outID].YieldType].ID
	local yield		= GameInfo.Outcomes[outID].Yield
	Plot_ChangeYield(plot, yieldType, yield)
end

--
-- Main algorithm
--

function CheckTriggers(player)
	if player:IsMinorCiv() then return end
	local playerID		= player:GetID()
	local trigChance	= MapModData.VEM.TrigChance[playerID] --(player == activePlayer) and 100 or 0
	local rand			= 1 + Map.Rand(100, "CheckTriggers") -- correct calculation, or off-by-one ?
	local doCheck		= MapModData.VEM.CanDoTriggers[playerID] and trigChance >= rand
	
	log:Trace("player=%20s trigChance=%s rand=%s", player:GetName(), trigChance, rand)
	if doCheck then
		local eligibleIDs	= {}
		local totalWeight	= 0
		local chanceIDs		= {}
		local chancePos		= 1
		eligibleIDs = GetEligibleTriggers(player)
		if #eligibleIDs <= 1 then
			MapModData.VEM.TrigRanRecently[playerID] = {}
			if #eligibleIDs <= 0 then
				eligibleIDs	= GetEligibleTriggers(player)
				if #eligibleIDs <= 0 then
					log:Warn("No valid triggers for %s on turn %s", player:GetName(), Game.GetGameTurn())
					--MapModData.VEM.CanDoTriggers[playerID] = false
					doCheck = false
				end
			end
		end

		if doCheck then
			for _, trigID in pairs(eligibleIDs) do
				totalWeight = totalWeight + GameInfo.Triggers[trigID].Weight
			end
		
			-- map probabilities to trigger IDs
			for _, trigID in pairs(eligibleIDs) do
				local step = 1000 * GameInfo.Triggers[trigID].Weight / totalWeight
				for i = math.floor(chancePos), math.floor(chancePos + step) do
					chanceIDs[i] = trigID
				end
				chancePos = chancePos + step
			end
		
			DoTrigger(player, chanceIDs[1 + Map.Rand(1000, "CheckTriggers")])
		end
	end
	
	if trigChance == 100 then
		ResetTriggers(player)
	else
		local trigRate = GameInfo.Eras[Players[Game.GetActivePlayer()]:GetCurrentEra()].TriggerRatePercent
		local techRate = GameInfo.GameSpeeds[Game.GetGameSpeedType()].ResearchPercent / 100

		MapModData.VEM.TrigChance[playerID] = trigChance + trigRate * techRate
		SaveValue(trigChance, "MapModData.VEM.TrigChance[%s]", playerID)
	end
end

function DoTrigger(player, trigID)
	log:Info("DoTrigger player=%s trigger=%s", player:GetName(), GameInfo.Triggers[trigID].Type)
	local trigInfo = GameInfo.Triggers[trigID]
	local playerID = player:GetID()
	
	local possibleOutIDs = {}
	for targetID, outInfo in pairs(MapModData.VEM.TrigOutcomes[playerID][trigID]) do
		table.insert(possibleOutIDs, targetID)
	end
	
	local targetID = possibleOutIDs[1 + Map.Rand(#possibleOutIDs, "CheckTriggers")]

	SetTriggeredFor(playerID, trigID, targetID, true)
	MapModData.VEM.CanDoTriggers[playerID] = false
	SaveValue(0, "MapModData.VEM.CanDoTriggers[%s]", playerID)
	LuaEvents.TriggerPopup(player, trigID, targetID)
end

--
-- Check for eligible triggers
--

function GetEligibleTriggers(player)
	local eligibleIDs = {}
	local playerID = player:GetID()
	for trigInfo in GameInfo.Triggers() do
		if not MapModData.VEM.TrigRanRecently[playerID][trigInfo.ID] and CanDoThisTurn(player, trigInfo.ID) then
			log:Debug("GetEligibleTriggers : %s", trigInfo.Type)
			table.insert(eligibleIDs, trigInfo.ID)
		end
	end
	log:Debug("GetEligibleTriggers #eligibleIDs = %s", #eligibleIDs)
	return eligibleIDs
end

function CanDoThisTurn(player, trigID)
	local canDo				= false
	local playerID			= player:GetID()
	local trigInfo			= GameInfo.Triggers[trigID]
	local trigTech			= MapModData.VEM.TrigTech[playerID][trigID]
	local target			= nil
	local tarUnitClass		= nil
	local tarBuildingClass	= nil
	local tarImprovement	= nil
	local tarPolicy			= nil
	local query				= string.format("TriggerType = '%s'", trigInfo.Type)
	MapModData.VEM.TrigOutcomes[playerID][trigID] = {n=0}
	
	--log:Trace("%-30s trigTech = %s", trigInfo.Type, trigTech)
	if not Player_HasTech(player, trigTech) then
		return false
	end
	if trigInfo.EraType then
		if player:GetCurrentEra() < GameInfo.Eras[trigInfo.EraType].ID then
			return false
		end
	elseif trigInfo.Turn then
		if Game.GetGameTurn() ~= trigInfo.Turn then
			return false
		end
	end
		
	target = trigInfo.Target
	if trigInfo.UnitClass then
		tarUnitClass = GameInfo.UnitClasses[trigInfo.UnitClass].Type
		target = target or "TARGET_UNIT"
	elseif trigInfo.BuildingClass then
		tarBuildingClass = GameInfo.BuildingClasses[trigInfo.BuildingClass].Type
		target = target or "TARGET_CITY"
	elseif trigInfo.ImprovementType then
		tarImprovement = GameInfo.Improvements[trigInfo.ImprovementType].ID
		target = target or "TARGET_OWNED_PLOT"
	elseif trigInfo.PolicyType then
		tarPolicy = GameInfo.Policies[trigInfo.PolicyType].ID
		target = target or "TARGET_POLICY"
	end
	target = target or "TARGET_CUSTOM"
	
	if target == "TARGET_OWNED_PLOT" or target == "TARGET_CITY" then
		for city in player:Cities() do
			if target == "TARGET_OWNED_PLOT" or tarImprovement then
				for i = 0, city:GetNumCityPlots() - 1, 1 do
					local plot = city:GetCityIndexPlot(i)
					if plot and plot:GetOwner() == playerID then
						if tarImprovement == nil or tarImprovement == plot:GetImprovementType() then
							CheckOutcomes(playerID, trigID, Plot_GetID(plot))
						end
					end
				end
			elseif tarBuildingClass == nil or GetNumBuildingClass(city, tarBuildingClass) > 0 then
				log:Debug("GetNumBuildingClass(%s, %s) = %s", city:GetName(), tarBuildingClass, GetNumBuildingClass(city, tarBuildingClass))
				CheckOutcomes(playerID, trigID, City_GetID(city))
			end
		end
	elseif target == "TARGET_ANY_PLOT" then
		for plotID, plot in Plots() do
			if tarImprovement == nil or tarImprovement == plot:GetImprovementType() then
				CheckOutcomes(playerID, trigID, plotID)
			end
		end
	elseif target == "TARGET_UNIT" then
		for unit in player:Units() do
			if tarUnitClass == nil or tarUnitClass == GetUnitClass(unit) then
				CheckOutcomes(playerID, trigID, unit:GetID())
			end
		end
	elseif target == "TARGET_POLICY" or tarPolicy then
		if tarPolicy and player:HasPolicy(tarPolicy) then
			CheckOutcomes(playerID, trigID, policyInfo.ID)
		else
			for policyInfo in GameInfo.Policies() do
				if player:HasPolicy(policyInfo.ID) then
					CheckOutcomes(playerID, trigID, policyInfo.ID)
				end
			end
		end
	elseif target == "TARGET_PLAYER" or target == "TARGET_CITYSTATE" then
		for otherPlayerID, otherPlayer in pairs(Players) do
			if IsValidPlayer(player) and playerID ~= otherPlayerID then
				if (target == "TARGET_PLAYER" and not otherPlayer:IsMinorCiv()) or (target == "TARGET_CITYSTATE" and otherPlayer:IsMinorCiv()) then
					CheckOutcomes(playerID, trigID, otherPlayerID)
				end
			end
		end
	elseif target == "TARGET_TURN" or target == "TARGET_ERA" or target == "TARGET_CUSTOM" then
		CheckOutcomes(playerID, trigID, 1)
	else
		log:Warn("Invalid TargetClass %s for trigger %s", target, trigInfo.Type)
	end
	if MapModData.VEM.TrigOutcomes[playerID][trigID].n > 0 then
		canDo = true
	end
	MapModData.VEM.TrigOutcomes[playerID][trigID].n = nil
	return canDo
end

function CheckOutcomes(playerID, trigID, targetID)
	local trigInfo = GameInfo.Triggers[trigID]
	if not HasTriggeredFor(playerID, trigID, targetID) then
		for outInfo in GameInfo.Outcomes(string.format("TriggerType = '%s'", trigInfo.Type)) do
			local outID = outInfo.ID
			if Player_GetYieldStored(Players[playerID], YieldTypes.YIELD_GOLD) >= GameInfo.Outcomes[outID].GoldCost then
				if not outInfo.Condition or assert(loadstring("return " .. outInfo.Condition))()(playerID, trigID, targetID, outID) then
					log:Trace("Valid Outcome: %s %s %s", trigInfo.Type, outID, targetID)
					MapModData.VEM.TrigOutcomes[playerID][trigID][targetID] = MapModData.VEM.TrigOutcomes[playerID][trigID][targetID] or {}
					MapModData.VEM.TrigOutcomes[playerID][trigID][targetID][outInfo.Order] = outID
					MapModData.VEM.TrigOutcomes[playerID][trigID].n = (MapModData.VEM.TrigOutcomes[playerID][trigID].n or 0) + 1
				end
			end
		end
	end
end

function HasTriggeredFor(playerID, trigID, targetID)
	if MapModData.VEM.TrigRanFor[playerID][trigID][targetID] == nil then
		MapModData.VEM.TrigRanFor[playerID][trigID][targetID] = LoadValue("MapModData.VEM.TrigRanFor[%s][%s][%s]", playerID, trigID, targetID) or 0
	end
	return (1 == MapModData.VEM.TrigRanFor[playerID][trigID][targetID])
end

function SetTriggeredFor(playerID, trigID, targetID, value)
	MapModData.VEM.TrigRanFor[playerID][trigID][targetID] = value and 1 or 0
	SaveValue(value and 1 or 0, "MapModData.VEM.TrigRanFor[%s][%s][%s]", playerID, trigID, targetID)
end

--
-- Load/save operations
--

function LoadTriggers(player)
	local playerID = player:GetID()
	MapModData.VEM.CanDoTriggers[playerID] = (1 == LoadValue("MapModData.VEM.CanDoTriggers[%s]", playerID))
	for trigInfo in GameInfo.Triggers() do
		local trigID = trigInfo.ID
		MapModData.VEM.TrigOutcomes[playerID][trigID] = {n=0}
		MapModData.VEM.TrigRanFor[playerID][trigID] = {}
		MapModData.VEM.TrigRanRecently[playerID][trigID] = (1 == LoadValue("MapModData.VEM.TrigRanRecently[%s][%s]", playerID, trigID))
	end
end

function ResetTriggers(player)
	local playerID = player:GetID()
	MapModData.VEM.TrigChance[playerID] = 0
	MapModData.VEM.CanDoTriggers[playerID] = true
	MapModData.VEM.TrigRanRecently[playerID] = {}
	SaveValue(0, "MapModData.VEM.TrigChance[%s]", playerID)
	SaveValue(1, "MapModData.VEM.CanDoTriggers[%s]", playerID)
	for trigInfo in GameInfo.Triggers() do
		local trigID = trigInfo.ID
		MapModData.VEM.TrigOutcomes[playerID][trigID] = {n=0}
		MapModData.VEM.TrigRanFor[playerID][trigID] = {}
	end
end

--
-- Initialize
--

if not MapModData.VEM.InitTriggers then
	log:Debug("Initializing Trigger System")
	MapModData.VEM.InitTriggers		= true
	MapModData.VEM.CanDoTriggers	= {}
	MapModData.VEM.TrigChance		= {}
	MapModData.VEM.TrigOutcomes		= {}
	MapModData.VEM.TrigRanRecently	= {}
	MapModData.VEM.TrigRanFor		= {}
	MapModData.VEM.TrigTech			= {}
	for playerID,player in pairs(Players) do
		if IsValidPlayer(player) and not player:IsMinorCiv() then
			MapModData.VEM.TrigOutcomes[playerID]		= {}
			MapModData.VEM.TrigRanRecently[playerID]	= {}
			MapModData.VEM.TrigChance[playerID]			= LoadValue("MapModData.VEM.TrigChance[%s]", playerID)
			MapModData.VEM.TrigTech[playerID]			= {}
			MapModData.VEM.TrigRanFor[playerID]			= {}

			-- prerequisite techs
			for trigInfo in GameInfo.Triggers() do
				local prereqTech = nil
				if trigInfo.PrereqTech then
					-- priority override
					prereqTech = trigInfo.PrereqTech
				elseif trigInfo.BuildingClass then
					prereqTech = GameInfo.Buildings[GetUniqueBuildingID(player, trigInfo.BuildingClass)].PrereqTech
				elseif trigInfo.UnitClass then
					prereqTech = GameInfo.Units[GetUniqueUnitID(player, trigInfo.UnitClass)].PrereqTech
				elseif trigInfo.ImprovementType then
					for buildInfo in GameInfo.Builds(string.format("ImprovementType = '%s'", trigInfo.ImprovementType)) do
						prereqTech = buildInfo.PrereqTech
					end
				end
				if not prereqTech then
					prereqTech = "TECH_AGRICULTURE"
				end
				MapModData.VEM.TrigTech[playerID][trigInfo.ID] = prereqTech
			end
			
			-- load data from savegame
			if MapModData.VEM.TrigChance[playerID] then
				LoadTriggers(player)
			else
				ResetTriggers(player)
			end
		end
	end
end

if GameInfo.Triggers[1] ~= nil then
	log:Debug("Trigger System Active")
	LuaEvents.ActivePlayerTurnStart_Player.Add(CheckTriggers)
end