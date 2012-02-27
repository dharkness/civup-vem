-------------------------------------------------
-- Generic Popups
-------------------------------------------------
PopupLayouts = {};
PopupInputHandlers = {};
local mostRecentPopup = nil;
local g_isOpen = false;

------------------------------------------------
-- Misc Utility Methods
------------------------------------------------
-- Shows popup window.
function ShowWindow()
	ResizeWindow();
	UIManager:QueuePopup( ContextPtr, PopupPriority.GenericPopup );
end

-- Hides popup window.
function HideWindow()
	--print("HideWindow")
    UIManager:DequeuePopup( ContextPtr );
    Events.SerialEventGameMessagePopupProcessed.CallImmediate( mostRecentPopup, 0 );
	mostRecentPopup = nil;	
    ClearButtons();
    g_isOpen = false;
end
 
function ResizeWindow()
    Controls.ButtonStack:CalculateSize();
	Controls.ButtonStackFrame:DoAutoSize();
end

-- Sets popup text.
function SetPopupText(popupText)
	Controls.PopupText:SetText(popupText);
end

-- Remove all buttons from popup.
function ClearButtons()
	local i = 1;
	repeat
		local button = Controls["Button"..i];
		if button then
			button:SetHide(true);
		end
		i = i + 1;
	until button == nil;
	Controls.CloseButton:SetHide( true );
	ResizeWindow();
end

-- Add a button to popup.
-- NOTE: Current Limitation is 4 buttons
function AddButton(buttonText, buttonClickFunc, strToolTip, bPreventClose)
	local i = 1;
	repeat
		local button = Controls["Button"..i];
		if button and button:IsHidden() then
			local buttonLabel = Controls["Button"..i.."Text"];
			buttonLabel:SetText( buttonText );
			
			button:SetToolTipString(strToolTip);

			--By default, button clicks will hide the popup window after
			--executing the click function
			local clickHandler = function()
				if buttonClickFunc ~= nil then
					buttonClickFunc();
				end
				
				HideWindow();
			end
			local clickHandlerPreventClose = function()
				if buttonClickFunc ~= nil then
					buttonClickFunc();
				end
			end
			
			-- This is only used in one case, when viewing a captured city (PuppetCityPopup)
			if (bPreventClose) then
				button:RegisterCallback(Mouse.eLClick, clickHandlerPreventClose);
			else
				button:RegisterCallback(Mouse.eLClick, clickHandler);
			end
			
			button:SetHide(false);
			
			return;
		end
		i = i + 1;
	until button == nil;
end

-------------------------------------------------
-- On Display
-------------------------------------------------
function OnDisplay(popupInfo)
	--print("OnDisplay "..tostring(popupInfo.Type))

	if g_isOpen then
		return;
	end

	-- Initialize popups
	local initialize = PopupLayouts[popupInfo.Type];
	if initialize then
		local activePlayer = Players[Game.GetActivePlayer()]
		--[[
		if (popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_CITY_CAPTURED) then
			local city = activePlayer:GetCityByID(popupInfo.Data1)
			print(city:GetName().. "  LiberatedPlayer=" ..popupInfo.Data3.. "  CanRaze=" ..tostring(activePlayer:CanRaze(city)))
			if popupInfo.Data3 == -1 and not activePlayer:CanRaze(city) then
				-- No option but puppeting
				Network.SendDoTask(popupInfo.Data1, TaskTypes.TASK_CREATE_PUPPET, -1, -1, false, false, false, false);				
				Events.SerialEventGameMessagePopupProcessed.CallImmediate( mostRecentPopup, 0 );
				mostRecentPopup = nil;	
				ClearButtons();
				g_isOpen = false;
				print("Automatically Puppet")
			else
				print("No Puppet")
			end
		else--]]
			ClearButtons();
			initialize(popupInfo);
			ShowWindow();
			mostRecentPopup = popupInfo.Type;
			g_isOpen = true;	
		--end
	end
end
Events.SerialEventGameMessagePopup.Add( OnDisplay );

function OnCloseButtonClicked()
	HideWindow();
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnCloseButtonClicked );

-------------------------------------------------
-- Popup Initializers
-------------------------------------------------
local files = include("InGame\\PopupsGeneric\\%w+Popup.lua",true);
for i, v in ipairs(files) do
	--print("Loaded Popup - "..v);
end

-------------------------------------------------
-- Keyboard Handler
-------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )

	local specializedInputHandler = nil;
	if mostRecentPopup then
		specializedInputHandler = PopupInputHandlers[mostRecentPopup];
	end
	if specializedInputHandler then
		return specializedInputHandler( uiMsg, wParam, lParam );
	else
		--Eventually trigger the first button once that code is avail
		if uiMsg == KeyEvents.KeyDown and not ContextPtr:IsHidden() then
			return true;
		end
	end
end
ContextPtr:SetInputHandler( InputHandler );


