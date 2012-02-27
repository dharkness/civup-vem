-- YieldLibrary
-- Author: Thalassicus
-- DateCreated: 5/4/2011 10:43:09 AM
--------------------------------------------------------------

--[[

When the game core becomes accessable, functions in this library
like City_ and Player_ should be methods of those classes:

City_GetYieldRate(city, yieldType, itemTable, itemID, queueNum)
Player_GetSupplyModifier(player, yieldType, doUpdate)

|
V

City:GetYieldRate(yieldType, itemTable, itemID, queueNum)
Player:GetSupplyModifier(yieldType, doUpdate)

--]]

include("ThalsUtilities.lua")

--print("INFO   Loading YieldLibrary.lua")

if Game == nil or IncludedYieldLibrary then
	return
end

IncludedYieldLibrary = true

local log = Events.LuaLogger:New()
log:SetLevel("WARN")

--log:Info("Loading YieldLibrary.Lua")

MapModData.VEM						= MapModData.VEM					or {}
MapModData.VEM.AvoidModifier		= MapModData.VEM.AvoidModifier		or {}
MapModData.VEM.CityWeights			= MapModData.VEM.CityWeights		or {}
MapModData.VEM.MinorCivRewards		= MapModData.VEM.MinorCivRewards	or {}
MapModData.VEM.PlayerCityIDs		= MapModData.VEM.PlayerCityIDs		or {}
MapModData.VEM.PlayerCityWeights	= MapModData.VEM.PlayerCityWeights	or {}
MapModData.VEM.UnitSupplyCurrent	= MapModData.VEM.UnitSupplyCurrent	or {}
MapModData.VEM.UnitSupplyMax		= MapModData.VEM.UnitSupplyMax		or {}

doUpdate = false

YieldTypes.YIELD_FOOD				= YieldTypes.YIELD_FOOD
YieldTypes.YIELD_PRODUCTION			= YieldTypes.YIELD_PRODUCTION
YieldTypes.YIELD_GOLD				= YieldTypes.YIELD_GOLD
YieldTypes.YIELD_SCIENCE			= YieldTypes.YIELD_SCIENCE
YieldTypes.YIELD_CULTURE			= GameInfo.Yields.YIELD_CULTURE.ID
YieldTypes.YIELD_HAPPINESS			= GameInfo.Yields.YIELD_HAPPINESS.ID
YieldTypes.YIELD_GREAT_PERSON		= GameInfo.Yields.YIELD_GREAT_PERSON.ID
YieldTypes.YIELD_EXPERIENCE			= GameInfo.Yields.YIELD_EXPERIENCE.ID
YieldTypes.YIELD_LAW				= GameInfo.Yields.YIELD_LAW.ID
YieldTypes.YIELD_CS_MILITARY		= GameInfo.Yields.YIELD_CS_MILITARY.ID
YieldTypes.YIELD_CS_GREAT_PERSON	= GameInfo.Yields.YIELD_CS_GREAT_PERSON.ID
YieldTypes.YIELD_POPULATION			= GameInfo.Yields.YIELD_POPULATION.ID

CityYieldFocusTypes = {}
CityYieldFocusTypes[YieldTypes.YIELD_FOOD]				= CityAIFocusTypes.CITY_AI_FOCUS_TYPE_FOOD
CityYieldFocusTypes[YieldTypes.YIELD_PRODUCTION]		= CityAIFocusTypes.CITY_AI_FOCUS_TYPE_PRODUCTION
CityYieldFocusTypes[YieldTypes.YIELD_GOLD]				= CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GOLD
CityYieldFocusTypes[YieldTypes.YIELD_SCIENCE]			= CityAIFocusTypes.CITY_AI_FOCUS_TYPE_SCIENCE
CityYieldFocusTypes[YieldTypes.YIELD_CULTURE]			= CityAIFocusTypes.CITY_AI_FOCUS_TYPE_CULTURE
CityYieldFocusTypes[YieldTypes.YIELD_HAPPINESS]			= -2
CityYieldFocusTypes[YieldTypes.YIELD_GREAT_PERSON]		= CityAIFocusTypes.CITY_AI_FOCUS_TYPE_GREAT_PERSON
CityYieldFocusTypes[YieldTypes.YIELD_EXPERIENCE]		= -2
CityYieldFocusTypes[YieldTypes.YIELD_LAW]				= -2
CityYieldFocusTypes[YieldTypes.YIELD_CS_MILITARY]		= -2
CityYieldFocusTypes[YieldTypes.YIELD_CS_GREAT_PERSON]	= -2
CityYieldFocusTypes[YieldTypes.YIELD_POPULATION]			= -2

local tileYieldTypes = {
	YieldTypes.YIELD_FOOD,
	YieldTypes.YIELD_PRODUCTION,
	YieldTypes.YIELD_GOLD,
	YieldTypes.YIELD_SCIENCE,
	YieldTypes.YIELD_CULTURE,
	YieldTypes.YIELD_HAPPINESS
}

---------------------------------------------------------------------
---------------------------------------------------------------------




function IsBuildable(city, buildingID, continue, testVisible, ignoreCost)
	return city:CanConstruct(buildingID, continue, testVisible, ignoreCost)
end

function IsPurchaseable(city, testVisible, unitID, buildingID, projectID)
	if testVisible then
		return city:IsCanPurchase(testVisible, unitID, buildingID, projectID)
	end

	if unitID ~= -1 then
		itemID = unitID
		itemTable = GameInfo.Units
	elseif buildingID ~= -1 then
		itemID = buildingID
		itemTable = GameInfo.Buildings
	elseif projectID ~= -1 then
		itemID = projectID
		itemTable = GameInfo.Projects
	end
	if GetPurchaseCost(city, itemTable, itemID) > Player_GetYieldStored(Players[city:GetOwner()], YieldTypes.YIELD_GOLD) then
		return false
	end
	return city:IsCanPurchase(testVisible, unitID, buildingID, projectID)
end

---------------------------------------------------------------------
-- Base Cost
---------------------------------------------------------------------

function City_GetCostMod(city, yieldType, itemTable, itemID)
	local costMod = 1
	if itemTable == nil then
		if city:GetProductionUnit() ~= -1 then
			itemID = city:GetProductionUnit()
			itemTable = GameInfo.Units
		end
		if city:GetProductionBuilding() ~= -1 then
			itemID = city:GetProductionBuilding()
			itemTable = GameInfo.Buildings
		end
		if city:GetProductionProject() ~= -1 then
			itemID = city:GetProductionProject()
			itemTable = GameInfo.Projects
		end
	end
	if yieldType == YieldTypes.YIELD_PRODUCTION then
		if itemTable == GameInfo.Buildings and itemID then
			costMod = 1 + city:GetPopulation() * itemTable[itemID].PopCostMod / 100
		end
		-- add new cost modifier here
	end
	return costMod
end

---------------------------------------------------------------------
-- Base Yield
---------------------------------------------------------------------

function City_GetBaseYieldRate(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetBaseYieldRate city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetBaseYieldRate itemID=nil")
	end
	--log:Debug("City_GetBaseYieldRate %15s %15s", city:GetName(), GameInfo.Yields[yieldType].Type)
	local baseYield = 0
	--
	if yieldType == YieldTypes.YIELD_CULTURE then
		baseYield = (
			  City_GetBaseYieldFromTerrain		(city, yieldType)
			+ City_GetBaseYieldFromProcesses	(city, yieldType)
			+ City_GetBaseYieldFromBuildings	(city, yieldType)
			+ City_GetBaseYieldFromPopulation	(city, yieldType)
			+ City_GetBaseYieldFromSpecialists	(city, yieldType)
			+ City_GetBaseYieldFromPolicies		(city, yieldType)
			+ City_GetBaseYieldFromTraits		(city, yieldType)
			+ City_GetBaseYieldFromMinorCivs	(city, yieldType)
		)
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		for i = 0, city:GetNumCityPlots() - 1 do
			local plot = city:GetCityIndexPlot(i)
			if plot and city:IsWorkingPlot(plot) then
				baseYield = baseYield + Plot_GetYield(plot, yieldType)
			end
		end
	else
		baseYield = (
			  city:GetBaseYieldRate				(yieldType)
			+ City_GetBaseYieldFromPopulation	(city, yieldType)
			+ City_GetBaseYieldFromMinorCivs	(city, yieldType)
		)
	end
	return baseYield
end

function City_GetBuildingYield(player, buildingID, yieldType)
	local yield = 0
	local buildingInfo = GameInfo.Buildings[buildingID]
	if yieldType == nil then
		log:Fatal("City_GetBuildingYield yieldType=nil")
	end
	if buildingID == nil then
		log:Fatal("City_GetBuildingYield buildingID=nil")
	end
	if yieldType == YieldTypes.YIELD_HAPPINESS then 
		yield = yield + buildingInfo.UnmoddedHappiness
		yield = yield + player:GetExtraBuildingHappinessFromPolicies(buildingID)
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		yield = yield + buildingInfo.Culture
	else
		yield = yield + Game.GetBuildingYieldChange(buildingID, yieldType)
	end

	local buildingClass = GameInfo.Buildings[buildingID].BuildingClass
	local query = string.format("BuildingClassType = '%s' AND YieldType = '%s'", buildingClass, GameInfo.Yields[yieldType].Type)
	for row in GameInfo.Policy_BuildingClassYieldChanges(query) do
		if player:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
			yield = yield + row.YieldChange
		end
	end
	return yield
end

function City_GetBuildingYieldMod(player, buildingID, yieldType)
	local yield = 0
	local buildingInfo = GameInfo.Buildings[buildingID]
	local query = ""
	if yieldType == nil then
		log:Fatal("City_GetBuildingYieldMod yieldType=nil")
	end
	if yieldType == YieldTypes.YIELD_CULTURE then
		yield = yield + buildingInfo.CultureRateModifier
		query = string.format("BuildingType = '%s' AND YieldType = '%s'", buildingInfo.Type, GameInfo.Yields[yieldType].Type)
		for row in GameInfo.Building_YieldModifiers(query) do
			yield = yield + row.Yield
		end
	--[[elseif yieldType == YieldTypes.YIELD_GOLD then
		query = string.format("BuildingType = '%s' AND YieldType = '%s'", buildingInfo.Type, GameInfo.Yields[yieldType].Type)
		for row in GameInfo.Building_YieldModifiers(query) do
			yield = yield + row.Yield
		end--]]
	else
		yield = yield + Game.GetBuildingYieldModifier(buildingID, yieldType)
	end

	query = string.format("BuildingClassType = '%s' AND YieldType = '%s'", buildingInfo.BuildingClass, GameInfo.Yields[yieldType].Type)
	for row in GameInfo.Policy_BuildingClassYieldModifiers(query) do
		if player:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
			log:Trace("%30s %20s %5s", buildingInfo.BuildingClass, GameInfo.Yields[yieldType].Type, row.YieldMod)
			yield = yield + row.YieldMod
		end
	end
	return yield
end

function City_GetBaseYieldFromTerrain(city, yieldType)
	local yield = 0
	if yieldType == YieldTypes.YIELD_CULTURE then
		yield = city:GetJONSCulturePerTurnFromTerrain()
	else
		yield = city:GetBaseYieldRateFromTerrain(yieldType)
		--[[
		if not CiVUP.ENABLE_DISTRIBUTED_MINOR_CIV_YIELDS then
			yield = yield - City_GetBaseYieldFromMinorCivs(city, yieldType)
		end
		--]]
	end
	return yield
end

function City_GetBaseYieldFromPopulation(city, yieldType)
	local yield = 0
	if yieldType == YieldTypes.YIELD_CULTURE then
		for building in GameInfo.Buildings("CulturePerPop != 0") do
			if city:IsHasBuilding(building.ID) then
				yield = yield + building.CulturePerPop * city:GetPopulation() / 100
			end
		end
	else
		yield = city:GetPopulation() * city:GetYieldPerPopTimes100(yieldType) / 100
	end
	return yield
end

function City_GetBaseYieldFromProcesses(city, yieldType)
	local yield = 0
	if yieldType ~= YieldTypes.YIELD_PRODUCTION then
		local processID = city:GetProductionProcess()
		if processID ~= -1 then
			local processInfo = GameInfo.Processes[processID]
			local query = string.format("ProcessType = '%s' AND YieldType = '%s'", processInfo.Type, GameInfo.Yields[yieldType].Type)
			for row in GameInfo.Process_ProductionYields(query) do
				yield = yield + row.Yield / 100 * math.max(0, City_GetYieldRate(city, YieldTypes.YIELD_PRODUCTION))
			end
		end
	end
	return yield
end

function City_GetBaseYieldFromBuildings(city, yieldType)
	local yield = 0
	local player = Players[city:GetOwner()]
	for building in GameInfo.Buildings() do		
		if city:IsHasBuilding(building.ID) and (building.Type ~= "BUILDING_EXTRA_HAPPINESS") then
			yield = yield + City_GetBuildingYield(player, building.ID, yieldType)
		end
	end
	return yield
end

function City_GetBaseYieldModFromBuildings(city, yieldType)
	local yield = 0
	local player = Players[city:GetOwner()]
	for building in GameInfo.Buildings() do
		if city:IsHasBuilding(building.ID) then
			yield = yield + City_GetBuildingYieldMod(player, building.ID, yieldType)
		end
	end
	return yield
end


function City_GetBaseYieldFromSpecialists(city, yieldType)
	local yield = 0
	local citizenID = GameDefines.DEFAULT_SPECIALIST
	for specialistInfo in GameInfo.Specialists() do
		yield = yield + city:GetSpecialistCount(specialistInfo.ID) * City_GetSpecialistYield(city, yieldType, specialistInfo.ID)
	end
	return yield
end

function City_GetBaseYieldFromPolicies(city, yieldType)
	local player = Players[city:GetOwner()]
	local query = ""
	local yield = 0
	if yieldType == YieldTypes.YIELD_CULTURE then
		yield = city:GetJONSCulturePerTurnFromPolicies()
	elseif yieldType == YieldTypes.YIELD_FOOD then
		--[[
		-- This goes directly to the base terrain and cannot be reported separately.
		if city:IsCapital() then			
			query = string.format("YieldType = '%s'", GameInfo.Yields[yieldType].Type)
			for row in GameInfo.Policy_CapitalYieldChanges(query) do
				if player:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
					yield = yield + row.Yield
				end
			end
		end 
		--]]
	end
	return yield
end


function City_GetBaseYieldFromTraits(city, yieldType)
	if yieldType == YieldTypes.YIELD_CULTURE then
		return city:GetJONSCulturePerTurnFromTraits()
	else
		return 0
	end
end

function City_GetBaseYieldFromMisc(city, yieldType)
	if yieldType == YieldTypes.YIELD_CULTURE then
		return 0
	else
		return city:GetBaseYieldRateFromMisc(yieldType)
	end
end


function City_GetBaseYieldFromMinorCivs(city, yieldType)
	local player = Players[city:GetOwner()]
	local yield = 0
	if player:IsMinorCiv() then
		return yield
	end
	if CiVUP.ENABLE_DISTRIBUTED_MINOR_CIV_YIELDS then
		yield = Player_GetYieldsFromCitystates(player)[yieldType]
		if not yield then
			log:Fatal("Player_GetYieldsFromCitystates %s %s is nil", player:GetName(), GameInfo.Yields[yieldType].Type)
		end
		if yield ~= 0 then
			yield = yield * City_GetWeight(city, yieldType) / Player_GetTotalWeight(player, yieldType)
		end

		--[[
		for row in GameInfo.Policy_MinorCivBonuses(string.format("YieldType = '%s'", GameInfo.Yields[yieldType].Type)) do
			if player:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
				for minorCivID,minorCiv in pairs(Players) do
					if IsValidPlayer(minorCiv) and minorCiv:IsMinorCiv() then
						if row.FriendLevel == minorCiv:GetMinorCivFriendshipLevelWithMajor(player:GetID()) then
							yield = yield + row.Yield
						end
					end
				end
			end
		end
		--]]
	--[[
	-- This goes directly to the base terrain and cannot be reported separately.
	elseif yieldType == YieldTypes.YIELD_FOOD then
		local isRenaissance = (player:GetCurrentEra() >= GameInfo.Eras.ERA_RENAISSANCE.ID)
		local yieldLevel	= {}
		yieldLevel[-1]		= 0
		yieldLevel[0]		= 0
		yieldLevel[1]		= 0
		yieldLevel[2]		= 0
		if city:IsCapital() then
			if isRenaissance then
				yieldLevel[1] = GameDefines.FRIENDS_CAPITAL_FOOD_BONUS_AMOUNT_POST_RENAISSANCE
			else
				yieldLevel[1] = GameDefines.FRIENDS_CAPITAL_FOOD_BONUS_AMOUNT_PRE_RENAISSANCE
			end
			yieldLevel[2] = yieldLevel[1] + GameDefines.ALLIES_CAPITAL_FOOD_BONUS_AMOUNT
		else
			if isRenaissance then
				yieldLevel[1] = GameDefines.FRIENDS_OTHER_CITIES_FOOD_BONUS_AMOUNT_POST_RENAISSANCE
			else
				yieldLevel[1] = GameDefines.FRIENDS_OTHER_CITIES_FOOD_BONUS_AMOUNT_PRE_RENAISSANCE
			end
			yieldLevel[2] = yieldLevel[1] + GameDefines.ALLIES_OTHER_CITIES_FOOD_BONUS_AMOUNT
		end

		for minorCivID,minorCiv in pairs(Players) do
			if IsValidPlayer(minorCiv) and minorCiv:IsMinorCiv() then
				yield = yield + yieldLevel[minorCiv:GetMinorCivFriendshipLevelWithMajor(player:GetID())] / 100
			end
		end
	--]]
	end
	return yield
end

function City_GetSpecialistYield(city, yieldType, specialistID)
	if specialistID == nil then
		log:Fatal("City_GetSpecialistYield specialistID=nil")
	end
	local yield		= 0
	local player	= Players[city:GetOwner()]
	local traitType	= GetTrait(player).Type
	local specType	= GameInfo.Specialists[specialistID].Type
	local query		= nil

	query = string.format("YieldType = '%s' AND SpecialistType = '%s' AND TraitType = '%s'", GameInfo.Yields[yieldType].Type, specType, traitType)
	for row in GameInfo.Trait_SpecialistYieldChanges(query) do
		--if row.TraitType == traitType then
			yield = yield + row.Yield
		--end
	end

	query = string.format("YieldType = '%s' AND SpecialistType = '%s'", GameInfo.Yields[yieldType].Type, specType)
	for row in GameInfo.Policy_SpecialistYieldChanges(query) do
		if player:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
			yield = yield + row.Yield
		end
	end
	
	if yieldType == YieldTypes.YIELD_CULTURE then
		yield = yield + city:GetCultureFromSpecialist(specialistID)
	
		query = string.format("YieldType = '%s' AND SpecialistType = '%s'", GameInfo.Yields[yieldType].Type, specType)
		for row in GameInfo.Building_SpecialistYieldChanges(query) do
			if city:IsHasBuilding(GameInfo.Buildings[row.BuildingType].ID) then
				yield = yield + row.Yield
			end
		end

		query = string.format("YieldType = '%s'", GameInfo.Yields[yieldType].Type)
		for row in GameInfo.Policy_SpecialistExtraYields(query) do
			if player:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
				yield = yield + row.Yield
			end
		end

	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		
	elseif yieldType == YieldTypes.YIELD_GREAT_PERSON then
		yield = yield + GameInfo.Specialists[specialistID].GreatPeopleRateChange
	elseif yieldType == YieldTypes.YIELD_EXPERIENCE then
		yield = yield + GameInfo.Specialists[specialistID].Experience
	elseif Contains(tileYieldTypes, yieldType) then
		yield = yield + city:GetSpecialistYield(specialistID, yieldType)
	end
	return yield
end


---------------------------------------------------------------------
-- Base Yield Modifiers
---------------------------------------------------------------------

function City_GetBaseYieldRateModifier(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetBaseYieldRateModifier city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetBaseYieldRateModifier itemTable=%s itemID=%s", itemTable, itemID)
	end
	local yieldMod = 0
	local cityOwner = Players[city:GetOwner()]	
	if yieldType == YieldTypes.YIELD_CULTURE then
		yieldMod = yieldMod + City_GetBaseYieldModFromBuildings(city, yieldType) + cityOwner:GetCultureCityModifier()
		if city:GetNumWorldWonders() > 0 then
			yieldMod = yieldMod + cityOwner:GetCultureWonderMultiplier()
		end
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		-- todo
	else
		yieldMod = yieldMod + city:GetYieldRateModifier(yieldType)
		yieldMod = yieldMod + City_GetBaseYieldModifierFromPolicies(city, yieldType)
		if yieldType == YieldTypes.YIELD_FOOD then
			yieldMod = yieldMod + City_GetCapitalSettlerModifier(city, yieldType, itemTable, itemID, queueNum)
			yieldMod = yieldMod + City_GetBaseYieldModifierFromGlobalBuildings(cityOwner, yieldType)
		elseif yieldType == YieldTypes.YIELD_PRODUCTION then
			if Round(Player_GetYieldRate(cityOwner, YieldTypes.YIELD_HAPPINESS)) <= GameDefines.VERY_UNHAPPY_THRESHOLD then
				yieldMod = yieldMod + GameDefines.VERY_UNHAPPY_PRODUCTION_PENALTY
			end
			if cityOwner:GetGoldenAgeTurns() > 0 then
				yieldMod = yieldMod + 20
			end
			if itemTable == GameInfo.Units then
				--yieldMod = yieldMod + City_GetCapitalSettlerModifier(city, yieldType, itemTable, itemID, queueNum) 
				yieldMod = yieldMod + City_GetSupplyModifier(city, yieldType, itemTable, itemID, queueNum)
				yieldMod = yieldMod + city:GetUnitProductionModifier(itemID)
				return yieldMod
			elseif itemTable == GameInfo.Buildings then
				--yieldMod = yieldMod + City_GetBuildingClassConstructionYieldModifier(city, yieldType, itemTable, itemID, queueNum)
				if IsWonder(itemID) then
					return yieldMod + City_GetWonderConstructionModifier(city, yieldType, itemTable, itemID, queueNum)
				end
				yieldMod = yieldMod + city:GetBuildingProductionModifier(itemID)
				--log:Warn("buildMod = %3s %20s", city:GetBuildingProductionModifier(itemID), itemTable[itemID].Type)
				return yieldMod
			elseif itemTable == GameInfo.Projects then
				yieldMod = yieldMod + city:GetProjectProductionModifier(itemID)
				--log:Warn("projMod  = %3s %20s", yieldMod, itemTable[itemID].Type)
				return yieldMod
			else
				local unitID		= city:GetProductionUnit()
				local buildingID	= city:GetProductionBuilding()
				local projectID		= city:GetProductionProject()
				if unitID and unitID ~= -1 then
					return City_GetBaseYieldRateModifier(city, yieldType, GameInfo.Units, unitID)
				elseif buildingID and buildingID ~= -1 then
					return City_GetBaseYieldRateModifier(city, yieldType, GameInfo.Buildings, buildingID)
				elseif projectID and projectID ~= -1 then
					return City_GetBaseYieldRateModifier(city, yieldType, GameInfo.Projects, projectID)
				end
			end
		end
	end
	return yieldMod
end

function City_GetBaseYieldModifierTooltip(city, yieldType)
	local tooltip = ""
	if yieldType == YieldTypes.YIELD_CULTURE then
		-- Empire Culture modifier
		local empireMod = Players[city:GetOwner()]:GetCultureCityModifier()
		if empireMod ~= 0 then
			tooltip = tooltip .. "[NEWLINE][ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_CULTURE_PLAYER_MOD", empireMod)
		end
		
		-- City Culture modifier
		local cityMod = city:GetCultureRateModifier()
		if cityMod ~= 0 then
			tooltip = tooltip .. "[NEWLINE][ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_CULTURE_CITY_MOD", cityMod)
		end
		
		-- Culture Wonders modifier
		local wonderMod = 0
		if city:GetNumWorldWonders() > 0 then
			wonderMod = Players[city:GetOwner()]:GetCultureWonderMultiplier()
		
			if (wonderMod ~= 0) then
				tooltip = tooltip .. "[NEWLINE][ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_CULTURE_WONDER_BONUS", wonderMod)
			end
		end
	else
		tooltip = tooltip .. (city:GetYieldModifierTooltip(yieldType) or "")
		--[[
		local yieldMod = City_GetBaseYieldModifierFromGlobalBuildings(Players[city:GetOwner()], yieldType)
		if yieldMod ~= 0 then
			tooltip = tooltip .. Locale.ConvertTextKey("TXT_KEY_YIELD_MOD_GLOBAL_BUILDINGS", yieldMod)
		end
		--]]
	end
	return tooltip
end

function City_GetBaseYieldModifierFromGlobalBuildings(player, yieldType)
	local yieldMod = 0
	local yieldInfo = GameInfo.Yields[yieldType]
	local query = string.format("YieldType = '%s'", yieldInfo.Type)
	for entry in GameInfo.Building_GlobalYieldModifiers(query) do
		local buildingInfo = GameInfo.Buildings[entry.BuildingType]
		for city in player:Cities() do
			if GetNumBuilding(city, buildingInfo.ID) > 0 then
				yieldMod = entry.Yield
			end
		end
	end
	return yieldMod
end

function City_GetBaseYieldModifierFromPolicies(city, yieldType)
	local yieldMod = 0
	for row in GameInfo.Policy_YieldModifiers() do
		if yieldType == GameInfo.Yields[row.YieldType].ID and Players[city:GetOwner()]:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
			yieldMod = yieldMod + row.Yield
		end
	end
	return yieldMod
end

function City_GetSupplyModifier(city, yieldType, itemTable, itemID, queueNum)
	if itemID == nil then
		itemID = city:GetProductionUnit()
		itemTable = GameInfo.Units
	end
	if (itemID
		and itemID ~= -1
		and itemTable == GameInfo.Units
		and itemTable[itemID].Domain == "DOMAIN_LAND"
		and (itemTable[itemID].Combat > 0 or itemTable[itemID].RangedCombat > 0)
		) then
		return Player_GetSupplyModifier(Players[city:GetOwner()], yieldType)
	end
	return 0
end

function Player_GetSupplyModifier(player, yieldType, doUpdate)
	if yieldType and yieldType ~= YieldTypes.YIELD_PRODUCTION then
		return 0
	end
	local yieldMod = 0
	local netSupply = GetMaxUnitSupply(player, doUpdate) - GetCurrentUnitSupply(player, doUpdate)
	if netSupply < 0 then
		yieldMod = math.max(CiVUP.SUPPLY_PENALTY_MAX, netSupply * CiVUP.SUPPLY_PENALTY_PER_UNIT_PERCENT)
	end
	return yieldMod
end

function GetSupplyFromPopulation(player)
	if player:GetNumCities() == 0 then
		return 0
	end
	local supply = 0
	for city in player:Cities() do
		supply = supply + CiVUP.SUPPLY_PER_POP * city:GetPopulation()
	end
	return Round(supply)
end

function GetMaxUnitSupply(player, doUpdate)
	local playerID = player:GetID()
	if player:GetNumCities() == 0 then
		return 0
	end
	if not player:IsHuman() then
		return 1000
	end
	if doUpdate or MapModData.VEM.UnitSupplyMax[playerID] == nil then
		MapModData.VEM.UnitSupplyMax[playerID] = CiVUP.SUPPLY_BASE
		for city in player:Cities() do
			MapModData.VEM.UnitSupplyMax[playerID] = MapModData.VEM.UnitSupplyMax[playerID] + CiVUP.SUPPLY_PER_CITY + CiVUP.SUPPLY_PER_POP * city:GetPopulation()
		end
		MapModData.VEM.UnitSupplyMax[playerID] = Round(MapModData.VEM.UnitSupplyMax[playerID])
		--log:Warn("%20s UnitSupplyMax     = %-3s", player:GetName(), MapModData.VEM.UnitSupplyMax[playerID])
	end
	return MapModData.VEM.UnitSupplyMax[playerID]
end

function GetCurrentUnitSupply(player, doUpdate)
	local playerID = player:GetID()
	if doUpdate or MapModData.VEM.UnitSupplyCurrent[playerID] == nil then
		MapModData.VEM.UnitSupplyCurrent[playerID] = 0
		for unit in player:Units() do
			if IsCombatAndDomain(unit, "DOMAIN_LAND") then
				MapModData.VEM.UnitSupplyCurrent[playerID] = MapModData.VEM.UnitSupplyCurrent[playerID] + 1
			end
		end
		--log:Warn("%20s UnitSupplyCurrent = %-3s", player:GetName(), MapModData.VEM.UnitSupplyCurrent[playerID])
	end
	return MapModData.VEM.UnitSupplyCurrent[playerID]
end

function City_GetCapitalSettlerModifier(city, yieldType, itemTable, itemID, queueNum)
	local yieldMod = 0
	if itemID == nil then
		itemID = city:GetProductionUnit()
		itemTable = GameInfo.Units
	end
	if city:IsCapital() and itemID and itemID ~= -1 and itemTable[itemID].Food then
		for policyInfo in GameInfo.Policies("CapitalSettlerProductionModifier != 0") do
			if Players[city:GetOwner()]:HasPolicy(policyInfo.ID) then
				yieldMod = yieldMod + policyInfo.CapitalSettlerProductionModifier
			end
		end
	end
	return yieldMod
end

function City_GetBuildingClassConstructionYieldModifier(city, yieldType, itemTable, itemID, queueNum)
	local yieldMod = 0
	if itemID == nil then
		itemID = city:GetProductionBuilding()
		if itemID == nil or itemID == -1 then
			return 0
		end
		itemTable = GameInfo.Buildings
	end
	for policyInfo in GameInfo.Policy_BuildingClassProductionModifiers() do
		if (policyInfo.BuildingClassType == itemTable[itemID].BuildingClass) then
			if Players[city:GetOwner()]:HasPolicy(GameInfo.Policies[policyInfo.PolicyType].ID) then
				yieldMod = yieldMod + policyInfo.ProductionModifier
			end
		end
	end
	return yieldMod
end

function City_GetWonderConstructionModifier(city, yieldType, itemTable, itemID, queueNum)
	local yieldMod = 0
	if yieldType == YieldTypes.YIELD_PRODUCTION then
		local player = Players[city:GetOwner()]

		yieldMod = yieldMod + GetTrait(player).WonderProductionModifier
		
		for resourceInfo in GameInfo.Resources("WonderProductionMod != 0") do
			if city:IsHasResourceLocal(resourceInfo.ID) then
				yieldMod = yieldMod + resourceInfo.WonderProductionMod
			end
		end
		for policyInfo in GameInfo.Policies("WonderProductionModifier != 0") do
			if player:HasPolicy(policyInfo.ID) then
				yieldMod = yieldMod + policyInfo.WonderProductionModifier
			end
		end
		--log:Debug("wondMod = "..yieldMod.." "..itemTable[itemID].Type)
	end
	return yieldMod
end



---------------------------------------------------------------------
-- Surplus Yield
---------------------------------------------------------------------

function City_GetYieldConsumed(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetYieldConsumed city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetYieldConsumed itemID=nil")
	end
	if yieldType == YieldTypes.YIELD_FOOD then
		return city:FoodConsumption(true, 0)
	end
	return 0
end

function City_GetSurplusYieldRate(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetSurplusYieldRate city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetSurplusYieldRate itemTable=%s itemID=%s", itemTable, itemID)
	end
	if city:IsResistance() then
		return 0
	end
	
	--log:Debug("City_GetSurplusYieldRate %15s %15s", city:GetName(), GameInfo.Yields[yieldType].Type)
	--
	local baseMod = City_GetBaseYieldRateModifier(city, yieldType, itemTable, itemID, queueNum)
	local baseYield = City_GetBaseYieldRate(city, yieldType, itemTable, itemID, queueNum) * (1 + baseMod/100)
	return baseYield - City_GetYieldConsumed(city, yieldType, itemTable, itemID, queueNum)
	--]]
end

function City_GetSurplusYieldModFromBuildings(city, yieldType, itemTable, itemID, queueNum)
	local player = Players[city:GetOwner()]
	local surplusMod = 0
	if yieldType == YieldTypes.YIELD_HAPPINESS then
		return surplusMod
	end
	--log:Debug("City_GetSurplusYieldModFromBuildings %15s %15s", city:GetName(), GameInfo.Yields[yieldType].Type)
	if City_GetSurplusYieldRate(city, yieldType) < 0 and Round(Player_GetYieldRate(player, YieldTypes.YIELD_HAPPINESS)) <= GameDefines.VERY_UNHAPPY_THRESHOLD then
		return surplusMod
	end
	for row in GameInfo.Building_YieldSurplusModifiers() do
		if yieldType == YieldTypes[row.YieldType] and city:IsHasBuilding(GameInfo.Buildings[row.BuildingType].ID) then
			surplusMod = row.Yield + surplusMod
		end
	end
	return surplusMod
end

function City_GetSurplusYieldRateModifier(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetSurplusYieldRateModifier city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetSurplusYieldRateModifier itemID=nil")
	end
	local surplusMod = 0
	
	--log:Debug("City_GetSurplusYieldRateModifier %15s %15s", city:GetName(), GameInfo.Yields[yieldType].Type)
	if yieldType == YieldTypes.YIELD_HAPPINESS or City_GetSurplusYieldRate(city, yieldType) < 0 then
		return surplusMod
	end
	--
	local player = Players[city:GetOwner()]
	local surplusMod = City_GetSurplusYieldModFromBuildings(city, yieldType, itemTable, itemID, queueNum)
	local happiness = Round(Player_GetYieldRate(player, YieldTypes.YIELD_HAPPINESS))
	
	if yieldType == YieldTypes.YIELD_FOOD then
		if City_GetSurplusYieldRate(city, yieldType) > 0 then
			if happiness <= GameDefines.VERY_UNHAPPY_THRESHOLD then
				surplusMod = surplusMod + GameDefines.VERY_UNHAPPY_GROWTH_PENALTY
			elseif happiness < 0 then
				surplusMod = surplusMod + GameDefines.UNHAPPY_GROWTH_PENALTY
			end
		end
		if city:GetWeLoveTheKingDayCounter() > 0 then
			surplusMod = surplusMod + GameDefines.WLTKD_GROWTH_MULTIPLIER
		end
		for policyInfo in GameInfo.Policies("CityGrowthMod != 0") do
			if player:HasPolicy(policyInfo.ID) then
				surplusMod = surplusMod + policyInfo.CityGrowthMod
			end
		end
		if city:IsCapital() then
			for policyInfo in GameInfo.Policies("CapitalGrowthMod != 0") do
				if player:HasPolicy(policyInfo.ID) then
					surplusMod = surplusMod + policyInfo.CapitalGrowthMod
				end
			end			
		end
	end
	--]]
	
	return surplusMod
end



---------------------------------------------------------------------
-- Total Yield
---------------------------------------------------------------------

function City_GetYieldRate(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetYieldRate city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetYieldRate itemID=nil")
	end
	if not Contains(tileYieldTypes, yieldType) then
		return 0
	end

	local player = Players[city:GetOwner()]
	local activePlayer = Players[Game.GetActivePlayer()]
	
	if MapModData.CityYieldRatesDirty then
		CleanCityYieldRates(activePlayer)
	end

	local yieldRate = 1
	if not updateCityYields and not itemTable then
		local cityID = City_GetID(city)
		yieldRate = MapModData.CityYields[cityID]
		if not yieldRate then
			CleanCityYieldRates(player)
			yieldRate = MapModData.CityYields[cityID]
		end
		if yieldRate then
			yieldRate = yieldRate[yieldType]
			if yieldRate then
				return yieldRate
			end
		end
		log:Warn("City_GetYieldRate: Cleaning failed! %20s %15s %15s %3s", player:GetName(), city:GetName(), GameInfo.Yields[yieldType].Type, yieldRate)
	end

	yieldRate = City_GetSurplusYieldRate(city, yieldType, itemTable, itemID, queueNum)
	yieldRate = yieldRate * (1 + City_GetSurplusYieldRateModifier(city, yieldType, itemTable, itemID, queueNum) / 100)
	if yieldType == YieldTypes.YIELD_PRODUCTION then
		if itemTable == nil then
			if city:GetProductionUnit() ~= -1 then
				itemID = city:GetProductionUnit()
				itemTable = GameInfo.Units
			end
		end
		if itemID then
			if itemTable == GameInfo.Units then
				if itemTable[itemID].Food then
					yieldRate = yieldRate + math.max(0, City_GetYieldRate(city, YieldTypes.YIELD_FOOD, itemTable, itemID))
				end
				if itemID == GameInfo.Units.UNIT_SETTLER.ID then
					yieldRate = yieldRate * 105 / CiVUP.UNIT_SETTLER_BASE_COST
				end
			end
		end
		if not player:IsHuman() then
			local handicapInfo = GameInfo.HandicapInfos[activePlayer:GetHandicapType()]
			local handicapBonus = 1 + 0.01 * handicapInfo.AIProductionPercentPerEra * activePlayer:GetCurrentEra()
			--log:Warn("%-15s %3s", city:GetName(), Round(handicapBonus * 100))
			yieldRate = yieldRate * handicapBonus
		end
	end
	yieldRate = yieldRate / City_GetCostMod(city, yieldType, itemTable, itemID)
	return yieldRate
end

function City_GetYieldFromFood(city, yieldType, itemTable, itemID, queueNum)
	local yieldRate = 0
	if yieldType == YieldTypes.YIELD_PRODUCTION then
		if itemTable == nil then
			if city:GetProductionUnit() ~= -1 then
				itemID = city:GetProductionUnit()
				itemTable = GameInfo.Units
			end
		end
		if itemID and itemTable == GameInfo.Units and itemTable[itemID].Food then
			yieldRate = yieldRate + math.max(0, City_GetYieldRate(city, YieldTypes.YIELD_FOOD, itemTable, itemID))
		end
	end
	return yieldRate
end

function City_GetYieldRateTimes100(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetYieldRateTimes100 city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetYieldRateTimes100 itemID=nil")
	end
	return City_GetYieldRate(city, yieldType) * 100
end

function City_GetYieldStored(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetYieldStored city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetYieldStored itemID=nil")
	end
	if yieldType == YieldTypes.YIELD_FOOD then
		return city:GetFoodTimes100() / 100
	elseif yieldType == YieldTypes.YIELD_PRODUCTION then
		if itemTable == GameInfo.Units then
			return city:GetUnitProduction(itemID, queueNum)
		elseif itemTable == GameInfo.Buildings then
			return city:GetBuildingProduction(itemID, queueNum)
		elseif itemTable == GameInfo.Projects then
			log:Fatal("City_GetYieldStored: Civ API has no city:GetProjectProductionNeeded function!")
			--return city:GetProjectProduction(itemID, queueNum)
			return 0
		else
			return city:GetProduction()
		end		
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		return city:GetJONSCultureStored()
	else
		return 0
	end
end

function City_GetYieldNeeded(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetYieldNeeded city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetYieldNeeded itemID=nil")
	end
	if yieldType == YieldTypes.YIELD_FOOD then
		return city:GrowthThreshold()
	elseif yieldType == YieldTypes.YIELD_PRODUCTION then
		if itemTable == GameInfo.Units then
			return city:GetUnitProductionNeeded(itemID, queueNum)
		elseif itemTable == GameInfo.Buildings then
			return city:GetBuildingProductionNeeded(itemID, queueNum)
		elseif itemTable == GameInfo.Projects then
			return city:GetProjectProductionNeeded(itemID, queueNum)
		elseif not city:IsProductionProcess() and city:GetProductionNameKey() and city:GetProductionNameKey() ~= "" then 
			return city:GetProductionNeeded()
		end
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		return city:GetJONSCultureThreshold()
	end
	return 0
end

function City_GetYieldTurns(city, yieldType, itemTable, itemID, queueNum)
	if city == nil then
		log:Fatal("City_GetYieldTurns city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_GetYieldTurns itemID=nil")
	end
	if itemTable == GameInfo.Projects then
		-- The API is missing the "city:GetProjectProduction(itemID, queueNum)" function!
		return math.max(1, math.ceil(
			city:GetProjectProductionTurnsLeft(itemID, queueNum)
			* City_GetYieldRate(city, yieldType, itemTable, itemID, queueNum)
			/ (city:GetYieldRateTimes100(yieldType) / 100)
		))
	end
	return math.max(1, math.ceil(
			( City_GetYieldNeeded(city, yieldType, itemTable, itemID, queueNum)
			- City_GetYieldStored(city, yieldType, itemTable, itemID, queueNum) )
			/ City_GetYieldRate(city, yieldType, itemTable, itemID, queueNum)
		))
end

function City_ChangeYieldStored(city, yieldType, amount, checkThreshold)
	if city == nil then
		log:Fatal("City_ChangeYieldStored city=nil")
	elseif itemTable and not itemID then
		log:Fatal("City_ChangeYieldStored itemID=nil")
	end
	local player = Players[city:GetOwner()]
	if yieldType == YieldTypes.YIELD_FOOD then
		city:ChangeFood(amount)
		local overflow = City_GetYieldStored(city, yieldType) - City_GetYieldNeeded(city, yieldType)
		if checkThreshold and overflow >= 0 then
			local totalYieldKept = 0
			for building in GameInfo.Buildings("FoodKept != 0") do
				if city:IsHasBuilding(building.ID) then
					totalYieldKept = totalYieldKept + building.FoodKept / 100
				end
			end
			city:ChangePopulation(1,true)
			city:SetFood(0)
			City_ChangeYieldStored(city, yieldType, overflow + totalYieldKept * City_GetYieldNeeded(city, yieldType), true)
		end
	elseif yieldType == YieldTypes.YIELD_PRODUCTION then
		city:ChangeProduction(amount)
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		city:ChangeJONSCultureStored(amount)
		Player_ChangeYieldStored(player, YieldTypes.YIELD_CULTURE, amount)
		local overflow = City_GetYieldStored(city, yieldType) - City_GetYieldNeeded(city, yieldType)
		if checkThreshold and overflow >= 0 then
			city:DoJONSCultureLevelIncrease()
			city:SetJONSCultureStored(0)
			City_ChangeYieldStored(city, yieldType, overflow, true)
		end
	elseif yieldType == YieldTypes.YIELD_POPULATION then
		city:ChangePopulation(amount,true)
	end
end



---------------------------------------------------------------------
-- Total Player Yields
---------------------------------------------------------------------

if not MapModData.VEM.Yields then
	MapModData.VEM.Yields = {}
	MapModData.VEM.Yields[YieldTypes.YIELD_CS_MILITARY]		= {}
	MapModData.VEM.Yields[YieldTypes.YIELD_CS_GREAT_PERSON]	= {}
	local milBaseThreshold = CiVUP.MINOR_CIV_MILITARISTIC_REWARD_NEEDED * GameInfo.GameSpeeds[Game.GetGameSpeedType()].TrainPercent / 100
	local gpBaseThreshold = GameDefines.GREAT_PERSON_THRESHOLD_BASE	* GameInfo.GameSpeeds[Game.GetGameSpeedType()].GreatPeoplePercent / 100	
	for playerID,player in pairs(Players) do
		if IsValidPlayer(player) and not player:IsMinorCiv() then
			MapModData.VEM.Yields[YieldTypes.YIELD_CS_MILITARY][playerID]				= {}
			MapModData.VEM.Yields[YieldTypes.YIELD_CS_MILITARY][playerID].Stored		= LoadValue("MapModData.VEM.Yields[%s][%s].Stored", YieldTypes.YIELD_CS_MILITARY, playerID) or 0
			MapModData.VEM.Yields[YieldTypes.YIELD_CS_MILITARY][playerID].Needed		= milBaseThreshold
			MapModData.VEM.Yields[YieldTypes.YIELD_CS_GREAT_PERSON][playerID]			= {}
			MapModData.VEM.Yields[YieldTypes.YIELD_CS_GREAT_PERSON][playerID].Stored	= LoadValue("MapModData.VEM.Yields[%s][%s].Stored", YieldTypes.YIELD_CS_GREAT_PERSON, playerID) or 0
			MapModData.VEM.Yields[YieldTypes.YIELD_CS_GREAT_PERSON][playerID].Needed	= LoadValue("MapModData.VEM.Yields[%s][%s].Needed", YieldTypes.YIELD_CS_GREAT_PERSON, playerID) or gpBaseThreshold			
		end
	end
end

function Player_GetYieldStored(player, yieldType, itemID)
	if player == nil then
		log:Fatal("Player_GetYieldStored player=nil")
	end
	if yieldType == YieldTypes.YIELD_GOLD then
		return player:GetGold()
	elseif yieldType == YieldTypes.YIELD_SCIENCE then
		return Teams[player:GetTeam()]:GetTeamTechs():GetResearchProgress(itemID or player:GetCurrentResearch()) + player:GetOverflowResearch()
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		return player:GetJONSCulture()
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		return player:GetGoldenAgeProgressMeter()
	elseif yieldType == YieldTypes.YIELD_CS_MILITARY or yieldType == YieldTypes.YIELD_CS_GREAT_PERSON then
		return MapModData.VEM.Yields[yieldType][player:GetID()].Stored
	end
	
	return 0
end

function Player_SetYieldStored(player, yieldType, yield, itemID)
	if player == nil then
		log:Fatal("Player_GetYieldStored player=nil")
	end
	if yieldType == YieldTypes.YIELD_GOLD then
		player:SetGold(yield)
	elseif yieldType == YieldTypes.YIELD_SCIENCE then
		local sciString	= ""
		local teamID	= player:GetTeam()
		local team   	= Teams[teamID]
		local teamTechs	= team:GetTeamTechs()
		
		sciString = "Sci bonus for "..player:GetName()..": "
		local targetTech = itemID or player:GetCurrentResearch()
		if targetTech ~= -1 then
			targetTech = GameInfo.Technologies[targetTech]
			teamTechs:SetResearchProgress(targetTech.ID, yield, player)
			sciString = string.format("%-40s +%-3d  @ %s", sciString, Round(yield), targetTech.Type)
		else
			local researchableTechs = {}
			for techInfo in GameInfo.Technologies() do
				if player:CanResearch(techInfo.ID) and not team:IsHasTech(techInfo.ID) then
					table.insert(researchableTechs, techInfo.ID)
				end
			end
			if #researchableTechs > 0 then
				targetTech = researchableTechs[1 + Map.Rand(#researchableTechs, "Player_ChangeYieldStored: Random Tech")]
				targetTech = GameInfo.Technologies[targetTech]
				teamTechs:SetResearchProgress(targetTech.ID, yield, player)
				sciString = string.format("%-40s +%-3d  @ %s (random)", sciString, Round(yield), targetTech.Type)
			end
		end
		--log:Warn(sciString)
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		player:SetJONSCulture(yield)
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		player:SetGoldenAgeProgressMeter(yield)
	elseif yieldType == YieldTypes.YIELD_CS_MILITARY or yieldType == YieldTypes.YIELD_CS_GREAT_PERSON then
		MapModData.VEM.Yields[yieldType][player:GetID()].Stored = yield
		Saveyield(yield, "MapModData.VEM.Yields[%s][%s].Stored", yieldType, player:GetID())
	end
end

function Player_ChangeYieldStored(player, yieldType, yield, itemID)
	if yield == 0 then
		return
	end
	if yieldType == YieldTypes.YIELD_GOLD then
		player:ChangeGold(yield)
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		player:ChangeJONSCulture(yield)
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		player:ChangeGoldenAgeProgressMeter(yield)
		local surplusGoldenPoints = player:GetGoldenAgeProgressMeter() - player:GetGoldenAgeProgressThreshold()
		if surplusGoldenPoints > 0 then
			player:SetGoldenAgeProgressMeter(surplusGoldenPoints)
			player:ChangeGoldenAgeTurns((1 + player:GetGoldenAgeModifier() / 100) * (GameDefines.GOLDEN_AGE_LENGTH - player:GetNumGoldenAges()))
			--log:Debug("Mod=%s Turns=%s NumAges=%s", player:GetGoldenAgeModifier(), GameDefines.GOLDEN_AGE_LENGTH - player:GetNumGoldenAges(), player:GetNumGoldenAges())
			player:ChangeNumGoldenAges(1)
		end
	elseif yieldType == YieldTypes.YIELD_EXPERIENCE then
		player:ChangeCombatExperience(yield)
	elseif yieldType == YieldTypes.YIELD_SCIENCE then
		local sciString	= ""
		local teamID	= player:GetTeam()
		local team   	= Teams[teamID]
		local teamTechs	= team:GetTeamTechs()
		
		sciString = "Sci bonus for "..player:GetName()..": "
		local targetTech = itemID or player:GetCurrentResearch()
		if targetTech ~= -1 then
			targetTech = GameInfo.Technologies[targetTech]
			teamTechs:ChangeResearchProgress(targetTech.ID, yield, player)
			sciString = string.format("%-40s +%-3d  @ %s", sciString, Round(yield), targetTech.Type)
		else
			local researchableTechs = {}
			for techInfo in GameInfo.Technologies() do
				if player:CanResearch(techInfo.ID) and not team:IsHasTech(techInfo.ID) then
					table.insert(researchableTechs, techInfo.ID)
				end
			end
			if #researchableTechs > 0 then
				targetTech = researchableTechs[1 + Map.Rand(#researchableTechs, "Player_ChangeYieldStored: Random Tech")]
				targetTech = GameInfo.Technologies[targetTech]
				teamTechs:ChangeResearchProgress(targetTech.ID, yield, player)
				sciString = string.format("%-40s +%-3d  @ %s (random)", sciString, Round(yield), targetTech.Type)
			end
		end
		--log:Warn(sciString)
	end
end

function Player_GetYieldNeeded(player, yieldType, itemID)
	if player == nil then
		log:Fatal("Player_GetYieldNeeded player=nil")
	end
	if yieldType == YieldTypes.YIELD_SCIENCE then
		return Teams[player:GetTeam()]:GetTeamTechs():GetResearchCost(itemID)
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		return player:GetNextPolicyCost()
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		return player:GetGoldenAgeProgressThreshold()
	elseif yieldType == YieldTypes.YIELD_CS_MILITARY or yieldType == YieldTypes.YIELD_CS_GREAT_PERSON then
		return MapModData.VEM.Yields[yieldType][player:GetID()].Needed
	end
	return 0
end

function Player_SetYieldNeeded(player, yieldType, value)
	if player == nil then
		log:Fatal("Player_GetYieldNeeded player=nil")
	end
	if yieldType == YieldTypes.YIELD_CS_GREAT_PERSON then
		MapModData.VEM.Yields[yieldType][player:GetID()].Needed = value
		SaveValue(value, "MapModData.VEM.Yields[%s][%s].Needed", yieldType, player:GetID())
	end
	return 0
end

function Player_GetYieldRate(player, yieldType, itemID)
	if player == nil then
		log:Fatal("Player_GetYieldRate player=nil")
	end

	local capital = player:GetCapitalCity()
	if capital == nil then
		return 0
	end

	local yield = 0
	if yieldType == YieldTypes.YIELD_GOLD then
		return Round(player:CalculateGoldRate() + Player_GetFreeGarrisonMaintenance(player) + Player_GetTradeDealYield(player, yieldType))
	elseif yieldType == YieldTypes.YIELD_SCIENCE then
		return (player:GetScience() + Player_GetTradeDealYield(player, yieldType))
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		yield = (
			  player:GetJONSCulturePerTurnForFree()
			+ player:GetJONSCulturePerTurnFromExcessHappiness()
			+ player:GetJONSCulturePerTurnFromMinorCivs()
		)
		for city in player:Cities() do
			yield = yield + City_GetYieldRate(city, YieldTypes.YIELD_CULTURE)
		end
		return yield
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		yield = player:GetExcessHappiness()
		for city in player:Cities() do
			yield = yield + City_GetYieldRate(city, YieldTypes.YIELD_HAPPINESS)
		end
		if not player:IsMinorCiv() then
			yield = yield + Player_GetYieldFromSurplusResources(player, yieldType)
			yield = yield + Player_GetYieldsFromCitystates(player)[yieldType]
			yield = yield - GetNumBuilding(player:GetCapitalCity(), GameInfo.Buildings.BUILDING_EXTRA_HAPPINESS.ID)
		end
		return yield
	elseif yieldType == YieldTypes.YIELD_CS_MILITARY then
		yield = yield + Player_GetYieldsFromCitystates(player,true)[yieldType]
		return yield
	elseif yieldType == YieldTypes.YIELD_CS_GREAT_PERSON then
		local gpRate = 0
		for policyInfo in GameInfo.Policies("MinorGreatPeopleRate != 0") do
			if player:HasPolicy(policyInfo.ID) then
				gpRate = gpRate + policyInfo.MinorGreatPeopleRate
			end
		end
		if gpRate > 0 then
			for minorCivID,minorCiv in pairs(Players) do
				if IsValidPlayer(minorCiv) and minorCiv:IsMinorCiv() then
					local friendLevel = minorCiv:GetMinorCivFriendshipLevelWithMajor(playerID)
					if friendLevel == 1 then
						yield = yield + 1.0 * gpRate
					elseif friendLevel == 2 then
						yield = yield + 1.5 * gpRate
					end
				end
			end
		end
		return yield
	end
	return yield
end

function Player_GetYieldTurns(player, yieldType, itemID, overflow)
	local rate = Player_GetYieldRate(player, yieldType, itemID)
	if rate == 0 then
		return 0
	end
	return math.max(0, math.ceil(
		( Player_GetYieldNeeded(player, yieldType, itemID)
		- Player_GetYieldStored(player, yieldType, itemID) )
		/ rate
	))
end

function Player_GetYieldFromSurplusResources(player, yieldType)
	local luxurySurplus = 0
	if yieldType == YieldTypes.YIELD_HAPPINESS then
		for policyInfo in GameInfo.Policies("ExtraHappinessPerLuxury != 0") do
			if player:HasPolicy(policyInfo.ID) and policyInfo.ExtraHappinessPerLuxury > 0 then
				for resourceInfo in GameInfo.Resources("Happiness != 0") do
					if resourceInfo.Happiness > 0 then
						luxurySurplus = luxurySurplus + math.max(0, player:GetNumResourceTotal(resourceInfo.ID, true) - 1)
					end
				end
			end
		end
	end
	return luxurySurplus
end

function Player_CalculateUnitCost(player)
	return player:CalculateUnitCost() - Player_GetFreeGarrisonMaintenance(player)
end

function Player_GetFreeGarrisonMaintenance(player)
	local gold = 0
	for policyInfo in GameInfo.Policies() do
		if policyInfo.GarrisonFreeMaintenance and player:HasPolicy(policyInfo.ID) then
			for city in player:Cities() do
				local garrisonUnit = city:GetGarrisonedUnit()
				if garrisonUnit then
					gold = gold + GameInfo.Units[garrisonUnit:GetUnitType()].ExtraMaintenanceCost
				end
			end
			break
		end
	end
	return gold
end


---------------------------------------------------------------------
-- Plot Yields
---------------------------------------------------------------------

if not MapModData.VEM.PlotYields then
	MapModData.VEM.PlotYields = {}
	for yieldInfo in GameInfo.Yields() do
		MapModData.VEM.PlotYields[yieldInfo.ID] = {}
		for plotID, plot in Plots() do
			MapModData.VEM.PlotYields[yieldInfo.ID][plotID] = LoadValue("MapModData.VEM.PlotYields[%s][%s]", yieldInfo.ID, plotID) or 0
		end
	end
end

function Plot_GetYield(plot, yieldType)
	local yield = 0
	if (yieldType == YieldTypes.YIELD_FOOD
		or yieldType == YieldTypes.YIELD_PRODUCTION
		or yieldType == YieldTypes.YIELD_GOLD
		or yieldType == YieldTypes.YIELD_SCIENCE
		) then
		yield = plot:CalculateYield(yieldType, true)
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		yield = MapModData.VEM.PlotYields[yieldType][Plot_GetID(plot)]
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		yield = MapModData.VEM.PlotYields[yieldType][Plot_GetID(plot)]
	end
	return yield
end

function Plot_ChangeYield(plot, yieldType, yield)
	local currentYield = Plot_GetYield(plot, yieldType)
	local newYield = 0
	if (yieldType == YieldTypes.YIELD_FOOD
		or yieldType == YieldTypes.YIELD_PRODUCTION
		or yieldType == YieldTypes.YIELD_GOLD
		or yieldType == YieldTypes.YIELD_SCIENCE
		) then
		newYield = MapModData.VEM.PlotYields[yieldType][Plot_GetID(plot)] + yield
		Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), yieldType, newYield)
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		plot:ChangeCulture(yield)
		newYield = currentYield + yield
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		newYield = currentYield + yield
	elseif yieldType == YieldTypes.YIELD_POPULATION then
		City_ChangeYieldStored(plot:GetWorkingCity(), yieldType, yield)
		return
	end
	MapModData.CityYieldRatesDirty = true
	MapModData.VEM.PlotYields[yieldType][Plot_GetID(plot)] = newYield
	SaveValue(newYield, "MapModData.VEM.PlotYields[%s][%s]", yieldType, Plot_GetID(plot))
	Events.HexYieldMightHaveChanged(plot:GetX(), plot:GetY())
end

function Plot_SetYield(plot, yieldType, yield)
	local newYield = 0
	if (yieldType == YieldTypes.YIELD_FOOD
		or yieldType == YieldTypes.YIELD_PRODUCTION
		or yieldType == YieldTypes.YIELD_GOLD
		or yieldType == YieldTypes.YIELD_SCIENCE
		) then
		newYield = yield
		Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), yieldType, yield)
	elseif yieldType == YieldTypes.YIELD_CULTURE then
		newYield = yield
		plot:ChangeCulture(yield - Plot_GetYield(plot, yieldType))		
	elseif yieldType == YieldTypes.YIELD_HAPPINESS then
		newYield = yield
	end
	MapModData.CityYieldRatesDirty = true
	MapModData.VEM.PlotYields[yieldType][Plot_GetID(plot)] = newYield
	SaveValue(newYield, "MapModData.VEM.PlotYields[%s][%s]", yieldType, Plot_GetID(plot))
	Events.HexYieldMightHaveChanged(plot:GetX(), plot:GetY())
end

---------------------------------------------------------------------
-- Update modded yields
---------------------------------------------------------------------

MapModData.CityYieldRatesDirty = false
MapModData.CityYields = {}

LuaEvents.CityYieldRatesDirty = LuaEvents.CityYieldRatesDirty or function() end

function CleanCityYieldRates(player)
	local activePlayer = Players[Game.GetActivePlayer()]
	if MapModData.CityYieldRatesDirty then
		if player == activePlayer then
			MapModData.CityYieldRatesDirty = false
		else
			CleanCityYieldRates(activePlayer)
		end
	end
	updateCityYields = true
	Player_GetYieldsFromCitystates(player, true)
	Player_UpdateModdedHappiness(player)
	for yieldInfo in GameInfo.Yields() do
		Player_GetSupplyModifier(player, yieldInfo.ID, true)
		for city in player:Cities() do
			local cityID = City_GetID(city)
			City_GetWeight(city, yieldInfo.ID, true)
			MapModData.CityYields[cityID] = MapModData.CityYields[cityID] or {}
			MapModData.CityYields[cityID][yieldInfo.ID] = City_GetYieldRate(city, yieldInfo.ID)
		end
	end
	updateCityYields = false
end

function OnCityYieldRatesDirty()
	if Players[Game.GetActivePlayer()]:IsTurnActive() then
		MapModData.CityYieldRatesDirty = true
		--log:Warn("MapModData.CityYieldRatesDirty = true")
	end
end


function City_UpdateModdedYields(city, cityOwner)	
	showWarnings = true
	log:Info("%20s %15s City_UpdateModdedYields", cityOwner:GetName(), city:GetName())
	if city:IsResistance() then
		return
	end
	local yieldType = YieldTypes.YIELD_FOOD
	local vanillaYield = city:FoodDifferenceTimes100() / 100
	local modYield = City_GetYieldRate(city, yieldType)
	if modYield ~= vanillaYield and not city:IsFoodProduction() then
		log:Debug("%20s %15s vanillaYield:%3s modYield:%3s (to food)", cityOwner:GetName(), city:GetName(), Round(vanillaYield), Round(modYield))
		City_ChangeYieldStored(city, yieldType, modYield-vanillaYield)
	end
	
	yieldType = YieldTypes.YIELD_PRODUCTION
	vanillaYield = city:GetCurrentProductionDifferenceTimes100(false, false) / 100
	modYield = City_GetYieldRate(city, yieldType)
	if modYield ~= vanillaYield then
		log:Debug("%20s %15s vanillaYield:%3s modYield:%3s (to production)", cityOwner:GetName(), city:GetName(), Round(vanillaYield), Round(modYield))
		City_ChangeYieldStored(city, yieldType, modYield-vanillaYield)
	end
	
	yieldType = YieldTypes.YIELD_CULTURE
	vanillaYield = city:GetJONSCulturePerTurn()
	modYield = City_GetYieldRate(city, yieldType)
	if modYield ~= vanillaYield then
		log:Debug("%20s %15s vanillaYield:%3s modYield:%3s (to culture)", cityOwner:GetName(), city:GetName(), Round(vanillaYield), Round(modYield))
		City_ChangeYieldStored(city, yieldType, modYield-vanillaYield)
	end
	showWarnings = false
end

function Player_UpdateModdedYields(player)
	if player:IsMinorCiv() then
		return
	end
	log:Debug("%s: Player_UpdateModdedYields", player:GetName())
	local playerID = player:GetID()

	GetCurrentUnitSupply(player, true)
	Player_UpdateModdedHappiness(player)
	Player_ChangeYieldStored(player, YieldTypes.YIELD_GOLD, Player_GetTradeDealYield(player, YieldTypes.YIELD_GOLD) + Player_GetFreeGarrisonMaintenance(player))
	Player_ChangeYieldStored(player, YieldTypes.YIELD_SCIENCE, Player_GetTradeDealYield(player, YieldTypes.YIELD_SCIENCE))
end

function Player_UpdateModdedHappiness(player)	
	local capital = player:GetCapitalCity()
	if capital and not player:IsMinorCiv() then
		local yieldType = YieldTypes.YIELD_HAPPINESS
		local yield = 0
		yield = yield + Player_GetYieldFromSurplusResources(player, yieldType)
		yield = yield + Player_GetYieldsFromCitystates(player)[yieldType]
		for city in player:Cities() do
			local happiness = City_GetYieldRate(city, yieldType)
			--log:Error("%20s %20s happiness = %s", city:GetName(), player:GetName(), happiness)
			yield = yield + City_GetYieldRate(city, yieldType)
		end
		capital:SetNumRealBuilding(GameInfo.Buildings.BUILDING_EXTRA_HAPPINESS.ID, yield)

		yield = Round(Player_GetYieldRate(player, yieldType) * CiVUP.PERCENT_SCIENCE_FOR_1_SURPLUS_HAPPINESS)

		capital:SetNumRealBuilding(GameInfo.Buildings.BUILDING_SCIENCE_BONUS.ID, Constrain(0, yield, 200))
		capital:SetNumRealBuilding(GameInfo.Buildings.BUILDING_SCIENCE_PENALTY.ID, Constrain(0, -yield, 90))
	end
end

function Player_GetTradeDealYield(playerUs, yieldType, doUpdate)
	local yieldSum = 0
	local playerUsID = playerUs:GetID()
	local teamUsID = playerUs:GetTeam()
	local teamUs = Teams[teamUsID]
	local playerUsScience = CiVUP.RESEARCH_AGREEMENT_SCIENCE_RATE_PERCENT
	local playerUsGold = CiVUP.OPEN_BORDERS_GOLD_RATE_PERCENT
	if yieldType == YieldTypes.YIELD_SCIENCE then
		if playerUsScience == nil or playerUsScience == 0 then
			--log:Debug("playerUsScience: %s", playerUsScience)
			return 0
		end
		if playerUs:GetScience() <= 0 then
			--log:Debug("%s - no science for DoF research (%i)", playerUs:GetName(), playerUs:GetScience())
			return 0
		end
		playerUsScience = playerUs:GetScience()
	elseif yieldType == YieldTypes.YIELD_GOLD then
		if playerUsGold == nil or playerUsGold == 0 then
			--log:Debug("playerUsGold: %s", playerUsGold)
			return 0
		end
		playerUsGold = playerUs:GetGoldFromCitiesTimes100() / 100 + playerUs:GetCityConnectionGoldTimes100() / 100 + Player_GetFreeGarrisonMaintenance(playerUs)
	else
		--log:Debug("Invalid yield type: %s", GameInfo.Yields[yieldType].Type)
		return 0
	end

	--log:Debug("Player_GetTradeDealYield(%s, %s)", playerUs:GetName(), GameInfo.Yields[yieldType].Type)
	for playerThemID,playerThem in pairs(Players) do
		if IsValidPlayer(playerThem) and not playerThem:IsMinorCiv() and not (playerThem == playerUs) then
			local teamThemID = playerThem:GetTeam()
			local teamThem = Teams[teamThemID]
			if not teamUs:IsAtWar(teamThemID) then
				local yieldChange = 0
				if yieldType == YieldTypes.YIELD_SCIENCE then
					if teamUs:IsHasResearchAgreement(teamThemID) then
						yieldChange = yieldChange + (playerUsScience + playerThem:GetScience()) * CiVUP.RESEARCH_AGREEMENT_SCIENCE_RATE_PERCENT / 100
						--log:Debug("%s has RA with %s", playerUs:GetName(), playerThem:GetName())
					end
				elseif yieldType == YieldTypes.YIELD_GOLD then
					if teamUs:IsAllowsOpenBordersToTeam(teamThemID) and teamThem:IsAllowsOpenBordersToTeam(teamUsID) then
						local playerThemGold = math.max(0, playerThem:GetGoldFromCitiesTimes100() / 100 + playerThem:GetCityConnectionGoldTimes100() / 100 + Player_GetFreeGarrisonMaintenance(playerThem))
						yieldChange = yieldChange + (playerUsGold + playerThemGold) * CiVUP.OPEN_BORDERS_GOLD_RATE_PERCENT / 100
					end
				end
				if playerUs:IsDoF(playerThemID) then
					yieldChange = yieldChange * (1 + CiVUP.FRIENDSHIP_TRADE_BONUS_PERCENT / 100)
				end
				--log:Debug("%s %s from %s = %s", playerUs:GetName(), GameInfo.Yields[yieldType].Type, playerThem:GetName(), yieldChange)
				yieldSum = yieldSum + math.ceil(yieldChange)
			end
		end
	end
	if yieldSum > 0 then
		local yieldMod = 1
		for buildingInfo in GameInfo.Buildings("TradeDealModifier != 0") do
			for city in playerUs:Cities() do 
				if city:IsHasBuilding(buildingInfo.ID) then
					yieldMod = yieldMod + buildingInfo.TradeDealModifier / 100
				end
			end
		end
		yieldSum = yieldSum * yieldMod
	end

	return math.max(0, Round(yieldSum))
end

function City_ChangeCulture(city, player, culture)
	city:ChangeJONSCultureStored(culture)
	Player_ChangeYieldStored(player, YieldTypes.YIELD_CULTURE, culture)
	cultureStored = city:GetJONSCultureStored()
	cultureNext = city:GetJONSCultureThreshold()
	cultureDiff = cultureNext - cultureStored
	if cultureDiff < 1 then
		city:DoJONSCultureLevelIncrease()
		city:SetJONSCultureStored(-cultureDiff)
	end
end


---------------------------------------------------------------------
-- Update citystate rewards
---------------------------------------------------------------------

function UpdatePlayerRewardsFromMinorCivs(player)
	log:Warn("UpdatePlayerRewardsFromMinorCivs")
end

Game.UpdatePlayerRewardsFromMinorCivs = UpdatePlayerRewardsFromMinorCivs

function Player_GetYieldsFromCitystates(player, doUpdate)
	local playerID = player:GetID()
	MapModData.VEM.MinorCivRewards[playerID] = MapModData.VEM.MinorCivRewards[playerID] or {}
	if doUpdate or MapModData.VEM.MinorCivRewards[playerID].Total == nil then
		log:Debug("Recalculate Player Rewards from Minor Civs %s", player:GetName())
		MapModData.VEM.MinorCivRewards[playerID].Total = {}
		for yieldInfo in GameInfo.Yields() do
			MapModData.VEM.MinorCivRewards[playerID].Total[yieldInfo.ID] = 0
		end
		if not (player:GetNumCities() == 0 or player:IsMinorCiv() or player:IsBarbarian()) then
			for minorCivID,minorCiv in pairs(Players) do
				if IsValidPlayer(minorCiv) and minorCiv:IsMinorCiv() then
					local traitType = minorCiv:GetMinorCivTrait()
					local friendLevel = minorCiv:GetMinorCivFriendshipLevelWithMajor(player:GetID())
					for yieldType,yield in pairs(Player_GetCitystateYields(player, traitType, friendLevel)) do
						MapModData.VEM.MinorCivRewards[playerID].Total[yieldType] = MapModData.VEM.MinorCivRewards[playerID].Total[yieldType] + yield.Total
					end
					log:Debug("friendLevel with %s = %i", minorCiv:GetName(), friendLevel)
				end
			end
		end
		log:Debug("Player_GetYieldsFromCitystates %s yield=%s", GameInfo.Yields[YieldTypes.YIELD_CS_MILITARY].Type, MapModData.VEM.MinorCivRewards[playerID].Total[YieldTypes.YIELD_CS_MILITARY])
	end
	return MapModData.VEM.MinorCivRewards[playerID].Total
end

function Player_GetCitystateYields(player, traitType, friendLevel)
	local yields = {}
	local query = ""
	if friendLevel <= 0 then
		return yields
	end

	for yieldInfo in GameInfo.Yields() do
		yields[yieldInfo.ID] = {Base=0, PerEra=0, Total=0}		
	end
	
	query = string.format("FriendLevel = '%s'", friendLevel)
	for traitInfo in GameInfo.MinorCivTrait_Yields(query) do
		if GameInfo.MinorCivTraits[traitInfo.TraitType].ID == traitType then
			local yieldID = GameInfo.Yields[traitInfo.YieldType].ID
			yields[yieldID].Base = yields[yieldID].Base + traitInfo.Yield
			yields[yieldID].PerEra = yields[yieldID].PerEra + traitInfo.YieldPerEra
		end
	end
	
	for row in GameInfo.Policy_MinorCivBonuses(query) do
		if player:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
			local yieldID = GameInfo.Yields[row.YieldType].ID
			yields[yieldID].Base = yields[yieldID].Base + row.Yield
			yields[yieldID].PerEra = yields[yieldID].PerEra + row.YieldPerEra
		end
	end

	for yieldType,yield in pairs(yields) do
		yield.Total = yield.Total + yield.Base + yield.PerEra * (1 + player:GetCurrentEra())
		if yieldType ~= YieldTypes.YIELD_CS_MILITARY then
			-- one city games
			if player:GetNumCities() == 2 then
				yield.Total = 0.75 * yield.Total
			elseif player:GetNumCities() == 1 then
				yield.Total = 0.50 * yield.Total
			end
		end
		yield.Total = math.ceil(yield.Total * (1 + GetTrait(player).CityStateBonusModifier / 100))
	end
	return yields
end

function Player_GetAvoidModifier(player, doUpdate)
	if type(player) ~= "table" then
		log:Fatal("Player_GetAvoidModifier player=%s", player)
	elseif MapModData.VEM == nil then
		log:Warn("Player_GetAvoidModifier: VEM Not Initialized Yet")
		return 0
	end
	
	local playerID = player:GetID()
	if true then --doUpdate then
		log:Debug("Recalculate Avoid Modifier ", player)
		local player = Players[playerID]
		local numAvoid = 0
		local numCities = 0
		for city in player:Cities() do
			numAvoid = numAvoid + (city:IsForcedAvoidGrowth() and 1 or 0)
			numCities = numCities + (not city:IsPuppet() and 1 or 0)
		end
		MapModData.VEM.AvoidModifier[playerID] = math.max(0, 1 + (numAvoid / numCities - 1) / (1 - CiVUP.AVOID_GROWTH_FULL_EFFECT_CUTOFF / 100))
	end
	return MapModData.VEM.AvoidModifier[playerID] or 0
end

function Player_GetTotalWeight(player, yieldType, doUpdate)
	if MapModData.VEM == nil then
		log:Warn("Player_GetTotalWeight: TBM Not Yet Initialized")
		return 1
	end
	if player == nil then
		log:Fatal("Player_GetTotalWeight: Invalid player")
	end

	local playerID = player:GetID()
	local totalWeight = 0
	if MapModData.VEM.CityWeights[playerID] and MapModData.VEM.CityWeights[playerID][yieldType] then
		for k,v in pairs(MapModData.VEM.CityWeights[playerID][yieldType]) do
			if player:GetCityByID(k) ~= nil and player:GetCityByID(k):GetOwner() == playerID then
				totalWeight = totalWeight + v
			else
				v = nil
			end
		end
	end
	if totalWeight == 0 then
		return 1
	else
		return totalWeight
	end
end

function City_GetWeight(city, yieldType, doUpdate)
	if MapModData.VEM == nil then
		log:Warn("City_GetWeight: VEM Not Initialized Yet")
		return 0
	elseif city == nil then
		log:Fatal("City_GetWeight city=nil")
	elseif yieldType == nil then
		log:Fatal("City_GetWeight yieldType=nil")
	end
	--log:Error(string.format("City_GetWeight %s %s %s", city:GetName(), GameInfo.Yields[yieldType].Description, tostring(doUpdate)))
	local ownerID = city:GetOwner()
	local owner = Players[ownerID]
	if doUpdate or not (MapModData.VEM.CityWeights[ownerID] and MapModData.VEM.CityWeights[ownerID][yieldType] and MapModData.VEM.CityWeights[ownerID][yieldType][city:GetID()]) then
		MapModData.VEM.CityWeights[ownerID] = MapModData.VEM.CityWeights[ownerID] or {}
		MapModData.VEM.CityWeights[ownerID][yieldType] = MapModData.VEM.CityWeights[ownerID][yieldType] or {}

		local weight = 1
		for v in GameInfo.CityWeights() do
			if v.IsCityStatus == true and city[v.Type](city) then
				local result = city[v.Type](city)
				weight = weight * v.Value * ((type(result) == type(1)) and result or 1)
			end
		end
		if city:GetFocusType() == CityYieldFocusTypes[yieldType] then
			weight = weight * GameInfo.CityWeights.CityFocus.Value
		end
		if not Players[ownerID]:IsCapitalConnectedToCity(city) then
			weight = weight * GameInfo.CityWeights.NotConnected.Value
		end
		if yieldType == YieldTypes.YIELD_FOOD and city:IsForcedAvoidGrowth() then
			weight = weight * Player_GetAvoidModifier(owner, doUpdate)
		end	
		MapModData.VEM.CityWeights[ownerID][yieldType][city:GetID()] = math.max(0, weight)
	end
	--log:Error("Weight = "..MapModData.VEM.CityWeights[ownerID][yieldType][city:GetID()])
	return MapModData.VEM.CityWeights[ownerID][yieldType][city:GetID()]
end

---------------------------------------------------------------------
---------------------------------------------------------------------