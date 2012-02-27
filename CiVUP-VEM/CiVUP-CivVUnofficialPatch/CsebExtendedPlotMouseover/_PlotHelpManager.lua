-------------------------------------------------
-------------------------------------------------

include("PlotMouseoverInclude");
include("ResourceTooltipGenerator");
include("AlpacaUtils");
include("EPM-Common.lua");
include("EPM-CommonPlotHelpers.lua");

local m_fTime = 0;
local m_iTipLevel = 0;
local m_bFirstUpdate = true;
local m_bAltPressed;

local m_pPlotHelpText;

local m_strLevel1Text = "";

local tipControls = {};
TTManager:GetTypeControlTable( "HexDetails", tipControls );

local m_iCurrentX = -1;
local m_iCurrentY = -1;

-------------------------------------------------
-------------------------------------------------
function ProcessInput( uiMsg, wParam, lParam )
    if( uiMsg == MouseEvents.MouseMove ) then
        x, y = UIManager:GetMouseDelta();
        if( x ~= 0 or y ~= 0 ) then 
			Reset();
        end
    end
end
ContextPtr:SetInputHandler( ProcessInput );

-------------------------------------------------
-------------------------------------------------
function OnStrategicViewStateChanged( )
    Reset();
end
Events.StrategicViewStateChanged.Add(OnStrategicViewStateChanged);

-------------------------------------------------
-------------------------------------------------
function Reset()
	m_fTime = 0;
	if( m_iTipLevel ~= 0 ) then
		Controls.TheBox:SetToolTipType();
		m_iTipLevel = 0;
	end
end

-------------------------------------------------
-------------------------------------------------
function OnUpdate( fDTime )
    if( m_bFirstUpdate ) then
    
        m_pPlotHelpText = ContextPtr:LookUpControl( "/InGame/WorldView/PlotHelpText" );
        m_bFirstUpdate = false;
        return;
    end
    
    local bHasMouseOver = Controls.TheBox:HasMouseOver();
    
    if( bHasMouseOver ) then
        m_pPlotHelpText:SetHide( false );
    else
        m_pPlotHelpText:SetHide( true );
    end
    
    
    if( m_iTipLevel == 0 ) then
        if( not bHasMouseOver ) then
            return;
        end
        
        m_fTime = m_fTime + fDTime;

		
	local bAlt = UIManager:GetAlt();
	--local bCtrl = UIManager:GetControl();	

    if( m_fTime > (OptionsManager.GetTooltip1Seconds() / 100) and (not m_bVisible or bAlt ~= m_bAltPressed)) then
		m_bAltPressed = bAlt;
		OnMouseOverHex(m_iCurrentX, m_iCurrentY, bAlt);
		m_bVisible = true;
    end
        
        if( m_fTime > (OptionsManager.GetTooltip1Seconds() / 100) ) then
			if( MouseOverStrategicViewResource() ) then
				ResourceToolTip();
			else
				Level1Tip();
			end
			
            m_iTipLevel = 1;
        end
    elseif( m_iTipLevel == 1 ) then
        if( not bHasMouseOver ) then
            m_iTipLevel = 0;
            Controls.TheBox:SetToolTipType();
            return;
        end
        
        m_fTime = m_fTime + fDTime;
    
         if( m_fTime > (OptionsManager.GetTooltip2Seconds() / 100) ) then
         	if( MouseOverStrategicViewResource() ) then
				ResourceToolTip();
			else
				Level2Tip();
			end
			
            m_iTipLevel = 2;
         end
     elseif( not bHasMouseOver ) then
        m_iTipLevel = 0;
        Controls.TheBox:SetToolTipType();
        return;
    end
end
ContextPtr:SetUpdate( OnUpdate );


-------------------------------------------------
-------------------------------------------------
function Level1Tip()
	
	local TextString = "";
	
	local iActiveTeam = Game.GetActiveTeam();
	local pTeam = Teams[iActiveTeam];

	local bIsDebug = Game.IsDebugMode();
	local bShowBasicHelp = not OptionsManager.IsNoBasicHelp()
	
	local plot = Map.GetPlot(m_iCurrentX, m_iCurrentY);
	
	if (plot and plot:IsRevealed(iActiveTeam, bIsDebug)) then
		
		-- Plot must be visible to see Units there
		if (plot:IsVisible(iActiveTeam, bIsDebug)) then
			local strUnitsText = GetUnitsString(plot);
			if (strUnitsText ~= "") then
				TextString = TextString .. "[NEWLINE]" .. strUnitsText;
			end
		end

		-- under construction display
		local UnderConstructionStr = "";
		for i=0, plot:GetNumUnits()-1 do
			local iBuildID = plot:GetUnit( i ):GetBuildType();
			if iBuildID ~= -1 then
				--local iTurnsLeft = plot:GetBuildTurnsLeft(pBuildInfo.ID, 0, 0); -- vanilla version is bugged
				local iTurnsLeft = PlotGetBuildTurnsLeft(plot, iBuildID);
				
				if (iTurnsLeft < 4000 and iTurnsLeft >= 0) then
					local convertedKey = Locale.ConvertTextKey(GameInfo.Builds[iBuildID].Description);
					UnderConstructionStr = UnderConstructionStr .. Locale.ConvertTextKey("TXT_KEY_WORKER_BUILD_PROGRESS", iTurnsLeft, convertedKey);
				end
			end
		end

		if (UnderConstructionStr ~= "") then
			TextString = TextString .. "[NEWLINE]" .. UnderConstructionStr;
		end

		--local player = Players[Game.GetActivePlayer()];
		--local dangerPlotValue = player:GetPlotDanger(plot);
		--TextString = TextString .. "Plot Danger: ";
		--TextString = TextString .. dangerPlotValue;
		
		-- City/plot owner
		local strOwner = GetOwnerString(plot);
		if (strOwner ~= "") then
			TextString = TextString .. "[NEWLINE]" .. strOwner;
		end
		
		-- Resource
		local strResource = GetResourceString(plot, true);

		if (strResource ~= "") then
			TextString = TextString .. "[NEWLINE]"
			if bShowBasicHelp then
				TextString = TextString .. "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_RESOURCE") .. "[ENDCOLOR]" .. " : "
			end
			TextString = TextString .. strResource;
		end	
		
		-- Improvement, route
		local strImprovement = GetImprovementString(plot);

		--if (strImprovement ~= "") then
		if (strImprovement ~= "" or plot:IsTradeRoute()) then		
			local bWroteImprovement = false;	
			if (strImprovement ~= "") then
				TextString = TextString .. "[NEWLINE]"
				if bShowBasicHelp then
					TextString = TextString .. "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_IMPROVEMENT") .. "[ENDCOLOR]" .. " : "
				end
				TextString = TextString .. strImprovement;
				bWroteImprovement = true;		
			end
		
			-- Trade Route
			if (plot:IsTradeRoute()) then
				local strTradeRouteBlock;
			
				if (bWroteImprovement) then
					strTradeRouteBlock = ", " .. Locale.ConvertTextKey( "TXT_KEY_PLOTROLL_TRADE_ROUTE" );
				else
					strTradeRouteBlock = Locale.ConvertTextKey( "TXT_KEY_PLOTROLL_TRADE_ROUTE" );			
				end
			
				TextString = TextString .. strTradeRouteBlock;
			end
		end	
		
		-- Terrain type, feature
		local natureStr = GetNatureString(plot);
		
		if (natureStr ~= "") then
			TextString = TextString .. "[NEWLINE]"
			if bShowBasicHelp then
				TextString = TextString .. "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_PEDIA_TERRAIN_LABEL") .. "[ENDCOLOR]" .. " : "
			end
			TextString = TextString .. natureStr;
		end
		
		-- Presence of fresh water
		local freshWaterStr = "";
		if (plot:IsFreshWater()) then
			freshWaterStr = Locale.ConvertTextKey( "TXT_KEY_PLOTROLL_FRESH_WATER" );
		end
		
		if (freshWaterStr ~= "") then
			TextString = TextString .. "[NEWLINE]" .. freshWaterStr;
		end
		
		-- Yield
		local strYield = bShowBasicHelp and GetYieldLines(plot, true) or GetYieldString(plot);
		if (strYield ~= "") then
			TextString = TextString .. "[NEWLINE]" .. strYield;
		end
		--TextString = TextString .. "[COLOR_POSITIVE_TEXT]" .. Locale.ConvertTextKey("TXT_KEY_OUTPUT") .. "[ENDCOLOR]" .. " : "
		
		-- Defense
		if bShowBasicHelp then
			local iDefensePlotTotal = plot:DefenseModifier(Teams[Game.GetActiveTeam()], false);
			if (iDefensePlotTotal ~= 0) then
				strResult = Locale.ConvertTextKey("TXT_KEY_PLOT_DEFENSE", iDefensePlotTotal)
			end
		end
		
		-- City state quest
		local CityStateStr = GetCivStateQuestString(plot, false);
		if (CityStateStr ~= "") then
			TextString = TextString .. "[NEWLINE]" .. CityStateStr;
		end
	end
	
	TextString = string.gsub(TextString, "^"..Literalize("[NEWLINE]"), "")

	m_strLevel1Text = TextString;

    if( TextString ~= "" ) then	
        tipControls.Text:SetText( TextString );
        tipControls.Grid:DoAutoSize();
        Controls.TheBox:SetToolTipType( "HexDetails" );
    else
        Controls.TheBox:SetToolTipType();
    end
end


-------------------------------------------------
-------------------------------------------------
function Level2Tip()
	
	local TextString = m_strLevel1Text;
	
	--TextString = TextString .. "[NEWLINE]" .. "EXTRA STUFF HERE!";
    if( TextString ~= "" ) then	
        tipControls.Text:SetText( TextString );
        tipControls.Grid:DoAutoSize();
        Controls.TheBox:SetToolTipType( "HexDetails" );
    else
        Controls.TheBox:SetToolTipType();
    end
end

-------------------------------------------------
-------------------------------------------------
function ResourceToolTip()
	local plot = Map.GetPlot( m_iCurrentX, m_iCurrentY );
	
	local TextString = "";
    if( plot:IsRevealed( Game.GetActiveTeam(), false ) ) then
        TextString = GenerateResourceToolTip(plot);
    end
    
    if( TextString ~= nil and TextString ~= "" ) then	
        tipControls.Text:SetText( TextString );
        tipControls.Grid:DoAutoSize();
        Controls.TheBox:SetToolTipType( "HexDetails" );
    else
        Controls.TheBox:SetToolTipType();
    end
end


-------------------------------------------------
-------------------------------------------------
function DoUpdateXY( hexX, hexY )
	
	local plot = Map.GetPlot( hexX, hexY );
	
	if (plot ~= nil) then
		m_iCurrentX = hexX;
		m_iCurrentY = hexY;
	end
	
end
Events.SerialEventMouseOverHex.Add( DoUpdateXY );


-------------------------------------------------
-------------------------------------------------
function OnCameraViewChanged()
    m_fTime = 0;

    if( m_iTipLevel ~= 0 ) then
        Controls.TheBox:SetToolTipType();
        m_iTipLevel = 0;
    end
end
Events.CameraViewChanged.Add( OnCameraViewChanged );


-------------------------------------------------
-------------------------------------------------
Controls.TheBox:RegisterCallback( Mouse.eMouseEnter, function() Events.WorldMouseOver( true  ); end );
Controls.TheBox:RegisterCallback( Mouse.eMouseExit,  function() Events.WorldMouseOver( false ); end );



