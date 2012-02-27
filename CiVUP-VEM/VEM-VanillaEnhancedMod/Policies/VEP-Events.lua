-- BalanceSocialPolicies
-- Author: Thalassicus
-- DateCreated: 11/14/2010 10:38:30 PM
--------------------------------------------------------------

include("ThalsUtilities.lua")

local log = Events.LuaLogger:New();
log:SetLevel("WARN");

function DoEndCombatPolicyBonuses(
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
	log:Debug("DoEndCombatPolicyBonuses")
	log:Trace("attPlayerID         "..attPlayerID)
	log:Trace("attUnitID           "..attUnitID)
	log:Trace("attUnitDamage       "..attUnitDamage)
	log:Trace("attFinalUnitDamage  "..attFinalUnitDamage)
	log:Trace("attMaxHitPoints     "..attMaxHitPoints)
	log:Trace("defPlayerID         "..defPlayerID)
	log:Trace("defUnitID           "..defUnitID)
	log:Trace("defUnitDamage       "..defUnitDamage)
	log:Trace("defFinalUnitDamage  "..defFinalUnitDamage)
	log:Trace("defMaxHitPoints     "..defMaxHitPoints)

	local wonPlayer, lostPlayer, lostUnit

	if defFinalUnitDamage >= defMaxHitPoints then
		wonPlayer	= Players[attPlayerID]
		lostPlayer	= Players[defPlayerID]
		lostUnit	= lostPlayer:GetUnitByID(defUnitID)
	elseif attFinalUnitDamage >= attMaxHitPoints then
		wonPlayer	= Players[defPlayerID]
		lostPlayer	= Players[attPlayerID]
		lostUnit	= lostPlayer:GetUnitByID(attUnitID)
	end

	if lostUnit then
		lostUnitInfo = GameInfo.Units[lostUnit:GetUnitType()]
		for policyInfo in GameInfo.Policies("GoldFromKillsCostBased != 0") do
			if wonPlayer:HasPolicy(policyInfo.ID) then
				local gold = wonPlayer:GetUnitProductionNeeded(lostUnit:GetUnitType())
				gold = math.pow(gold * GameDefines.GOLD_PURCHASE_GOLD_PER_PRODUCTION, GameDefines.HURRY_GOLD_PRODUCTION_EXPONENT)
				gold = gold * (1 + GameInfo.Units[lostUnit:GetUnitType()].HurryCostModifier / 100)
				gold = RoundDown(policyInfo.GoldFromKillsCostBased * gold, -1)

				wonPlayer:ChangeGold(gold)
				if wonPlayer:GetID() == Game.GetActivePlayer() then
					Events.GameplayAlertMessage(string.format("%i[ICON_GOLD] Gold looted from defeating a %s.", gold, lostUnit:GetName()))
				end
			end
		end
	end
end

Events.EndCombatSim.Add( DoEndCombatPolicyBonuses )

---------------------------------------------------------------------
---------------------------------------------------------------------

function GivePolicyPromotionsToUnit_Created( playerID,
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
	log:Info("DoFreePromotionUnitClasses")
	local player = Players[playerID]
    if not player or not player:IsAlive() or player:IsMinorCiv() or player:IsBarbarian() then
		return
	end

	local unit = Players[ playerID ]:GetUnitByID( unitID )
	if unit == nil or unit:IsDead() then
        return
    end
	
	GivePolicyPromotionsToUnit(unit, player)
end
Events.SerialEventUnitCreated.Add( GivePolicyPromotionsToUnit_Created )

function GivePolicyPromotionsToUnit(unit)
	local player = Players[unit:GetOwner()]	
	for policyInfo in GameInfo.Policy_FreePromotionUnitClasses() do
		if (player:HasPolicy(GameInfo.Policies[policyInfo.PolicyType].ID)) and (policyInfo.UnitClass == GameInfo.Units[unit:GetUnitType()].Class) then
			unit:SetHasPromotion(GameInfo.UnitPromotions[policyInfo.PromotionType].ID, true)
			--LuaEvents.RefreshUnitFlagPromotions(unit)
		end
	end
end
LuaEvents.ActivePlayerTurnStart_Unit.Add(GivePolicyPromotionsToUnit)


function GivePolicyPromotionsToActivePlayer(policyID, policyAdopted)
	local player = Players[Game.GetActivePlayer()]
	if policyAdopted then
		for policyInfo in GameInfo.Policy_FreePromotionUnitClasses() do
			if (policyID == GameInfo.Policies[policyInfo.PolicyType].ID) and (policyInfo.UnitClass == GameInfo.Units[unit:GetUnitType()].Class) then
				unit:SetHasPromotion(GameInfo.UnitPromotions[policyInfo.PromotionType].ID, true)
				--LuaEvents.RefreshUnitFlagPromotions(unit)
			end
		end
	end
end
--Network.SendUpdatePolicies.Add(GivePolicyPromotionsToActivePlayer)