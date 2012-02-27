-- Production
UPDATE Units
SET Cost = ROUND((Cost * 1.4) / 10) * 10
WHERE Cost > 0;

UPDATE Buildings
SET Cost = ROUND((Cost * 1.4) / 10) * 10
WHERE Cost > 0;

UPDATE Projects
SET Cost = ROUND((Cost * 1.4) / 10) * 10
WHERE Cost > 0;

UPDATE Buildings
SET NumCityCostMod = ROUND((NumCityCostMod * 1.2) / 10) * 10
WHERE NumCityCostMod > 0;