UPDATE Resources
SET TechCityTrade = "TECH_ARCHERY"
WHERE TechCityTrade = "TECH_TRAPPING";

DELETE FROM Terrain_RiverYieldChanges;

DELETE FROM Feature_RiverYieldChanges;

INSERT INTO Improvement_RiverSideYields (ImprovementType, YieldType, Yield)
SELECT Type, 'YIELD_GOLD', 1 from Improvements
WHERE NOT Type IN (
	'IMPROVEMENT_CITY_RUINS',
	'IMPROVEMENT_BARBARIAN_CAMP',
	'IMPROVEMENT_GOODY_HUT',
	'IMPROVEMENT_FISHING_BOATS',
	'IMPROVEMENT_OFFSHORE_PLATFORM'
);