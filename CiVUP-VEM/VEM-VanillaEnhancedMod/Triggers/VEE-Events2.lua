-- Example events
-- Author: veyDer
--------------------------------------------------------------

include("UserEvents")

--[[ Wandering Wiseman ]]--
function WanderingWisemanCond( player, city, unit, plot )
 	return city and city:IsCapital() and plot:IsCity()
end

function WanderingWisemanCond1( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
		ncounter = 1
	elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
		ncounter = 2
	elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
		ncounter = 3
	elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
		ncounter = 4
	elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
		ncounter = 5
	elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
		ncounter = 6
	else
		ncounter = 7
	end
	return WanderingWisemanCond( player, city, unit, plot ) and player:GetGold() >= (200 + ncounter*50) 
end
function WanderingWisemanCond2( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
		ncounter = 1
	elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
		ncounter = 2
	elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
		ncounter = 3
	elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
		ncounter = 4
	elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
		ncounter = 5
	elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
		ncounter = 6
	else
		ncounter = 7
	end
	return WanderingWisemanCond( player, city, unit, plot ) and player:GetGold() >= (100 + ncounter*25) 
end

function WanderingWisemanNoEffect( player, city, unit, plot )
	_UserEventMessage( "TXT_KEY_USER_EVENT_WANDERING_SEER_EFFECT_NONE", player, city, unit, plot )
--	print("Event ID: Wiseman none")
end

function WanderingWisemanEffect1( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
		ncounter = 1
	elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
		ncounter = 2
	elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
		ncounter = 3
	elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
		ncounter = 4
	elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
		ncounter = 5
	elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
		ncounter = 6
	else
		ncounter = 7
	end
	player:ChangeGold( - (200 + ncounter*50) )
	_AddNewUnit( player, "UNIT_SCIENTIST", plot:GetX(), plot:GetY() )
	_UserEventMessage( "TXT_KEY_USER_EVENT_WANDERING_SEER_EFFECT1", player, city, unit, plot )
--	print("Event ID: Wiseman effect1")
end

function WanderingWisemanEffect2( player, city, unit, plot )
	local mera	= player:GetCurrentEra() 
	local mcounter = 0
	if mera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
		mcounter = 1
	elseif mera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
		mcounter = 2
	elseif mera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
		mcounter = 3
	elseif mera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
		mcounter = 4
	elseif mera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
		mcounter = 5
	elseif mera == GameInfo.Eras[ "ERA_MODERN" ].ID then
		mcounter = 6
	else
		mcounter = 7
	end
	player:ChangeGold ( - (100 + mcounter*25) )
	local res	= math.random( 0, 99 )
	if res < 35 then
		local nera	= player:GetCurrentEra() 
		local ncounter = 0
		if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
			ncounter = 40
		elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
			ncounter = 70
		elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
			ncounter = 122
		elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
			ncounter = 214
		elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
			ncounter = 375
		elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
			ncounter = 656
		else
			ncounter = 1148
		end
		player:GetCurrentCultureBonus(ncounter)
		_UserEventMessage( "TXT_KEY_USER_EVENT_WANDERING_SEER_EFFECT2A", player, city, unit, plot )
--		print("Event ID: Wiseman effect2A")
	elseif res < 40 then
		player:SetNumFreeTechs( 1 )
		_UserEventMessage( "TXT_KEY_USER_EVENT_WANDERING_SEER_EFFECT2B", player, city, unit, plot )
--		print("Event ID: Wiseman effect2B")
		Events.SerialEventGameMessagePopup( {	Type	= ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH,
												Data1	= player,
												Data3	= -1
											} )

	elseif res < 60 then
		local tech = player:GetCurrentResearch()
		_PlayerSetTech( player, tech, true )
		_UserEventMessage( "TXT_KEY_USER_EVENT_WANDERING_SEER_EFFECT2C", player, city, unit, plot )
--		print("Event ID: Wiseman effect2C")
		Events.SerialEventGameMessagePopup( {	Type	= ButtonPopupTypes.BUTTONPOPUP_CHOOSETECH,
												Data1	= player,
												Data3	= tech
											} )
	elseif res < 95 then
		local turns	= math.random( 2, 4 )
		player:ChangeGoldenAgeTurns( turns )
		_UserEventMessage( "TXT_KEY_USER_EVENT_WANDERING_SEER_EFFECT2D", player, city, unit, plot )
--		_UserEventMessage( "TXT_KEY_USER_EVENT_WANDERING_SEER_EFFECT2D", turns ) )
--		print("Event ID: Wiseman effect2D")
	else
		_UserEventMessage( "TXT_KEY_USER_EVENT_WANDERING_SEER_EFFECT2E", player, city, unit, plot )
--		print("Event ID: Wiseman effect2E")
	end
end
UserEventAdd{
	id			= "WANDERING_SEER",
	probability	= 0.003,
	options		= {
		OPTION1 = { order = 1, condition = WanderingWisemanCond1, effect = WanderingWisemanEffect1, flavor1 = "FLAVOR_GROWTH", flavor2 = "FLAVOR_SCIENCE" },
		OPTION2 = { order = 2, condition = WanderingWisemanCond2, effect = WanderingWisemanEffect2, flavor1 = "FLAVOR_SCIENCE", flavor2 = "FLAVOR_SCIENCE" },
		OPTION3 = { order = 3, condition = WanderingWisemanCond, effect = WanderingWisemanNoEffect, flavor1 = "FLAVOR_GOLD", flavor2 = "FLAVOR_GROWTH" },
	}
}
--[[ / Wandering Wiseman ]]--

--[[ Builder ]]--
function BuilderCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only if the player has knowledge of Construction
	if pTeam:IsHasTech(GameInfoTypes.TECH_CONSTRUCTION) then
		return city and city:IsCapital() and plot:IsCity()
	end
end

function BuilderCond1( player, city, unit, plot )
local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
			ncounter = 1
		elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
			ncounter = 2
		elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
			ncounter = 3
		elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
			ncounter = 4
		elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
			ncounter = 5
		elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
			ncounter = 6
		else
			ncounter = 7
	end
	local goldneeded = ( 125 * ncounter )
	return BuilderCond( player, city, unit, plot ) and player:GetGold() >= goldneeded
end
function BuilderCond2( player, city, unit, plot )
local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
			ncounter = 1
		elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
			ncounter = 2
		elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
			ncounter = 3
		elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
			ncounter = 4
		elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
			ncounter = 5
		elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
			ncounter = 6
		else
			ncounter = 7
	end
	local goldneeded = ( 75 * ncounter )
	return BuilderCond( player, city, unit, plot ) and player:GetGold() >= goldneeded
end

function BuilderNoEffect( player, city, unit, plot )
	for ncity in player:Cities() do
		ncity:ChangeProduction(ncity:GetYieldRate(GameInfo.Yields[ "YIELD_PRODUCTION" ].ID)*1)
	end
	_UserEventMessage("TXT_KEY_USER_EVENT_BUILDER_EFFECT_NONE", player, city, unit, plot )
--	print("Event ID: builder effect none")
end

function BuilderEffect1( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
			ncounter = 1
		elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
			ncounter = 2
		elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
			ncounter = 3
		elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
			ncounter = 4
		elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
			ncounter = 5
		elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
			ncounter = 6
		else
			ncounter = 7
	end
	player:ChangeGold ( - 125 * ncounter )
	
	for ncity in player:Cities() do
		ncity:ChangeProduction(ncity:GetYieldRate(GameInfo.Yields[ "YIELD_PRODUCTION" ].ID)*5)
	end
	_UserEventMessage("TXT_KEY_USER_EVENT_BUILDER_EFFECT1", player, city, unit, plot )
--	print("Event ID: builder effect1")
end

function BuilderEffect2( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
			ncounter = 1
		elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
			ncounter = 2
		elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
			ncounter = 3
		elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
			ncounter = 4
		elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
			ncounter = 5
		elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
			ncounter = 6
		else
			ncounter = 7
	end
	player:ChangeGold ( - 75 * ncounter )
	
	for ncity in player:Cities() do
		ncity:ChangeProduction(ncity:GetYieldRate(GameInfo.Yields[ "YIELD_PRODUCTION" ].ID)*3)
	end
	_UserEventMessage("TXT_KEY_USER_EVENT_BUILDER_EFFECT2", player, city, unit, plot )
--	print("Event ID: builder effect2")
end
UserEventAdd{
	id			= "BUILDER",
	probability	= 0.003,
	options		= {
		OPTION1 = { order = 1, condition = BuilderCond1, effect = BuilderEffect1, flavor1 = "FLAVOR_GROWTH", flavor2 = "FLAVOR_GROWTH" },
		OPTION2 = { order = 2, condition = BuilderCond2, effect = BuilderEffect2, flavor1 = "FLAVOR_GROWTH", flavor2 = "FLAVOR_GOLD" },
		OPTION3 = { order = 3, condition = BuilderCond, effect = BuilderNoEffect, flavor1 = "FLAVOR_GOLD", flavor2 = "FLAVOR_GOLD" },
	}
}
--[[ / Builder ]]--

--[[ Artist ]]--
function ArtistCond( player, city, unit, plot )
	return city and plot:IsCity()
end

function ArtistCond1( player, city, unit, plot )
	return ArtistCond( player, city, unit, plot ) and player:GetGold() >= (150)
end
function ArtistCond2( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only if the player has vertain combinations of buildings and techs
	if pTeam:IsHasTech(GameInfoTypes.TECH_AGRICULTURE) then
		return ArtistCond( player, city, unit, plot ) and (
		( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MONUMENT" ].ID ) ~= 1 ) or
		( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MONUMENT" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_TEMPLE"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_PHILOSOPHY) ) or
		( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_TEMPLE" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_OPERA_HOUSE"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_ACOUSTICS) ) or
		( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_OPERA_HOUSE" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MUSEUM"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_ARCHAEOLOGY) ) or
		( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_TEMPLE" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_OPERA_HOUSE"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_ACOUSTICS) ) or
		( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MUSEUM" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_BROADCAST_TOWER"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_RADIO) ) )
		and player:GetGold() >= 300
	end
end

function ArtistNoEffect( player, city, unit, plot )
	city:DoJONSCultureLevelIncrease()
	_UserEventMessage("TXT_KEY_USER_EVENT_ARTIST_EFFECT_NONE", player, city, unit, plot )
--	print("Event ID: Artist none")
end

function ArtistEffect1( player, city, unit, plot )
	city:DoJONSCultureLevelIncrease()
	city:DoJONSCultureLevelIncrease()
	city:DoJONSCultureLevelIncrease()
	player:ChangeGold(-150)
	_UserEventMessage("TXT_KEY_USER_EVENT_ARTIST_EFFECT1", player, city, unit, plot )
--	print("Event ID: Artist effect1")
end

function ArtistEffect2( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only if the player has vertain combinations of buildings and techs
	if (  city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MONUMENT" ].ID ) ~= 1 ) then
		city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MONUMENT" ].ID, 1 )
	elseif ( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MONUMENT" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_TEMPLE"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_PHILOSOPHY) ) then
		city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_TEMPLE"].ID, 1 )
	elseif ( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_TEMPLE" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_OPERA_HOUSE"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_ACOUSTICS) ) then
		city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_OPERA_HOUSE"].ID, 1 )
	elseif ( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_OPERA_HOUSE" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MUSEUM"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_ARCHAEOLOGY) ) then
		city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MUSEUM"].ID, 1 )
	elseif ( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_TEMPLE" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_OPERA_HOUSE"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_ACOUSTICS) ) then
		city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_OPERA_HOUSE"].ID, 1 )
	elseif ( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MUSEUM" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_BROADCAST_TOWER"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_RADIO) ) then
		city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_BROADCAST_TOWER"].ID, 1 )	
end	
	player:ChangeGold(-300)
	_UserEventMessage( "TXT_KEY_USER_EVENT_ARTIST_EFFECT2", player, city, unit, plot )
--	print("Event ID: Artist effect2")
end
UserEventAdd{
	id			= "ARTIST",
	probability	= 0.003,
	options		= {
		OPTION1 = { order = 1, condition = ArtistCond1, effect = ArtistEffect1, flavor1 = "FLAVOR_GROWTH", flavor2 = "FLAVOR_CULTURE" },
		OPTION2 = { order = 2, condition = ArtistCond2, effect = ArtistEffect2, flavor1 = "FLAVOR_CULTURE", flavor2 = "FLAVOR_CULTURE" },
		OPTION3 = { order = 3, condition = ArtistCond, effect = ArtistNoEffect, flavor1 = "FLAVOR_GOLD", flavor2 = "FLAVOR_GOLD" },
	}
}
--[[ / Artist ]]--

--[[ New Spring ]]--
function NewSpringCond( player, city, unit, plot )
	return city and plot:GetTerrainType() == GameInfo.Terrains[ "TERRAIN_DESERT" ].ID 
	and not plot:IsCity() and plot:GetFeatureType() == -1 and plot:GetResourceType() == -1 and plot:IsFlatlands()
end
function NewSpringEffect( player, city, unit, plot )
	plot:SetFeatureType( GameInfo.Features[ "FEATURE_OASIS" ].ID )
	_UserEventMessage( "TXT_KEY_USER_EVENT_NEW_SPRING_EFFECT", player, city, unit, plot )
--	print("Event ID: New Spring effect")
end
UserEventAdd{
	id			= "NEW_SPRING",
	probability	= 0.002,
	options		= {
		OPTION1	= { order	= 1, condition	= NewSpringCond, effect	= NewSpringEffect }
		}
}
--[[ / New Spring ]]--

--[[ NewMineral ]]--
function NewMineralCond( player, city, unit, plot )
	return plot and not plot:IsCity() and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID 
	and plot:GetResourceType() == -1
end
function NewMineralEffect( player, city, unit, plot )
	local nvalidmineral = false
	local nmineral = math.random( 1, 11 )
	while (nvalidmineral == false) do
		nmineral = math.random( 1, 11 )
		nvalidmineral = true
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
		if 	( nmineral == 7 and not pTeam:IsHasTech(GameInfoTypes.TECH_ATOMIC_THEORY) ) or 
			( nmineral == 6 and not pTeam:IsHasTech(GameInfoTypes.TECH_ELECTRICITY) ) or 
			( nmineral == 5 and not pTeam:IsHasTech(GameInfoTypes.TECH_SCIENTIFIC_THEORY) ) then
				nvalidmineral = false
		end
	end
	local namount = math.random( 2, 5 )
	if (nmineral == 1 or nmineral == 8 or nmineral == 9 ) then
		plot:SetImprovementType( -1 )
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_IRON" ].ID, namount) 
		plot:SetImprovementType(  GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID )
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWMINERAL_EFFECT1", player, city, unit, plot )
--		print("Event ID: New Mineral effect1")
	end
	if nmineral == 2 then
		plot:SetImprovementType( -1 )
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_GOLD" ].ID, 1) 
		plot:SetImprovementType(  GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID )
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWMINERAL_EFFECT2", player, city, unit, plot )
--		print("Event ID: New Mineral effect2")
	end
	if nmineral == 3 then
		plot:SetImprovementType( -1 )
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_SILVER" ].ID, 1) 
		plot:SetImprovementType(  GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID )
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWMINERAL_EFFECT3", player, city, unit, plot )
--		print("Event ID: New Mineral effect3")
	end
	if nmineral == 4 then
		plot:SetImprovementType( -1 )
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_GEMS" ].ID, 1) 
		plot:SetImprovementType(  GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID )
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWMINERAL_EFFECT4", player, city, unit, plot )
--		print("Event ID: New Mineral effect4")
	end
	if (nmineral == 5 or nmineral == 10 or nmineral == 11 ) then
		plot:SetImprovementType( -1 )
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_COAL" ].ID, namount) 
		plot:SetImprovementType(  GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID )
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWMINERAL_EFFECT5", player, city, unit, plot )
--		print("Event ID: New Mineral effect5")
	end
	if nmineral == 6 then
		plot:SetImprovementType( -1 )
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_ALUMINIUM" ].ID, namount) 
		plot:SetImprovementType(  GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID )
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWMINERAL_EFFECT6", player, city, unit, plot )
--		print("Event ID: New Mineral effect6")
	end
	if nmineral == 7 then
		plot:SetImprovementType( -1 )
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_URANIUM" ].ID, namount) 
		plot:SetImprovementType(  GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID )
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWMINERAL_EFFECT7", player, city, unit, plot )
--		print("Event ID: New Mineral effect7")
	end	
end
UserEventAdd{
	id			= "NEWMINERAL",
	probability	= 0.003,
	options		= {
		OPTION1	= { order	= 1, condition	= NewMineralCond, effect	= NewMineralEffect }
		}
}
--[[ / NewMineral ]]--

--[[ NewPlant ]]--
function NewPlantCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on flat tiles with plains/grass and without resources. Furthermore the player must have knowledge of the tech Calendar
	if pTeam:IsHasTech(GameInfoTypes.TECH_CALENDAR) then
		return plot and not plot:IsCity() and plot:GetResourceType() == -1 and ( plot:GetTerrainType() == GameInfo.Terrains[ "TERRAIN_PLAINS" ].ID or plot:GetTerrainType() == GameInfo.Terrains[ "TERRAIN_GRASS" ].ID ) 
		and	plot:GetImprovementType() == -1	and plot:IsFlatlands()
	end
end
function NewPlantEffect( player, city, unit, plot )
	local nvalidplant = false
	local nplant = math.random( 1, 8 )
	while (nvalidplant == false) do
		nplant = math.random( 1, 8 )
		nvalidplant = true
		if 	( ( nplant == 1 and not plot:CanHaveResource( GameInfo.Resources[ "RESOURCE_BANANA" ].ID, true) ) or 
			  ( nplant == 2 and not plot:CanHaveResource( GameInfo.Resources[ "RESOURCE_DYE" ].ID, true) ) or 
			  ( nplant == 3 and not plot:CanHaveResource( GameInfo.Resources[ "RESOURCE_SPICES" ].ID, true) ) or 
			  ( nplant == 4 and not plot:CanHaveResource( GameInfo.Resources[ "RESOURCE_SILK" ].ID, true) ) or 
			  ( nplant == 5 and not plot:CanHaveResource( GameInfo.Resources[ "RESOURCE_SUGAR" ].ID, true) ) or 
			  ( nplant == 6 and not plot:CanHaveResource( GameInfo.Resources[ "RESOURCE_COTTON" ].ID, true) ) or 
			  ( nplant == 7 and not plot:CanHaveResource( GameInfo.Resources[ "RESOURCE_WINE" ].ID, true) ) or 
			  ( nplant == 8 and not plot:CanHaveResource( GameInfo.Resources[ "RESOURCE_INCENSE" ].ID, true) ) ) then
			nvalidplant = false
		end
	end
	if nplant == 1 then
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_BANANA" ].ID, 1) 
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWPLANT_EFFECT1", player, city, unit, plot )
--		print("Event ID: New Plant effect1")
	end	
	if nplant == 2 then
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_DYE" ].ID, 1) 
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWPLANT_EFFECT2", player, city, unit, plot )
--		print("Event ID: New Plant effect2")
	end	
	if nplant == 3 then
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_SPICES" ].ID, 1) 
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWPLANT_EFFECT3", player, city, unit, plot )
--		print("Event ID: New Plant effect3")
	end	
	if nplant == 4 then
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_SILK" ].ID, 1) 
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWPLANT_EFFECT4", player, city, unit, plot )
--		print("Event ID: New Plant effect4")
	end	
	if nplant == 5 then
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_SUGAR" ].ID, 1) 
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWPLANT_EFFECT5", player, city, unit, plot )
--		print("Event ID: New Plant effect5")
	end	
	if nplant == 6 then
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_COTTON" ].ID, 1) 
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWPLANT_EFFECT6", player, city, unit, plot )
--		print("Event ID: New Plant effect6")
	end	
	if nplant == 7 then
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_WINE" ].ID, 1) 
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWPLANT_EFFECT7", player, city, unit, plot )
--		print("Event ID: New Plant effect7")
	end
	if nplant == 8 then
		plot:SetResourceType( GameInfo.Resources[ "RESOURCE_INCENSE" ].ID, 1) 
		_UserEventMessage( "TXT_KEY_USER_EVENT_NEWPLANT_EFFECT8", player, city, unit, plot )
--		print("Event ID: New Plant effect8")
	end	
end
UserEventAdd{
	id			= "NEWPLANT",
	probability	= 0.003,
	options		= {
		OPTION1	= { order	= 1, condition	= NewPlantCond, effect	= NewPlantEffect }
		}
}
--[[ / NewPlant ]]--

--[[ Parrots ]]--
function ParrotsCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on tiles with jungle. Furthermore the player must have knowledge of the tech Animal Husbandry
	if pTeam:IsHasTech(GameInfoTypes.TECH_ANIMAL_HUSBANDRY) then
		return city and plot:GetFeatureType() == GameInfo.Features[ "FEATURE_JUNGLE" ].ID
	end
end
function ParrotsEffect( player, city, unit, plot )
	Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), GameInfo.Yields[ "YIELD_GOLD" ].ID, 2)
	_UserEventMessage( "TXT_KEY_USER_EVENT_PARROTS_EFFECT", player, city, unit, plot )
--	print("Event ID: Parrots")
end
UserEventAdd{
    id			= "PARROTS",
	probability	= 0.004,
	options		= {
		OPTION1 = {	order	= 1, condition	= ParrotsCond, effect	= ParrotsEffect },
		}
}
--[[ / Parrots ]]--

--[[ RareHerbs ]]--
function RareHerbsCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on tiles with marsh. Furthermore the player must have knowledge of the tech Education
	if pTeam:IsHasTech(GameInfoTypes.TECH_EDUCATION) then
		return city and plot:GetFeatureType() == GameInfo.Features[ "FEATURE_MARSH" ].ID
	end
end
function RareHerbsEffect( player, city, unit, plot )
	Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), GameInfo.Yields[ "YIELD_FOOD" ].ID, 1)
	Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), GameInfo.Yields[ "YIELD_GOLD" ].ID, 1)
	_UserEventMessage( "TXT_KEY_USER_EVENT_RAREHERBS_EFFECT", player, city, unit, plot )
--	print("Event ID: Rare herbs")
end
UserEventAdd{
    id			= "RAREHERBS",
	probability	= 0.004,
	options		= {
		OPTION1 = {	order	= 1, condition	= RareHerbsCond, effect	= RareHerbsEffect },
		}
}
--[[ / RareHerbs ]]--

--[[ Fertile Soil ]]--
function FertileSoilCond( player, city, unit, plot )
	return city and
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_FARM" ].ID and
	(plot:GetFeatureType() == GameInfo.Features[ "FEATURE_FLOOD_PLAINS" ].ID or
	plot:GetTerrainType() == GameInfo.Terrains[ "TERRAIN_PLAINS" ].ID or 
	plot:GetTerrainType() == GameInfo.Terrains[ "TERRAIN_GRASS" ].ID ) and
	plot:IsFlatlands() and plot:GetResourceType() == -1
end
function FertileSoilEffect( player, city, unit, plot )
	plot:SetResourceType( GameInfo.Resources[ "RESOURCE_WHEAT" ].ID, 1)
	_UserEventMessage( "TXT_KEY_USER_EVENT_FERTILESOIL_EFFECT", player, city, unit, plot )
--	print("Event ID: Fertile soils")
end
UserEventAdd{
    id			= "FERTILESOIL",
	probability	= 0.005,
		options		= {
		OPTION1 = {	order	= 1, condition	= FertileSoilCond, effect	= FertileSoilEffect },
		}
}
--[[ / Fertile Soil ]]--

--[[ Holiday Resort ]]--
function ResortCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on tiles with atoll. Furthermore the player must have knowledge of the tech Compass
	if pTeam:IsHasTech(GameInfoTypes.TECH_COMPASS) then
		return city and plot:GetFeatureType() == GameInfo.Features[ "FEATURE_ATOLL" ].ID
	end
end
function ResortEffect( player, city, unit, plot )
	Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), GameInfo.Yields[ "YIELD_GOLD" ].ID, 1)
	_UserEventMessage( "TXT_KEY_USER_EVENT_RESORT_EFFECT", player, city, unit, plot )
--	print("Event ID: Resort")
end
UserEventAdd{
    id			= "RESORT",
	probability	= 0.003,
	options		= {
		OPTION1 = {	order	= 1, condition	= ResortCond, effect	= ResortEffect },
		}
}
--[[ / Holiday Resort ]]--

--[[ Minerals ]]--
function MineralsCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on tiles with mines. Furthermore the player must have knowledge of the tech Mining
	if pTeam:IsHasTech(GameInfoTypes.TECH_MINING) then
		return city and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID
	end
end
function MineralsEffect( player, city, unit, plot )
	Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), GameInfo.Yields[ "YIELD_PRODUCTION" ].ID, 1)
	_UserEventMessage( "TXT_KEY_USER_EVENT_MINERALS_EFFECT", player, city, unit, plot )
--	print("Event ID: Minerals")
end
UserEventAdd{
    id			= "MINERALS",
	probability	= 0.005,
	options		= {
		OPTION1 = {	order	= 1, condition	= MineralsCond, effect	= MineralsEffect },
		}
}
--[[ / Minerals ]]--

--[[ Tradecenter ]]--
function TradecenterCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on tiles with trading posts. Furthermore the player must have knowledge of the tech Banking
	if pTeam:IsHasTech(GameInfoTypes.TECH_BANKING) then
		return city and
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_TRADING_POST" ].ID
	end
end
function TradecenterEffect( player, city, unit, plot )
	plot:SetImprovementType(17) 
	_UserEventMessage( "TXT_KEY_USER_EVENT_TRADECENTER_EFFECT", player, city, unit, plot )
--	print("Event ID: Trade center")
end
UserEventAdd{
    id			= "TRADECENTER",
	probability	= 0.003,
	options		= {
		OPTION1 = {	order	= 1, condition	= TradecenterCond, effect	= TradecenterEffect },
		}
}
--[[ / Tradecenter ]]--

--[[ Renown ]]--
function RenownCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on tiles with an Academy, citadel, manufactory, Customs House or Landmark. Furthermore the player must have knowledge of the tech Philosophy
	if pTeam:IsHasTech(GameInfoTypes.TECH_PHILOSOPHY) then
		return city 
		and (plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_ACADEMY" ].ID 
		or plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_CITADEL" ].ID 
		or plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MANUFACTORY" ].ID 
		or plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_CUSTOMS_HOUSE" ].ID 
		or plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_LANDMARK" ].ID )
	end
end
function RenownEffect( player, city, unit, plot )
	plot:ChangeCulture(4)
	_UserEventMessage( "TXT_KEY_USER_EVENT_RENOWN_EFFECT", player, city, unit, plot )
--	print("Event ID: Renown")
end
UserEventAdd{
    id			= "RENOWN",
	probability	= 0.004,
	options		= {
		OPTION1 = {	order	= 1, condition	= RenownCond, effect	= RenownEffect },
		}
}
--[[ / Renown ]]--

--[[ Tornado ]]--
function TornadoCond( player, city, unit, plot )
	return city 
	and not plot:IsImprovementPillaged() and
	(plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_PLANTATION" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_FARM" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_TERRACE_FARM" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_QUARRY" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_TRADING_POST" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_LUMBERMILL" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_PASTURE" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_CAMP" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_WELL" ].ID or
	plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_FORT" ].ID )
end
function TornadoEffect( player, city, unit, plot )
	plot:SetImprovementPillaged(true)
	_UserEventMessage( "TXT_KEY_USER_EVENT_TORNADO_EFFECT", player, city, unit, plot )
--	print("Event ID: Tornado")
end
UserEventAdd{
    id			= "TORNADO",
	probability	= 0.004,
	options		= {
		OPTION1 = {	order	= 1, condition	= TornadoCond, effect	= TornadoEffect },
		}
}
--[[ / Tornado ]]--

--[[ Meteor ]]--
--function MeteorCond( player, city, unit, plot )
--	return plot and plot:IsCity() and city:IsCapital()
--end
--function MeteorEffect( player, city, unit, plot )
--	plot:NukeExplosion(1) 
--	_UserEventMessage( "TXT_KEY_USER_EVENT_METEOR_EFFECT", player, city, unit, plot )
--	print("Event ID: Meteor")
--end
--UserEventAdd{
--    id			= "METEOR",
----	probability	= 0.0002,
--	options		= {
--		OPTION1 = {	order	= 1, condition	= MeteorCond, effect	= MeteorEffect },
--		}
--}
--[[ / Meteor ]]--

--[[ Marketcrash ]]--
function MarketcrashCond( player, city, unit, plot )
	return city and city:IsCapital()
end
function MarketcrashEffect( player, city, unit, plot )
	player:ChangeGold( - ( player:GetGold() * ( math.random( 20,50 ) / 100 ) ) )	
	_UserEventMessage( "TXT_KEY_USER_EVENT_MARKETCRASH_EFFECT", player, city, unit, plot )
--	print("Event ID: Marketcrash")
end
UserEventAdd{
    id			= "MARKETCRASH",
	probability	= 0.002,
	options		= {
		OPTION1 = {	order	= 1, condition	= MarketcrashCond, effect	= MarketcrashEffect },
		}
}
--[[ / Marketcrash ]]--

--[[ Donation ]]--
function DonationCond( player, city, unit, plot )
	return city and city:IsCapital()
end
function DonationEffect( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
		ncounter = 1
	elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
		ncounter = 2
	elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
		ncounter = 3
	elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
		ncounter = 4
	elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
		ncounter = 5
	elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
		ncounter = 6
	else
		ncounter = 7
	end	
	player:ChangeGold( (40 * ncounter) + math.random( (1 * ncounter), (80 * ncounter) ))
	
	_UserEventMessage( "TXT_KEY_USER_EVENT_DONATION_EFFECT", player, city, unit, plot )
--	print("Event ID: Donation")
end
UserEventAdd{
    id			= "DONATION",
	probability	= 0.003,
	options		= {
		OPTION1 = {	order	= 1, condition	= DonationCond, effect	= DonationEffect },
		}
}
--[[ / Donation ]]--

--[[ Plague ]]--
function PlagueCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only if the player does not have knowledge of Penicilin
	if not pTeam:IsHasTech(GameInfoTypes.TECH_PENICILIN) then
		return city and plot:IsCity() and (city:GetPopulation() > 3)
	end
end
function PlagueEffect( player, city, unit, plot )
	local npopulation = city:GetPopulation()
	if npopulation < 7 then
	city:ChangePopulation(- math.random(1,3), true) 
	elseif npopulation < 15 then
	city:ChangePopulation(- math.random(2,4), true)
	end
	_UserEventMessage( "TXT_KEY_USER_EVENT_PLAGUE_EFFECT", player, city, unit, plot )
--	print("Event ID: Plague")
end
UserEventAdd{
    id			= "PLAGUE",
	probability	= 0.002,
	options		= {
		OPTION1 = {	order	= 1, condition	= PlagueCond, effect	= PlagueEffect },
		}
}
--[[ / Plague ]]--

--[[ Boom ]]--
function BoomCond( player, city, unit, plot )
	return city and plot:IsCity()
end
function BoomEffect( player, city, unit, plot )
	city:ChangePopulation(math.random(1,3), true) 
	_UserEventMessage( "TXT_KEY_USER_EVENT_BOOM_EFFECT", player, city, unit, plot )
--	print("Event ID: Boom")
end
UserEventAdd{
    id			= "BOOM",
	probability	= 0.003,
	options		= {
		OPTION1 = {	order	= 1, condition	= BoomCond, effect	= BoomEffect },
		}
}
--[[ / Boom ]]--

--[[ Plotplus ]]--
function PlotplusCond( player, city, unit, plot )
	return city and plot:IsCity() and (city:GetPopulation() < 6)
end
function PlotplusEffect( player, city, unit, plot )
	city:DoJONSCultureLevelIncrease()
	_UserEventMessage( "TXT_KEY_USER_EVENT_PLOTPLUS_EFFECT", player, city, unit, plot )
--	print("Event ID: Plot plus")
end
UserEventAdd{
    id			= "PLOTPLUS",
	probability	= 0.004,
	options		= {
		OPTION1 = {	order	= 1, condition	= PlotplusCond, effect	= PlotplusEffect },
		}
}
--[[ / Plotplus ]]--

--[[ Sickness ]]--
function SicknessCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only if the player does not have knowledge of Biology
	if not pTeam:IsHasTech(GameInfoTypes.TECH_BIOLOGY) then
		return unit and unit:GetCurrHitPoints() > 1 and unit:CanAcquirePromotionAny()
	end
end
function SicknessEffect( player, city, unit, plot )
	unit:SetDamage( math.random( 1, math.floor( unit:GetCurrHitPoints() - 1 ) ) )
	_UserEventMessage( "TXT_KEY_USER_EVENT_SICKNESS_EFFECT", player, city, unit, plot )
--	print("Event ID: Sickness")
end
UserEventAdd{
    id			= "SICKNESS",
	probability	= 0.004,
	options		= {
		OPTION1 = {	order	= 1, condition	= SicknessCond, effect	= SicknessEffect },
		}
}
--[[ / Sickness ]]--

--[[ Policy ]]--
function PolicyCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only if the player has knowledge of Archaeology
	if pTeam:IsHasTech(GameInfoTypes.TECH_ARCHAEOLOGY) then
		return city
	end
end
function PolicyEffect( player, city, unit, plot )
	player:SetNumFreePolicies(1)
	_UserEventMessage( "TXT_KEY_USER_EVENT_POLICY_EFFECT", player, city, unit, plot )
--	print("Event ID: Policy")
	Events.SerialEventGameMessagePopup( {	Type	= ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY,
												Data1	= player,
												Data3	= -1
											} )
end
UserEventAdd{
    id			= "POLICY",
	probability	= 0.0015,
	options		= {
		OPTION1 = {	order	= 1, condition	= PolicyCond, effect	= PolicyEffect },
		}
}
--[[ / Policy ]]--

--[[ HasMonarchy ]]--
function HasMonarchyCond( player, city, unit, plot )
	return city and city:IsCapital() and player:HasPolicy( GameInfo.Policies[ "POLICY_MONARCHY" ].ID )
end
function HasMonarchyEffect( player, city, unit, plot )
	city:ChangePopulation(3, true)
	_UserEventMessage( "TXT_KEY_USER_EVENT_HASMONARCHY_EFFECT", player, city, unit, plot )
--	print("Event ID: HasMonarchy")
end
UserEventAdd{
    id			= "HASMONARCHY",
	probability	= 0.002,
	options		= {
		OPTION1 = {	order	= 1, condition	= HasMonarchyCond, effect	= HasMonarchyEffect },
		}
}
--[[ / HasMonarchy ]]--

--[[ HasMilTrad ]]--
function HasMilTradCond( player, city, unit, plot )
	return unit and ( unit:CanAcquirePromotionAny() and not unit:IsHasPromotion(GameInfo.UnitPromotions[ "PROMOTION_SECOND_ATTACK" ].ID) and player:HasPolicy( GameInfo.Policies[ "POLICY_MILITARY_TRADITION" ].ID ) )
end
function HasMilTradEffect( player, city, unit, plot )
	unit:SetHasPromotion( GameInfo.UnitPromotions[ "PROMOTION_SECOND_ATTACK" ].ID, true)
	_UserEventMessage( "TXT_KEY_USER_EVENT_HASMILTRAD_EFFECT", player, city, unit, plot )
--	print("Event ID: HasMiltrad")
end
UserEventAdd{
    id			= "HASMILTRAD",
	probability	= 0.002,
	options		= {
		OPTION1 = {	order	= 1, condition	= HasMilTradCond, effect	= HasMilTradEffect },
		}
}
--[[ / HasMilTrad ]]--

--[[ HasMeritocracy ]]--
function HasMeritocracyCond( player, city, unit, plot )
	return player and player:HasPolicy( GameInfo.Policies[ "POLICY_MERITOCRACY" ].ID )
end
function HasMeritocracyEffect( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
		ncounter = 1
	elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
		ncounter = 2
	elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
		ncounter = 3
	elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
		ncounter = 4
	elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
		ncounter = 5
	elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
		ncounter = 6
	else
		ncounter = 7
	end
	
	for ncity in player:Cities() do
		if (not ncity:IsPuppet() and not ncity:IsOccupied()) then
			player:ChangeGold( math.random(10,50 ) * ncounter)
		else
		
		end
	end
	
	_UserEventMessage( "TXT_KEY_USER_EVENT_HASMERITOCRACY_EFFECT", player, city, unit, plot )
--	print("Event ID: HasMeritocracy")
end
UserEventAdd{
    id			= "HASMERITOCRACY",
	probability	= 0.002,
	options		= {
		OPTION1 = {	order	= 1, condition	= HasMeritocracyCond, effect	= HasMeritocracyEffect },
		}
}
--[[ / HasMeritocracy ]]--


--[[ Unpuppet ]]--
function UnpuppetCond( player, city, unit, plot )
	return city and city:IsPuppet()
end
function UnpuppetEffect( player, city, unit, plot )
	city:SetPuppet(false)
	city:SetOccupied(false)
	city:SetProductionAutomated(false)
	_UserEventMessage( "TXT_KEY_USER_EVENT_UNPUPPET_EFFECT", player, city, unit, plot )
--	print("Event ID: Unpuppet")
end
UserEventAdd{
    id			= "UNPUPPET",
	probability	= 0.00152,
	options		= {
		OPTION1 = {	order	= 1, condition	= UnpuppetCond, effect	= UnpuppetEffect },
		}
}
--[[ / Unpuppet ]]--

--[[ Entrepeneur ]]--
function EntrepeneurCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only if the player has certain combinations of gold buildings and techs
	if pTeam:IsHasTech(GameInfoTypes.TECH_CURRENCY) or pTeam:IsHasTech(GameInfoTypes.TECH_BANKING) or pTeam:IsHasTech(GameInfoTypes.TECH_ELECTRICITY) then
		return city and plot:IsCity() and
		( ( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MARKET" ].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_CURRENCY) ) or
		( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MARKET" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_BANK" ].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_BANKING) ) or
		( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_BANK"   ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_STOCK_EXCHANGE" ].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_ELECTRICITY) ) )
	end
end
function EntrepeneurEffect( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
	if (  city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MARKET" ].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_CURRENCY) ) then
		city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MARKET" ].ID, 1 )
		_UserEventMessage( "TXT_KEY_USER_EVENT_ENTREPENEUR_EFFECT1", player, city, unit, plot )
--		print("Event ID: Entrepeneur effect1")
	elseif ( city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_MARKET" ].ID ) == 1 and city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_BANK"].ID ) ~= 1 and pTeam:IsHasTech(GameInfoTypes.TECH_BANKING) ) then
		city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_BANK"].ID, 1 )
		_UserEventMessage( "TXT_KEY_USER_EVENT_ENTREPENEUR_EFFECT2", player, city, unit, plot )
--		print("Event ID: Entrepeneur effect2")
	else
		city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_STOCK_EXCHANGE" ].ID, 1 )
		_UserEventMessage( "TXT_KEY_USER_EVENT_ENTREPENEUR_EFFECT3", player, city, unit, plot )
--		print("Event ID: Entrepeneur effect 3")
	end
end
UserEventAdd{
    id			= "ENTREPENEUR",
	probability	= 0.002,
	options		= {
		OPTION1 = {	order	= 1, condition	= EntrepeneurCond, effect	= EntrepeneurEffect },
		}
}
--[[ / Entrepeneur ]]--

--[[ Tidal Wave ]]--
function TidalWaveCond( player, city, unit, plot )
	return city and plot:IsCity() and
	(city:GetNumRealBuilding(GameInfo.Buildings[ "BUILDING_HARBOR" ].ID ) == 1 or
	city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_LIGHTHOUSE" ].ID ) == 1 or
	city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_SEAPORT" ].ID ) == 1)
end
function TidalWaveEffect( player, city, unit, plot )
	city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_HARBOR" ].ID , 0 )
	city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_LIGHTHOUSE" ].ID , 0 )
	city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_SEAPORT" ].ID , 0 )
	_UserEventMessage( "TXT_KEY_USER_EVENT_TSUNAMI_EFFECT", player, city, unit, plot )
--	print("Event ID: Tidal Wave")
end
UserEventAdd{
    id			= "TSUNAMI",
	probability	= 0.002,
	options		= {
		OPTION1 = {	order	= 1, condition	= TidalWaveCond, effect	= TidalWaveEffect },
		}
}
--[[ / Tidal Wave ]]--

--[[ Flash Flood ]]--
function FlashFloodCond( player, city, unit, plot )
	return city and plot:IsCity() and
	(city:GetNumRealBuilding(GameInfo.Buildings[ "BUILDING_WATERMILL" ].ID ) == 1 or
	city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_HYDRO_PLANT" ].ID ) == 1)
end
function FlashFloodEffect( player, city, unit, plot )
	city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_WATERMILL" ].ID , 0 )
	city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_HYDRO_PLANT" ].ID , 0 )
	_UserEventMessage( "TXT_KEY_USER_EVENT_FLASHFLOOD_EFFECT", player, city, unit, plot )
--	print("Event ID: Flash Flood")
end
UserEventAdd{
    id			= "FLASHFLOOD",
	probability	= 0.002,
	options		= {
		OPTION1 = {	order	= 1, condition	= FlashFloodCond, effect	= FlashFloodEffect },
		}
}
--[[ / Flash Flood ]]--

--[[ Hurricane ]]--
function HurricaneCond( player, city, unit, plot )
	return city and plot:IsCity() and
	(city:GetNumRealBuilding(GameInfo.Buildings[ "BUILDING_WINDMILL" ].ID ) == 1 or
	city:GetNumRealBuilding(GameInfo.Buildings[ "BUILDING_SOLAR_PLANT" ].ID ) == 1 or
	city:GetNumRealBuilding( GameInfo.Buildings[ "BUILDING_BROADCAST_TOWER" ].ID ) == 1)
end
function HurricaneEffect( player, city, unit, plot )
	city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_WINDMILL" ].ID , 0 )
	city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_BROADCAST_TOWER" ].ID , 0 )
	city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_SOLAR_PLANT" ].ID , 0 )
	_UserEventMessage( "TXT_KEY_USER_EVENT_HURRICANE_EFFECT", player, city, unit, plot )
--	print("Event ID: Hurricane")
end
UserEventAdd{
    id			= "HURRICANE",
	probability	= 0.00153,
	options		= {
		OPTION1 = {	order	= 1, condition	= HurricaneCond, effect	= HurricaneEffect },
		}
}
--[[ / Hurricane ]]--

--[[ Meltdown ]]--
--[[
function MeltdownCond( player, city, unit, plot )
	return plot and plot:IsCity() and city:GetNumRealBuilding(GameInfo.Buildings[ "BUILDING_NUCLEAR_PLANT" ].ID ) == 1
	return city and plot:IsCity() and city:GetNumRealBuilding(GameInfo.Buildings[ "BUILDING_NUCLEAR_PLANT" ].ID ) == 1
end
function MeltdownEffect( player, city, unit, plot )
	city:SetNumRealBuilding( GameInfo.Buildings[ "BUILDING_NUCLEAR_PLANT" ].ID , 0 )
	plot:NukeExplosion(1) 
	_UserEventMessage( "TXT_KEY_USER_EVENT_MELTDOWN_EFFECT", player, city, unit, plot )
	print("Event ID: Meltdown")
end
UserEventAdd{
    id			= "MELTDOWN",
	probability	= 0.9,	
	probability	= 0.0001,
	options		= {
		OPTION1 = {	order	= 1, condition	= MeltdownCond, effect	= MeltdownEffect },
		}
}
--]]
--[[ / Meltdown ]]--

--[[ Exp ]]--
function ExpCond( player, city, unit, plot )
	return unit and unit:CanAcquirePromotionAny()
end
function ExpEffect( player, city, unit, plot )
	unit:ChangeExperience(15, -1, 0, 0, 0) 
	_UserEventMessage( "TXT_KEY_USER_EVENT_EXP_EFFECT", player, city, unit, plot )
--	print("Event ID: Exp")
end
UserEventAdd{
    id			= "EXP",
	probability	= 0.0038,
	options		= {
		OPTION1 = {	order	= 1, condition	= ExpCond, effect	= ExpEffect },
		}
}
--[[ / Exp ]]--

--[[ GoldenAge ]]--
function GoldenAgeCond( player, city, unit, plot )
	return player and not player:IsGoldenAge()
end
function GoldenAgeEffect( player, city, unit, plot )
local NewGoldenAgeCounter	= math.random( 1, 4 )
	player:ChangeGoldenAgeTurns( 6+NewGoldenAgeCounter )
	_UserEventMessage( "TXT_KEY_USER_EVENT_GOLDENAGE_EFFECT", player, city, unit, plot )
--	print("Event ID: GoldenAge")
end
UserEventAdd{
    id			= "GOLDENAGE",
	probability	= 0.002,
	options		= {
		OPTION1 = {	order	= 1, condition	= GoldenAgeCond, effect	= GoldenAgeEffect },
		}
}
--[[ / GoldenAge ]]--

--[[ Worker ]]--
function WorkerCond( player, city, unit, plot )
	local nera = player:GetCurrentEra() 
	return plot and not plot:IsCity() and
	(nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID or
	nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID or
	nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID) 
end
function WorkerEffect( player, city, unit, plot )
	_AddNewUnit( player, "UNIT_WORKER", plot:GetX(), plot:GetY() )
	_UserEventMessage( "TXT_KEY_USER_EVENT_WORKER_EFFECT", player, city, unit, plot )
--	print("Event ID: Worker")
end
UserEventAdd{
    id			= "WORKER",
	probability	= 0.005,
	options		= {
		OPTION1 = {	order	= 1, condition	= WorkerCond, effect	= WorkerEffect },
		}
}
--[[ / Worker ]]--

--[[ New Iron in mines ]]--
-- condition function
function NewIronCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on tiles with a mine but with no features nor resources. Furthermore the player must have knowledge of the tech Iron Working
	if pTeam:IsHasTech(GameInfoTypes.TECH_IRON_WORKING) then
		return plot and not plot:IsCity() and plot:GetResourceType() == -1 and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID
	end
end

function NewIronEffect( player, city, unit, plot )
	local NewIronCounter	= math.random( 2, 5 )
	-- add Iron to the plot
	plot:SetImprovementType( -1 )
	plot:SetResourceType( GameInfo.Resources[ "RESOURCE_IRON" ].ID, NewIronCounter )
	plot:SetImprovementType(  GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID )
	-- display the message
	_UserEventMessage( "TXT_KEY_USER_EVENT_NEW_IRON_EFFECT", player, city, unit, plot )
--	print("Event ID: New Iron")
end
-- enable the event
UserEventAdd{
	id			= "NEW_IRON",
	probability	= 0.004,
	options		= {
		OPTION1	= { order	= 1, condition	= NewIronCond, effect	= NewIronEffect }
		}
}
--[[ / New Iron in mines ]]--

--[[ New Coal in mines ]]--
-- condition function
function NewCoalCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on tiles with a mine but with no features nor resources. Furthermore the player must have knowledge of the tech Scientific Theory
	if pTeam:IsHasTech(GameInfoTypes.TECH_SCIENTIFIC_THEORY) then
		return plot and not plot:IsCity() and plot:GetResourceType() == -1 and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID
	end
end
-- effect function
function NewCoalEffect( player, city, unit, plot )
local NewCoalCounter	= math.random( 2, 5 )
	-- add Coal to the plot
	plot:SetImprovementType( -1 )
	plot:SetResourceType( GameInfo.Resources[ "RESOURCE_COAL" ].ID, NewCoalCounter )
	plot:SetImprovementType(  GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID )
	-- display the message
	_UserEventMessage( "TXT_KEY_USER_EVENT_NEW_COAL_EFFECT", player, city, unit, plot )
--	print("Event ID: New Coal")
end
-- enable the event
UserEventAdd{
	id			= "NEW_COAL",
	probability	= 0.003,
	options		= {
		OPTION1	= { order	= 1, condition	= NewCoalCond, effect	= NewCoalEffect }
		}
}
--[[ / New Coal in mines ]]--

--[[ New Oil on desert or plains ]]--
-- condition function
function NewOilCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on the flat desert/plains tile with no features nor resources. Furthermore the player must have knowledge of the tech Biology
	if pTeam:IsHasTech(GameInfoTypes.TECH_BIOLOGY) then
		return plot and not plot:IsCity() and plot:GetResourceType() == -1 and
		(plot:GetTerrainType() == GameInfo.Terrains[ "TERRAIN_DESERT" ].ID or
		plot:GetTerrainType() == GameInfo.Terrains[ "TERRAIN_PLAINS" ].ID)
	end
end
-- effect function
function NewOilEffect( player, city, unit, plot )
local NewOilCounter	= math.random( 2, 5 )
	-- add Oil to the plot
	plot:SetResourceType( GameInfo.Resources[ "RESOURCE_OIL" ].ID, NewOilCounter)
	-- display the message
	_UserEventMessage( "TXT_KEY_USER_EVENT_NEW_OIL_EFFECT", player, city, unit, plot )
--	print("Event ID: New Oil")
end
-- enable the event
UserEventAdd{
	id			= "NEW_OIL",
	probability	= 0.003,
	options		= {
		OPTION1	= { order	= 1, condition	= NewOilCond, effect	= NewOilEffect }
		}
}
--[[ / Oil on desert or plains ]]--

--[[ Rare Wood ]]--
-- condition function
function RareWoodCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
-- valid only on plots with forests and only if the player knows Iron Working
	if pTeam:IsHasTech(GameInfoTypes.TECH_IRON_WORKING) then
			return city and plot:GetFeatureType() == GameInfo.Features[ "FEATURE_FOREST" ].ID
end
end
-- effect function
function RareWoodEffect( player, city, unit, plot )
	-- add +2 gold yield to the plot
	Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), GameInfo.Yields[ "YIELD_GOLD" ].ID, 2)
	_UserEventMessage( "TXT_KEY_USER_EVENT_RAREWOOD_EFFECT", player, city, unit, plot )
--	print("Event ID: Rare Wood")
end
-- enable the event
UserEventAdd{
    id			= "RAREWOOD",
	probability	= 0.005,
	options		= {
		OPTION1 = {	order	= 1, condition	= RareWoodCond, effect	= RareWoodEffect },
		}
}
--[[ / Rare Wood ]]--

--[[ More Food]]--
-- condition function
function MoreFoodCond( player, city, unit, plot )
-- valid only on tiles improved food resources
	return city and 
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_COW" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_PASTURE" ].ID) or
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_SHEEP" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_PASTURE" ].ID) or
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_WHEAT" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_FARM" ].ID) or
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_DEER" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_CAMP" ].ID) or
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_BANANA" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_PLANTATION" ].ID) or
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_FISH" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_FISHING_BOATS" ].ID)
end
function MoreFoodEffect( player, city, unit, plot )
	Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), GameInfo.Yields[ "YIELD_FOOD" ].ID, 1)
	_UserEventMessage( "TXT_KEY_USER_EVENT_MOREFOOD_EFFECT", player, city, unit, plot )
--	print("Event ID: More Food")
end
UserEventAdd{
    id			= "MOREFOOD",
	probability	= 0.005,
	options		= {
		OPTION1 = {	order	= 1, condition	= MoreFoodCond, effect	= MoreFoodEffect },
		}
}
--[[ / More Food]]

--[[ More Production]]--
-- condition function
function MoreProdCond( player, city, unit, plot )
-- valid only on tiles improved "production" resources
	return city and 
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_IRON" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID) or
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_COAL" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID) or
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_STONE" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_QUARRY" ].ID) or
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_OIL" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_WELL" ].ID) or
	(plot:GetResourceType() ==  GameInfo.Resources[ "RESOURCE_ALUMINUM" ].ID and plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID)
end
function MoreProdEffect( player, city, unit, plot )
	Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), GameInfo.Yields[ "YIELD_PRODUCTION" ].ID, 1)
	_UserEventMessage( "TXT_KEY_USER_EVENT_MOREPROD_EFFECT", player, city, unit, plot )
--	print("Event ID: More Production")
end
UserEventAdd{
    id			= "MOREPROD",
	probability	= 0.005,
	options		= {
		OPTION1 = {	order	= 1, condition	= MoreProdCond, effect	= MoreProdEffect },
		}
 }
-- [[ / More Production]]

--[[ Relic]]--
-- condition function

function RelicCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
--	valid only if player has writing and on plots with improvements
	if pTeam:IsHasTech(GameInfoTypes.TECH_WRITING) then
		return plot and
		(plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_FARM" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_TRADING_POST" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_QUARRY" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_PASTURE" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_CAMP" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_PLANTATION" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_LUMBERMILL" ].ID)
	end
end
 --effect function
function RelicEffect( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
		ncounter = 2
	elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
		ncounter = 2
	elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
		ncounter = 3
	elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
		ncounter = 3
	elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
		ncounter = 4
	elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
		ncounter = 5
	else
		ncounter = 6
	end	
-- add science per era to the plot
	Game.SetPlotExtraYield( plot:GetX(), plot:GetY(), GameInfo.Yields[ "YIELD_SCIENCE" ].ID, ncounter)
	_UserEventMessage( "TXT_KEY_USER_EVENT_RELIC_EFFECT", player, city, unit, plot )
--	print("Event ID: Relic")
end
-- enable the event
UserEventAdd{
    id			= "RELIC",
	probability	= 0.003,
	options		= {
		OPTION1 = {	order	= 1, condition	= RelicCond, effect	= RelicEffect },
		}
 }
-- / Relic ]

--[[ Singer]]--
-- condition function
function SingerCond( player, city, unit, plot )
	local pTnum = player:GetTeam()
	local pTeam = Teams[pTnum]
--  valid only if player has writing and on plots with improvements
	if pTeam:IsHasTech(GameInfoTypes.TECH_WRITING) then
		return city and (plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_MINE" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_FARM" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_TRADING_POST" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_QUARRY" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_PASTURE" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_CAMP" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_PLANTATION" ].ID or
		plot:GetImprovementType() == GameInfo.Improvements[ "IMPROVEMENT_LUMBERMILL" ].ID)
	end
end
 --effect function
function SingerEffect( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	local ncounter = 0
	if nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID then
		ncounter = 1
	elseif nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID then
		ncounter = 2
	elseif nera == GameInfo.Eras[ "ERA_MEDIEVAL" ].ID then
		ncounter = 3
	elseif nera == GameInfo.Eras[ "ERA_RENAISSANCE" ].ID then
		ncounter = 4
	elseif nera == GameInfo.Eras[ "ERA_INDUSTRIAL" ].ID then
		ncounter = 5
	elseif nera == GameInfo.Eras[ "ERA_MODERN" ].ID then
		ncounter = 6
	else
		ncounter = 7
	end	
-- add culture per era to the plot
	plot:ChangeCulture(ncounter)	
	_UserEventMessage( "TXT_KEY_USER_EVENT_SINGER_EFFECT", player, city, unit, plot )
--	print("Event ID: Singer")
end
-- enable the event
UserEventAdd{
    id			= "SINGER",
	probability	= 0.003,
	options		= {
		OPTION1 = {	order	= 1, condition	= SingerCond, effect	= SingerEffect },
		}
 }
-- / Singer ]

--[[ Settler ]]--
function SettlerCond( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	return plot and not plot:IsCity() and
	(nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID or
	nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID)
end
function SettlerCond1( player, city, unit, plot )
	local nera	= player:GetCurrentEra() 
	return plot and not plot:IsCity() and
	(nera == GameInfo.Eras[ "ERA_ANCIENT" ].ID or
	nera == GameInfo.Eras[ "ERA_CLASSICAL" ].ID) and
	player:GetGold() >= 250
end
function SettlerNoEffect( player, city, unit, plot )
	_UserEventMessage( "TXT_KEY_USER_EVENT_SETTLER_EFFECT_NONE", player, city, unit, plot )
--	print("Event ID: Settler none")
end
function SettlerEffect( player, city, unit, plot )
	player:ChangeGold(- 150 )
	_AddNewUnit( player, "UNIT_SETTLER", plot:GetX(), plot:GetY() )
	_UserEventMessage( "TXT_KEY_USER_EVENT_SETTLER_EFFECT", player, city, unit, plot )
--	print("Event ID: Settler effect")
end

UserEventAdd{
    id			= "SETTLER",
	probability	= 0.0015,
	options		= {
		OPTION1 = { order = 1, condition = SettlerCond1, effect = SettlerEffect, flavor1 = "FLAVOR_GROWTH", flavor2 = "FLAVOR_GROWTH" },
		OPTION2 = { order = 2, condition = SettlerCond, effect = SettlerNoEffect, flavor1 = "FLAVOR_GOLD", flavor2 = "FLAVOR_GROWTH" },

		}
}
--[[ / Settler ]]--

--[[ Great Person ]]--
function GreatPersonCond( player, city, unit, plot )
	return city and city:IsCapital() and plot:IsCity() and player:IsGoldenAge()
end
function GreatPersonCond1( player, city, unit, plot )
	return city and city:IsCapital() and plot:IsCity() and player:IsGoldenAge() and
	player:GetGold() >= 350
end
function GreatPersonCond2( player, city, unit, plot )
	return city and city:IsCapital() and plot:IsCity() and player:IsGoldenAge() and
	player:GetGold() >= 350
end
function GreatPersonCond3( player, city, unit, plot )
	return city and city:IsCapital() and plot:IsCity() and player:IsGoldenAge() and
	player:GetGold() >= 350
end
function GreatPersonCond4( player, city, unit, plot )
	return city and city:IsCapital() and plot:IsCity() and player:IsGoldenAge() and
	player:GetGold() >= 350
end
function GreatPersonCond5( player, city, unit, plot )
	return city and city:IsCapital() and plot:IsCity() and player:IsGoldenAge() and
	player:GetGold() >= 350
end
function GreatPersonNoEffect( player, city, unit, plot )
	_UserEventMessage( "TXT_KEY_USER_EVENT_GREATPERSON_EFFECT_NONE", player, city, unit, plot )
--	print("Event ID: Great person none")
end
function GreatPersonEffect1( player, city, unit, plot )
	player:ChangeGold(- 350 )
	_AddNewUnit( player, "UNIT_ENGINEER", plot:GetX(), plot:GetY() )
	_UserEventMessage( "TXT_KEY_USER_EVENT_GREATPERSON_EFFECT1", player, city, unit, plot )
--	print("Event ID: Great engineer effect")
end
function GreatPersonEffect2( player, city, unit, plot )
	player:ChangeGold(- 350 )
	_AddNewUnit( player, "UNIT_SCIENTIST", plot:GetX(), plot:GetY() )
	_UserEventMessage( "TXT_KEY_USER_EVENT_GREATPERSON_EFFECT2", player, city, unit, plot )
--	print("Event ID: Great Scientist effect")
end
function GreatPersonEffect3( player, city, unit, plot )
	player:ChangeGold(- 350 )
	_AddNewUnit( player, "UNIT_ARTIST", plot:GetX(), plot:GetY() )
	_UserEventMessage( "TXT_KEY_USER_EVENT_GREATPERSON_EFFECT3", player, city, unit, plot )
--	print("Event ID: Great Artist effect")
end
function GreatPersonEffect4( player, city, unit, plot )
	player:ChangeGold(- 350 )
	_AddNewUnit( player, "UNIT_MERCHANT", plot:GetX(), plot:GetY() )
	_UserEventMessage( "TXT_KEY_USER_EVENT_GREATPERSON_EFFECT4", player, city, unit, plot )
--	print("Event ID: Great Merchant effect")
end
function GreatPersonEffect5( player, city, unit, plot )
	player:ChangeGold(- 350 )
	_AddNewUnit( player, "UNIT_GREAT_GENERAL", plot:GetX(), plot:GetY() )
	_UserEventMessage( "TXT_KEY_USER_EVENT_GREATPERSON_EFFECT5", player, city, unit, plot )
--	print("Event ID: Great General effect")
end
UserEventAdd{
    id			= "GREATPERSON",
	probability	= 0.0015,
	options		= {
		OPTION1 = { order = 1, condition = GreatPersonCond1, effect = GreatPersonEffect1, flavor1 = "FLAVOR_GROWTH", flavor2 = "FLAVOR_WONDER" },
		OPTION2 = { order = 2, condition = GreatPersonCond2, effect = GreatPersonEffect2, flavor1 = "FLAVOR_SCIENCE", flavor2 = "FLAVOR_SCIENCE" },
		OPTION3 = { order = 3, condition = GreatPersonCond3, effect = GreatPersonEffect3, flavor1 = "FLAVOR_CULTURE", flavor2 = "FLAVOR_EXPANSION" },
		OPTION4 = { order = 4, condition = GreatPersonCond4, effect = GreatPersonEffect4, flavor1 = "FLAVOR_GOLD", flavor2 = "FLAVOR_GROWTH" },
		OPTION5 = { order = 5, condition = GreatPersonCond5, effect = GreatPersonEffect5, flavor1 = "FLAVOR_OFFENSE", flavor2 = "FLAVOR_DEFENSE" },
		OPTION6 = { order = 6, condition = GreatPersonCond, effect = GreatPersonNoEffect, flavor1 = "FLAVOR_GOLD", flavor2 = "FLAVOR_GOLD" },
		}
}
--[[ / Great Person ]]--