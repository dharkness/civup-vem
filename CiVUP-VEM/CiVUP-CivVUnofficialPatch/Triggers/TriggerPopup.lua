-- TriggerPopup.lua
-- Author: Thalassicus
-- Based on work by: Hipfot, Skodkim, Spatzimaus, and VeyDer
--------------------------------------------------------------

include("InstanceManager");
include("IconSupport");
include("FLuaVector");
include("GameplayUtilities");
include("CiVUP_Core.lua");
include("T-Events.lua");

local log = Events.LuaLogger:New()
log:SetLevel("WARN")



function GetAlignmentWeight(player, outcomeOrder)
	return 1.0
end

function DoTriggerPopup(player, trigID, targetID)
	local playerID			= player:GetID()
	local activePlayerID	= Game.GetActivePlayer()
	local activeTeamID		= Game.GetActiveTeam()
	local trigInfo			= GameInfo.Triggers[trigID]
	local targetType		= trigInfo.Target
	local tipTitle			= string.format("TXT_KEY_TRIGGER_%s", trigInfo.Type)
	local tipDesc			= string.format("TXT_KEY_TRIGGER_%s_DESC", trigInfo.Type)
	local tipPlayer			= Teams[player:GetTeam()]:IsHasMet(activeTeamID) and player:GetName() or Locale.ConvertTextKey("TXT_KEY_DISTANT_PLAYER")
	local tipTarget			= ""
	local screenSizeX, screenSizeY = UIManager:GetScreenSizeVal() 
	local tarCity, tarPlot, tarHex, tarUnit, tarPlayer
	
	if targetType == "TARGET_CITY" or trigInfo.BuildingClass then
		tarCity		= Map_GetCityByID(targetID)
		tarPlot		= tarCity:Plot()
		tipTarget	= tarCity:IsRevealed(activeTeamID) and tarCity:GetName() or Locale.ConvertTextKey("TXT_KEY_DISTANT_CITY")
	elseif targetType == "TARGET_ANY_PLOT" or targetType == "TARGET_OWNED_PLOT" or trigInfo.ImprovementType then
		tarPlot		= Map.GetPlotByIndex(targetID)
		local nearestCity = tarPlot:GetWorkingCity()
		if nearestCity then
			tipTarget = nearestCity:IsRevealed(activeTeamID) and nearestCity:GetName() or Locale.ConvertTextKey("TXT_KEY_DISTANT_CITY")
		end
	elseif targetType == "TARGET_UNIT" or trigInfo.UnitClass then
		tarUnit		= player:GetUnitByID(targetID)
		tarPlot		= tarUnit:GetPlot()
		tipTarget	= (not tarUnit:IsInvisible(activeTeamID)) and Locale.ConvertTextKey(GameInfo.Units[tarUnit:GetUnitType()].Description) or Locale.ConvertTextKey("TXT_KEY_DISTANT_UNIT")
	elseif targetType == "TARGET_PLAYER" or targetType == "TARGET_CITYSTATE" then
		tarPlayer	= Players[targetID]
		tipTarget	= Teams[tarPlayer:GetTeam()]:IsHasMet(activeTeamID) and tarPlayer:GetName() or Locale.ConvertTextKey("TXT_KEY_DISTANT_PLAYER")
		if targetType == "TARGET_CITYSTATE" then
			tarPlot	= tarPlayer:GetCapitalCity():Plot()
		end
	end
	
	if playerID == activePlayerID then
		local controlTable	= {}

		if tarPlot then
			tarHex = ToHexFromGrid(Vector2(tarPlot:GetX(), tarPlot:GetY()))
			Events.SerialEventHexHighlight(tarHex, true, Vector4(1.0, 1.0, 0.0, 1))
			UI.LookAt(tarPlot)
		end

		Controls.TriggerTitle:LocalizeAndSetText(tipTitle, tipPlayer, tipTarget)
		Controls.TriggerDescription:LocalizeAndSetText(tipDesc, tipPlayer, tipTarget)
		CivIconHookup(playerID, 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true)
		Controls.OutcomeStack:DestroyAllChildren()

		for outInfo in GameInfo.Outcomes(string.format("TriggerType = '%s'", trigInfo.Type)) do
			local out		= {}
			local outID		= outInfo.ID
			local outOrder	= outInfo.Order
			local outTitle	= string.format("%s_%s", tipTitle, outOrder)
			local outDesc	= string.format("%s_OUTCOME_%s", tipTitle, outOrder)
			local outTip	= string.format("%s_TIP_%s", tipTitle, outOrder)

			ContextPtr:BuildInstanceForControl("OutcomeInstance", out, Controls.OutcomeStack)

			out.Name:LocalizeAndSetText(outDesc, tipPlayer, tipTarget)
			local height = out.Name:GetSizeY() + 20
			out.Button:SetSizeY(height)

			if not MapModData.VEM.TrigOutcomes[playerID][trigID][targetID][outInfo.Order] then
				out.MouseOverContainer:SetHide(true)
				out.Button:SetAlpha(0.6)
			else
				out.MouseOverContainer:SetHide(false)
				out.MouseOverContainer:SetSizeY(height + 5)
				out.MouseOverAnim:SetSizeY(height + 5)
				out.MouseOverGrid:SetSizeY(height + 5)
				out.Button:SetAlpha(1.0)
				out.Button:RegisterCallback(
					Mouse.eLClick,
					function()
						local message = Locale.ConvertTextKey(string.format("%s_ALERT_%s", tipTitle, outOrder), tipPlayer, tipTarget)
						log:Debug("%s\n", message)
						if tarHex then
							Events.GameplayFX(tarHex.x, tarHex.y, -1)
						end
						Events.GameplayAlertMessage(message)						
						Controls.Background:SetHide(true)
						Player_ChangeYieldStored(player, YieldTypes.YIELD_GOLD, -1 * outInfo.GoldCost)
						assert(loadstring("return "..outInfo.Action))()(playerID, trigID, targetID, outID)
					end
				)
			end

			out.Button:LocalizeAndSetToolTip(outTip, tipPlayer, tipTarget)
		end
		Controls.OutcomeStack:CalculateSize()
		Controls.OutcomeStack:ReprocessAnchoring()
		Controls.MainStack:CalculateSize()
		Controls.MainStack:ReprocessAnchoring()
		Controls.MainBox:SetSizeY(100 + Controls.MainStack:GetSizeY())
		Controls.MainBox:SetOffsetY(0.5 * screenSizeY + 10)
		Controls.Background:SetSizeY(Controls.MainBox:GetSizeY())
		Controls.Background:SetHide(false)
	else
		local outWeights	= {}
		local totalWeight	= 0
		local chanceIDs		= {}
		local chancePos		= 1
		local leaderType	= GameInfo.Leaders[player:GetLeaderType()].Type
		
		-- calculate weights
		for outInfo in GameInfo.Outcomes(string.format("TriggerType = '%s'", trigInfo.Type)) do
			local outID		= outInfo.ID
			local outOrder	= outInfo.Order
			if not MapModData.VEM.TrigOutcomes[playerID][trigID][targetID][outInfo.Order] then
				outWeights[outOrder] = 0
			else
				outInfo	= GameInfo.Outcomes[outID]
				outWeights[outOrder] = GetAlignmentWeight(player, outOrder) * 1.0
				
				for flavorInfo in GameInfo.Outcome_Flavors(string.format("OutcomeType = '%s'", outInfo.Type)) do
					for row in GameInfo.Leader_Flavors(string.format("LeaderType = '%s' and FlavorType = '%s'", leaderType, flavorInfo.OutcomeType)) do
						outWeights[outOrder] = outWeights[outOrder] * (CiVUP.OUTCOME_FLAVOR_CONSTANT + row.Flavor * CiVUP.OUTCOME_FLAVOR_MULTIPLIER)
					end
				end
				
				outWeights[outOrder] = math.max(0, outWeights[outOrder])
				totalWeight = totalWeight + outWeights[outOrder]
			end
		end
		if totalWeight == 0 then
			for outOrder, weight in ipairs(outWeights) do
				weight = 1
				totalWeight = totalWeight + 1
			end
		end
		
		-- map probabilities to outcome IDs
		for outOrder, weight in ipairs(outWeights) do
			local step = 100 * weight / totalWeight
			for i = math.floor(chancePos), math.floor(chancePos + step) do
				chanceIDs[i] = outOrder
			end
			chancePos = chancePos + step
		end		
		
		local outID = chanceIDs[1 + Map.Rand(100, "CheckOutcomes")]		
		local message = Locale.ConvertTextKey(string.format("%s_ALERT_%s", tipTitle, outID), tipPlayer, tipTarget)		
		log:Trace("AI triggering outcome : triggerID=%s outID=%s action=%s", trigID, outID, GameInfo.Outcomes[outID].Action)
		log:Debug(message)
		
		assert(loadstring("return " .. GameInfo.Outcomes[outID].Action))(playerID, trigID, outID, targetID)
		Events.GameplayAlertMessage(message)
	end
end
LuaEvents.TriggerPopup.Add(DoTriggerPopup)