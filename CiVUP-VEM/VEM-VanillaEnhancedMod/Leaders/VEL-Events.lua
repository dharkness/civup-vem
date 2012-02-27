-- BL - General
-- Author: Thalassicus
-- DateCreated: 2/17/2011 4:00:14 PM
--------------------------------------------------------------

include("CiVUP_Core.lua")

local log = Events.LuaLogger:New()
log:SetLevel("WARN")

function DoEndCombatLeaderBonuses(
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
	log:Debug("DoEndCombatLeaderBonuses")

	local wonPlayer, wonUnit, wonCity, lostPlayer, lostUnit, lostCity

	if defFinalUnitDamage >= defMaxHitPoints then
		wonPlayer	= Players[attPlayerID]
		lostPlayer	= Players[defPlayerID]
		wonUnit		= wonPlayer:GetUnitByID(attUnitID)
		lostUnit	= lostPlayer:GetUnitByID(defUnitID)
	elseif attFinalUnitDamage >= attMaxHitPoints then
		wonPlayer	= Players[defPlayerID]
		lostPlayer	= Players[attPlayerID]
		wonUnit		= wonPlayer:GetUnitByID(defUnitID)
		lostUnit	= lostPlayer:GetUnitByID(attUnitID)
	end

	if wonPlayer then
		wonCity = not wonUnit
		lostCity = not lostUnit

		log:Trace("%20s   %3s", "attPlayerID",			attPlayerID)
		log:Trace("%20s   %3s", "attUnitID",			attUnitID)
		log:Trace("%20s   %3s", "attUnitDamage",		attUnitDamage)
		log:Trace("%20s   %3s", "attFinalUnitDamage",	attFinalUnitDamage)
		log:Trace("%20s   %3s", "attMaxHitPoints",		attMaxHitPoints)
		log:Trace("%20s   %3s", "defPlayerID",			defPlayerID)
		log:Trace("%20s   %3s", "defUnitID",			defUnitID)
		log:Trace("%20s   %3s", "defUnitDamage",		defUnitDamage)
		log:Trace("%20s   %3s", "defFinalUnitDamage",	defFinalUnitDamage)
		log:Trace("%20s   %3s", "defMaxHitPoints",		defMaxHitPoints)
		log:Trace("%20s   %3s", "wonPlayer",			wonPlayer:GetName())
		log:Trace("%20s   %3s", "lostPlayer",			lostPlayer:GetName())
		log:Trace("%20s   %3s", "wonUnit",				wonUnit and GameInfo.Units[wonUnit:GetUnitType()].Type or "City")
		log:Trace("%20s   %3s", "lostUnit",				lostUnit and GameInfo.Units[lostUnit:GetUnitType()].Type or "City")

		local playerTrait = GetTrait(wonPlayer)
		local culturePerStrength = playerTrait.CultureFromKills / 100
		local barbCapture = playerTrait.BarbarianCapturePercent
		local goldenPoints = 0
		if wonUnit then
			for promoInfo in GameInfo.UnitPromotions("GoldenPoints <> 0") do
				if wonUnit:IsHasPromotion(promoInfo.ID) then
					goldenPoints = goldenPoints + promoInfo.GoldenPoints
				end
			end
			if goldenPoints > 0 then
				local yield = wonPlayer:GetUnitProductionNeeded(lostUnit:GetUnitType())
				yield = math.pow(yield * GameDefines.GOLD_PURCHASE_GOLD_PER_PRODUCTION, GameDefines.HURRY_GOLD_PRODUCTION_EXPONENT)
				yield = yield * (1 + GameInfo.Units[lostUnit:GetUnitType()].HurryCostModifier / 100)
				yield = Round(yield / 100)
				Player_ChangeYieldStored(wonPlayer, YieldTypes.YIELD_HAPPINESS, yield)
			end
		end
		if lostUnit and culturePerStrength > 0 then
			local culture = culturePerStrength * lostUnit:GetBaseCombatStrength()
			local leastCultureCity = wonPlayer:GetCapitalCity()
			for city in wonPlayer:Cities() do
				if not city:IsPuppet() and not city:IsRazing() then
					if city:GetJONSCultureLevel() == leastCultureCity:GetJONSCultureLevel() then
						if City_GetYieldStored(city, YieldTypes.YIELD_CULTURE) < City_GetYieldStored(leastCultureCity, YieldTypes.YIELD_CULTURE) then
							leastCultureCity = city
						end
					elseif city:GetJONSCultureLevel() < leastCultureCity:GetJONSCultureLevel() then
						leastCultureCity = city
					end
				end
			end
			leastCultureCity:ChangeJONSCultureStored(culture)
			log:Debug(leastCultureCity:GetName().." +"..culture.." culture from killing "..lostUnit:GetName())
			cultureStored = City_GetYieldStored(leastCultureCity, YieldTypes.YIELD_CULTURE)
			cultureNext = City_GetYieldNeeded(leastCultureCity, YieldTypes.YIELD_CULTURE)
			cultureDiff = cultureNext - cultureStored
			if cultureDiff <= 0 then
				leastCultureCity:DoJONSCultureLevelIncrease()
				leastCultureCity:SetJONSCultureStored(-cultureDiff)
			end
		end
		if lostPlayer:IsBarbarian() and lostUnit and lostUnit:IsCombatUnit() then
			if wonCity or (wonUnit:GetDomainType() == lostUnit:GetDomainType()) then
				local randChance = (1 + Map.Rand(99, "BL - General: DoEndCombatLeaderBonuses - barbCapture"))
				log:Info("Barbarian dead, checking " ..barbCapture.. " >= " ..randChance)
				if barbCapture >= randChance then
					log:Debug(wonPlayer:GetName().." captured barbarian "..lostUnit:GetName())
					local plot = lostUnit:GetPlot()
					local newUnitID = GameInfo.Units[lostUnit:GetUnitType()].ID
					if newUnitID == GameInfo.Units.UNIT_SETTLER.ID then
						newUnitID = GameInfo.Units.UNIT_WORKER.ID
					end
					local newUnit = wonPlayer:InitUnit( newUnitID, plot:GetX(), plot:GetY() )
					newUnit:SetDamage(0.75 * newUnit:GetMaxHitPoints(), wonPlayer)
					newUnit:SetMadeAttack(true)
					newUnit:SetMoves(1)
				end
			end
		end
	end
end

Events.EndCombatSim.Add( DoEndCombatLeaderBonuses )

---------------------------------------------------------------------
---------------------------------------------------------------------

function DoLuxuryTradeBonus(player)
	local capital = player:GetCapitalCity()
	
	if capital then
		local playerTrait = GetTrait(player)
		if playerTrait.ExtraHappinessPerLuxury > 0 then
			local luxuryTotal = 0
			for resourceInfo in GameInfo.Resources() do
				local resourceID = resourceInfo.ID;
				if Game.GetResourceUsageType(resourceID) == ResourceUsageTypes.RESOURCEUSAGE_LUXURY then
					if player:GetNumResourceAvailable(resourceID, true) > 0 then
						luxuryTotal = luxuryTotal + 1
					end
				end
			end

			capital:SetNumRealBuilding(GameInfo.Buildings.BUILDING_DESERT_CARAVANS.ID, luxuryTotal * playerTrait.ExtraHappinessPerLuxury)
		end
	end
end

LuaEvents.ActivePlayerTurnEnd_Player.Add( DoLuxuryTradeBonus )