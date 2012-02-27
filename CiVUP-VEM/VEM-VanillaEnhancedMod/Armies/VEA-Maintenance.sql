UPDATE Units
SET ExtraMaintenanceCost = 1
WHERE Cost > 0 AND (Combat = 0 AND RangedCombat = 0);

UPDATE Units
SET ExtraMaintenanceCost = Cost / 50 + MAX(Combat, RangedCombat) / 5 - 1
WHERE Cost > 0 AND (Combat > 0 OR RangedCombat > 0);

UPDATE Units SET ExtraMaintenanceCost = 30 WHERE Class = 'UNITCLASS_ATOMIC_BOMB';
UPDATE Units SET ExtraMaintenanceCost = 60 WHERE Class = 'UNITCLASS_NUCLEAR_MISSILE';
UPDATE Units SET ExtraMaintenanceCost = 10 WHERE Class = 'UNITCLASS_GUIDED_MISSILE';

UPDATE Units
SET ExtraMaintenanceCost = 1.5 * ExtraMaintenanceCost
WHERE Type IN (
	SELECT UnitType FROM Civilization_UnitClassOverrides
	WHERE CivilizationType = 'CIVILIZATION_BARBARIAN'
);

UPDATE Units
SET ExtraMaintenanceCost = 0.75 * ExtraMaintenanceCost
WHERE ExtraMaintenanceCost > 0 AND (
	CombatClass = 'UNITCOMBAT_RECON'
	OR Domain = 'DOMAIN_SEA'
	OR Domain = 'DOMAIN_AIR'
);

UPDATE Units
SET ExtraMaintenanceCost = MAX(ExtraMaintenanceCost, 1)
WHERE ExtraMaintenanceCost > 0;

UPDATE Units
SET ExtraMaintenanceCost = ROUND(ExtraMaintenanceCost, 0)
WHERE ExtraMaintenanceCost > 0;