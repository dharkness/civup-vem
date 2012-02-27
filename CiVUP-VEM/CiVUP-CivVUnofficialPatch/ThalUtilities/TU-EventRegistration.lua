-- TU - Event REgistration
-- Author: Thalassicus
-- DateCreated: 4/5/2011 1:59:05 PM
--------------------------------------------------------------

include("ThalsUtilities")

Events.ActivePlayerTurnStart		.Add(OnTurnStart)
Events.ActivePlayerTurnEnd			.Add(OnTurnEnd)
Events.SerialEventUnitCreated		.Add(OnNewUnit)
Events.SerialEventCityCreated		.Add(OnNewCity)
Events.SerialEventCityCaptured		.Add(UpdateTurnAcquiredCapture)
Events.SerialEventCityCaptured		.Add(OnCityDestroyed)
Events.SerialEventCityDestroyed		.Add(OnCityDestroyed)
Events.SerialEventHexCultureChanged	.Add(OnHexCultureChanged)
LuaEvents.CityFounded				.Add(UpdateTurnAcquiredFounding)
LuaEvents.BuildingConstructed		.Add(OnBuildingConstructed)
LuaEvents.BuildingDestroyed			.Add(OnBuildingDestroyed)
LuaEvents.ActivePlayerTurnEnd_Unit	.Add(RemoveNewUnitFlag)
LuaEvents.ActivePlayerTurnStart_Plot.Add(LuaEvents.CheckPlotBuildingsStatus)
LuaEvents.ActivePlayerTurnEnd_Plot	.Add(LuaEvents.CheckPlotBuildingsStatus)