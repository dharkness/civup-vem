-- CiVUP - Event Registration
-- Author: Thalassicus
-- DateCreated: 2/12/2011 9:42:55 AM
--------------------------------------------------------------

include("CustomNotification.lua")
include("CiVUP_Core.lua")

LuaEvents.ActivePlayerTurnEnd_Player	.Add(CleanCityYieldRates)
LuaEvents.ActivePlayerTurnEnd_City		.Add(City_UpdateModdedYields)
LuaEvents.ActivePlayerTurnStart_Player	.Add(Player_UpdateModdedYields)
LuaEvents.ActivePlayerTurnEnd_Player	.Add(Player_UpdateModdedYields)
--LuaEvents.ActivePlayerTurnStart_Player.Add(UpdatePlayerRewardsFromMinorCivs)
LuaEvents.CityYieldRatesDirty			.Add(OnCityYieldRatesDirty)

LuaEvents.NotificationOverrideAddin({
	type="NOTIFICATION_STARVING",
	override=function(tooltip,summary,value1,value2)
		--LuaEvents.CustomStarving();
	end
})

--
for playerID, player in pairs(Players) do
	if IsValidPlayer(player) then
		CleanCityYieldRates(player)
	end
end
--]]