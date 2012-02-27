-------------------------------
-- TopPanel.lua
-------------------------------

--AttilaMod+
include("TopPanel_Clock");
include("CiVUP_Core.lua")

function TradedResources(iResourceID)
	local iPlayerID = Game.GetActivePlayer();
	local import = 0;
	local export = 0;
	local citystate = 0;
	
	if (Game.GetResourceUsageType(iResourceID) == ResourceUsageTypes.RESOURCEUSAGE_BONUS) then
		return 0,0,0;
	end

	if(iPlayerID >= 0) then
		local itemType, duration, finalTurn, data1, data2, fromPlayer;

		local m_Deal = UI.GetScratchDeal();
		local iNumCurrentDeals = UI:GetNumCurrentDeals( iPlayer );

		if( iNumCurrentDeals > 0 ) then
			for i = 0, iNumCurrentDeals - 1 do
				UI.LoadCurrentDeal( iPlayerID, i );
				
				m_Deal:ResetIterator();
				itemType, duration, finalTurn, data1, data2, fromPlayer = m_Deal:GetNextItem();
				repeat
					if(itemType == TradeableItems.TRADE_ITEM_RESOURCES) then
						if (data1 == iResourceID) then
							if (fromPlayer == iPlayerID) then
								export = export + 1;
							else
								import = import + 1;
							end
						end
					end
					itemType, duration, finalTurn, data1, data2, fromPlayer = m_Deal:GetNextItem();
				until (itemType == nil);
			end
		end
		
		for minorCivID,minorCiv in pairs(Players) do
			if minorCiv and minorCiv:IsMinorCiv() and minorCiv:IsAlive() and minorCiv:GetNumCities() > 0 then
				if minorCiv:GetMinorCivFriendshipLevelWithMajor(iPlayerID) == 2 then
					citystate = citystate + minorCiv:GetResourceExport(iResourceID)
				end
			end
		end
	end
	return import, export, citystate;
end

--Great People display helper functions - from BlakeTheGreat

local bestGPCity;

--return a dictionary of all the GPs from each pCity being built in the format: [{pCity, specialist} = progress]
function GetGPList(pPlayer)
	local progresses = {};
	for pCity in pPlayer:Cities() do
		for pSpecialistInfo in GameInfo.Specialists() do	
			local gpEntry				= {};
			gpEntry.progress			= pCity:GetSpecialistGreatPersonProgress(pSpecialistInfo.ID);
			gpEntry.perTurn				= getRateOfChange(pCity,pSpecialistInfo,pPlayer);
			if (gpEntry.progress > 0) or (gpEntry.perTurn > 0) then
				gpEntry.pCity			= pCity;
				gpEntry.specialistInfo	= pSpecialistInfo;
				gpEntry.name			= Locale.ConvertTextKey(GameInfo.UnitClasses[pSpecialistInfo.GreatPeopleUnitClass].Description);
				gpEntry.color			= GameInfo.UnitClasses[pSpecialistInfo.GreatPeopleUnitClass].Color;
				gpEntry.icon			= GameInfo.UnitClasses[pSpecialistInfo.GreatPeopleUnitClass].IconString;
				gpEntry.threshold		= pCity:GetSpecialistUpgradeThreshold();
				gpEntry.turnsRemaining	= math.ceil((gpEntry.threshold - gpEntry.progress) / gpEntry.perTurn);
				table.insert(progresses, gpEntry);
			end
		end
	end
	return progresses;
end

--given a pCity and GP, returns the progress per turn
function getRateOfChange(pCity, specialistInfo, pPlayer)
	local iCount = pCity:GetSpecialistCount( specialistInfo.ID );
	local iGPPChange = specialistInfo.GreatPeopleRateChange * iCount * 100;
	for building in GameInfo.Buildings() do
		local buildingID = building.ID;
		if building.SpecialistType == specialistInfo.Type then
			if (pCity:IsHasBuilding(buildingID)) then
				iGPPChange = iGPPChange + building.GreatPeopleRateChange * 100;
			end
		end
	end
	if iGPPChange > 0 then
		local iMod = 0;
		iMod = iMod + pCity:GetGreatPeopleRateModifier();
		iMod = iMod + pPlayer:GetGreatPeopleRateModifier();
		if (specialistInfo.GreatPeopleUnitClass == "UNITCLASS_SCIENTIST") then
			iMod = iMod + pPlayer:GetTraitGreatScientistRateModifier();
		end
		iGPPChange = (iGPPChange * (100 + iMod)) / 100;
		return math.floor(iGPPChange/100);
	else
		return 0;
	end
end

--AttilaMod-

function UpdateData()

	local iPlayerID = Game.GetActivePlayer();
	if iPlayerID < 0 then
		return
	end

	local pPlayer = Players[iPlayerID];
	local pTeam = Teams[pPlayer:GetTeam()];

	-- Update turn counter
	local turn = Locale.ConvertTextKey("TXT_KEY_TP_TURN_COUNTER", Game.GetGameTurn());
	Controls.CurrentTurn:SetText(turn);
		
	-- Update date
	local year = Game.GetGameTurnYear();
	local date;
	if year < 0 then
		date = Locale.ConvertTextKey("TXT_KEY_TIME_BC", math.abs(year));
	else
		date = Locale.ConvertTextKey("TXT_KEY_TIME_AD", math.abs(year));
	end		
	Controls.CurrentDate:SetText(date);
	
	if pPlayer:GetNumCities() <= 0 then
		Controls.TopPanelInfoStack:SetHide(true)
		return
	end
	
	if not pPlayer:IsTurnActive() then
		return
	end

	Controls.TopPanelInfoStack:SetHide(false);
	
	local pCity = UI.GetHeadSelectedCity();
	if pCity and UI.IsCityScreenUp() then		
		Controls.MenuButton:SetText(Locale.ToUpper(Locale.ConvertTextKey("TXT_KEY_RETURN")));
		Controls.MenuButton:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_CITY_SCREEN_EXIT_TOOLTIP"));
	else
		Controls.MenuButton:SetText(Locale.ToUpper(Locale.ConvertTextKey("TXT_KEY_MENU")));
		Controls.MenuButton:SetToolTipString(Locale.ConvertTextKey("TXT_KEY_MENU_TOOLTIP"));
	end

	-----------------------------
	-- Update science stats
	-----------------------------
	local strScienceText;

	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE)) then
		strScienceText = Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_SCIENCE_OFF");
	else

		local sciencePerTurn = Player_GetYieldRate(pPlayer, YieldTypes.YIELD_SCIENCE);

		-- No Science
		if (sciencePerTurn <= 0) then
			strScienceText = string.format("[COLOR:255:60:60:255]" .. Locale.ConvertTextKey("TXT_KEY_NO_SCIENCE") .. "[/COLOR]");
		-- We have science
		else
			local pTeamTechs = pTeam:GetTeamTechs();
			
			eCurrentTech = pPlayer:GetCurrentResearch();
			eRecentTech = pTeamTechs:GetLastTechAcquired();

			if (eCurrentTech ~= -1) then
				local iResearchTurnsLeft = Player_GetYieldTurns(pPlayer, YieldTypes.YIELD_SCIENCE,  eCurrentTech);
				local pTechInfo = GameInfo.Technologies[eCurrentTech];
				local szText = Locale.ConvertTextKey( pTechInfo.Description );
				strScienceText = string.format("%s (%i)", szText, math.ceil(iResearchTurnsLeft));
			elseif (eRecentTech ~= -1) then
				local pTechInfo = GameInfo.Technologies[eRecentTech];
				local szText = Locale.ConvertTextKey( pTechInfo.Description );
				strScienceText = string.format("%s (%i)", szText, 0);
				
			end

			local iGoldPerTurn = Player_GetYieldRate(pPlayer, YieldTypes.YIELD_GOLD);
			
			-- Gold being deducted from our Science
			if (pPlayer:GetGold() + iGoldPerTurn < 0) then
				strScienceText = "[COLOR:255:60:0:255]" .. strScienceText .. "[/COLOR]";
			-- Normal Science state
			else
				strScienceText = "[COLOR:33:190:247:255]" .. strScienceText .. "[/COLOR]";
			end
		end

		strScienceText = "[ICON_RESEARCH]" .. strScienceText;
	end

	Controls.SciencePerTurn:SetText(strScienceText);

	-----------------------------
	-- Update gold stats
	-----------------------------
	local iTotalGold = pPlayer:GetGold();
	local iGoldPerTurn = Player_GetYieldRate(pPlayer, YieldTypes.YIELD_GOLD);

	-- Accounting for positive or negative GPT - there's obviously a better way to do this.  If you see this comment and know how, it's up to you ;)
	-- Text is White when you can buy a Plot
	--if (iTotalGold >= pPlayer:GetBuyPlotCost(-1,-1)) then
		--if (iGoldPerTurn >= 0) then
			--strGoldStr = string.format("[COLOR:255:255:255:255]%i (+%i)[/COLOR]", iTotalGold, iGoldPerTurn)
		--else
			--strGoldStr = string.format("[COLOR:255:255:255:255]%i (%i)[/COLOR]", iTotalGold, iGoldPerTurn)
		--end
	---- Text is Yellow or Red when you can't buy a Plot
	--else
	local strGoldStr = Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_GOLD", iTotalGold, iGoldPerTurn);
	--end

	Controls.GoldPerTurn:SetText(strGoldStr);

	-----------------------------
	-- Update Happiness
	-----------------------------
	local strHappiness;

	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_HAPPINESS)) then
		strHappiness = Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_HAPPINESS_OFF");
	else
		local iHappiness = Round(Player_GetYieldRate(pPlayer, YieldTypes.YIELD_HAPPINESS));
		local tHappinessTextColor;

		-- Empire is Happiness
		if iHappiness >= 0 then
			strHappiness = string.format("[ICON_HAPPINESS_1][COLOR:60:255:60:255]%i[/COLOR]", iHappiness);
		
		-- Empire Really Unhappy
		elseif iHappiness <= GameDefines.VERY_UNHAPPY_THRESHOLD then
			strHappiness = string.format("[ICON_HAPPINESS_4][COLOR:255:60:60:255]%i[/COLOR]", -iHappiness);
		
		-- Empire Unhappy
		else
			strHappiness = string.format("[ICON_HAPPINESS_3][COLOR:255:60:60:255]%i[/COLOR]", -iHappiness);
		end
	end

	Controls.HappinessString:SetText(strHappiness);

	-----------------------------
	-- Update Golden Age Info
	-----------------------------
	local strGoldenAgeStr = "";

	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_HAPPINESS)) then
		strGoldenAgeStr = Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_GOLDEN_AGES_OFF");
	else
		strGoldenAgeStr = string.format("%s%i/%i", strGoldenAgeStr, pPlayer:GetGoldenAgeProgressMeter(), pPlayer:GetGoldenAgeProgressThreshold());
		if (pPlayer:GetGoldenAgeTurns() > 0) then
			strGoldenAgeStr = string.format("%s (%i %s!)", strGoldenAgeStr, pPlayer:GetGoldenAgeTurns(), Locale.ConvertTextKey("TXT_KEY_TURNS"));
		end

		strGoldenAgeStr = "[ICON_GOLDEN_AGE][COLOR:255:255:255:255]" .. strGoldenAgeStr .. "[/COLOR]";
	end

	Controls.GoldenAgeString:SetText(strGoldenAgeStr);

	-----------------------------
	-- Update Culture
	-----------------------------

	local strCultureStr;

	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES)) then
		strCultureStr = Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_POLICIES_OFF");
	else
		strCultureStr = "[ICON_CULTURE][COLOR:255:0:255:255]" .. Player_GetYieldTurns(pPlayer, YieldTypes.YIELD_CULTURE) .. "[ENDCOLOR][/COLOR]";
	end

	Controls.CultureString:SetText(strCultureStr);
	
	-----------------------------------------------
	----------- Update Great People ---------------
	-----------------------------------------------


	--Controls.GreatPeopleString:SetHide(false);

	local strTooltip = ""

	local GPList = GetGPList(pPlayer)

	if GPList ~= nil then
		table.sort(GPList, function (a,b)
			if a.turnsRemaining ~= b.turnsRemaining then
				return a.turnsRemaining < b.turnsRemaining
			else
				if a.progress ~= b.progress then
					return a.progress < b.progress
				else
					return a.name < b.name
				end
			end
		end)
		local bestGP = GPList[1]
		if bestGP and bestGP.perTurn > 0 then
			bestGPCity = bestGP.pCity
			strTooltip = strTooltip .. "[ICON_GREAT_PEOPLE][COLOR:" .. bestGP.color .. "]" .. bestGP.name
			strTooltip = strTooltip ..  " (" .. bestGP.turnsRemaining .. ")[/COLOR]"
		else
			bestGPCity = nil
			gpName = Locale.ConvertTextKey(GameInfo.UnitClasses.UNITCLASS_GREAT_GENERAL.Description)
			gpColor = Locale.ConvertTextKey(GameInfo.UnitClasses.UNITCLASS_GREAT_GENERAL.Color)
			strTooltip =  "[ICON_GREAT_PEOPLE]"..gpName .. " (" .. pPlayer:GetCombatExperience() .."/" .. pPlayer:GreatGeneralThreshold() .. ")"
		end
	end
	Controls.GreatPeopleString:SetText(strTooltip);
	--AttilaMod-

	-----------------------------
	-- Update Resources
	-----------------------------
	local iLuxurySurplus = 0;
	local strResourceText = "";

	for pResource in GameInfo.Resources() do
		local iResourceLoop = pResource.ID;
		local iNumImport, iNumExport, iNumCitystates = TradedResources(iResourceLoop);
		local bShowResource	= false;
		local iNumAvailable	= pPlayer:GetNumResourceAvailable(iResourceLoop, true)
		local iNumUsed		= pPlayer:GetNumResourceUsed(iResourceLoop, true)
		local iNumTradable	= iNumAvailable - iNumImport - iNumCitystates
	
		if (Game.GetResourceUsageType(iResourceLoop) == ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC) then				
			bShowResource = iNumUsed > 0;
		
			if (pTeam:GetTeamTechs():HasTech(GameInfoTypes[pResource.TechReveal])) then
				if (pTeam:GetTeamTechs():HasTech(GameInfoTypes[pResource.TechCityTrade])) then
					bShowResource = true;
				end
			end
		
			if (bShowResource) then
				local strTempText = string.format(" %s %i  ", Locale.ConvertTextKey(pResource.IconString), iNumAvailable);
				if (iNumTradable > 0) then
					strTempText = "[COLOR_POSITIVE_TEXT]" .. strTempText .. "[ENDCOLOR]";
				elseif (iNumAvailable < 0) then
					strTempText = "[COLOR_WARNING_TEXT]" .. strTempText .. "[ENDCOLOR]";
				end
				strResourceText = strResourceText .. strTempText;
			end
		elseif (Game.GetResourceUsageType(iResourceLoop) == ResourceUsageTypes.RESOURCEUSAGE_LUXURY) then
			if (iNumAvailable > 0) and (iNumAvailable == iNumTradable) then
				iNumTradable = iNumTradable - 1
			end
			if(iNumTradable > 0) then
				iLuxurySurplus = iLuxurySurplus + iNumTradable;
			end
		end
	end
	if iLuxurySurplus > 0 then
		iLuxurySurplus = "[COLOR_POSITIVE_TEXT]".. iLuxurySurplus .."[/COLOR]";
	end		
	Controls.ResourceString:SetText(strResourceText.." [ICON_RES_GEMS]"..iLuxurySurplus);

	-- Update Unit Supply
	local supplyMod = Player_GetSupplyModifier(pPlayer, YieldTypes.YIELD_PRODUCTION, true)
	if (supplyMod ~= 0) then
		local maxSupply = GetMaxUnitSupply(pPlayer)
		local netSupply = GetMaxUnitSupply(pPlayer) - GetCurrentUnitSupply(pPlayer)
		local strUnitSupplyToolTip = Locale.ConvertTextKey("TXT_KEY_UNIT_SUPPLY_REACHED_TOOLTIP", maxSupply, -netSupply, -supplyMod);

		Controls.UnitSupplyString:SetToolTipString(strUnitSupplyToolTip);
		Controls.UnitSupplyString:SetHide(false);
	else
		Controls.UnitSupplyString:SetHide(true);
	end
	--]]
end

function OnTopPanelDirty()
	UpdateData();
end

-------------------------------------------------
-------------------------------------------------
function OnCivilopedia()	
	-- In City View, return to main game
	--if (UI.GetHeadSelectedCity() ~= nil) then
		--Events.SerialEventExitCityScreen();
	--end
	--
	-- opens the Civilopedia without changing its current state
	Events.SearchForPediaEntry("");
end
Controls.CivilopediaButton:RegisterCallback( Mouse.eLClick, OnCivilopedia );


-------------------------------------------------
-------------------------------------------------
function OnMenu()
	
	-- In City View, return to main game
	if (UI.GetHeadSelectedCity() ~= nil) then
		Events.SerialEventExitCityScreen();
		--UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_SELECTION);
	-- In Main View, open Menu Popup
	else
	    UIManager:QueuePopup( LookUpControl( "/InGame/GameMenu" ), PopupPriority.InGameMenu );
	end
end
Controls.MenuButton:RegisterCallback( Mouse.eLClick, OnMenu );


-------------------------------------------------
-------------------------------------------------
function OnCultureClicked()
	
	Events.SerialEventGameMessagePopup( { Type = ButtonPopupTypes.BUTTONPOPUP_CHOOSEPOLICY } );

end
Controls.CultureString:RegisterCallback( Mouse.eLClick, OnCultureClicked );


-------------------------------------------------
-------------------------------------------------
function OnTechClicked()
	
	Events.SerialEventGameMessagePopup( { Type = ButtonPopupTypes.BUTTONPOPUP_TECH_TREE } );

end
Controls.SciencePerTurn:RegisterCallback( Mouse.eLClick, OnTechClicked );


-------------------------------------------------
-------------------------------------------------
function OnGoldClicked()
	
	Events.SerialEventGameMessagePopup( { Type = ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW } );

end
Controls.HappinessString:RegisterCallback( Mouse.eLClick, OnGoldClicked );
Controls.GoldenAgeString:RegisterCallback( Mouse.eLClick, OnGoldClicked );
Controls.GoldPerTurn:RegisterCallback( Mouse.eLClick, OnGoldClicked );


-------------------------------------------------
-------------------------------------------------
function OnGreatPeopleClicked()
	if bestGPCity == nil then
		Events.SerialEventGameMessagePopup( { Type = ButtonPopupTypes.BUTTONPOPUP_MILITARY_OVERVIEW } );
		return;
	end
	
	local plot = bestGPCity:Plot();
	if plot then
		local playerID = plot:GetOwner();
		local pPlayer = Players[playerID];
		
		-- Puppets are special
		if (bestGPCity:IsPuppet()) then
			local popupInfo = {
					Type = ButtonPopupTypes.BUTTONPOPUP_ANNEX_CITY,
					Data1 = bestGPCity:GetID(),
					Data2 = -1,
					Data3 = -1,
					Option1 = false,
					Option2 = false;
				}
			Events.SerialEventGameMessagePopup(popupInfo);
		else
			UI.DoSelectCityAtPlot( plot );
		end
	end
end
Controls.GreatPeopleString:RegisterCallback( Mouse.eLClick, OnGreatPeopleClicked );


-------------------------------------------------
-------------------------------------------------
function OnResourcesClicked()
	
	Events.SerialEventGameMessagePopup( { Type = ButtonPopupTypes.BUTTONPOPUP_DIPLOMATIC_OVERVIEW } );

end
Controls.ResourceString:RegisterCallback( Mouse.eLClick, OnResourcesClicked );


-------------------------------------------------
-------------------------------------------------
function OnTurnsClicked()
	if MapModData.InfoAddict then
		UIManager:PushModal(MapModData.InfoAddict.InfoAddictScreenContext);
	end
end
Controls.CurrentDate:RegisterCallback( Mouse.eLClick, OnTurnsClicked );
Controls.CurrentTurn:RegisterCallback( Mouse.eLClick, OnTurnsClicked );




-------------------------------------------------
-- TOOLTIPS
-------------------------------------------------


-- Tooltip init
function DoInitTooltips()
	Controls.SciencePerTurn:SetToolTipCallback( ScienceTipHandler );
	Controls.GoldPerTurn:SetToolTipCallback( GoldTipHandler );
	Controls.HappinessString:SetToolTipCallback( HappinessTipHandler );
	Controls.GoldenAgeString:SetToolTipCallback( GoldenAgeTipHandler );
	Controls.CultureString:SetToolTipCallback( CultureTipHandler );
	Controls.GreatPeopleString:SetToolTipCallback(GreatPeopleTipHandler);
	Controls.ResourceString:SetToolTipCallback( ResourcesTipHandler );
end

-- Science Tooltip
local tipControlTable = {};
TTManager:GetTypeControlTable( "TooltipTypeTopPanel", tipControlTable );
function ScienceTipHandler( control )
	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_SCIENCE)) then
		strText = Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_SCIENCE_OFF_TOOLTIP");
		tipControlTable.TooltipLabel:SetText( strText );
		tipControlTable.TopPanelMouseover:SetHide(false);
	    
	    -- Autosize tooltip
	    tipControlTable.TopPanelMouseover:DoAutoSize();
		return;
	end

	local strText = "";
	local iPlayerID = Game.GetActivePlayer();
	local pPlayer = Players[iPlayerID];
	local pTeam = Teams[pPlayer:GetTeam()];
	local pCity = UI.GetHeadSelectedCity();
	
	local iSciencePerTurn = Player_GetYieldRate(pPlayer, YieldTypes.YIELD_SCIENCE);

	local bFirstEntry = true;
	
	-- Science
	if (not OptionsManager.IsNoBasicHelp()) then
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_SCIENCE", iSciencePerTurn);
		
		if (pPlayer:GetNumCities() > 0) then
			strText = strText .. "[NEWLINE][NEWLINE]";
		end
	else
		if (bFirstEntry) then
			bFirstEntry = false;
		else
			strText = strText .. "[NEWLINE]";
		end

		local strScienceText = string.format("+%i", iSciencePerTurn);
		strScienceText = "[COLOR:33:190:247:255]" .. strScienceText .. "[/COLOR]";

		strText = strText .. strScienceText;
		strText = strText .. "[ICON_RESEARCH]";
		strText = strText .. " per turn";
		strText = strText .. "[NEWLINE]";
	end
	
	-- Science LOSS from Budget Deficits
	local iScienceFromBudgetDeficit = pPlayer:GetScienceFromBudgetDeficitTimes100();
	if (iScienceFromBudgetDeficit ~= 0) then
		
		-- Add separator for non-initial entries
		if (bFirstEntry) then
			bFirstEntry = false;
		else
			strText = strText .. "[NEWLINE]";
		end

		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_SCIENCE_FROM_BUDGET_DEFICIT", iScienceFromBudgetDeficit / 100);
		strText = strText .. "[NEWLINE]";
	end
	
	-- Science from Cities
	local iScienceFromCities = pPlayer:GetScienceFromCitiesTimes100();
	if (iScienceFromCities ~= 0) then
		
		-- Add separator for non-initial entries
		if (bFirstEntry) then
			bFirstEntry = false;
		else
			strText = strText .. "[NEWLINE]";
		end

		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_SCIENCE_FROM_CITIES", iScienceFromCities / 100);
	end
	
	-- Science from Other Players
	local iScienceFromOtherPlayers = pPlayer:GetScienceFromOtherPlayersTimes100();
	if (iScienceFromOtherPlayers ~= 0) then
		
		-- Add separator for non-initial entries
		if (bFirstEntry) then
			bFirstEntry = false;
		else
			strText = strText .. "[NEWLINE]";
		end

		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_SCIENCE_FROM_MINORS", iScienceFromOtherPlayers / 100);
	end
	
	-- Science from Happiness
	local iScienceFromHappiness = pPlayer:GetScienceFromHappinessTimes100();
	if (iScienceFromHappiness ~= 0) then
		
		-- Add separator for non-initial entries
		if (bFirstEntry) then
			bFirstEntry = false;
		else
			strText = strText .. "[NEWLINE]";
		end

		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_SCIENCE_FROM_HAPPINESS", iScienceFromHappiness / 100);
	end
	
	-- Science from Research Agreements
	local iScienceFromRAs = Player_GetTradeDealYield(pPlayer, YieldTypes.YIELD_SCIENCE);
	if (iScienceFromRAs ~= 0) then
		
		-- Add separator for non-initial entries
		if (bFirstEntry) then
			bFirstEntry = false;
		else
			strText = strText .. "[NEWLINE]";
		end
	
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_SCIENCE_FROM_RESEARCH_AGREEMENTS", Round(iScienceFromRAs));
	end
	
	tipControlTable.TooltipLabel:SetText( strText );
	tipControlTable.TopPanelMouseover:SetHide(false);
    
    -- Autosize tooltip
    tipControlTable.TopPanelMouseover:DoAutoSize();
	
end

-- Gold Tooltip
function GoldTipHandler( control )

	local strText = "";
	local iPlayerID = Game.GetActivePlayer();
	local pPlayer = Players[iPlayerID];
	local pTeam = Teams[pPlayer:GetTeam()];
	local pCity = UI.GetHeadSelectedCity();
	
	local iTotalGold = pPlayer:GetGold();

	local iGoldPerTurnFromOtherPlayers = pPlayer:GetGoldPerTurnFromDiplomacy();
	local iGoldPerTurnToOtherPlayers = 0;
	if (iGoldPerTurnFromOtherPlayers < 0) then
		iGoldPerTurnToOtherPlayers = -iGoldPerTurnFromOtherPlayers;
		iGoldPerTurnFromOtherPlayers = 0;
	end

	local fGoldPerTurnFromCities = pPlayer:GetGoldFromCitiesTimes100() / 100;
	local fCityConnectionGold = pPlayer:GetCityConnectionGoldTimes100() / 100;
	local fOpenBordersGold = Player_GetTradeDealYield(pPlayer, YieldTypes.YIELD_GOLD);
	local fTotalIncome = fGoldPerTurnFromCities + iGoldPerTurnFromOtherPlayers + fCityConnectionGold + fOpenBordersGold;
	
	if (not OptionsManager.IsNoBasicHelp()) then
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_AVAILABLE_GOLD", iTotalGold);
		strText = strText .. "[NEWLINE][NEWLINE]";
	end
	
	strText = strText .. "[COLOR:150:255:150:255]";
	strText = strText .. "+" .. Locale.ConvertTextKey("TXT_KEY_TP_TOTAL_INCOME", math.floor(fTotalIncome));
	strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_CITY_OUTPUT", fGoldPerTurnFromCities);
	strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_FROM_TR", Round(fCityConnectionGold));
	if CiVUP.OPEN_BORDERS_GOLD_RATE_PERCENT and CiVUP.OPEN_BORDERS_GOLD_RATE_PERCENT ~= 0 then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_FROM_OPEN_BORDERS", Round(fOpenBordersGold));		
	end
	if (iGoldPerTurnFromOtherPlayers > 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_FROM_OTHERS", iGoldPerTurnFromOtherPlayers);
	end
	strText = strText .. "[/COLOR]";
	
	local iUnitCost = Player_CalculateUnitCost(pPlayer);
	local iUnitSupply = pPlayer:CalculateUnitSupply();
	local iBuildingMaintenance = pPlayer:GetBuildingGoldMaintenance();
	local iImprovementMaintenance = pPlayer:GetImprovementGoldMaintenance();
	local iTotalExpenses = iUnitCost + iUnitSupply + iBuildingMaintenance + iImprovementMaintenance + iGoldPerTurnToOtherPlayers;
	
	strText = strText .. "[NEWLINE]";
	strText = strText .. "[COLOR:255:150:150:255]";
	strText = strText .. "[NEWLINE]-" .. Locale.ConvertTextKey("TXT_KEY_TP_TOTAL_EXPENSES", iTotalExpenses);
	if (iUnitCost ~= 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_UNIT_MAINT", iUnitCost);
	end
	if (iUnitSupply ~= 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_UNIT_SUPPLY", iUnitSupply);
	end
	if (iBuildingMaintenance ~= 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_BUILDING_MAINT", iBuildingMaintenance);
	end
	if (iImprovementMaintenance ~= 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_TILE_MAINT", iImprovementMaintenance);
	end
	if (iGoldPerTurnToOtherPlayers > 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_TO_OTHERS", iGoldPerTurnToOtherPlayers);
	end
	strText = strText .. "[/COLOR]";
	
	if (fTotalIncome + iTotalGold < 0) then
		strText = strText .. "[NEWLINE][COLOR:255:60:60:255]" .. Locale.ConvertTextKey("TXT_KEY_TP_LOSING_SCIENCE_FROM_DEFICIT") .. "[/COLOR]";
	end
	
	-- Basic explanation of Happiness
	if (not OptionsManager.IsNoBasicHelp()) then
		strText = strText .. "[NEWLINE][NEWLINE]";
		strText = strText ..  Locale.ConvertTextKey("TXT_KEY_TP_GOLD_EXPLANATION");
	end
	
	--Controls.GoldPerTurn:SetToolTipString(strText);
	
	tipControlTable.TooltipLabel:SetText( strText );
	tipControlTable.TopPanelMouseover:SetHide(false);
    
    -- Autosize tooltip
    tipControlTable.TopPanelMouseover:DoAutoSize();
	
end

-- Happiness Tooltip
function HappinessTipHandler( control )
	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_HAPPINESS)) then
		strText = Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_HAPPINESS_OFF_TOOLTIP");
		tipControlTable.TooltipLabel:SetText( strText );
		tipControlTable.TopPanelMouseover:SetHide(false);
	    
	    -- Autosize tooltip
	    tipControlTable.TopPanelMouseover:DoAutoSize();
		return;
	end

	local strText;
	local iPlayerID = Game.GetActivePlayer();
	local pPlayer = Players[iPlayerID];
	local pTeam = Teams[pPlayer:GetTeam()];
	local pCity = UI.GetHeadSelectedCity();	
	local yieldType = YieldTypes.YIELD_HAPPINESS;

	local iHappiness = Round(Player_GetYieldRate(pPlayer, yieldType));	
	local iTotalHappiness = iHappiness + pPlayer:GetUnhappiness();
	local iPoliciesHappiness = pPlayer:GetHappinessFromPolicies() + Player_GetYieldsFromCitystates(pPlayer)[yieldType];
	local iResourcesHappiness = pPlayer:GetHappinessFromResources() + Player_GetYieldFromSurplusResources(pPlayer, yieldType);
	local iExtraLuxuryHappiness = pPlayer:GetExtraHappinessPerLuxury();
	local iBuildingHappiness = pPlayer:GetHappinessFromBuildings() - GetNumBuilding(pPlayer:GetCapitalCity(), GameInfo.Buildings.BUILDING_EXTRA_HAPPINESS.ID);
	local iGarrisonedUnitsHappiness = pPlayer:GetHappinessFromGarrisonedUnits();
	local iTradeRouteHappiness = pPlayer:GetHappinessFromTradeRoutes();
	local iReligionHappiness = pPlayer:GetHappinessFromReligion();
	local iNaturalWonderHappiness = pPlayer:GetHappinessFromNaturalWonders();
	local iExtraHappinessPerCity = pPlayer:GetExtraHappinessPerCity() * pPlayer:GetNumCities();
	local iHandicapHappiness = GameInfo.HandicapInfos[Players[Game.GetActivePlayer()]:GetHandicapType()].HappinessDefault;	
	local iMinorCivHappiness = 0;
	local pMinor;
	
	-- Loop through all the Minors the active pPlayer knows
	for iPlayerLoop = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS-1, 1 do
		iMinorCivHappiness = iMinorCivHappiness + pPlayer:GetHappinessFromMinor(iPlayerLoop);
	end

	if iHappiness >= 0 then
		strText = Locale.ConvertTextKey("TXT_KEY_TP_TOTAL_HAPPINESS", iHappiness);
	elseif iHappiness <= GameDefines.VERY_UNHAPPY_THRESHOLD then
		strText = Locale.ConvertTextKey("TXT_KEY_TP_TOTAL_UNHAPPINESS", "[ICON_HAPPINESS_4]", -iHappiness);
	else
		strText = Locale.ConvertTextKey("TXT_KEY_TP_TOTAL_UNHAPPINESS", "[ICON_HAPPINESS_3]", -iHappiness);
	end	
	
	if iHappiness <= GameDefines.VERY_UNHAPPY_THRESHOLD then
		
		if (pPlayer:IsEmpireSuperUnhappy()) then
			strText = strText .. "[NEWLINE][NEWLINE]";
			strText = strText .. "[COLOR:255:60:60:255]" .. Locale.ConvertTextKey("TXT_KEY_TP_EMPIRE_SUPER_UNHAPPY") .. "[/COLOR]";
		end
		
		strText = strText .. "[NEWLINE][NEWLINE]";
		strText = strText .. "[COLOR:255:60:60:255]" .. Locale.ConvertTextKey("TXT_KEY_TP_EMPIRE_VERY_UNHAPPY") .. "[/COLOR]";
	elseif iHappiness < 0 then
		
		strText = strText .. "[NEWLINE][NEWLINE]";
		strText = strText .. "[COLOR:255:60:60:255]" .. Locale.ConvertTextKey("TXT_KEY_TP_EMPIRE_UNHAPPY") .. "[/COLOR]";
	end
	
	strText = strText .. "[NEWLINE][NEWLINE]";
	strText = strText .. "[COLOR:150:255:150:255]";
	strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_SOURCES", iTotalHappiness);
	
	strText = strText .. "[NEWLINE]";
	strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_FROM_RESOURCES", iResourcesHappiness);
	
	-- Individual Resource Info

	local iBaseHappinessFromResources = 0;
	local iNumHappinessResources = 0;
	for resource in GameInfo.Resources() do
		local resourceID = resource.ID;
		if (pPlayer:GetNumResourceTotal(resourceID, true) > 0) then
			if (resource.Happiness ~= 0) then
				strText = strText .. "[NEWLINE]";
				strText = strText .. "          +" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_EACH_RESOURCE", resource.Happiness, resource.IconString, resource.Description);
				iNumHappinessResources = iNumHappinessResources + 1;
				iBaseHappinessFromResources = iBaseHappinessFromResources + resource.Happiness;
			end
		end
	end
	
	-- Happiness from Luxury Variety
	local iHappinessFromExtraResources = pPlayer:GetHappinessFromResourceVariety();
	if (iHappinessFromExtraResources > 0) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "          +" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_RESOURCE_VARIETY", iHappinessFromExtraResources);
	end
	
	-- Extra Happiness from each Luxury
	if (iExtraLuxuryHappiness >= 1) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "          +" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_EXTRA_PER_RESOURCE", iExtraLuxuryHappiness, iExtraLuxuryHappiness * iNumHappinessResources + Player_GetYieldFromSurplusResources(pPlayer, yieldType));
	end
	
	-- Misc Happiness from Resources
	local iMiscHappiness = iResourcesHappiness - iBaseHappinessFromResources - iHappinessFromExtraResources - (iExtraLuxuryHappiness * iNumHappinessResources) - Player_GetYieldFromSurplusResources(pPlayer, yieldType);
	if (iMiscHappiness > 0) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "          +" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_OTHER_SOURCES", iMiscHappiness);
	end
	
	strText = strText .. "[NEWLINE]";
	strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_POLICIES", iPoliciesHappiness);
	strText = strText .. "[NEWLINE]";
	strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_BUILDINGS", iBuildingHappiness);
	if (iGarrisonedUnitsHappiness ~= 0) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_GARRISONED_UNITS", iGarrisonedUnitsHappiness);
	end
	if (iTradeRouteHappiness ~= 0) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_CONNECTED_CITIES", iTradeRouteHappiness);
	end
	if (iReligionHappiness ~= 0) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_STATE_RELIGION", iReligionHappiness);
	end
	if (iNaturalWonderHappiness ~= 0) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_NATURAL_WONDERS", iNaturalWonderHappiness);
	end
	if (iExtraHappinessPerCity ~= 0) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_CITY_COUNT", iExtraHappinessPerCity);
	end
	if (iMinorCivHappiness ~= 0) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_CITY_STATE_FRIENDSHIP", iMinorCivHappiness);
	end
	strText = strText .. "[NEWLINE]";
	strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_DIFFICULTY_LEVEL", iHandicapHappiness);
	strText = strText .. "[/COLOR]";
	
	-- Unhappiness
	local iTotalUnhappiness = pPlayer:GetUnhappiness();
	local iUnhappinessFromUnits = Locale.ToNumber( pPlayer:GetUnhappinessFromUnits() / 100, "#.#" );
	local iUnhappinessFromCityCount = Locale.ToNumber( pPlayer:GetUnhappinessFromCityCount() / 100, "#.#" );
	local iUnhappinessFromCapturedCityCount = Locale.ToNumber( pPlayer:GetUnhappinessFromCapturedCityCount() / 100, "#.#" );
	local iUnhappinessFromPupetCities = pPlayer:GetUnhappinessFromPuppetCityPopulation();
	local unhappinessFromSpecialists = pPlayer:GetUnhappinessFromCitySpecialists();
	local unhappinessFromPop = pPlayer:GetUnhappinessFromCityPopulation() - unhappinessFromSpecialists - iUnhappinessFromPupetCities;
	
	local iUnhappinessFromPop = Locale.ToNumber( unhappinessFromPop / 100, "#.##" );
	local iUnhappinessFromOccupiedCities = Locale.ToNumber( pPlayer:GetUnhappinessFromOccupiedCities() / 100, "#.##" );


	strText = strText .. "[NEWLINE][NEWLINE]";
	strText = strText .. "[COLOR:255:150:150:255]";
	strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_UNHAPPINESS_TOTAL", iTotalUnhappiness);
	strText = strText .. "[NEWLINE]";
	strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_UNHAPPINESS_CITY_COUNT", iUnhappinessFromCityCount);
	if (iUnhappinessFromCapturedCityCount ~= "0") then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_UNHAPPINESS_CAPTURED_CITY_COUNT", iUnhappinessFromCapturedCityCount);
	end
	strText = strText .. "[NEWLINE]";
	strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_UNHAPPINESS_POPULATION", iUnhappinessFromPop);
	if(iUnhappinessFromPupetCities > 0) then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_UNHAPPINESS_PUPPET_CITIES", iUnhappinessFromPupetCities / 100);
	end
	if (iUnhappinessFromOccupiedCities ~= "0") then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_UNHAPPINESS_OCCUPIED_POPULATION", iUnhappinessFromOccupiedCities);
	end
	if(unhappinessFromSpecialists > 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_UNHAPPINESS_SPECIALISTS", unhappinessFromSpecialists / 100);
	end
	if (iUnhappinessFromUnits ~= "0") then
		strText = strText .. "[NEWLINE]";
		strText = strText .. "  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_UNHAPPINESS_UNITS", iUnhappinessFromUnits);
	end
	strText = strText .. "[/COLOR]";
	
	-- Basic explanation of Happiness
	if (not OptionsManager.IsNoBasicHelp()) then
		strText = strText .. "[NEWLINE][NEWLINE]";
		strText = strText ..  Locale.ConvertTextKey("TXT_KEY_TP_HAPPINESS_EXPLANATION");
	end
	
	tipControlTable.TooltipLabel:SetText( strText );
	tipControlTable.TopPanelMouseover:SetHide(false);
    
    -- Autosize tooltip
    tipControlTable.TopPanelMouseover:DoAutoSize();
	
end

-- Golden Age Tooltip
function GoldenAgeTipHandler( control )

	local strText = "";
	local iPlayerID = Game.GetActivePlayer();
	local pPlayer = Players[iPlayerID];
	local pTeam = Teams[pPlayer:GetTeam()];
	local pCity = UI.GetHeadSelectedCity();
	
	if (pPlayer:GetGoldenAgeTurns() > 0) then
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_GOLDEN_AGE_NOW", pPlayer:GetGoldenAgeTurns());
	else
		local iHappiness = Round(Player_GetYieldRate(pPlayer, YieldTypes.YIELD_HAPPINESS));

--AttlaMod+
--Display turns left until next Golden Age (from salaminizer)
		local iTurns;

		if (iHappiness > 0) then
			iTurns = math.floor((pPlayer:GetGoldenAgeProgressThreshold() - pPlayer:GetGoldenAgeProgressMeter()) / iHappiness + 1);

			strText = string.format("%i turns left until the next Golden Age",iTurns);
			--strText = Locale.ConvertTextKey("TXT_KEY_NEXT_GOLDEN_AGE_TURN_LABEL", iTurns);
			strText = strText .. "[NEWLINE][NEWLINE]";
		end

--		strText = Locale.ConvertTextKey("TXT_KEY_TP_GOLDEN_AGE_PROGRESS", pPlayer:GetGoldenAgeProgressMeter(), pPlayer:GetGoldenAgeProgressThreshold());
		strText = strText..Locale.ConvertTextKey("TXT_KEY_TP_GOLDEN_AGE_PROGRESS", pPlayer:GetGoldenAgeProgressMeter(), pPlayer:GetGoldenAgeProgressThreshold());
--AttilaMod-

		strText = strText .. "[NEWLINE]";
		
		if (iHappiness >= 0) then
			strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_GOLDEN_AGE_ADDITION", iHappiness);
		else
			strText = strText .. "[COLOR_WARNING_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLDEN_AGE_LOSS", -iHappiness) .. "[ENDCOLOR]";
		end
	end
	
	strText = strText .. "[NEWLINE][NEWLINE]";
	strText = strText ..  Locale.ConvertTextKey("TXT_KEY_TP_GOLDEN_AGE_EFFECT");
	
	tipControlTable.TooltipLabel:SetText( strText );
	tipControlTable.TopPanelMouseover:SetHide(false);
    
    -- Autosize tooltip
    tipControlTable.TopPanelMouseover:DoAutoSize();
	
end

-- Culture Tooltip
function CultureTipHandler( control )
	if (Game.IsOption(GameOptionTypes.GAMEOPTION_NO_POLICIES)) then
		strText = Locale.ConvertTextKey("TXT_KEY_TOP_PANEL_POLICIES_OFF_TOOLTIP");
		tipControlTable.TooltipLabel:SetText( strText );
		tipControlTable.TopPanelMouseover:SetHide(false);
	    
	    -- Autosize tooltip
	    tipControlTable.TopPanelMouseover:DoAutoSize();
		return;
	end


	local strText = "";
	local iPlayerID = Game.GetActivePlayer();
	local pPlayer = Players[iPlayerID];
    
    local iTurns;
    local iCultureNeeded = Player_GetYieldNeeded(pPlayer, YieldTypes.YIELD_CULTURE) - Player_GetYieldStored(pPlayer, YieldTypes.YIELD_CULTURE);
	local culturePerTurn = Round(Player_GetYieldRate(pPlayer, YieldTypes.YIELD_CULTURE))
    if (iCultureNeeded <= 0) then
		iTurns = 0;
    else
		if (culturePerTurn == 0) then
			iTurns = "?";
		else
			-- iTurns = iCultureNeeded / culturePerTurn;
			-- iTurns = iTurns + 1;
			-- iTurns = math.floor(iTurns);
			iTurns = iCultureNeeded / culturePerTurn;
			iTurns = math.ceil(iTurns);
		end
    end
    strText = strText .. Locale.ConvertTextKey("TXT_KEY_NEXT_POLICY_TURN_LABEL", iTurns);

--AttilaMod+
--Removed check for IsNoBasicHelp, so info always displayed since no longer on top panel

--	if (not OptionsManager.IsNoBasicHelp()) then
		strText = strText .. "[NEWLINE][NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_CULTURE_ACCUMULATED", Player_GetYieldStored(pPlayer, YieldTypes.YIELD_CULTURE));
		strText = strText .. "[NEWLINE]";
		
		if (Player_GetYieldNeeded(pPlayer, YieldTypes.YIELD_CULTURE) > 0) then
			strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_CULTURE_NEXT_POLICY", Player_GetYieldNeeded(pPlayer, YieldTypes.YIELD_CULTURE));
		end
--	end
--AttilaMod-

	local bFirstEntry = true;
	
	-- Culture for Free
	local iCultureForFree = pPlayer:GetJONSCulturePerTurnForFree();
	if (iCultureForFree ~= 0) then
		
		-- Add separator for non-initial entries
		if (bFirstEntry) then
			strText = strText .. "[NEWLINE]";
			bFirstEntry = false;
		end

		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_CULTURE_FOR_FREE", iCultureForFree);
	end
	
	-- Culture from Cities
	local iCultureFromCities = 0
	for pCity in pPlayer:Cities() do
		iCultureFromCities = iCultureFromCities + City_GetYieldRate(pCity, YieldTypes.YIELD_CULTURE)
	end
	if (iCultureFromCities ~= 0) then
		
		-- Add separator for non-initial entries
		if (bFirstEntry) then
			strText = strText .. "[NEWLINE]";
			bFirstEntry = false;
		end

		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_CULTURE_FROM_CITIES", iCultureFromCities);
	end
	
	-- Culture from Excess Happiness
	local iCultureFromHappiness = pPlayer:GetJONSCulturePerTurnFromExcessHappiness();
	if (iCultureFromHappiness ~= 0) then
		
		-- Add separator for non-initial entries
		if (bFirstEntry) then
			strText = strText .. "[NEWLINE]";
			bFirstEntry = false;
		end

		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_CULTURE_FROM_HAPPINESS", iCultureFromHappiness);
	end
	
	-- Culture from Minor Civs
	local iCultureFromMinors = pPlayer:GetJONSCulturePerTurnFromMinorCivs();
	if (iCultureFromMinors ~= 0) then
		
		-- Add separator for non-initial entries
		if (bFirstEntry) then
			strText = strText .. "[NEWLINE]";
			bFirstEntry = false;
		end

		strText = strText .. "[NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_CULTURE_FROM_MINORS", iCultureFromMinors);
	end
	
	-- Let people know that building more cities makes policies harder to get
	if (not OptionsManager.IsNoBasicHelp()) then
		strText = strText .. "[NEWLINE][NEWLINE]";
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_CULTURE_CITY_COST", Game.GetNumCitiesPolicyCostMod());
	end
	
	tipControlTable.TooltipLabel:SetText( strText );
	tipControlTable.TopPanelMouseover:SetHide(false);
    
    -- Autosize tooltip
    tipControlTable.TopPanelMouseover:DoAutoSize();
	
end

-- Resources Tooltip
function ResourcesTipHandler( control )

	local strText;
	local iPlayerID = Game.GetActivePlayer();
	local pPlayer = Players[iPlayerID];
	local pTeam = Teams[pPlayer:GetTeam()];
	local pCity = UI.GetHeadSelectedCity();
	
	strText = "";
	
	local pResource;
	local bShowResource;
	local bIsStrategic;
	local bThisIsFirstResourceShown = true;
	local iNumAvailable;
	local iNumUsed;
	local iNumTotal;
	local iNumImport;
	local iNumExport;
	local iNumTradable;
	local strExtraText;
	local strName;
	local tResourceList = {};
	
	for pResource in GameInfo.Resources() do
		local iResourceLoop = pResource.ID;
		strText = "";
		bShowResource = false;
		bIsStrategic = false;
		
		if (Game.GetResourceUsageType(iResourceLoop) == ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC)
				and (pTeam:GetTeamTechs():HasTech(GameInfoTypes[pResource.TechReveal]))
				and (pTeam:GetTeamTechs():HasTech(GameInfoTypes[pResource.TechCityTrade])) then
			bShowResource = true;
			bIsStrategic = true
		elseif (Game.GetResourceUsageType(iResourceLoop) == ResourceUsageTypes.RESOURCEUSAGE_LUXURY) then
			bShowResource = true;
		end
			
		if bShowResource then
			iNumImport, iNumExport, iNumCitystates = TradedResources(iResourceLoop);
			iNumAvailable	= pPlayer:GetNumResourceAvailable(iResourceLoop, true);
			iNumUsed		= pPlayer:GetNumResourceUsed(iResourceLoop, true);
			strName			= Locale.ConvertTextKey(pResource.Description);
			strText			= string.format("%"..((iNumAvailable/10 >= 1) and 2 or 3).."i", iNumAvailable)
			strExtraText	= ""
			iNumTradable	= iNumAvailable - iNumImport - iNumCitystates
			
			if (not bIsStrategic) and (iNumAvailable > 0) and (iNumAvailable == iNumTradable) then
				iNumTradable = iNumTradable - 1
			end
			
			if iNumTradable > 0 then
				strText = string.format("[COLOR_POSITIVE_TEXT]%s[ENDCOLOR]", strText);
			elseif (bIsStrategic and iNumAvailable < 0) or (not bIsStrategic and iNumExport > 0 and iNumAvailable == 0) then
				strText = string.format("[COLOR_WARNING_TEXT]%s[ENDCOLOR]", strText);
			end
			
			strText = strText .. "  " .. pResource.IconString .. " " .. strName
			
			if iNumImport > 0 then
				strExtraText = (strExtraText=="") and ": " or (strExtraText..", ")
				strExtraText = strExtraText .. Locale.ConvertTextKey("TXT_KEY_RES_IMPORTED", iNumImport)
			end
			if iNumCitystates > 0 then
				strExtraText = (strExtraText=="") and ": " or (strExtraText..", ")
				strExtraText = strExtraText .. Locale.ConvertTextKey("TXT_KEY_RES_CITYSTATES", iNumCitystates)
			end
			if iNumExport > 0 then
				strExtraText = (strExtraText=="") and ": " or (strExtraText..", ")
				strExtraText = strExtraText .. "[COLOR_WARNING_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_RES_EXPORTED", iNumExport) .. "[ENDCOLOR]"
			end
			if iNumUsed > 0 and bIsStrategic then
				strExtraText = (strExtraText=="") and ": " or (strExtraText..", ")
				strExtraText = strExtraText .. "[COLOR_WARNING_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_RES_USED", iNumUsed) .. "[ENDCOLOR]"
			end
			if iNumTradable > 0 then
				strExtraText = (strExtraText=="") and ": " or (strExtraText..", ")
				strExtraText = strExtraText .. "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_RES_SURPLUS", iNumTradable) .. "[ENDCOLOR]"
			end
			
			if iNumAvailable == 0 and strExtraText == "" then
				strText = "[COLOR:192:192:192:255]" .. strText .. "[ENDCOLOR]";
			else
				strText = strText .. strExtraText
			end

			table.insert(tResourceList, {strategic=bIsStrategic, name=strName, str=strText});
		end
	end
	
	table.sort(tResourceList, function (a,b)
		if a.strategic ~= b.strategic then
			return a.strategic;
		else
			return a.name < b.name;
		end
	end)

	strText = ""
	bIsCurrentStrategic = false;
	for _,v in ipairs(tResourceList) do
		--print("Resource displayed: "..v.name);
		if bIsCurrentStrategic == true and v.strategic == false then
			strText = strText .. "[NEWLINE]";		
		end
		bIsCurrentStrategic = v.strategic;
		strText = strText .. "[NEWLINE]" .. v.str;
	end
	
	--print(strText);
	
	strText = string.gsub(strText, "^%[NEWLINE%]+", "")
	strText = string.gsub(strText, "^%[NEWLINE%]+", "")
	
	if(strText ~= "") then
		tipControlTable.TopPanelMouseover:SetHide(false);
		tipControlTable.TooltipLabel:SetText( strText );
	else
		tipControlTable.TopPanelMouseover:SetHide(true);
	end
    
    -- Autosize tooltip
    tipControlTable.TopPanelMouseover:DoAutoSize();
	
end


---------------------------------------------------
---------ADDED Update Great People Tooltip---------
---------------------------------------------------

function GreatPeopleTipHandler( control )
	local pPlayer = Players[Game.GetActivePlayer()]
	local strTooltip = ""
	local GPList = GetGPList(pPlayer)
	
	if GPList ~= nil then
		-- Find GP priorities
		local gpPriority = {}
		for _,v in pairs(GPList) do
			if (gpPriority[v.name] == nil) or (gpPriority[v.name] < v.turnsRemaining) then
				gpPriority[v.name] = v.turnsRemaining
			end
		end
		
		-- Sort the GP list
		table.sort(GPList, function (a,b)
			if a.name ~= b.name then
				if gpPriority[a.name] ~= gpPriority[b.name] then
					return gpPriority[a.name] < gpPriority[b.name]
				else
					return a.name < b.name
				end
			else
				if a.turnsRemaining ~= b.turnsRemaining then
					return a.turnsRemaining < b.turnsRemaining
				else
					return a.progress < b.progress
				end
			end
		end)

		if GPList[1] then
			strTooltip = strTooltip .. string.format("%s: %i[ICON_GREAT_PEOPLE]", Locale.ConvertTextKey("TXT_KEY_ADVISOR_COUNSEL_ECONOMIC_NEXT"), GPList[1].threshold)
		end
		
		-- Add each GP in the list to the tooltip
		local currentGP = {name="", cities=0}
		for _,v in ipairs(GPList) do
			if v.name ~= currentGP.name then
				-- New GP entry
				currentGP.name = v.name
				currentGP.cities = 0
				local strTurns = ""
				if v.turnsRemaining ~= math.huge then
					strTurns = v.turnsRemaining .. " "
					strTurns = strTurns .. Locale.ConvertTextKey(v.turnsRemaining==1 and "TXT_KEY_DO_TURN" or "TXT_KEY_DO_TURNS")
				end
				strTooltip = strTooltip .. "[NEWLINE][NEWLINE]" ..v.icon.. " " ..v.name.. ": " ..strTurns.. " "
			end
			
			-- Add cities to current GP entry
			if currentGP.cities < (GameDefines.TOOLTIP_MAX_CITIES_PER_GP or 3) then
				local cityName = Locale.ToUpper(Locale.ConvertTextKey(v.pCity:GetNameKey()))
				cityName = string.sub(cityName, 1, 1) .. string.lower(string.sub(cityName, 2))
				
				strTooltip = strTooltip.."[NEWLINE][ICON_BULLET] "..cityName.." "..v.progress
				if v.perTurn > 0 then
					strTooltip = strTooltip .. " [COLOR_POSITIVE_TEXT]+" ..v.perTurn.. "[/COLOR]"
				else
					strTooltip = strTooltip .. " +" ..v.perTurn
				end
			end
			currentGP.cities = currentGP.cities + 1
		end
	end

	-- Add great general
	strTooltip = strTooltip .. "[NEWLINE][NEWLINE][ICON_WAR] "
	strTooltip = strTooltip .. Locale.ConvertTextKey(GameInfo.UnitClasses.UNITCLASS_GREAT_GENERAL.Description)
	strTooltip = strTooltip .. ": " .. pPlayer:GetCombatExperience() .. "/" .. pPlayer:GreatGeneralThreshold()

	-- Remove excess newlines
	strTooltip = string.gsub(strTooltip, "^%[NEWLINE%]+", "")
	strTooltip = string.gsub(strTooltip, "^%[NEWLINE%]+", "")

	tipControlTable.TooltipLabel:SetText( strTooltip )
	tipControlTable.TopPanelMouseover:SetHide(false)
    tipControlTable.TopPanelMouseover:DoAutoSize()
end

--AttilaMod-

-------------------------------------------------
-- On Top Panel mouseover exited
-------------------------------------------------
--function HelpClose()
	---- Hide the help text box
	--Controls.HelpTextBox:SetHide( true );
--end


-- Register Events
Events.SerialEventGameDataDirty.Add(OnTopPanelDirty);
Events.SerialEventTurnTimerDirty.Add(OnTopPanelDirty);
Events.SerialEventCityInfoDirty.Add(OnTopPanelDirty);

-- Update data at initialization
UpdateData();
DoInitTooltips();