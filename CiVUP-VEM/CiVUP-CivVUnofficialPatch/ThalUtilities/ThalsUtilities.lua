-- Thals Utilities
-- DateCreated: 2/6/2011 5:17:42 AM
--------------------------------------------------------------

if Game == nil or IncludedThalsUtilities then
	return
end

IncludedThalsUtilities = true

--print("INFO   Loading ThalsUtilities.lua")

--
-- Function Prototypes
--

LuaEvents.ActivePlayerTurnStart_Turn	= LuaEvents.ActivePlayerTurnStart_Turn		or function()							end
LuaEvents.ActivePlayerTurnStart_Player	= LuaEvents.ActivePlayerTurnStart_Player	or function(player)						end
LuaEvents.ActivePlayerTurnStart_Unit	= LuaEvents.ActivePlayerTurnStart_Unit		or function(unit)						end
LuaEvents.ActivePlayerTurnStart_City	= LuaEvents.ActivePlayerTurnStart_City		or function(city, owner)				end
LuaEvents.ActivePlayerTurnStart_Plot	= LuaEvents.ActivePlayerTurnStart_Plot		or function(plot)						end
LuaEvents.ActivePlayerTurnEnd_Turn		= LuaEvents.ActivePlayerTurnEnd_Turn		or function()							end
LuaEvents.ActivePlayerTurnEnd_Player	= LuaEvents.ActivePlayerTurnEnd_Player		or function(player)						end
LuaEvents.ActivePlayerTurnEnd_Unit		= LuaEvents.ActivePlayerTurnEnd_Unit		or function(unit)						end
LuaEvents.ActivePlayerTurnEnd_City		= LuaEvents.ActivePlayerTurnEnd_City		or function(city, owner)				end
LuaEvents.ActivePlayerTurnEnd_Plot		= LuaEvents.ActivePlayerTurnEnd_Plot		or function(plot)						end
LuaEvents.CityFounded					= LuaEvents.CityFounded						or function(hexPos, playerID, cityID, cultureType, eraType, continent, populationSize, size, fowState) end
LuaEvents.UnitSpawned					= LuaEvents.UnitSpawned						or function(playerID, unitID, hexVec, unitType, cultureType, civID, primaryColor, secondaryColor, unitFlagIndex, fogState, selected, military, notInvisible) end
LuaEvents.PlotAcquired					= LuaEvents.PlotAcquired					or function(plot, newOwnerID)			end
LuaEvents.PolicyAdopted					= LuaEvents.PolicyAdopted					or function(policyID, isPolicy)			end
LuaEvents.CityOccupied					= LuaEvents.CityOccupied					or function(city, player, isForced)		end
LuaEvents.CityPuppeted					= LuaEvents.CityPuppeted					or function(city, player, isForced)		end
LuaEvents.CityLiberated					= LuaEvents.CityLiberated					or function(city, player, isForced)		end
LuaEvents.PromotionEarned				= LuaEvents.PromotionEarned					or function(unit, promotionType)		end
LuaEvents.UnitUpgraded					= LuaEvents.UnitUpgraded					or function(unit)						end
LuaEvents.BuildingConstructed			= LuaEvents.BuildingConstructed				or function(player, city, buildingID)	end
LuaEvents.BuildingDestroyed				= LuaEvents.BuildingDestroyed				or function(player, city, buildingID)	end
LuaEvents.CheckPlotBuildingsStatus		= LuaEvents.CheckPlotBuildingsStatus		or function(plot)						end

--
-- Function Definitions
--

include("SaveUtils.lua")
MY_MOD_NAME = "CiVUP_VEM"

MapModData.VEM = MapModData.VEM or {}
saveDB = saveDB or Modding.OpenSaveData()
CiVUP = CiVUP or {}
for row in GameInfo.CiVUP() do
	CiVUP[row.Type] = row.Value
end
---------------------------------------------------------------------
--[[ LuaLogger usage example:
include("ThalsUtilities")
local log = Events.LuaLogger:New()
log:SetLevel("WARN")
log:Info("Loading ThalsUtilities")
]]

LOG_TRACE	= "TRACE"
LOG_DEBUG	= "DEBUG"
LOG_INFO	= "INFO"
LOG_WARN	= "WARN"
LOG_ERROR	= "ERROR"
LOG_FATAL	= "FATAL"

local LEVEL = {
	[LOG_TRACE] = 1,
	[LOG_DEBUG] = 2,
	[LOG_INFO]  = 3,
	[LOG_WARN]  = 4,
	[LOG_ERROR] = 5,
	[LOG_FATAL] = 6,
}

Events.LuaLogger = Events.LuaLogger or {}
Events.LuaLogger.New = Events.LuaLogger.New or function(self)
	local logger = {}
	setmetatable(logger, self)
	self.__index = self

	logger.level = LEVEL.INFO

	logger.SetLevel = function (self, level)
		self.level = level
	end

	logger.Message = function (self, level, ...)
		if LEVEL[level] < LEVEL[self.level] then
			return false
		end
		local _, numCommands = string.gsub(arg[1], "[%%]", "")
		for i = 2, numCommands+1 do
			if type(arg[i]) ~= "number" and type(arg[i]) ~= "string" then
				arg[i] = tostring(arg[i])
			end
		end
		--if level == LOG_FATAL then
		--	error(level .. string.rep(" ", 7-level:len()) .. string.format(unpack(arg)))
		--else
			print(level .. string.rep(" ", 7-level:len()) .. string.format(unpack(arg)))
		--end
		return true
	end

	logger.Trace = function (logger, ...) return logger:Message(LOG_TRACE, unpack(arg)) end
	logger.Debug = function (logger, ...) return logger:Message(LOG_DEBUG, unpack(arg)) end
	logger.Info  = function (logger, ...) return logger:Message(LOG_INFO,  unpack(arg)) end
	logger.Warn  = function (logger, ...) return logger:Message(LOG_WARN,  unpack(arg)) end
	logger.Error = function (logger, ...) return logger:Message(LOG_ERROR, unpack(arg)) end
	logger.Fatal = function (logger, ...) return logger:Message(LOG_FATAL, unpack(arg)) end
	return logger
end

local log = Events.LuaLogger:New()
log:SetLevel("WARN")

---------------------------------------------------------------------
--[[ Plot_GetID(plot) usage example:
MapModData.buildingsAlive[Plot_GetID(city:Plot())][buildingID] = true
]]

function Plot_GetID(plot)
	if not plot then
		log:Fatal("Plot_GetID plot=nil")
		return nil
	end
	local iW, iH = Map.GetGridSize()
	return plot:GetY() * iW + plot:GetX()
end

function City_GetID(city)
	if not city then
		log:Fatal("City_GetID city=nil")
		return nil
	end
	return Plot_GetID(city:Plot())
end

function Map_GetCityByID(index)
	local plot = Map.GetPlotByIndex(index)
	return plot:GetPlotCity()
end

---------------------------------------------------------------------
--[[  usage example:

]]

function LoadValue(...)
	if arg == nil then
		log:Fatal("LoadValue arg=nil")
		return
	end
	return saveDB.GetValue("_"..string.format( unpack(arg) ))
end

function SaveValue(value, ...)
	if arg == nil then
		log:Fatal("SaveValue arg=nil")
		return
	end
	return saveDB.SetValue("_"..string.format( unpack(arg) ), value)
end

function LoadPlayer(player, ...)
	return saveDB.GetValue(string.format( "_player%s_%s", player:GetID(), string.format(unpack(arg)) ))
end

function SavePlayer(player, value, ...)
	return saveDB.SetValue(string.format( "_player%s_%s", player:GetID(), string.format(unpack(arg)) ), value)
end

function LoadCity(city, ...)
	if city == nil then
		log:Fatal("LoadCity city=nil key=%s value=%s", string.format(unpack(arg)), value)
		return
	end
	return saveDB.GetValue(string.format( "_city%s_%s", City_GetID(city), string.format(unpack(arg)) ))
end

function SaveCity(city, value, ...)
	if city == nil then
		log:Fatal("SaveCity city=nil key=%s value=%s", string.format(unpack(arg)), value)
		return
	end
	return saveDB.SetValue(string.format( "_city%s_%s", City_GetID(city), string.format(unpack(arg)) ), value)
end

function LoadUnit(unit, ...)
	return saveDB.GetValue(string.format( "_player%s_unit%s_%s", unit:GetOwner(), unit:GetID(), string.format(unpack(arg)) ))
end

function SaveUnit(unit, value, ...)
	return saveDB.SetValue(string.format( "_player%s_unit%s_%s", unit:GetOwner(), unit:GetID(), string.format(unpack(arg)) ), value)
end

function LoadPlot(plot, ...)
	return saveDB.GetValue(string.format( "_plot%s_%s", Plot_GetID(plot), string.format(unpack(arg)) ))
end

function SavePlot(plot, value, ...)
	return saveDB.SetValue(string.format( "_plot%s_%s", Plot_GetID(plot), string.format(unpack(arg)) ), value)
end

----------------------------------------------------------------
--[[ DeepCopy(object) usage example: copies all elements of a table
table1 = DeepCopy(table2)
]]
function OnEnterGame()
	MapModData.VEM.Initialized = true
end
Events.LoadScreenClose.Add(OnEnterGame)

----------------------------------------------------------------
--[[ DeepCopy(object) usage example: copies all elements of a table
table1 = DeepCopy(table2)
]]
function DeepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

----------------------------------------------------------------
--[[ Literalize(str) usage example: gets rid of newline at the start of a string
strText = string.gsub(strText, "^"..Literalize("[NEWLINE]"), "")
]]
function Literalize(str)
	return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end)
end

----------------------------------------------------------------
--[[ GetTruthTableResult(inputs, truthTable) usage example:
showYieldString = {
--   show { base, surplus} if Consumed YieldMod SurplusMod
		  { false, false}, --    -        -         -     
		  {  true, false}, --    -        -     SurplusMod
		  {  true, false}, --    -     YieldMod     -     
		  {  true,  true}, --    -     YieldMod SurplusMod
		  { false,  true}, -- Consumed    -         -     
		  { false,  true}, -- Consumed    -     SurplusMod
		  {  true,  true}, -- Consumed YieldMod     -     
		  {  true,  true}  -- Consumed YieldMod SurplusMod
}

local truthiness = GetTruthTableResult(showYieldString, {isConsumed, hasYieldMod, hasSurplusMod})
local showBaseYield = truthiness[1]
local showSurplusYield = truthiness[2]
]]
function GetTruthTableResult(truthTable, inputs)
	local index = 0
	for k,v in ipairs(inputs) do
		if v then
			index = index + math.pow(2, #inputs-k)
		end
	end
	return truthTable[index + 1]
end

----------------------------------------------------------------
--[[ IsBetween(lower, mid, upper) usage example:
if IsBetween(0, x, 5) then
]]
function IsBetween(lower, mid, upper)
	return (lower <= mid) and (mid <= upper)
end

----------------------------------------------------------------
--[[ Constrain(lower, mid, upper) usage example:
local healthPercent = Constrain(0, pUnit:GetCurrHitPoints() / pUnit:GetMaxHitPoints(), 1)
]]
function Constrain(lower, mid, upper)
	return math.max(lower, math.min(mid, upper))
end

----------------------------------------------------------------
--[[ Round(num, idp) usage example:
local iFoodPerTurn = Round(City_GetYieldRateTimes100(city, YieldTypes.YIELD_FOOD)/100, 1)
]]
function Round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

----------------------------------------------------------------
--[[ RoundDown(num, idp) usage example:
costMultiplier = RoundDown(costMultiplier, -1) / baseCost * 100
]]
function RoundDown(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.0) / mult
end

----------------------------------------------------------------
--[[ IsCombatAndDomain(unit, domain) usage example:
if IsCombatAndDomain(unit, "DOMAIN_LAND") then
	return unit
end
]]
function IsCombatAndDomain(unit, domain)
	return unit and unit:IsCombatUnit() and unit:GetDomainType() == DomainTypes[domain]
end

----------------------------------------------------------------
--[[ IsValidPlayer(player) usage example:
for playerID,player in pairs(Players) do
	if IsValidPlayer(player) and player:IsMinorCiv() then
		local capitalCity = player:GetCapitalCity()
		player:InitUnit( GameInfo.Units.UNIT_ARCHER.ID, capitalCity:GetX(), capitalCity:GetY() )
		player:InitUnit( GameInfo.Units.UNIT_WARRIOR.ID, capitalCity:GetX(), capitalCity:GetY() )
		player:InitUnit( GameInfo.Units.UNIT_WARRIOR.ID, capitalCity:GetX(), capitalCity:GetY() )
	end
end
]]
function IsValidPlayer(player)
	return player ~= nil and player:IsAlive() and not player:IsBarbarian()
end

----------------------------------------------------------------
--[[ GetActiveHuman() usage example:
local playerActiveHuman = GetActiveHuman()
]]
function GetActiveHuman()
	local iPlayerID = Game.GetActivePlayer()
	if (iPlayerID < 0) then
		print("Error - player index not correct")
		return nil
	end

	if (not Players[iPlayerID]:IsHuman()) then
		return nil
	end

	return Players[iPlayerID]
end

----------------------------------------------------------------
--[[ IsStrictlyWorker(pUnit) usage example:

]]
function IsStrictlyWorker(pUnit)
	if (pUnit:WorkRate() > 0 and not pUnit:IsCombatUnit() and pUnit:GetDomainType() == DomainTypes.DOMAIN_LAND and pUnit:GetSpecialUnitType() == -1) then
		return true
	else
		return false
	end	
end

----------------------------------------------------------------
--[[ Shuffle(t) usage example:

for index, plot in Plots(Shuffle) do
	if ( not plot:IsWater() ) then
					
		-- Prevents too many goodies from clustering on any one landmass.
		local area = plot:Area()
		local improvementCount = area:GetNumImprovements(improvementID)
		local scaler = (area:GetNumTiles() + (tilesPerGoody/2))/tilesPerGoody	
		if (improvementCount < scaler) then
						
			if (CanPlaceGoodyAt(improvement, plot)) then
				plot:SetImprovementType(improvementID)
			end
		end
	end
end
]]
function Shuffle(t)
	local len = #t
	for i = 1, len, 1 do
		local k = Map.Rand(len - 1, "Shuffling Values") + 1
		t[i], t[k] = t[k], t[i]
	end
end

----------------------------------------------------------------
--[[ Plots(sort) usage example:

-- GenerateCoasts function
for i, plot in Plots() do
	if(plot:IsWater()) then
		if(plot:IsAdjacentToLand()) then
			plot:SetTerrainType(shallowWater, false, false)
		else
			plot:SetTerrainType(deepWater, false, false)
		end
	end
end
]]
local _plots = _plots or {}
function Plots(sort)
	local _indices = {}
	for i = 0, Map.GetNumPlots(), 1 do
		_indices[i] = i - 1
	end	
	
	if(sort) then
		sort(_indices)
	end
	
	local cur = 0
	local it = function()
		cur = cur + 1
		local index = _indices[cur]
		local plot
		
		if(index) then
			plot = _plots[index] or Map.GetPlotByIndex(index)
			_plots[index] = plot
		end
		return index, plot
	end
	
	return it
end



------------------------------------------------------------------
--[[ Contains(table, value) checks if a table contains a value
if Contains(myTable, 1) then
	-- do stuff
end
]]
function Contains(table, value)
	for k, v in pairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

------------------------------------------------------------------
--[[ HasValue(conditionList, tableName) usage: returns true where CONDITIONS in TABLE
HasValue( {BuildingType=pBuildingInfo.Type}, GameInfo.Building_LakePlotYieldChanges )
]]
function HasValue(conditionList, tableName)
	if tableName then
		for tableEntry in tableName() do
			local isMatch = true
			for k,v in pairs(conditionList) do
				if tableEntry[k] ~= v then
					isMatch = false
					break
				end
			end
			if isMatch then
				return true
			end
		end
	end
	return false
end

------------------------------------------------------------------
--[[ GetValue(valueName, conditionList, tableName) usage: returns VALUE where CONDITONS in TABLE
GetValue( "Yield", {BuildingType=pBuildingInfo.Type, YieldType="YIELD_FOOD"}, Game.Building_LakePlotYieldChanges )
]]
function GetValue(valueName, conditionList, tableName)
	for tableEntry in tableName() do
		local isMatch = true
		for k,v in pairs(conditionList) do
			if tableEntry[k] ~= v then
				isMatch = false
				break
			end
		end
		if isMatch then
			return tableEntry[valueName]
		end
	end
	return 0
end

------------------------------------------------------------------
--[[ IsWonder(buildingID) usage: IsWonder(buildingID)
if IsWonder(GameInfo.Buildings.BUILDING_GREAT_LIBRARY) then
]]

function IsWonder(buildingID)
	local buildingClass = GameInfo.BuildingClasses[GameInfo.Buildings[buildingID].BuildingClass]
	return (buildingClass.MaxPlayerInstances == 1) or (buildingClass.MaxGlobalInstances == 1)
end

------------------------------------------------------------------
--[[ usage: GetTrait(somePlayer)
local trait = GetTrait(somePlayer)
]]

function GetTrait(player)
	local leaderType = GameInfo.Leaders[player:GetLeaderType()].Type
	local traitType = GameInfo.Leader_Traits("LeaderType ='" .. leaderType .. "'")().TraitType
	return GameInfo.Traits[traitType]
end

---------------------------------------------------------------------
--[[ GetAreaWeights(centerPlot, minRadius, maxRadius) usage example:

areaWeights = GetAreaWeights(plot, 2, 2)
if (areaWeights.PLOT_LAND + areaWeights.PLOT_HILLS) <= 0.25 then
	return
end
]]

local plotTypeName		= {}-- -1="NO_PLOT"}
local terrainTypeName	= {}-- -1="NO_TERRAIN"}
local featureTypeName	= {}-- -1="NO_FEATURE"}
for k, v in pairs(PlotTypes) do
	plotTypeName[v] = k
end
for itemInfo in GameInfo.Terrains() do
	terrainTypeName[itemInfo.ID] = itemInfo.Type
end
for itemInfo in GameInfo.Features() do
	featureTypeName[itemInfo.ID] = itemInfo.Type
end

function GetAreaWeights(plot, minR, maxR)
	local weights = {TOTAL=0, SEA=0, NO_PLOT=0, NO_TERRAIN=0, NO_FEATURE=0}
	
	for k, v in pairs(PlotTypes) do
		weights[k] = 0
	end
	for itemInfo in GameInfo.Terrains() do
		weights[itemInfo.Type] = 0
	end
	for itemInfo in GameInfo.Features() do
		weights[itemInfo.Type] = 0
	end
	
	for _, adjPlot in pairs(GetPlotsInCircle(plot, minR, maxR)) do
		local distance		 = Map.PlotDistance(adjPlot:GetX(), adjPlot:GetY(), plot:GetX(), plot:GetY())
		local adjWeight		 = (distance == 0) and 6 or (1/distance)
		local plotType		 = plotTypeName[adjPlot:GetPlotType()]
		local terrainType	 = terrainTypeName[adjPlot:GetTerrainType()]
		local featureType	 = featureTypeName[adjPlot:GetFeatureType()] or "NO_FEATURE"
		
		weights.TOTAL		 = weights.TOTAL		+ adjWeight 
		weights[plotType]	 = weights[plotType]	+ adjWeight
		weights[terrainType] = weights[terrainType]	+ adjWeight
		weights[featureType] = weights[featureType]	+ adjWeight
				
		if plotType == "PLOT_OCEAN" then
			if not adjPlot:IsLake() and featureType ~= "FEATURE_ICE" then
				weights.SEA = weights.SEA + adjWeight
			end
		end
	end
	
	if weights.TOTAL == 0 then
		log:Fatal("GetAreaWeights Total=0! x=%s y=%s", x, y)
	end
	for k, v in pairs(weights) do
		if k ~= "TOTAL" then
			weights[k] = weights[k] / weights.TOTAL
		end
	end
	
	return weights
end

---------------------------------------------------------------------
--[[ GetPlotsInCircle(plot, minR, maxR) usage example:
for _, plot in pairs(GetPlotsInCircle(plot, 1, 4)) do
	--process plot
end
]]

function GetPlotsInCircle(plot, minR, maxR)
	local plotList	= {}
	local iW, iH	= Map.GetGridSize()
	local isWrapX	= Map:IsWrapX()
	local isWrapY	= Map:IsWrapY()
	local centerX	= plot:GetX()
	local centerY	= plot:GetY()

	x1 = isWrapX and ((centerX-maxR) % iW) or Constrain(0, centerX-maxR, iW-1)
	x2 = isWrapX and ((centerX+maxR) % iW) or Constrain(0, centerX+maxR, iW-1)
	y1 = isHrapY and ((centerY-maxR) % iH) or Constrain(0, centerY-maxR, iH-1)
	y2 = isHrapY and ((centerY+maxR) % iH) or Constrain(0, centerY+maxR, iH-1)

	local x		= x1
	local y		= y1
	local xStep	= 0
	local yStep	= 0
	local rectW	= x2-x1 
	local rectH	= y2-y1
	
	if rectW < 0 then
		rectW = rectW + iW
	end
	
	if rectH < 0 then
		rectH = rectH + iH
	end
	
	local adjPlot = Map.GetPlot(x, y)

	while (yStep < 1 + rectH) and adjPlot ~= nil do
		while (xStep < 1 + rectW) and adjPlot ~= nil do
			if IsBetween(minR, Map.PlotDistance(x, y, centerX, centerY), maxR) then
				table.insert(plotList, adjPlot)
			end
			
			x		= x + 1
			x		= isWrapX and (x % iW) or x
			xStep	= xStep + 1
			adjPlot	= Map.GetPlot(x, y)
		end
		x		= x1
		y		= y + 1
		y		= isWrapY and (y % iH) or y
		xStep	= 0
		yStep	= yStep + 1
		adjPlot	= Map.GetPlot(x, y)
	end
	
	return plotList
end

---------------------------------------------------------------------
--[[ GetCombatUnitOnTile(plot) usage example:
local capturingUnit = GetCombatUnitOnTile(plot)
]]

function GetCombatUnitOnTile(plot)
    local lostCityPlot = Map.GetPlot( ToGridFromHex( plot.x, plot.y ) )
	local count = lostCityPlot:GetNumUnits()
	for i = 0, count - 1 do
		local pUnit = lostCityPlot:GetUnit( i )
		if IsCombatAndDomain(pUnit, "DOMAIN_LAND") then
			return pUnit
		end
	end
	return nil
end

function GetBestUnitType(capitalCity)
	local player				= Players[capitalCity:GetOwner()]
	local bestUnitType			= GameInfo.Units["UNIT_WARRIOR"].ID
	local bestCombatStrength	= GameInfo.Units["UNIT_WARRIOR"].Combat	
	local isCoastal				= false
	local plot					= capitalCity:Plot()
	if plot:IsCoastalLand() then
		if GetAreaWeights(plot, 1, 8).SEA >= 0.5 then
			isCoastal = true
		end
	end
 	for unit in GameInfo.Units("Combat > 0") do
		local unitCombat = unit.Combat
		if unit.CombatClass == "_UNITCOMBAT_SIEGE" or unit.CombatClass == "UNITCOMBAT_SIEGE" then
			unitCombat = unitCombat * 0.75
		elseif (unit.Domain == "DOMAIN_SEA" and isCoastal) then
			unitCombat = unitCombat * 1.25
		elseif (unit.Domain == "DOMAIN_SEA" and not isCoastal) or (unit.Domain == "DOMAIN_AIR") then
			unitCombat = 0
		end
		if unit.Combat > bestCombatStrength and capitalCity:CanTrain( unit.ID ) then
			local isResourceRequired = false
			for unitType in GameInfo.Unit_ResourceQuantityRequirements() do
				if unitType.UnitType == unit.Type then
					isResourceRequired = true
					break
				end
			end
			if not isResourceRequired then
				bestUnitType = unit.ID
				bestCombatStrength = unit.Combat
			end
		end
	end
	log:Debug("Best unit: "..GameInfo.Units[bestUnitType].Type)
	return bestUnitType
end

---------------------------------------------------------------------
--[[ GetUniqueUnitID(player, itemClass) usage example:
player:InitUnit( GetUniqueUnitID(player, "UNITCLASS_ARCHER"),  x, y )
capitalCity:SetNumRealBuilding(GetUniqueBuildingID(player, "BUILDINGCLASS_MARKET"), 1)
]]

function GetUniqueUnitID(player, classType)
	local civType = GameInfo.Civilizations[player:GetCivilizationType()].Type
	local classType = GameInfo.UnitClasses[classType]
	if not classType or not classType.DefaultUnit then
		log:Error("Invalid unit class: %s", classType)
		return nil
	end
	classType = classType.DefaultUnit
	if civType ~= "CIVILIZATION_MINOR" and civType ~= "CIVILIZATION_BARBARIAN" then
		for itemInfo in GameInfo.Civilization_UnitClassOverrides(string.format("UnitClassType = '%s'", classType)) do
			if civType == itemInfo.CivilizationType then
				classType = itemInfo.UnitType
				break
			end
		end
	end
	return GameInfo.Units[classType].ID
end

function GetUniqueBuildingID(player, classType)
	if not player then
		log:Error("GetUniqueBuildingID player=nil")
		return nil
	end
	if not GameInfo.Civilizations[player:GetCivilizationType()] then
		log:Error("GetUniqueBuildingID invalid civilization: player=%s classType=%s", player:GetName(), classType)
		return nil
	end
	local civType = GameInfo.Civilizations[player:GetCivilizationType()].Type
	local classType = GameInfo.BuildingClasses[classType]
	if not classType then
		log:Error("Invalid building class: %s", classType)
		return nil
	end
	classType = classType.DefaultBuilding
	if civType ~= "CIVILIZATION_MINOR" and civType ~= "CIVILIZATION_BARBARIAN" then
		for itemInfo in GameInfo.Civilization_BuildingClassOverrides(string.format("BuildingClassType = '%s'", classType)) do
			if civType == itemInfo.CivilizationType then
				classType = itemInfo.BuildingType
				break
			end
		end
	end
	return GameInfo.Buildings[classType].ID
end

---------------------------------------------------------------------
--[[ GetAvailableUnitIDs(city) usage example:

local availableIDs	= GetAvailableUnitIDs(capitalCity)
local newUnitID		= availableIDs[1 + Map.Rand(#availableIDs, "InitUnitFromList")]
local capitalPlot	= capitalCity:Plot()
local exp			= Player_GetCitystateYields(player, MinorCivTraitTypes.MINOR_CIV_TRAIT_MILITARISTIC, 2)[YieldTypes.YIELD_EXPERIENCE].Total
Player_InitUnit(player, newUnitID, capitalPlot, exp)
]]

function GetAvailableUnitIDs(city)
	local unitList = {}
	if city == nil then
		log:Fatal("GetAvailableUnitIDs: invalid city")
		return nil
	end
	local player = Players[city:GetOwner()]
	if player == nil then
		log:Fatal("GetAvailableUnitIDs: invalid player ID = %s", city, city:GetOwner())
		return nil
	end
 	for unitInfo in GameInfo.Units("Combat > 0") do
		if city:CanTrain( unitInfo.ID ) and unitInfo.Class ~= "UNITCLASS_SCOUT" and unitInfo.Class ~= "UNITCLASS_CARRIER" then
			local isResourceAvailable = true
			for row in GameInfo.Unit_ResourceQuantityRequirements("UnitType = '"..unitInfo.Type.."'") do
				if player:GetNumResourceAvailable(GameInfo.Resources[row.ResourceType].ID, true) <= 0 then
					isResourceAvailable = false
					break
				end
			end
			if isResourceAvailable then
				table.insert(unitList, unitInfo.ID)
			end
		end
	end
	if #unitList == 0 then
		log:Warn("GetAvailableUnitIDs %s no units found, adding Scout", city:GetName())
		table.insert(unitList, GameInfo.Units.UNIT_SCOUT.ID)
	end
	return unitList
end

---------------------------------------------------------------------
--[[ Player_InitUnit(player, unitID, plot, experience) usage example:

local availableIDs	= GetAvailableUnitIDs(player)
local newUnitID		= availableIDs[1 + Map.Rand(#availableIDs, "InitUnitFromList")]
local capitalPlot	= capitalCity:Plot()
local exp			= (1 + player:GetCurrentEra()) * CiVUP.MINOR_CIV_MILITARISTIC_XP_PER_ERA
Player_InitUnit(player, newUnitID, capitalPlot, exp)
]]

function Player_InitUnit(player, unitID, plot, exp)
	local newUnit = player:InitUnit( unitID, plot:GetX(), plot:GetY() )
	if exp then
		newUnit:ChangeExperience(exp)
		newUnit:SetPromotionReady(true)
	end
	return newUnit
end

---------------------------------------------------------------------
--[[ Player_InitUnitClass(player, unitClassType, plot, experience) usage example:

local availableIDs	= GetAvailableUnitIDs(player)
local newUnitID		= availableIDs[Map.Rand(#availableIDs, "InitUnitFromList")]
local capitalPlot	= capitalCity:Plot()
local exp			= (1 + player:GetCurrentEra()) * CiVUP.MINOR_CIV_MILITARISTIC_XP_PER_ERA
Player_InitUnit(player, newUnitID, capitalPlot, exp)
]]

function Player_InitUnitClass(player, unitClassType, plot, exp)
	local newUnit = player:InitUnit( GetUniqueUnitID(player, unitClassType), plot:GetX(), plot:GetY() )
	if exp then
		newUnit:ChangeExperience(exp)
	end
	return newUnit
end

---------------------------------------------------------------------
--[[ GetExperienceStored(level) usage example:
local iExperience = GetExperienceStored(unit)

-- also available:
-- GetExperienceForLevel(level)
-- GetExperienceStored(unit)
-- GetExperienceNeeded(unit)
]]

function GetExperienceForLevel(level)
	local xpSum = 0
	for i=1, level-1 do
		xpSum = xpSum + i*GameDefines.EXPERIENCE_PER_LEVEL
	end
	return xpSum
end

function GetExperienceStored(unit)
	return unit:GetExperience() - GetExperienceForLevel(unit:GetLevel())
end

function GetExperienceNeeded(unit)
	return unit:ExperienceNeeded() - GetExperienceForLevel(unit:GetLevel())
end

---------------------------------------------------------------------
--[[  usage example:

local improvementType = buildingInfo.MountainImprovement
if improvementType then
	local mountainPlot = GetMachuPicchuPlot(plot)
	mountainPlot:SetOwner(playerID, city:GetID())
	mountainPlot:SetImprovementType(GameInfo.Improvements[improvementType].ID)
end
]]
function GetMachuPicchuPlot(startPlot)
	local hex = ToHexFromGrid( Vector2(startPlot:GetX(), startPlot:GetY()) )
	
	local directions = {
		Vector2(  0,  1),
		Vector2( -1,  0),
		Vector2(  1, -1),
		Vector2(  0, -1),
		Vector2(  1,  0),
		Vector2( -1,  1)
	}

	for _, vecJ in ipairs(directions) do
		local hexJ = VecAdd(hex, vecJ)
		log:Trace("hexJ =  hex + vecJ  %s,%s = %s,%s + %s,%s", hexJ.x, hexJ.y, hex.x, hex.y, vecJ.x, vecJ.y)
		
		for _, vecK in ipairs(directions) do
			local hexK = VecAdd(hexJ, vecK)
			log:Trace("hexK = hexJ + vecK  %s,%s = %s,%s + %s,%s", hexK.x, hexK.y, hexJ.x, hexJ.y, vecK.x, vecK.y)
			local targetPlot = Map.GetPlot(ToGridFromHex(hexK.x, hexK.y))
			
			if targetPlot and targetPlot:IsMountain() then
				return targetPlot
			end
		end
	end
	return startPlot
end

---------------------------------------------------------------------
--[[ GetPurchaseCostMod usage example:

]]
function GetPurchaseCostMod(player, baseCost, hurryCostMod)
	local costMultiplier = -1
	if hurryCostMod == -1 then
		return costMultiplier
	end
	costMultiplier = math.pow(baseCost * GameDefines.GOLD_PURCHASE_GOLD_PER_PRODUCTION, GameDefines.HURRY_GOLD_PRODUCTION_EXPONENT)
	costMultiplier = costMultiplier * (1 + hurryCostMod / 100)
	local empireMod = 100
	for row in GameInfo.Building_HurryModifiers() do
		for city in player:Cities() do
			if city:IsHasBuilding(GameInfo.Buildings[row.BuildingType].ID) then
				empireMod = empireMod + row.HurryCostModifier
			end
		end
	end
	for row in GameInfo.Policy_HurryModifiers() do
		if player:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
			empireMod = empireMod + row.HurryCostModifier
		end
	end
	costMultiplier = (costMultiplier * empireMod) / 100
	costMultiplier = Round(costMultiplier / baseCost * 100, -1)
	return costMultiplier
end

---------------------------------------------------------------------
--[[ GetPurchaseCost usage example:

Player_GetYieldStored(Players[city:GetOwner()], YieldTypes.YIELD_GOLD) >= GetPurchaseCost(city, GameInfo.Buildings, buildingID)
]]
function GetPurchaseCost(city, itemTable, itemID)
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

	local player = Players[city:GetOwner()]
	local cost = 0
	local hurryCost = -1
	local hurryCostMod = itemTable[itemID].HurryCostModifier

	if hurryCostMod ~= -1 then
		if itemTable == GameInfo.Units then
			cost = player:GetUnitProductionNeeded(itemID)
		elseif itemTable == GameInfo.Buildings then
			cost = player:GetBuildingProductionNeeded(itemID)
			cost = cost + itemTable[itemID].PopCostMod * city:GetPopulation()
		elseif itemTable == GameInfo.Projects then
			cost = player:GetProjectProductionNeeded(itemID)
		end
		hurryCost = math.pow(cost * GameDefines.GOLD_PURCHASE_GOLD_PER_PRODUCTION, GameDefines.HURRY_GOLD_PRODUCTION_EXPONENT)
		local empireMod = 0
		for row in GameInfo.Building_HurryModifiers() do
			for city in player:Cities() do
				if city:IsHasBuilding(GameInfo.Buildings[row.BuildingType].ID) then
					empireMod = empireMod + row.HurryCostModifier
				end
			end
		end
		for row in GameInfo.Policy_HurryModifiers() do
			if player:HasPolicy(GameInfo.Policies[row.PolicyType].ID) then
				empireMod = empireMod + row.HurryCostModifier
			end
		end
		hurryCost = hurryCost * (1 + hurryCostMod/100) * (1 + empireMod/100)
		hurryCost = Round(hurryCost / GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR) * GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR		
	end

	return hurryCost
end

---------------------------------------------------------------------
--[[ GetResourceIDsOfUsage(usageType) usage example:

local resIDs = GetResourceIDsOfUsage(ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC)
	
for _, resID in pairs(resIDs) do
	plotList[resID] = {}
end
]]
function GetResourceIDsOfUsage(usageType)
	local resIDs = {}
	for resInfo in GameInfo.Resources() do
		if Game.GetResourceUsageType(resInfo.ID) == usageType then
			table.insert(resIDs, resInfo.ID)
		end
	end
	return resIDs
end

---------------------------------------------------------------------
--[[ GetBestBuildingOfFlavor(city, flavorType) usage example:

local buildingID = GetBestBuildingOfFlavor(city, row.FlavorType)
if buildingID ~= -1 then
	city:SetNumRealBuilding(buildingID, 1)
	hasFreeBuilding[row.FlavorType][cityID] = true
end
]]
function GetBestBuildingOfFlavor(city, flavorType, includeWonders)
	local bestBuildingID = -1
	local bestFlavor = 0
	for row in GameInfo.Building_Flavors(string.format("FlavorType = '%s'", flavorType)) do
		local buildingID = GameInfo.Buildings[row.BuildingType].ID
		if (city:CanConstruct(buildingID, 0, 1)
				and (row.Flavor > bestFlavor)
				and (includeWonders or not IsWonder(buildingID))
				) then
			bestBuildingID = buildingID
			bestFlavor = row.Flavor
		end
	end
	return bestBuildingID
end

---------------------------------------------------------------------
--[[ SetResistanceTurns(city, turns) usage example:

]]
function SetResistanceTurns(city, turns)
	city:ChangeResistanceTurns(turns - city:GetResistanceTurns())
end

---------------------------------------------------------------------
--[[ SetMinorCivFriendship(minorCiv, majorCivID, friendship) usage example:

]]
function SetMinorCivFriendship(minorCiv, majorCivID, friendship)
	minorCiv:ChangeMinorCivFriendshipWithMajor(majorCivID, friendship - minorCiv:GetMinorCivFriendshipLevelWithMajor(majorCivID))
end

---------------------------------------------------------------------
--[[ GetNumBuilding(city, buildingID) usage example:

]]
function GetNumBuilding(city, buildingID)
	return city:GetNumRealBuilding(buildingID) + city:GetNumFreeBuilding(buildingID)
end

---------------------------------------------------------------------
--[[ GetNumBuildingClass(city, buildingClass) usage example:

]]
function GetNumBuildingClass(city, buildingClass)
	return GetNumBuilding(city, GetUniqueBuildingID(Players[city:GetOwner()], buildingClass))
end

---------------------------------------------------------------------
--[[ GetBuildingAddonLevel(player, buildingID) usage example:

]]
function GetBuildingAddonLevel(player, buildingID)
	local parentClass = GameInfo.Buildings[buildingID].AdditionParent
	if parentClass then
		return (1 + GetBuildingAddonLevel(player, GetUniqueBuildingID(player, parentClass)))
	end
	return 0
end

---------------------------------------------------------------------
--[[ City_GetUnitExperience(city, unitType) usage example:

]]
function City_GetUnitExperience(city, unitType)
	if city == nil then
		log:Fatal("City_GetUnitExperience: nil city")
		return nil
	end
	if unitType == nil then
		log:Fatal("City_GetUnitExperience: nil unitType @ %20s %20s", city:GetName(), city:GetOwner())
		return nil
	end
	local domain = GameInfo.Units[unitType].Domain
	local domainID = GameInfo.Domains[domain].ID
	return city:GetDomainFreeExperience(domainID)
end

---------------------------------------------------------------------
--[[ Player_HasTech(player, tech) usage example:

]]
function Player_HasTech(player, tech)
	if type(tech) == "string" then
		tech = GameInfo.Technologies[tech].ID
	end

	local team = Teams[player:GetTeam()]
	return team:IsHasTech(tech)
end

---------------------------------------------------------------------
--[[ GetUnitClass(unit) usage example:

]]
function GetUnitClass(unit)
	return GameInfo.Units[unit:GetUnitType()].Class
end

---------------------------------------------------------------------
--[[ ReplaceUnit(unit, unitType) usage example:

]]
function Unit_Replace(oldUnit, unitClass)
	local newUnit = Player_InitUnitClass(Players[oldUnit:GetOwner()], unitClass, oldUnit:GetPlot(), oldUnit:GetExperience())
	for promoInfo in GameInfo.UnitPromotions() do
		if oldUnit:IsHasPromotion(promoInfo.ID) and not promoInfo.LostWithUpgrade then
			newUnit:SetHasPromotion(promoInfo.ID, true)
		end
	end
	newUnit:SetDamage(oldUnit:GetDamage())
	newUnit:SetLevel(oldUnit:GetLevel())
	newUnit:SetPromotionReady(newUnit:GetExperience() >= newUnit:ExperienceNeeded())
	newUnit:FinishMoves()
	LuaEvents.UnitUpgraded(newUnit)
	oldUnit:Kill()
	return newUnit
end

---------------------------------------------------------------------
--[[ Player_GetTurnAcquired(player, city) usage example:

]]

function Player_GetTurnAcquired(player, city)
	local playerID = player:GetID()
	local cityID = City_GetID(city)
	return MapModData.VEM.TurnAcquired[playerID][City_GetID(city)]
end

function Player_SetTurnAcquired(player, city, turn)
	local playerID = player:GetID()
	local cityID = City_GetID(city)
	MapModData.VEM.TurnAcquired[playerID][cityID] = turn
	SaveValue(turn, "MapModData.VEM.TurnAcquired[%s][%s]", playerID, cityID)
end

function UpdateTurnAcquiredFounding(hexPos, playerID, cityID, cultureType, eraType, continent, populationSize, size, fowState)
	local player = Players[playerID]
	Player_SetTurnAcquired(player, player:GetCityByID(cityID), Game.GetGameTurn())	
end

function UpdateTurnAcquiredCapture(plot, lostPlayerID, cityID, wonPlayerID)
	local player = Players[wonPlayerID]
	Player_SetTurnAcquired(player, player:GetCityByID(cityID), Game.GetGameTurn())
end

if not MapModData.VEM.TurnAcquired then
	MapModData.VEM.TurnAcquired = {}
	for playerID, player in pairs(Players) do
		MapModData.VEM.TurnAcquired[playerID] = {}
		if IsValidPlayer(player) then
			for city in player:Cities() do
				local cityID = City_GetID(city)
				MapModData.VEM.TurnAcquired[playerID][cityID] = LoadValue("MapModData.VEM.TurnAcquired[%s][%s]", playerID, cityID) 
				if not MapModData.VEM.TurnAcquired[playerID][cityID] then
					Player_SetTurnAcquired(player, city, city:GetGameTurnAcquired())
				end
			end
		end
	end
end


































--
-- Event Definitions
--

----------------------------------------------------------------
--[[ LuaEvents.ActivePlayerTurnStart usage example:

function UpdatePromotions(pUnit, pOwner)
	-- does stuff for each unit, once at the start of the turn
end
LuaEvents.ActivePlayerTurnStart_Unit.Add(UpdatePromotions)

-- also available:
-- LuaEvents.ActivePlayerTurnStart_Turn		()
-- LuaEvents.ActivePlayerTurnStart_Player	(player)
-- LuaEvents.ActivePlayerTurnStart_Unit		(unit)
-- LuaEvents.ActivePlayerTurnStart_City		(city, owner) 
-- LuaEvents.ActivePlayerTurnStart_Plot		(plot)
]]


function OnTurnStart()
	LuaEvents.ActivePlayerTurnStart_Turn()
	for playerID,player in pairs(Players) do
		if IsValidPlayer(player) then
			LuaEvents.ActivePlayerTurnStart_Player(player)
			for pUnit in player:Units() do
				if pUnit then
					LuaEvents.ActivePlayerTurnStart_Unit(pUnit)
				end
			end
			for city in player:Cities() do
				if city then
					LuaEvents.ActivePlayerTurnStart_City(city, player)
				end
			end
		end
	end
	for plotID = 0, Map.GetNumPlots() - 1, 1 do
		local plot = Map.GetPlotByIndex(plotID)
		LuaEvents.ActivePlayerTurnStart_Plot(plot)
		LuaEvents.CheckPlotBuildingsStatus(plot)
	end
end

----------------------------------------------------------------
--[[ Events.ActivePlayerTurnEnd usage example:

function CheckNewBuildingStats(city, player)
	-- does stuff for each city, once at the end of the turn
end
LuaEvents.ActivePlayerTurnEnd_City.Add(CheckNewBuildingStats)

-- also available:
-- LuaEvents.ActivePlayerTurnEnd_Turn	()
-- LuaEvents.ActivePlayerTurnEnd_Player	(player)
-- LuaEvents.ActivePlayerTurnEnd_Unit	(unit)
-- LuaEvents.ActivePlayerTurnEnd_City	(city, owner) 
-- LuaEvents.ActivePlayerTurnEnd_Plot	(plot)
]]

function OnTurnEnd()
	LuaEvents.ActivePlayerTurnEnd_Turn()
	for playerID,player in pairs(Players) do
		MapModData.buildingsAlive[playerID] = MapModData.buildingsAlive[playerID] or {}
		if IsValidPlayer(player) then
			LuaEvents.ActivePlayerTurnEnd_Player(player)
			for pUnit in player:Units() do
				if pUnit then
					LuaEvents.ActivePlayerTurnEnd_Unit(pUnit)
				end
			end
			for city in player:Cities() do
				if city then
					LuaEvents.ActivePlayerTurnEnd_City(city, player)
				end
			end
		end
	end
	for plotID = 0, Map.GetNumPlots() - 1, 1 do
		local plot = Map.GetPlotByIndex(plotID)
		LuaEvents.ActivePlayerTurnStart_Plot(plot)
		LuaEvents.CheckPlotBuildingsStatus(plot)
	end
end

----------------------------------------------------------------
--[[ These run a single time when a city is founded

LuaEvents.CityFounded.Add(CityCreatedChecks)
]]

function OnNewCity(hexPos, playerID, cityID, cultureType, eraType, continent, populationSize, size, fowState)
	if MapModData.VEM.Initialized then
		LuaEvents.CityFounded(hexPos, playerID, cityID, cultureType, eraType, continent, populationSize, size, fowState)
	end
end

----------------------------------------------------------------
--[[ LuaEvents.UnitSpawned runs a single time when the unit is created

function UnitCreatedChecks( playerID, unitID, hexVec, unitType, cultureType, civID, primaryColor, secondaryColor, unitFlagIndex, fogState, selected, military, notInvisible )
	-- do stuff
end

LuaEvents.UnitSpawned.Add(UnitCreatedChecks)
]]

if not MapModData.VEM.UnitCreated then
	MapModData.VEM.UnitCreated = {}
	for playerID, player in pairs(Players) do
		MapModData.VEM.UnitCreated[playerID] = {}
		for unit in player:Units() do
			MapModData.VEM.UnitCreated[playerID][unit:GetID()] = true
		end
	end
end

function OnNewUnit(playerID, unitID, hexVec, unitType, cultureType, civID, primaryColor, secondaryColor, unitFlagIndex, fogState, selected, military, notInvisible)
	if MapModData.VEM.Initialized then
		local unit = Players[playerID]:GetUnitByID(unitID)
		if not MapModData.VEM.UnitCreated[playerID][unitID] then
			MapModData.VEM.UnitCreated[playerID][unitID] = true
			LuaEvents.UnitSpawned(playerID, unitID, hexVec, unitType, cultureType, civID, primaryColor, secondaryColor, unitFlagIndex, fogState, selected, military, notInvisible)
		end
	end
end


---------------------------------------------------------------------
--[[ LuaEvents.PlotAcquired(plot, newOwnerID) usage example:

]]

if not MapModData.VEM.PlotOwner then
	MapModData.VEM.PlotOwner = {}
	for plotID = 0, Map.GetNumPlots() - 1, 1 do
		local plot = Map.GetPlotByIndex(plotID)
		--if plot:GetOwner() ~= -1 then
			--log:Warn("Loading PlotOwner %s", plotID)
			MapModData.VEM.PlotOwner[plotID] = plot:GetOwner() --LoadPlot(plot, "PlotOwner")
		--end
	end
end

function OnHexCultureChanged(hexX, hexY, newOwnerID, unknown)
	local plot = Map.GetPlot(ToGridFromHex(hexX, hexY))
	local plotID = Plot_GetID(plot)
	--log:Warn("OnHexCultureChanged old=%s new=%s", MapModData.VEM.PlotOwner[plotID], newOwnerID)
	if newOwnerID ~= MapModData.VEM.PlotOwner[plotID] then
		MapModData.VEM.PlotOwner[plotID] = newOwnerID
		--SavePlot(plot, "PlotOwner", newOwnerID)
		--log:Warn("PlotAcquired")
		LuaEvents.PlotAcquired(plot, newOwnerID)
	end
end

---------------------------------------------------------------------
--[[ LuaEvents.PolicyAdopted(player, policyID) usage example:

function CheckFreeBuildings(player, policyID)
	-- check for buildings affected by the new policy
end

LuaEvents.ActivePlayerTurnEnd_Player.Add( CheckFreeBuildings )
LuaEvents.PolicyAdopted.Add( CheckFreeBuildings )	
]]

Events.PolicyAdopted = Events.PolicyAdopted or function(policyID, isPolicy)
	log:Info("TriggerPolicyAdopted %s %s", policyID, isPolicy)
	if not isPolicy then
		policyID = GameInfo.Policies[GameInfo.PolicyBranchTypes[policyID].FreePolicy].ID
	end
	LuaEvents.PolicyAdopted(Players[Game.GetActivePlayer()], policyID)
end


---------------------------------------------------------------------
--[[ LuaEvents.UnitExperienceChange(unit, experience) usage example:

]]
--LuaEvents.UnitExperienceChange = LuaEvents.UnitExperienceChange or function(unit, oldXP, newXP) end

if not MapModData.VEM.UnitXP then
	MapModData.VEM.UnitXP = {}
	for playerID,player in pairs(Players) do
		if IsValidPlayer(player) then
			MapModData.VEM.UnitXP[playerID] = {}
			local initializedXP = false
			if not player:IsMinorCiv() then
				for policyInfo in GameInfo.Policies("GarrisonedExperience != 0") do
					if player:HasPolicy(policyInfo.ID) then
						initializedXP = true
						for unit in player:Units() do
							--log:Debug("Loading UnitXP %s", unit:GetName())
							MapModData.VEM.UnitXP[playerID][unit:GetID()] = (MapModData.VEM.UnitXP[playerID][unit:GetID()] or 0) + (LoadUnit(unit, "unitXP") or 0)
						end
					end
				end
			end
			if not initializedXP then
				for unit in player:Units() do
					MapModData.VEM.UnitXP[playerID][unit:GetID()] = unit:GetExperience()
				end
			end		
		end
	end
end


Events.EndCombatSim.Add( CheckCombatLevelup )

---------------------------------------------------------------------
--[[ GetBranchFinisherID(policyBranchType) usage example:

]]
function GetBranchFinisherID(policyBranchType)
	return GameInfo.Policies[GameInfo.PolicyBranchTypes[policyBranchType].FreeFinishingPolicy].ID
end

---------------------------------------------------------------------
--[[ GetItemName(itemTable, itemTypeOrID) usage example:

]]
function GetName(itemInfo, itemTable)
	if itemTable then
		itemInfo = itemTable[itemInfo]
	end
	return Locale.ConvertTextKey(itemInfo.Description)
end

---------------------------------------------------------------------
--[[ HasFinishedBranch(player, policyBranchType, newPolicyID) usage example:

]]
function HasFinishedBranch(player, policyBranchType, newPolicyID)
	local branchFinisherID = GetBranchFinisherID(policyBranchType)
	if player:HasPolicy(branchFinisherID) then
		return true
	end

	for policyInfo in GameInfo.Policies(string.format("PolicyBranchType = '%s' AND ID != '%s'", policyBranchType, branchFinisherID)) do
		if (newPolicyID ~= policyInfo.ID) and not player:HasPolicy(policyInfo.ID) then
			return false
		end
	end
	log:Debug("%s finished %s", player:GetName(), policyBranchType)
	return true
end

---------------------------------------------------------------------
--[[ LuaEvents.CityOccupied(city, player) usage example:

]]
Events.CityOccupied = Events.CityOccupied or function(city, player, isForced)
	LuaEvents.CityOccupied(city, player, isForced)
end

Events.CityPuppeted = Events.CityPuppeted or function(city, player, isForced)
	LuaEvents.CityPuppeted(city, player, isForced)
end

Events.CityLiberated = Events.CityLiberated or function(city, player, isForced)
	LuaEvents.CityLiberated(city, player, isForced)
end

---------------------------------------------------------------------
--[[ LuaEvents.PromotionEarned(city, player) usage example:

]]
Events.PromotionEarned = Events.PromotionEarned or function(unit, promotionType)
	--log:Warn("PromotionEarned")
	LuaEvents.PromotionEarned(unit, promotionType)
end

Events.UnitUpgraded = Events.UnitUpgraded or function(unit)
	LuaEvents.UnitUpgraded(unit)
end

----------------------------------------------------------------
--[[ CheckPlotBuildingsStatus(plot) usage example:

]]


if not MapModData.buildingsAlive then
	MapModData.buildingsAlive = {}
	for plotID = 0, Map.GetNumPlots() - 1, 1 do
		MapModData.buildingsAlive[plotID] = {}
	end
	for playerID,player in pairs(Players) do
		for city in player:Cities() do
			for buildingInfo in GameInfo.Buildings() do
				--log:Info("Loading buildingsAlive %15s %20s = %s", city:GetName(), GetName(buildingInfo), city:IsHasBuilding(buildingInfo.ID))
				MapModData.buildingsAlive[City_GetID(city)][buildingInfo.ID] = city:IsHasBuilding(buildingInfo.ID)
			end
		end
	end
end

function OnBuildingConstructed(player, city, buildingID)
	log:Info("%25s %15s %15s %30s %s", "BuildingConstructed", player:GetName(), city:GetName(), GameInfo.Buildings[buildingID].Type, MapModData.buildingsAlive[City_GetID(city)])
	local cityID = City_GetID(city)
	MapModData.buildingsAlive[cityID] = MapModData.buildingsAlive[cityID] or {}
	MapModData.buildingsAlive[cityID][buildingID] = true
end

function OnBuildingDestroyed(player, city, buildingID)
	local buildingInfo = GameInfo.Buildings[buildingID]
	if buildingInfo.OneShot then
		return
	end
	log:Info("%25s %15s %15s %30s %s", "BuildingDestroyed", player:GetName(), city:GetName(), buildingInfo.Type, MapModData.buildingsAlive[City_GetID(city)])
	local cityID = City_GetID(city)
	MapModData.buildingsAlive[cityID] = MapModData.buildingsAlive[cityID] or {}
	MapModData.buildingsAlive[cityID][buildingID] = false
	if MapModData.VEM.FreeFlavorBuilding then
		for flavorInfo in GameInfo.Flavors() do
			if buildingID == MapModData.VEM.FreeFlavorBuilding[flavorInfo.Type][cityID] then
				MapModData.VEM.FreeFlavorBuilding[flavorInfo.Type][cityID] = false
				SaveValue(false, "MapModData.VEM.FreeFlavorBuilding[%s][%s]", flavorInfo.Type, cityID)
			end
		end
	end
end


LuaEvents.CheckPlotBuildingsStatus = function(plot)
	if plot == nil then
		log:Fatal("CheckPlotBuildingsStatus plot=nil")
		return
	end
	local plotID = Plot_GetID(plot)
	local city = plot:GetPlotCity()
	if city then
		local player = Players[city:GetOwner()]
		MapModData.buildingsAlive[plotID] = MapModData.buildingsAlive[plotID] or {}
		for buildingInfo in GameInfo.Buildings() do
			local buildingID = buildingInfo.ID
			if city:IsHasBuilding(buildingID) and not MapModData.buildingsAlive[plotID][buildingID] then
				LuaEvents.BuildingConstructed(player, city, buildingID)
			end
			if not city:IsHasBuilding(buildingID) and MapModData.buildingsAlive[plotID][buildingID] then
				LuaEvents.BuildingDestroyed(player, city, buildingID)
			end
		end
	else
		if MapModData.buildingsAlive[plotID] then
			for buildingID,status in pairs(MapModData.buildingsAlive[plotID]) do
				log:Info("%25s %15s %15s %30s %s", "BuildingDestroyed", "empty plot", " ", GameInfo.Buildings[buildingID].Type, MapModData.buildingsAlive[City_GetID(city)])
				MapModData.buildingsAlive[plotID][buildingID] = false
				--SaveValue(false, "MapModData.buildingsAlive[%s][%s]", plotID, buildingID)
			end
			MapModData.buildingsAlive[plotID] = false
		end
	end
end

function OnCityDestroyed(hexPos, playerID, cityID, newPlayerID)
	LuaEvents.CheckPlotBuildingsStatus(Map.GetPlot(ToGridFromHex(hexPos.x, hexPos.y)))
end