-- BC - General.lua
-- Author: Thalassicus
-- DateCreated: 10/29/2010 12:44:28 AM
--------------------------------------------------------------

include("CiVUP_Core.lua")
include("CustomNotification.lua")

local log = Events.LuaLogger:New()
log:SetLevel("WARN")

--local store = Events.SavegameData:New()
--store:SetModName("CiVUP")

LuaEvents.NotificationAddin( { name = "CSUnitReward", type = "CNOTIFICATION_CSUnitReward" } )
LuaEvents.NotificationAddin( { name = "CapturedCityLoot", type = "CNOTIFICATION_CAPTURED_CITY_LOOT" } )

for optionInfo in GameInfo.GameOptions() do
	if optionInfo.Reverse then
		Game.SetOption(optionInfo.ID, not Game.IsOption(optionInfo.ID))
	end
end

---------------------------------------------------------------------
---------------------------------------------------------------------

function GiveCSNewYields(player)
	local playerID = player:GetID()
	local capitalCity = player:GetCapitalCity()
	local yieldType = nil
	local yieldRate = 0
	if (CiVUP.MINOR_CIV_MILITARISTIC_REWARD_NEEDED == 0
		or player:GetNumCities() == 0
		or player:IsMinorCiv()
		or player:IsBarbarian()
		or capitalCity == nil
		) then
		return
	end
	
	
	yieldType = YieldTypes.YIELD_CS_MILITARY
	yieldRate = Player_GetYieldRate(player, yieldType)
	if yieldRate ~= 0 then
		local yieldStored = Player_GetYieldStored(player, yieldType) + yieldRate
		local yieldNeeded = Player_GetYieldNeeded(player, yieldType)
		log:Info("%25s %15s current=%i threshold=%i rate=%i", "GiveCSNewYields", player:GetName(), yieldStored, yieldNeeded, yieldRate)
		if yieldStored >= yieldNeeded then
			yieldStored = yieldStored - yieldNeeded
			log:Info("%25s %15s current=%i", " ", " ", yieldStored)
			local availableIDs	= GetAvailableUnitIDs(capitalCity)
			local newUnitID		= availableIDs[1 + Map.Rand(#availableIDs, "InitUnitFromList")]
			local capitalPlot	= capitalCity:Plot()
			local xp			= Player_GetCitystateYields(player, MinorCivTraitTypes.MINOR_CIV_TRAIT_MILITARISTIC, 2)[YieldTypes.YIELD_EXPERIENCE].Total

			if GameInfo.Units[newUnitID].Domain ~= "DOMAIN_LAND" then
				xp = xp * CiVUP.MINOR_CIV_MILITARISTIC_XP_NONLAND_PENALTY
			end

			log:Debug("  Reward=%s  XP=%s", GameInfo.Units[newUnitID].Type, xp)
			local newUnit = Player_InitUnit(player, newUnitID, capitalPlot, xp)

			local promotion = GetTrait(player).MilitaristicCSFreePromotion

			if promotion then
				newUnit:SetHasPromotion(GameInfo.UnitPromotions[promotion].ID, true)
			end
			

			local newUnitInfo = GameInfo.Units[newUnitID]
			if Game.GetActivePlayer() == player:GetID() then
				local newUnitIcon = {{"Unit1", newUnitID, 0, 0, 0}}
				local newUnitName = Locale.ConvertTextKey(newUnitInfo.Description)
				CustomNotification(
					"CSUnitReward",
					"New "..newUnitName,
					"A new "..newUnitName.." arrived in your [ICON_CAPITAL] Capital from your militaristic [ICON_CITY_STATE] City-State allies.",
					capitalPlot,
					0,
					0,
					newUnitIcon
				)
			end
		end
		Player_SetYieldStored(player, yieldType, yieldStored)
	end
	
	yieldType = YieldTypes.YIELD_CS_GREAT_PERSON
	yieldRate = Player_GetYieldRate(player, yieldType)
	if yieldRate ~= 0 then
		local yieldStored = Player_GetYieldStored(player, yieldType) + yieldRate
		local yieldNeeded = Player_GetYieldNeeded(player, yieldType)
		log:Info("%25s %15s current=%i threshold=%i rate=%i", "GiveCSNewYields", player:GetName(), yieldStored, yieldNeeded, yieldRate)
		if yieldStored >= yieldNeeded then
			yieldStored = yieldStored - yieldNeeded
			Player_SetYieldNeeded(player, yieldType, yieldNeeded + GameDefines.GREAT_PERSON_THRESHOLD_INCREASE)
			log:Info("%25s %15s current=%i", " ", " ", yieldStored)
			local availableIDs	= {}
			for unitInfo in GameInfo.Units("Special = 'SPECIALUNIT_PEOPLE' AND (CombatClass LIKE '%UNITCOMBAT_CIVILIAN')") do
				log:Info("%20s CombatClass=%15s ID=%3s UniqueID=%3s", unitInfo.Type, unitInfo.CombatClass, unitInfo.ID, GetUniqueUnitID(player, unitInfo.Class))
				if unitInfo.ID == GetUniqueUnitID(player, unitInfo.Class) then
					table.insert(availableIDs, unitInfo.ID)
				end
			end
			local newUnitID		= availableIDs[1 + Map.Rand(#availableIDs, "InitUnitFromList")]
			local capitalPlot	= capitalCity:Plot()
			local newUnit		= Player_InitUnit(player, newUnitID, capitalPlot)
			local newUnitInfo	= GameInfo.Units[newUnitID]
			if Game.GetActivePlayer() == player:GetID() then
				local newUnitIcon = {{"Unit1", newUnitID, 0, 0, 0}}
				local newUnitName = Locale.ConvertTextKey(newUnitInfo.Description)
				CustomNotification(
					"CSUnitReward",
					"New "..newUnitName,
					"A new "..newUnitName.." arrived in your [ICON_CAPITAL] Capital from your [ICON_CITY_STATE] City-State allies.",
					capitalPlot,
					0,
					0,
					newUnitIcon
				)
			end
		end
		Player_SetYieldStored(player, yieldType, yieldStored)
	end
end
LuaEvents.ActivePlayerTurnStart_Player.Add(GiveCSNewYields)

---------------------------------------------------------------------
---------------------------------------------------------------------

function UpdatePuppetOccupyStatus(city, player, isForced)
	if not player then 
		player = Players[city:GetOwner()]
	end
	
	if isForced then
		log:Info("UpdatePuppetOccupyStatus %15s's %15s isForced=%s", player:GetName(), city:GetName(), isForced)
	end
	
	local courthouseID		= GameInfo.Buildings.BUILDING_COURTHOUSE.ID
	local canCourthouseID	= GameInfo.Buildings.BUILDING_CAN_BUILD_COURTHOUSE.ID
	local governorID		= GameInfo.Buildings.BUILDING_VICEROY.ID
	local happinessModID	= GameInfo.Buildings.BUILDING_PUPPET_MODIFIER.ID
	local isOccupied		= (isForced == "OCCUPY") or (city:IsOccupied() and not isForced)
	local isPuppet			= (isForced == "PUPPET") or (city:IsPuppet() and not isForced)

	if isPuppet or isOccupied then
		if city:IsHasBuilding(courthouseID) then
			isPuppet		= false
			isOccupied		= false
			city:SetPuppet(false)
			city:SetOccupied(false)		
		else
			city:SetNumRealBuilding(governorID, 1)
		end
	elseif city:IsHasBuilding(governorID) then
		city:SetNumRealBuilding(governorID, 0)
	end
	
	if player:IsHuman() then
		if isOccupied and not city:IsHasBuilding(canCourthouseID) then
			city:SetNumRealBuilding(canCourthouseID, 1)
		elseif not isOccupied and city:IsHasBuilding(canCourthouseID) then
			city:SetNumRealBuilding(canCourthouseID, 0)
		end
	else
		if isPuppet then
			city:SetNumRealBuilding(canCourthouseID, 1)
		elseif city:IsHasBuilding(canCourthouseID) then
			city:SetNumRealBuilding(canCourthouseID, 0)
		end
	end
	
	if isPuppet then
		--city:SetNumRealBuilding(happinessModID, Round(city:GetPopulation() * CiVUP.PUPPET_UNHAPPINESS_MOD / 100))
	elseif city:IsHasBuilding(happinessModID) then
		city:SetNumRealBuilding(happinessModID, 0)
	end

end

LuaEvents.ActivePlayerTurnStart_City.Add( UpdatePuppetOccupyStatus )
LuaEvents.CityOccupied.Add( UpdatePuppetOccupyStatus )
LuaEvents.CityPuppeted.Add( UpdatePuppetOccupyStatus )

---------------------------------------------------------------------
---------------------------------------------------------------------

function DestroyCourthouseInCapturedCity(city, player, isForced)
	city:SetNumRealBuilding(GameInfo.Buildings.BUILDING_COURTHOUSE.ID, 0)
end

LuaEvents.CityOccupied.Add( DestroyCourthouseInCapturedCity )
LuaEvents.CityPuppeted.Add( DestroyCourthouseInCapturedCity )

---------------------------------------------------------------------
---------------------------------------------------------------------

function LiberatedMinor(city, minorCiv, isForced)
	if not minorCiv then 
		minorCiv = Players[city:GetOwner()]
	end
	if not minorCiv:IsMinorCiv() then
		return
	end
		
	local minorTeam = Teams[minorCiv:GetTeam()]
	for majorCivID,majorCiv in pairs(Players) do
		if IsValidPlayer(majorCiv) and not majorCiv:IsMinorCiv() and (majorCivID ~= Game.GetActivePlayer()) and (minorCiv:GetMinorCivFriendshipWithMajor(majorCivID) > CiVUP.MINOR_CIV_LIBERATED_FRIENDSHIP_MAX) then
			SetMinorCivFriendship(minorCiv, majorCivID, CiVUP.MINOR_CIV_LIBERATED_FRIENDSHIP_MAX)
		end
	end
end

LuaEvents.CityLiberated(city, player, isForced)

---------------------------------------------------------------------
---------------------------------------------------------------------

function BuildingCreated(player, city, buildingID)
	local playerID		= player:GetID()
	local plot			= city:Plot()
	local buildingInfo	= GameInfo.Buildings[buildingID]
	local query			= ""
	local trait			= GetTrait(player)

	log:Info("BuildingCreated %s %s %s", player:GetName(), city:GetName(), buildingInfo.Type)
	
	local improvementType = buildingInfo.MountainImprovement
	if improvementType then
		local mountainPlot = GetMachuPicchuPlot(plot)
		mountainPlot:SetOwner(playerID, city:GetID())
		mountainPlot:SetImprovementType(GameInfo.Improvements[improvementType].ID)
	end

	local endOccupy = buildingInfo.NoOccupiedUnhappinessFixed
	if endOccupy then
		city:SetPuppet(false)
		city:SetOccupied(false)
	end
	
	query = string.format("ID = '%s' AND InstantGoldenAgePoints != 0", buildingID)
	for buildingInfo in GameInfo.Buildings(query) do
		Player_ChangeYieldStored(player, YieldTypes.YIELD_HAPPINESS, buildingInfo.InstantGoldenAgePoints)
	end

	local borderExpand = buildingInfo.InstantBorderRadius
	if borderExpand ~= 0 then
		for _, adjPlot in pairs(GetPlotsInCircle(plot, 1, borderExpand)) do
			if adjPlot:GetOwner() == -1 then
				adjPlot:SetOwner(playerID, city:GetID())
			end
		end
	end

	local borderExpandAll = buildingInfo.GlobalInstantBorderRadius
	if borderExpandAll ~= 0 then
		for targetCity in player:Cities() do
			for _, adjPlot in pairs(GetPlotsInCircle(targetCity:Plot(), 1, borderExpandAll)) do
				if adjPlot:GetOwner() == -1 then
					adjPlot:SetOwner(playerID, targetCity:GetID())
				end
			end
		end
	end

	local influence = buildingInfo.MinorFriendshipFlatChange
	if influence ~= 0 then
		local playerTeam = Teams[player:GetTeam()]
		log:Debug("%s CS Friendship: +%s", player:GetName(), buildingInfo.MinorFriendshipFlatChange)
		for minorCivID,minorCiv in pairs(Players) do
			local minorTeamID = minorCiv:GetTeam()
			if IsValidPlayer(minorCiv) and minorCiv:IsMinorCiv() and playerTeam:IsHasMet(minorTeamID) and not playerTeam:IsAtWar(minorTeamID) then
				minorCiv:ChangeMinorCivFriendshipWithMajor(playerID, influence)
			end
		end
	end

	local promotion = buildingInfo.FreePromotionAllCombatUnits
	if promotion then
		local promotionID = GameInfo.UnitPromotions[promotion].ID
		for unit in player:Units() do
			if unit and (not unit:IsDead()) and unit:IsCombatUnit() then
				unit:SetHasPromotion(promotionID, true)
			end
		end
	end
	
	query = string.format("BuildingType = '%s' AND YieldType = 'YIELD_CULTURE'", buildingInfo.Type)
	if HasValue( {BuildingType=buildingInfo.Type, YieldType='YIELD_CULTURE'}, GameInfo.Building_SeaPlotYieldChanges ) then
		local nearbyPlots = GetPlotsInCircle(plot, 1, 3)
		for _,adjPlot in pairs(nearbyPlots) do
			local adjPlotID = Plot_GetID(adjPlot)
			if adjPlot:GetOwner() == playerID and not MapModData.VEM.HasTerrainCulture[adjPlotID][buildingInfo.Type] then
				for row in GameInfo.Building_ResourceYieldChanges(query) do
					Plot_ChangeYield(adjPlot, YieldTypes.YIELD_CULTURE, row.Yield)
					MapModData.VEM.HasTerrainCulture[adjPlotID][row.BuildingType] = true
					SaveValue(true, "MapModData.VEM.HasTerrainCulture[%s][%s]", adjPlotID, row.BuildingType)
				end
			end
		end
	end

	query = string.format("BuildingType = '%s' AND YieldType = 'YIELD_CULTURE'", buildingInfo.Type)
	if HasValue( {BuildingType=buildingInfo.Type, YieldType='YIELD_CULTURE'}, GameInfo.Building_ResourceYieldChanges ) then
		log:Info("ResourceYieldChanges %15s", buildingInfo.Type)
		local nearbyPlots = GetPlotsInCircle(plot, 1, 3)
		for _,adjPlot in pairs(nearbyPlots) do
			local adjPlotID = Plot_GetID(adjPlot)
			local adjResource = adjPlot:GetResourceType(-1)
			if adjResource ~= -1 and adjPlot:GetOwner() == playerID and not MapModData.VEM.HasResourceCulture[adjPlotID][buildingInfo.Type] then
				adjResource = GameInfo.Resources[adjResource].Type
				for row in GameInfo.Building_ResourceYieldChanges(query) do
					if adjResource == row.ResourceType then
						Plot_ChangeYield(adjPlot, YieldTypes.YIELD_CULTURE, row.Yield)
						MapModData.VEM.HasResourceCulture[adjPlotID][row.BuildingType] = true
						SaveValue(true, "MapModData.VEM.HasResourceCulture[%s][%s]", adjPlotID, row.BuildingType)
					end
				end
			end
		end
	end
	
	for row in GameInfo.Trait_FreeYieldFromFlavorInCapital() do
		if trait.Type == row.TraitType and buildingInfo.Type == row.BuildingType then
			if row.Yield ~= 0 then
				Player_ChangeYieldStored(player, GameInfo.Yields[row.YieldType].ID, row.Yield)
				--log:Debug("+%s %s from science building constructed in %s", row.Yield, GameInfo.Yields[row.YieldType].Type, city:GetName())
			end
			if row.YieldMod ~= 0 then
				local prereqTech = buildingInfo.PrereqTech or "TECH_AGRICULTURE"
				local yieldAdded = row.YieldMod/100 * GameInfo.Technologies[prereqTech].Cost * GameInfo.GameSpeeds[Game.GetGameSpeedType()].ResearchPercent/100
				Player_ChangeYieldStored(player, GameInfo.Yields[row.YieldType].ID, yieldAdded)
				--log:Debug("+%s %s from science building constructed in %s", yieldAdded, GameInfo.Yields[row.YieldType].Type, city:GetName())
			end
		end
	end
end

LuaEvents.BuildingConstructed.Add( BuildingCreated )

---------------------------------------------------------------------
---------------------------------------------------------------------

MapModData.VEM.HasTerrainCulture = {}
MapModData.VEM.HasResourceCulture = {}
for plotID = 0, Map.GetNumPlots() - 1, 1 do
	MapModData.VEM.HasTerrainCulture [plotID] = {}
	MapModData.VEM.HasResourceCulture[plotID] = {}
	local plot = Map.GetPlotByIndex(plotID)
	if plot:GetOwner() ~= -1 then
		for row in GameInfo.Building_SeaPlotYieldChanges ("YieldType = 'YIELD_CULTURE'") do
			MapModData.VEM.HasTerrainCulture[plotID][row.BuildingType] = LoadValue("MapModData.VEM.HasTerrainCulture[%s][%s]", plotID, row.BuildingType)
		end
		for row in GameInfo.Building_ResourceYieldChanges("YieldType = 'YIELD_CULTURE'") do
			MapModData.VEM.HasResourceCulture[plotID][row.BuildingType] = LoadValue("MapModData.VEM.HasResourceCulture[%s][%s]", plotID, row.BuildingType)
		end
	end
end

function OnPlotAcquired(plot, playerID)
	--log:Warn("Plot Acquired")
	local plotID = Plot_GetID(plot)
	local city = plot:GetWorkingCity()
	if city then
		for row in GameInfo.Building_SeaPlotYieldChanges("YieldType = 'YIELD_CULTURE'") do
			local buildingID = GameInfo.Buildings[row.BuildingType].ID
			if not MapModData.VEM.HasTerrainCulture[plotID][row.BuildingType] then
				if city:IsHasBuilding(buildingID) then
					log:Debug("HasTerrainCulture")
					Plot_ChangeYield(plot, YieldTypes.YIELD_CULTURE, row.Yield)
					MapModData.VEM.HasTerrainCulture[plotID][row.BuildingType] = true
					SaveValue(true, "MapModData.VEM.HasTerrainCulture[%s][%s]", plotID, row.BuildingType)
				end
			end
		end
		for row in GameInfo.Building_ResourceYieldChanges("YieldType = 'YIELD_CULTURE'") do
			local buildingID = GameInfo.Buildings[row.BuildingType].ID
			if not MapModData.VEM.HasResourceCulture[plotID][row.BuildingType] then
				if city:IsHasBuilding(buildingID) and (plot:GetResourceType(-1) == GameInfo.Resources[row.ResourceType].ID) then
					log:Debug("HasResourceCulture")
					Plot_ChangeYield(plot, YieldTypes.YIELD_CULTURE, row.Yield)
					MapModData.VEM.HasResourceCulture[plotID][row.BuildingType] = true
					SaveValue(true, "MapModData.VEM.HasResourceCulture[%s][%s]", plotID, row.BuildingType)
				end
			end
		end
	end

end

LuaEvents.PlotAcquired.Add(OnPlotAcquired)

---------------------------------------------------------------------
---------------------------------------------------------------------

function BuildingLost(player, city, buildingID)
	local playerID		= player:GetID()
	local plot			= city:Plot()
	local buildingInfo	= GameInfo.Buildings[buildingID]
	local query			= ""

	local endOccupy = buildingInfo.NoOccupiedUnhappinessFixed
	if endOccupy then
		city:SetOccupied(true)
	end

	query = string.format("BuildingType = '%s' AND YieldType = 'YIELD_CULTURE'", buildingInfo.Type)
	if HasValue( {BuildingType=buildingInfo.Type, YieldType='YIELD_CULTURE'}, GameInfo.Building_ResourceYieldChanges ) then
		local nearbyPlots = GetPlotsInCircle(plot, 1, 3)
		for _,adjPlot in pairs(nearbyPlots) do
			local adjPlotID = Plot_GetID(adjPlot)
			local adjResource = adjPlot:GetResourceType(-1)
			if adjResource ~= -1 and adjPlot:GetOwner() == playerID and MapModData.VEM.HasResourceCulture[adjPlotID][buildingInfo.Type] then
				adjResource = GameInfo.Resources[adjResource].Type
				for row in GameInfo.Building_ResourceYieldChanges(query) do
					if adjResource == row.ResourceType then
						Plot_ChangeYield(adjPlot, YieldTypes.YIELD_CULTURE, -row.Yield)
						MapModData.VEM.HasResourceCulture[adjPlotID][row.BuildingType] = false
						SaveValue(true, "MapModData.VEM.HasTerrainHasResourceCultureCulture[%s][%s]", adjPlotID, row.BuildingType)
					end
				end
			end
		end
	end
	
	query = string.format("BuildingType = '%s' AND YieldType = 'YIELD_CULTURE'", buildingInfo.Type)
	if HasValue( {BuildingType=buildingInfo.Type, YieldType='YIELD_CULTURE'}, GameInfo.Building_SeaPlotYieldChanges ) then
		local nearbyPlots = GetPlotsInCircle(plot, 1, 3)
		for _,adjPlot in pairs(nearbyPlots) do
			local adjPlotID = Plot_GetID(adjPlot)
			if adjPlot:GetOwner() == playerID and MapModData.VEM.HasTerrainCulture[adjPlotID][buildingInfo.Type] then
				for row in GameInfo.Building_ResourceYieldChanges(query) do
					Plot_ChangeYield(adjPlot, YieldTypes.YIELD_CULTURE, -row.Yield)
					MapModData.VEM.HasTerrainCulture[adjPlotID][row.BuildingType] = false
					SaveValue(true, "MapModData.VEM.HasTerrainCulture[%s][%s]", adjPlotID, row.BuildingType)
				end
			end
		end
	end
end

LuaEvents.BuildingDestroyed.Add( BuildingLost )

---------------------------------------------------------------------
---------------------------------------------------------------------

function NewCity(hexPos, playerID, cityID, cultureType, eraType, continent, populationSize, size, fowState)
	local plot		= Map.GetPlot(ToGridFromHex(hexPos.x, hexPos.y))
	local player	= Players[playerID]
	local city		= player:GetCityByID(cityID)
	local query		= ""

	query = "GlobalInstantBorderRadius != 0"
	for buildingInfo in GameInfo.Buildings(query) do
		local borderExpandAll = buildingInfo.GlobalInstantBorderRadius
		if borderExpandAll then
			for testCity in player:Cities() do
				if testCity:IsHasBuilding(buildingInfo.ID) then
					log:Debug("Detected: %s %s", testCity:GetName(), buildingInfo.Type)
					for _, adjPlot in pairs(GetPlotsInCircle(plot, 1, borderExpandAll)) do
						if adjPlot:GetOwner() == -1 then
							adjPlot:SetOwner(playerID, city:GetID())
						end
					end
					break
				end
			end
		end
	end

	CheckAdoptedPolicyEffects(player)
end

Events.SerialEventCityCreated.Add( NewCity )

---------------------------------------------------------------------
---------------------------------------------------------------------

function UnitCreatedChecks( playerID,
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
	local player		= Players[playerID]
	local activePlayer	= Players[Game.GetActivePlayer()]
	local unit			= player:GetUnitByID(unitID)
	local query			= ""

	if not player:IsBarbarian() and not player:IsMinorCiv() then
		--log:Debug(player:GetName().. " " ..unit:GetName().. " check for trait promotions")
		local unitInfo	= GameInfo.Units[unit:GetUnitType()]
		local playerTrait = GetTrait(player)

		for traitInfo in GameInfo.Trait_FreePromotionUnitTypes() do
			--log:Trace(traitInfo.TraitType.. " " ..traitInfo.UnitType.. " " ..traitInfo.PromotionType)
			if (traitInfo.TraitType == playerTrait.Type) and (traitInfo.UnitType == unitInfo.Type) then
				unit:SetHasPromotion(GameInfo.UnitPromotions[traitInfo.PromotionType].ID, true)
				--LuaEvents.RefreshUnitFlagPromotions(unit)
			end
		end

		if military then
			for traitInfo in GameInfo.Trait_FreeExperience_Domains() do
				--log:Trace(traitInfo.TraitType.. " " ..traitInfo.DomainType.. " " ..traitInfo.Experience)
				if (traitInfo.TraitType == playerTrait.Type) and (traitInfo.DomainType == unitInfo.Domain) then
					unit:ChangeExperience(traitInfo.Experience)
				end
			end

			query = "(FreePromotionAllCombatUnits IS NOT NULL) OR (GlobalExperience != 0)"
			for buildingInfo in GameInfo.Buildings(query) do
				local promo = buildingInfo.FreePromotionAllCombatUnits
				local experience = buildingInfo.GlobalExperience
				for city in player:Cities() do
					if city:IsHasBuilding(buildingInfo.ID) then
						if promo then
							unit:SetHasPromotion(GameInfo.UnitPromotions[promo].ID, true)
							promo = nil
						end
						if experience ~= 0 then
							unit:ChangeExperience(experience)
							experience = 0
						end
					end
					if promo == nil and experience == 0 then
						break
					end
				end
			end
		end
	end

	if military and not player:IsHuman() then
		local hostileMultiplier = 1
		if player:IsMinorCiv() or (GameInfo.Leaders[player:GetLeaderType()].Boldness <= 5) then
			hostileMultiplier = 0.5
		end
		local freeXP = hostileMultiplier * GameInfo.HandicapInfos[Game:GetHandicapType()].AIFreeXP
		local freeXPPerEra = hostileMultiplier * GameInfo.HandicapInfos[Game:GetHandicapType()].AIFreeXPPerEra
		if freeXP > 0 or freeXPPerEra > 0 then
			local era = 1 + activePlayer:GetCurrentEra()
			unit:ChangeExperience(freeXP + freeXPPerEra * era)
			--log:Debug(player:GetName().. " " ..unit:GetName().. " " ..freeXP.. " + " ..freeXPPerEra.. "*" ..era.. " xp")
		end
	end
end

LuaEvents.UnitSpawned.Add(UnitCreatedChecks)

---------------------------------------------------------------------
---------------------------------------------------------------------

function CityCaptureYield(city, yieldType, yieldConstant, yieldPopulation, yieldEra, yieldEraExponent, targetCity)
	log:Info("CityCaptureYield %s", city:GetName())

	local player = Players[city:GetOwner()]
	local baseYield = yieldConstant
		  baseYield = baseYield + city:GetPopulation() * yieldPopulation
		  baseYield = baseYield + yieldEra * (1 + player:GetCurrentEra()) ^ yieldEraExponent
		  baseYield = baseYield * GameInfo.GameSpeeds[Game.GetGameSpeedType()].CulturePercent / 100
		  
	log:Debug("CityCaptureYield baseYield = %s", baseYield)

	local totalYield = 0
	if targetCity then
		local cityCulture = baseYield * (1 + City_GetBaseYieldRateModifier(targetCity, yieldType)/100)
		totalYield = totalYield + cityCulture
		City_ChangeYieldStored(targetCity, yieldType, cityCulture)
	else
		for targetCity in player:Cities() do
			local cityCulture = baseYield * (1 + City_GetBaseYieldRateModifier(targetCity, yieldType)/100) * City_GetWeight(targetCity, yieldType)/Player_GetTotalWeight(player, yieldType)
			totalYield = totalYield + cityCulture
			City_ChangeYieldStored(targetCity, yieldType, cityCulture)
		end
	end

	log:Debug("CityCaptureYield totalYield = %s", baseYield)
	
	local yieldInfo = GameInfo.Yields[yieldType]
	local yieldName = Locale.ConvertTextKey(yieldInfo.Description)
	local tooltip = string.format( "%s %s %s looted from capturing %s.",
		Round(totalYield),
		yieldInfo.IconString,
		yieldName,
		city:GetName()
		)
	if player:GetID() == Game.GetActivePlayer() then
		CustomNotification(
			"CapturedCityLoot",
			"Looted " .. yieldName,
			tooltip,
			city:Plot(),
			0,
			0,
			0
		)
	end
end

function DoCityCaptureBonuses(capturedCity, player)
	log:Info("DoCityCaptureBonuses")
	for policyInfo in GameInfo.Policies("CityCaptureCulture != 0") do
		if player:HasPolicy(policyInfo.ID) then
			CityCaptureYield(capturedCity,
				YieldTypes.YIELD_CULTURE,
				policyInfo.CityCaptureCulture,
				policyInfo.CityCaptureCulturePerPop,
				policyInfo.CityCaptureCulturePerEra,
				policyInfo.CityCaptureCulturePerEraExponent
				)
		end
	end
	for buildingInfo in GameInfo.Buildings("CityCaptureCulture != 0") do
		for targetCity in player:Cities() do
			if targetCity:IsHasBuilding(buildingInfo.ID) then
				CityCaptureYield(capturedCity,
					YieldTypes.YIELD_CULTURE,
					buildingInfo.CityCaptureCulture,
					buildingInfo.CityCaptureCulturePerPop,
					buildingInfo.CityCaptureCulturePerEra,
					buildingInfo.CityCaptureCulturePerEraExponent,
					targetCity
					)
			end
		end
	end
end

LuaEvents.CityCaptureBonuses = LuaEvents.CityCaptureBonuses or function(city) end
LuaEvents.CityCaptureBonuses.Add( DoCityCaptureBonuses )

---------------------------------------------------------------------
---------------------------------------------------------------------

if not MapModData.VEM.FreeFlavorBuilding then
	MapModData.VEM.FreeFlavorBuilding = {}
	playerFreeBuildings = {}
	for row in GameInfo.Flavors() do
		MapModData.VEM.FreeFlavorBuilding[row.Type] = {}
		playerFreeBuildings[row.Type] = {}
		for playerID,player in pairs(Players) do
			playerFreeBuildings[row.Type][playerID] = 0
			for city in player:Cities() do
				local cityID = City_GetID(city)				
				local buildingID = LoadValue("MapModData.VEM.FreeFlavorBuilding[%s][%s]", row.Type, cityID)
				--log:Trace("Loading %15s MapModData.VEM.FreeFlavorBuilding %s = %s", city:GetName(), row.Type, buildingID)
				if buildingID then
					MapModData.VEM.FreeFlavorBuilding[row.Type][cityID] = buildingID
					playerFreeBuildings[row.Type][playerID] = playerFreeBuildings[row.Type][playerID] + 1
				end
			end
		end
	end
end

function CheckAdoptedPolicyEffects(player, policyID)
	local playerID = player:GetID()
	
	if policyID then
		local policyInfo = GameInfo.Policies[policyID]
		log:Debug("CheckAdoptedPolicyEffects %s %s", player:GetName(), policyInfo.Type)

		local influence = policyInfo.MinorInfluence
		local minInfluence = policyInfo.MinorFriendshipMinimum
		if influence ~= 0 then
			local playerTeam = Teams[player:GetTeam()]
			log:Debug("%s CS Friendship: +%s", player:GetName(), influence)
			for minorCivID,minorCiv in pairs(Players) do
				local minorTeamID = minorCiv:GetTeam()
				if IsValidPlayer(minorCiv) and minorCiv:IsMinorCiv() and playerTeam:IsHasMet(minorTeamID) and not playerTeam:IsAtWar(minorTeamID) then
					if (policyInfo.MinorFriendshipMinimum ~= 0) and (minorCiv:GetMinorCivFriendshipLevelWithMajor(playerID) < policyInfo.MinorFriendshipMinimum) then
						SetMinorCivFriendship(minorCiv, playerID, policyInfo.MinorFriendshipMinimum)
					end
					minorCiv:ChangeMinorCivFriendshipWithMajor(playerID, influence)
				end
			end
		end
		
		local experience = policyInfo.FreeExperience
		if experience ~= 0 then
			for unit in player:Units() do
				if unit:IsCombatUnit() then
					unit:ChangeExperience(experience)
				end
			end
		end
		
	end
	
	local cityList = nil
	for row in GameInfo.Policy_FreeBuildingFlavor() do
		local testPolicyID = GameInfo.Policies[row.PolicyType].ID
		if ((policyID == testPolicyID) or player:HasPolicy(testPolicyID)) then
			log:Debug("CheckAdoptedPolicyEffects %15s HasPolicy %s", player:GetName(), row.PolicyType)
			if row.NumCities == -1 then
				for city in player:Cities() do
					local cityID = City_GetID(city)
					if not MapModData.VEM.FreeFlavorBuilding[row.FlavorType][cityID] then
						local buildingID = GetBestBuildingOfFlavor(city, row.FlavorType)
						log:Debug("CheckAdoptedPolicyEffects %10s best %10s building: %20s", city:GetName(), row.FlavorType, (buildingID == -1) and "None Available" or GameInfo.Buildings[buildingID].Type)
						if buildingID ~= -1 then
							city:SetNumRealBuilding(buildingID, 1)
							SaveValue(buildingID, "MapModData.VEM.FreeFlavorBuilding[%s][%s]", row.FlavorType, cityID)
							MapModData.VEM.FreeFlavorBuilding[row.FlavorType][cityID] = buildingID
							playerFreeBuildings[row.FlavorType][playerID] = playerFreeBuildings[row.FlavorType][playerID] + 1
							log:Debug("CheckAdoptedPolicyEffects %10s Awarded Building", " ")
						end
					end
				end
			elseif (playerFreeBuildings[row.FlavorType][playerID] < row.NumCities) then
				if not cityList then
					cityList = {}
					for city in player:Cities() do
						log:Debug("cityList %s id=%s turn=%s", #cityList, City_GetID(city), city:GetGameTurnAcquired())
						table.insert(cityList, {id=City_GetID(city), turn=city:GetGameTurnAcquired()})
					end
					if row.NumCities ~= -1 then
						table.sort(cityList, function (a,b)
							return a.turn < b.turn
						end)
					end
				end
				local maxCityID = #cityList
				if row.NumCities < maxCityID then
					maxCityID = row.NumCities
				end
				for i = 1, maxCityID do
					local cityID = cityList[i].id
					log:Debug("cityID=%s freeBuilding=%s", cityID, MapModData.VEM.FreeFlavorBuilding[row.FlavorType][cityID])
					if not MapModData.VEM.FreeFlavorBuilding[row.FlavorType][cityID] then
						local city = Map_GetCityByID(cityID)
						if not city then
							log:Fatal("Policy_FreeBuildingFlavor invalid cityList[%s].id=%s !", i, cityList[i].id)
						end
						local buildingID = GetBestBuildingOfFlavor(city, row.FlavorType)
						log:Debug("CheckAdoptedPolicyEffects %10s best %10s building: %20s", city:GetName(), row.FlavorType, (buildingID == -1) and "None Available" or GameInfo.Buildings[buildingID].Type)
						if buildingID ~= -1 then
							city:SetNumRealBuilding(buildingID, 1)
							SaveValue(buildingID, "MapModData.VEM.FreeFlavorBuilding[%s][%s]", row.FlavorType, cityID)
							MapModData.VEM.FreeFlavorBuilding[row.FlavorType][cityID] = buildingID
							playerFreeBuildings[row.FlavorType][playerID] = playerFreeBuildings[row.FlavorType][playerID] + 1
							log:Debug("CheckAdoptedPolicyEffects %10s Awarded Building", " ")
						end
					end
				end
			end
		end
	end
end

LuaEvents.ActivePlayerTurnEnd_Player.Add( CheckAdoptedPolicyEffects )
LuaEvents.PolicyAdopted.Add( CheckAdoptedPolicyEffects )

---------------------------------------------------------------------
---------------------------------------------------------------------

function UpdatePromotions(unit, isUpgrading)
	if unit and IsCombatAndDomain(unit, "DOMAIN_LAND") then		
		local unitInfo = GameInfo.Units[unit:GetUnitType()]
		if isUpgrading then
			unitInfo = GameInfo.Units[unit:GetUpgradeUnitType()]
			log:Debug("UpdatePromotions upgrade %s to %s", GameInfo.Units[unit:GetUnitType()].Type, tostring(unitInfo.Type))
		end
		
		local promoCategory = GameInfo.UnitCombatInfos[unitInfo.CombatClass].PromotionCategory

		if isUpgrading then
			log:Debug("New promotion category: %s", promoCategory)
		end

		if unitInfo.CombatClass == "_UNITCOMBAT_ARMOR" or unitInfo.CombatClass == "UNITCOMBAT_ARMOR" then
			CheckReplacePromotion(
				unit,
				GameInfo.UnitPromotions.PROMOTION_MARCH.ID,
				GameInfo.UnitPromotions.PROMOTION_REPAIR.ID
				)
		end

		local needsAstronomy = GameInfo.UnitPromotions.PROMOTION_OCEAN_IMPASSABLE_UNTIL_ASTRONOMY.ID
		if unit:IsHasPromotion(needsAstronomy) and GetTrait(Players[unit:GetOwner()]).EmbarkedAllWater then
			unit:SetHasPromotion(needsAstronomy, false)
		end

		for swapInfo in GameInfo.UnitPromotions_Equivilancy() do
			local newPromoType = swapInfo[promoCategory]
			local newPromoID = -1
			if newPromoType then
				if GameInfo.UnitPromotions[newPromoType] then
					newPromoID = GameInfo.UnitPromotions[newPromoType].ID
				else
					log:Warn("UpdatePromotions: %s does not exist in UnitPromotions!", newPromoType)					
				end
			end
			for category, oldPromoType in pairs(swapInfo) do
				if category ~= promoCategory then
					if GameInfo.UnitPromotions[oldPromoType] then
						CheckReplacePromotion(unit, GameInfo.UnitPromotions[oldPromoType].ID, newPromoID)
					else
						log:Warn("UpdatePromotions: %s does not exist in UnitPromotions!", oldPromoType)
					end
				end
			end
		end
	end
end

LuaEvents.ActivePlayerTurnStart_Unit.Add(UpdatePromotions)
LuaEvents.UnitUpgraded.Add(function(unit) UpdatePromotions(unit, true) end)

function CheckReplacePromotion(unit, oldPromo, newPromo)
	if unit:IsHasPromotion(oldPromo) then
		log:Trace("%s replace %s with %s", unit:GetName(), GameInfo.UnitPromotions[oldPromo].Type, newPromo and GameInfo.UnitPromotions[newPromo].Type or "none")
		unit:SetHasPromotion(oldPromo, false)
		if newPromo ~= -1 then
			unit:SetHasPromotion(newPromo, true)
			--LuaEvents.RefreshUnitFlagPromotions(unit)
		end
	end
end

---------------------------------------------------------------------
---------------------------------------------------------------------

function CheckExtraBuildingStats(city, owner)
	local query = ""

	query = "GreatGeneralRateChange != 0"
	for buildingInfo in GameInfo.Buildings(query) do
		if (city:IsHasBuilding(buildingInfo.ID)) then
			owner:ChangeCombatExperience(buildingInfo.GreatGeneralRateChange)
		end
	end

	query = "GoldenAgePoints != 0"
	for buildingInfo in GameInfo.Buildings(query) do
		if (city:IsHasBuilding(buildingInfo.ID)) then
			owner:ChangeGoldenAgeProgressMeter(buildingInfo.GoldenAgePoints)
		end
	end
end

LuaEvents.ActivePlayerTurnStart_City.Add(CheckExtraBuildingStats)

---------------------------------------------------------------------
---------------------------------------------------------------------

function CheckGarrisonExperience(player)
	if player:IsMinorCiv() then
		return
	end
	local playerID = player:GetID()
	local exp = 0
	for policyInfo in GameInfo.Policies("GarrisonedExperience != 0") do
		if player:HasPolicy(policyInfo.ID)  then
			exp = exp + policyInfo.GarrisonedExperience
		end
	end
	if exp > 0 then
		for unit in player:Units() do
			if unit and not unit:IsDead() then
				unitXP = MapModData.VEM.UnitXP[playerID][unit:GetID()]

				if unit:IsGarrisoned() then
					unitXP = (unitXP or 0) + exp					
					if unitXP >= 1 then
						unit:ChangeExperience(math.floor(unitXP))
						unitXP = unitXP - math.floor(unitXP)
					end
				end
				if unitXP then
					MapModData.VEM.UnitXP[playerID][unit:GetID()] = unitXP
					SaveUnit(unit, unitXP, "unitXP")
					--log:Debug("%25s %15s %15s exp=%.1f", "CheckGarrisonExperience", player:GetName(), unit:GetName(), unitXP + GetExperienceStored(unit))
				end
			end
		end
	end
end

LuaEvents.ActivePlayerTurnStart_Player.Add(CheckGarrisonExperience)

---------------------------------------------------------------------
---------------------------------------------------------------------

--[[
function DoLevelupHeal(
		attPlayerID,
		attUnitID,
		attUnitDamage,
		attFinalUnitDamage,
		attMaxHitPoints,
		defPlayerID,
		defUnitID,
		defUnitDamage,
		defFinalUnitDamage,
		defMaxHitPoints
		)

	local heal = CiVUP.UNIT_LEVEL_UP_HEAL_PERCENT
	local attPlayer	= Players[attPlayerID]
	local attUnit	= attPlayer:GetUnitByID(attUnitID)

	if (not attUnit) or (not heal) or (heal == 0)  then
		return
	end

	log:Debug("DoLevelupHeal %15s %15s", attPlayer:GetName(), attUnit:GetName())

end



Events.EndCombatSim.Add( DoLevelupHeal )
--]]

---------------------------------------------------------------------
---------------------------------------------------------------------

if not MapModData.VEM.UnitLevel then
	MapModData.VEM.UnitLevel = {}
	for playerID,player in pairs(Players) do
		if IsValidPlayer(player) then
			MapModData.VEM.UnitLevel[playerID] = {}
			for unit in player:Units() do
				MapModData.VEM.UnitLevel[playerID][unit:GetID()] = unit:GetLevel()
			end
		end
	end
end

function DoPromotionHeal(unit, promotionType)
	local heal = CiVUP.UNIT_LEVEL_UP_HEAL_PERCENT
	if heal and heal ~= 0 then
		local playerID = unit:GetOwner()
		heal = unit:GetMaxHitPoints() * heal / 100
		unit:ChangeDamage(-heal)
		--log:Warn("Level %s", unit:GetLevel())
		MapModData.VEM.UnitLevel[playerID][unit:GetID()] = (MapModData.VEM.UnitLevel[playerID][unit:GetID()] or unit:GetLevel()) + 1
	end
end
LuaEvents.PromotionEarned.Add(DoPromotionHeal)

function CheckForAILevelup(unit)
	local playerID = unit:GetOwner()
	MapModData.VEM.UnitLevel[playerID][unit:GetID()] = MapModData.VEM.UnitLevel[playerID][unit:GetID()] or unit:GetLevel()
	for i = MapModData.VEM.UnitLevel[playerID][unit:GetID()], unit:GetLevel() - 1 do
		--log:Warn("%15s %15s old=%s new=%s", Players[playerID]:GetName(), unit:GetName(), MapModData.VEM.UnitLevel[playerID][unit:GetID()], unit:GetLevel())
		DoPromotionHeal(unit)
	end
end
LuaEvents.ActivePlayerTurnEnd_Unit.Add(CheckForAILevelup)
LuaEvents.ActivePlayerTurnStart_Unit.Add(CheckForAILevelup)

---------------------------------------------------------------------
---------------------------------------------------------------------


