ALTER TABLE Buildings ADD AlwaysShowHelp boolean;
-- Use this to force the help text to display for a building.

ALTER TABLE Buildings		ADD FreePromotionAllCombatUnits			text;
ALTER TABLE Buildings		ADD CulturePerPop						integer default 0;
ALTER TABLE Buildings		ADD InstantBorderRadius					integer default 0;
ALTER TABLE Buildings		ADD GlobalInstantBorderRadius			integer default 0;
ALTER TABLE Buildings		ADD MinorFriendshipFlatChange			integer default 0;
ALTER TABLE Buildings		ADD MountainImprovement					text;
ALTER TABLE Buildings		ADD NoOccupiedUnhappinessFixed			boolean;
ALTER TABLE Buildings		ADD OnlyAI								boolean;
ALTER TABLE Buildings		ADD IsVisible							boolean default true;
ALTER TABLE Buildings		ADD CityCaptureCulture					integer default 0;
ALTER TABLE Buildings		ADD CityCaptureCulturePerPop			integer default 0;
ALTER TABLE Buildings		ADD CityCaptureCulturePerEra			integer default 0;
ALTER TABLE Buildings		ADD CityCaptureCulturePerEraExponent	variant default 1;
ALTER TABLE Buildings		ADD GreatGeneralRateChange				integer default 0;
ALTER TABLE Buildings		ADD IsBuildingAddition					integer default 0;
ALTER TABLE Buildings		ADD IsMarketplace						integer default 0;
ALTER TABLE	Buildings		ADD	AdditionParent						text;
ALTER TABLE Buildings		ADD ShortDescription					text;
ALTER TABLE Buildings		ADD TradeDealModifier					integer default 0;
ALTER TABLE Buildings		ADD InstantGoldenAgePoints				integer default 0;
ALTER TABLE Buildings		ADD GoldenAgePoints						integer default 0;
ALTER TABLE Buildings		ADD OneShot								boolean;
ALTER TABLE Eras			ADD TriggerRatePercent					integer default 0;
ALTER TABLE UnitCombatInfos	ADD PromotionCategory					text;
ALTER TABLE HandicapInfos	ADD AIFreeXP							integer default 0;
ALTER TABLE HandicapInfos	ADD AIFreeXPPerEra						integer default 0;
ALTER TABLE HandicapInfos	ADD AIFreePromotion						text;
ALTER TABLE HandicapInfos	ADD AIResearchPercent					variant default 0;
ALTER TABLE HandicapInfos	ADD AIResearchPercentPerEra				variant default 0;
ALTER TABLE HandicapInfos	ADD AIProductionPercentPerEra			variant default 0;
ALTER TABLE HandicapInfos	ADD AIGold								integer default 0;
ALTER TABLE HandicapInfos	ADD AICapitalRevealRadius				integer default 0;
ALTER TABLE Worlds			ADD AICapitalRevealRadius				integer default 0;
ALTER TABLE Traits			ADD BarbarianCapturePercent				integer default 0;
ALTER TABLE Traits			ADD MinorCivCaptureBonus				integer default 0;
ALTER TABLE Traits			ADD ExtraHappinessPerLuxury				integer default 0;
ALTER TABLE Traits			ADD HappinessFromKills					integer default 0;
ALTER TABLE Traits			ADD MilitaristicCSFreePromotion			text;
ALTER TABLE Policies		ADD GoldFromKillsCostBased				variant default 0;
ALTER TABLE Policies		ADD MilitaristicCSExperience			integer default 0;
ALTER TABLE Policies		ADD GarrisonedExperience				variant default 0;
ALTER TABLE Policies		ADD CityCaptureCulture					integer default 0;
ALTER TABLE Policies		ADD CityCaptureCulturePerPop			integer default 0;
ALTER TABLE Policies		ADD CityCaptureCulturePerEra			integer default 0;
ALTER TABLE Policies		ADD CityCaptureCulturePerEraExponent	variant default 1;
ALTER TABLE Policies		ADD MinorInfluence						integer default 0;
ALTER TABLE Policies		ADD MinorGreatPeopleRate				integer default 0;
ALTER TABLE Resources		ADD NumPerTerritory						variant default 0;
ALTER TABLE UnitPromotions	ADD FullMovesAfterAttack				boolean;
ALTER TABLE UnitPromotions	ADD GoldenPoints						integer default 0;
ALTER TABLE Yields			ADD PlayerThreshold						integer default 0;
ALTER TABLE Yields			ADD YieldFriend							integer default 0;
ALTER TABLE Yields			ADD YieldAlly							integer default 0;
ALTER TABLE GameOptions		ADD Reverse								boolean;

ALTER TABLE Units			ADD PopCostMod integer default 0;
ALTER TABLE Buildings		ADD PopCostMod integer default 0;
ALTER TABLE Projects		ADD PopCostMod integer default 0;

ALTER TABLE Units			ADD ListPriority integer default -1;
ALTER TABLE Domains			ADD ListPriority integer default -1;
ALTER TABLE Buildings		ADD ListPriority integer default -1;
ALTER TABLE Projects		ADD ListPriority integer default -1;
ALTER TABLE Processes		ADD ListPriority integer default -1;
ALTER TABLE Flavors			ADD ListPriority integer default -1;

CREATE TABLE IF NOT EXISTS Building_PrereqBuildingClassesPercentage  (
BuildingType text REFERENCES Buildings(Type),
BuildingClassType text REFERENCES BuildingClasses(Type),
PercentBuildingNeeded integer default 0
);

CREATE TABLE IF NOT EXISTS CiVUP (
Type text,
Value variant default 0
);

UPDATE UnitPromotions
SET LostWithUpgrade = 1
WHERE Type LIKE '%PENALTY%'
OR Type IN (
	'PROMOTION_MUST_SET_UP',
	'PROMOTION_ROUGH_TERRAIN_ENDS_TURN',
	'PROMOTION_FOLIAGE_IMPASSABLE',
	'PROMOTION_NO_CAPTURE',
	'PROMOTION_ONLY_DEFENSIVE',
	'PROMOTION_NO_DEFENSIVE_BONUSES'
);

UPDATE UnitPromotions
SET PediaType = 'PEDIA_SHARED'
WHERE Type LIKE '%PROMOTION_BOMBARDMENT%';

UPDATE Units
SET CombatClass = 'UNITCOMBAT_COMMAND'
WHERE Class = 'UNITCLASS_GREAT_GENERAL';

UPDATE Units
SET CombatClass = 'UNITCOMBAT_CIVILIAN'
WHERE CombatClass IS NULL;

INSERT INTO UnitCombatInfos (Type, Description)
SELECT 'UNITCOMBAT_DIPLOMACY', 'TXT_KEY_UNITCOMBAT_DIPLOMACY'
WHERE NOT EXISTS (SELECT * FROM UnitCombatInfos WHERE Type='UNITCOMBAT_DIPLOMACY' );

UPDATE Units
SET DontShowYields = 1
WHERE Class = 'UNITCLASS_GREAT_GENERAL';

INSERT INTO UnitPromotions_UnitCombats
	(PromotionType, UnitCombatType)
SELECT DISTINCT
	PromotionType, 'UNITCOMBAT_MOUNTED_ARCHER'
FROM UnitPromotions_UnitCombats WHERE UnitCombatType = 'UNITCOMBAT_ARCHER';

INSERT INTO UnitPromotions_UnitCombats
	(PromotionType, UnitCombatType)
SELECT DISTINCT
	PromotionType, 'UNITCOMBAT_SUBMARINE'
FROM UnitPromotions_UnitCombats WHERE UnitCombatType = 'UNITCOMBAT_NAVAL';

DELETE FROM UnitPromotions_UnitCombats
WHERE UnitCombatType = 'UNITCOMBAT_SUBMARINE' AND PromotionType LIKE 'PROMOTION_BOMBARDMENT_%';

UPDATE Units
SET CombatClass = 'UNITCOMBAT_MOUNTED_ARCHER'
WHERE CombatClass = 'UNITCOMBAT_ARCHER' AND Class NOT IN (
	'UNITCLASS_ARCHER',
	'UNITCLASS_CROSSBOWMAN'
);

UPDATE MovementRates SET
TotalTime			= 0.5 * TotalTime,
EaseIn				= 0.5 * EaseIn,
EaseOut				= 0.5 * EaseOut,
IndividualOffset	= 0.5 * IndividualOffset,
RowOffset			= 0.5 * RowOffset;

UPDATE Technologies
SET Help = NULL;

INSERT INTO Building_ResourceYieldChanges
	(BuildingType, ResourceType, YieldType, Yield)
SELECT DISTINCT
	BuildingType, 'RESOURCE_FISH', YieldType, Yield
FROM Building_SeaResourceYieldChanges;

INSERT INTO Building_ResourceYieldChanges
	(BuildingType, ResourceType, YieldType, Yield)
SELECT DISTINCT
	BuildingType, 'RESOURCE_WHALE', YieldType, Yield
FROM Building_SeaResourceYieldChanges;

INSERT INTO Building_ResourceYieldChanges
	(BuildingType, ResourceType, YieldType, Yield)
SELECT DISTINCT
	BuildingType, 'RESOURCE_PEARLS', YieldType, Yield
FROM Building_SeaResourceYieldChanges;

DELETE FROM Building_SeaResourceYieldChanges;