-- Widgets created by Adirelle & k.shandurenko

local AceGUI = LibStub("AceGUI-3.0")

-- Localization
local L_ACTIONTYPE = {
	item = "Item"
}

local widgetVersion = 1

--------------------------------------------------------------------------------
-- Abstract action slot
--------------------------------------------------------------------------------

local BaseConstructor

do
	
	local function OnAcquire(self)
		self:SetWidth(200)
		self:SetHeight(44)
		self:SetDisabled(false)
		self:SetLabel()
	end

	local function OnRelease(self)
		self.rejectIcon:Hide()
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self:SetDisabled(false)
		self:SetText()
	end

	local spellbooks = { "spell", "pet" }
	local companionTypes = { "MOUNT", "CRITTER" }
	
	local function Pickup(actionType, actionData)
		if actionType == "item" then
			return PickupItem(actionData)
		end
		ClearCursor()
	end
	
	local function ParseActionInfo(actionType, data1, data2)
		if actionType == "item" then
			return true, "item", data1
		elseif actionType == "action" then
			return ParseActionInfo(GetActionInfo(data1))
		end
		return actionType and true or false
	end

	local function ParseCursorInfo()
		return ParseActionInfo(GetCursorInfo())
	end
	
	local function Button_OnEnter(this)
		local self = this.obj
		local hasAction, actionType = ParseCursorInfo()
		if hasAction and not self:AcceptActionType(actionType) then
			self.rejectIcon:Show()
		else
			self.rejectIcon:Hide()
		end
		self:Fire("OnEnter")
	end

	local function Button_OnLeave(this)
		local self = this.obj
		self.rejectIcon:Hide()
		self:Fire("OnLeave")
	end

	local function SetNewAction(self, newType, newData)
		local oldType, oldData = self.actionType, self.actionData
		if newType ~= oldType or newData ~= oldData then
			local value = newType and newData and self:BuildValue(newType, newData)
			self:Fire("OnEnterPressed", value)
			if self.actionType ~= oldType or self.actionData ~= oldData then
				Pickup(oldType, oldData)
			end
		end
	end

	local function Button_OnReceiveDrag(this)
		local self = this.obj
		local hasAction, actionType, actionData = ParseCursorInfo()
		if hasAction and actionType and actionData and self:AcceptActionType(actionType) then
			SetNewAction(self, actionType, actionData)
		end
	end

	local function Button_OnDragStart(this)
		SetNewAction(this.obj)
	end

	local function Button_OnClick(this, button)
		if button == "RightButton" then
			this.obj:Fire("OnEnterPressed", "")
		else
			return Button_OnReceiveDrag(this)
		end
	end
	
	local function SetText(self, text)
		local actionType, actionData, name, texture
		if text and text ~= "" then
			actionType, actionData, name, texture = self:ParseValue(tostring(text))
		end
		if actionType and actionData and name and texture and self:AcceptActionType(actionType) then
			self.actionType, self.actionData = actionType, actionData
			self.button:SetNormalTexture([[Interface\Buttons\UI-Quickslot2]])
			self.icon:SetTexture(texture)
			self:SetActionText(L_ACTIONTYPE[actionType] or actionType, name)
			self.text:Show()
			self.icon:Show()
		else
			self.actionType, self.actionData = nil, nil
			self.button:SetNormalTexture([[Interface\Buttons\UI-Quickslot]])
			self.text:Hide()
			self.icon:Hide()
		end
	end

	local function OnHeightSet(self, height)
		local button = self.button
		local icon = self.icon
		local tex = button:GetNormalTexture()
		local size = height - 8
		if self.label:IsShown() then
			size = size - self.label:GetHeight()
		end
		size = math.min(size, 36)
		button:SetWidth(size)
		button:SetHeight(size)
		tex:SetWidth(size*60/36)
		tex:SetHeight(size*60/36)
		icon:SetWidth(size)
		icon:SetHeight(size)
	end

	local function SetLabel(self, label)
		if label and label ~= "" then
			self.label:SetText(label)
			self.label:Show()
		else
			self.label:SetText("")
			self.label:Hide()
		end
		OnHeightSet(self, self.frame:GetHeight())
	end

	local function SetDisabled(self, disabled)
		if disabled then
			self.button:EnableMouse(false)
			self.icon:SetDesaturated(true)
			self.label:SetTextColor(0.5,0.5,0.5)
			self.text:SetTextColor(0.5,0.5,0.5)
		else
			self.button:EnableMouse(true)
			self.icon:SetDesaturated(false)
			self.label:SetTextColor(1,.82,0)
			self.text:SetTextColor(1,1,1)
		end
	end

	function BaseConstructor(self)
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire

		self.OnWidthSet = OnWidthSet
		self.OnHeightSet = OnHeightSet

		self.SetLabel = SetLabel
		self.SetText = SetText
		self.SetDisabled = SetDisabled

		local frame = CreateFrame("Frame")
		frame:SetWidth(200)
		frame:SetHeight(44)
		frame.obj = self
		self.frame = frame

		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("TOPLEFT")
		label:SetPoint("TOPRIGHT")
		label:SetJustifyH("LEFT")
		label:SetHeight(15)
		self.label = label

		local button = CreateFrame("Button", nil, frame)
		button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:RegisterForDrag("LeftButton")
		button:SetPoint("BOTTOMLEFT",4,4)
		button:SetWidth(29)
		button:SetHeight(29)
		button:SetNormalTexture([[Interface\Buttons\UI-Quickslot]])
		button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
		button:GetPushedTexture():SetBlendMode('ADD')
		button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
		button:GetHighlightTexture():SetBlendMode('ADD')
		button:SetScript('OnDragStart', Button_OnDragStart)
		button:SetScript('OnReceiveDrag', Button_OnReceiveDrag)
		button:SetScript('OnClick', Button_OnClick)
		button:SetScript('OnEnter', Button_OnEnter)
		button:SetScript('OnLeave', Button_OnLeave)
		button.obj = self
		self.button = button

		local tex = button:GetNormalTexture()
		tex:ClearAllPoints()
		tex:SetPoint("CENTER")

		local icon = button:CreateTexture("BACKGROUND")
		icon:SetPoint("CENTER")
		self.icon = icon
		
		local rejectIcon = frame:CreateTexture("OVERLAY")
		rejectIcon:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-LeaveItem-Transparent]])
		rejectIcon:SetAllPoints(icon)
		rejectIcon:Hide()
		self.rejectIcon = rejectIcon

		local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetPoint("TOPLEFT", button, "TOPRIGHT", 2, -5)
		text:SetPoint("BOTTOMRIGHT")
		text:SetJustifyH("LEFT")
		text:SetJustifyV("TOP")
		--text:SetWordWrap(false)
		self.text = text

		self:OnHeightSet(44)

		AceGUI:RegisterAsWidget(self)
		return self
	end
end

--------------------------------------------------------------------------------
-- Generic action slot
--------------------------------------------------------------------------------

do
	local function AcceptActionType(self, actionType)
		return actionType == "item"
	end	
	
	local function BuildValue(self, actionType, actionData)
		return strjoin(":", tostringall(actionType, actionData))
	end

	local function ParseValue(self, value)
		local itemId = tonumber(value:match("item:(%d+)"))
		if itemId then
			local name, _, _, _,  _, _, _, _,  _, texture = GetItemInfo(itemId)
			return "item", itemId, name, texture
		end
	end
	
	local function SetActionText(self, actionType, name)
		self.text:SetFormattedText("%s: %s", actionType, name)
	end

	local widgetType = "FDSlot"
	
	local function Constructor()
		return BaseConstructor{
			type = widgetType,
			AcceptActionType = AcceptActionType,
			ParseValue = ParseValue,
			BuildValue = BuildValue,
			SetActionText = SetActionText,
		}
	end
	
	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end

--------------------------------------------------------------------------------
-- Item-only action slot
--------------------------------------------------------------------------------

do
	local function AcceptActionType(self, actionType)
		return actionType == "item"
	end

	local function BuildValue(self, actionType, actionData)
		return tostring(actionData)
	end
	
	local function ParseValue(self, value)
		local itemId = tonumber(value) or tonumber(value:match("item:(%d+)"))
		if itemId then
			local name, link, _, _,  _, _, _, _,  _, texture = GetItemInfo(itemId)
			local split = FDKP:explode(link, '|');
			return "item", itemId, '|' .. split[1] .. name, texture		
		end
	end
	
	local function SetActionText(self, actionType, name)
		self.text:SetText(name)
	end

	local widgetType = "FDSlotItem"
	
	local function Constructor()
		return BaseConstructor{
			type = widgetType,
			AcceptActionType = AcceptActionType,
			ParseValue = ParseValue,
			BuildValue = BuildValue,
			SetActionText = SetActionText,
		}
	end
	
	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end

--------------------------------------------------------------------------------
-- Raiding helper frame
--------------------------------------------------------------------------------

do
	local function Button_OnClick(frame)
		PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
		frame.obj:Hide()
	end

	local function Frame_OnShow(frame)
		frame.obj:Fire("OnShow")
	end

	local function Frame_OnClose(frame)
		frame.obj:Fire("OnClose")
	end

	local function Frame_OnMouseDown(frame)
		AceGUI:ClearFocus()
	end

	local function Title_OnMouseDown(frame)
		frame:GetParent():StartMoving()
		AceGUI:ClearFocus()
	end

	local function MoverSizer_OnMouseUp(mover)
		local frame = mover:GetParent()
		frame:StopMovingOrSizing()
	end

	local function SizerSE_OnMouseDown(frame)
		frame:GetParent():StartSizing("BOTTOMRIGHT")
		AceGUI:ClearFocus()
	end

	local function SizerS_OnMouseDown(frame)
		frame:GetParent():StartSizing("BOTTOM")
		AceGUI:ClearFocus()
	end

	local function SizerE_OnMouseDown(frame)
		frame:GetParent():StartSizing("RIGHT")
		AceGUI:ClearFocus()
	end

	--[[-----------------------------------------------------------------------------
	Methods
	-------------------------------------------------------------------------------]]
	local methods = {
		["OnAcquire"] = function(self)
			self.frame:SetParent(UIParent)
			self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
			self:SetTitle()
			self:PrepareForRender()
			self:Show()
	        self:EnableResize(false)
		end,

		["OnRelease"] = function(self) end,

		["OnWidthSet"] = function(self, width)
			local content = self.content
			local contentwidth = width - 34
			if contentwidth < 0 then
				contentwidth = 0
			end
			content:SetWidth(contentwidth)
			content.width = contentwidth
		end,

		["OnHeightSet"] = function(self, height)
			local content = self.content
			local contentheight = height - 57
			if contentheight < 0 then
				contentheight = 0
			end
			content:SetHeight(contentheight)
			content.height = contentheight
		end,

		["SetTitle"] = function(self, title)
			self.titletext:SetText(title)
			self.titlebg:SetWidth((self.titletext:GetWidth() or 0) + 10)
		end,

		["Hide"] = function(self)
			self.frame:Hide()
		end,

		["Show"] = function(self)
			self.frame:Show()
		end,

		["EnableResize"] = function(self, state)
			local func = state and "Show" or "Hide"
			self.sizer_se[func](self.sizer_se)
			self.sizer_s[func](self.sizer_s)
			self.sizer_e[func](self.sizer_e)
		end,

		["PrepareForRender"] = function(self)
			local frame = self.frame
			self:SetWidth(400)
			self:SetHeight(350)
			frame:ClearAllPoints()
			frame:SetPoint('CENTER')
		end
	}

	--[[-----------------------------------------------------------------------------
	Constructor
	-------------------------------------------------------------------------------]]
	local FrameBackdrop = {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	}

	local PaneBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	}

	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:Hide()

		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:SetResizable(false)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetBackdrop(FrameBackdrop)
		frame:SetBackdropColor(0, 0, 0, 1)
        frame:SetMinResize(400, 350)
		frame:SetToplevel(true)
		frame:SetScript("OnShow", Frame_OnShow)
		frame:SetScript("OnHide", Frame_OnClose)
		frame:SetScript("OnMouseDown", Frame_OnMouseDown)

		local closebutton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		closebutton:SetScript("OnClick", Button_OnClick)
		closebutton:SetPoint("BOTTOMRIGHT", -17, 17)
		closebutton:SetHeight(20)
		closebutton:SetWidth(80)
		closebutton:SetText(CLOSE)

		local titlebg = frame:CreateTexture(nil, "OVERLAY")
		titlebg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		titlebg:SetTexCoord(0.31, 0.67, 0, 0.63)
		titlebg:SetPoint("TOP", 0, 12)
		titlebg:SetWidth(100)
		titlebg:SetHeight(40)

		local title = CreateFrame("Frame", nil, frame)
		title:EnableMouse(true)
		title:SetScript("OnMouseDown", Title_OnMouseDown)
		title:SetScript("OnMouseUp", MoverSizer_OnMouseUp)
		title:SetAllPoints(titlebg)

		local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		titletext:SetPoint("TOP", titlebg, "TOP", 0, -14)

		local titlebg_l = frame:CreateTexture(nil, "OVERLAY")
		titlebg_l:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		titlebg_l:SetTexCoord(0.21, 0.31, 0, 0.63)
		titlebg_l:SetPoint("RIGHT", titlebg, "LEFT")
		titlebg_l:SetWidth(30)
		titlebg_l:SetHeight(40)

		local titlebg_r = frame:CreateTexture(nil, "OVERLAY")
		titlebg_r:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		titlebg_r:SetTexCoord(0.67, 0.77, 0, 0.63)
		titlebg_r:SetPoint("LEFT", titlebg, "RIGHT")
		titlebg_r:SetWidth(30)
		titlebg_r:SetHeight(40)

		local sizer_se = CreateFrame("Frame", nil, frame)
		sizer_se:SetPoint("BOTTOMRIGHT")
		sizer_se:SetWidth(25)
		sizer_se:SetHeight(25)
		sizer_se:EnableMouse()
		sizer_se:SetScript("OnMouseDown",SizerSE_OnMouseDown)
		sizer_se:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

		local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
		line1:SetWidth(14)
		line1:SetHeight(14)
		line1:SetPoint("BOTTOMRIGHT", -8, 8)
		line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		local x = 0.1 * 14/17
		line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

		local line2 = sizer_se:CreateTexture(nil, "BACKGROUND")
		line2:SetWidth(8)
		line2:SetHeight(8)
		line2:SetPoint("BOTTOMRIGHT", -8, 8)
		line2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		local x = 0.1 * 8/17
		line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

		local sizer_s = CreateFrame("Frame", nil, frame)
		sizer_s:SetPoint("BOTTOMRIGHT", -25, 0)
		sizer_s:SetPoint("BOTTOMLEFT")
		sizer_s:SetHeight(25)
		sizer_s:EnableMouse(true)
		sizer_s:SetScript("OnMouseDown", SizerS_OnMouseDown)
		sizer_s:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

		local sizer_e = CreateFrame("Frame", nil, frame)
		sizer_e:SetPoint("BOTTOMRIGHT", 0, 25)
		sizer_e:SetPoint("TOPRIGHT")
		sizer_e:SetWidth(25)
		sizer_e:EnableMouse(true)
		sizer_e:SetScript("OnMouseDown", SizerE_OnMouseDown)
		sizer_e:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

		--Container Support
		local content = CreateFrame("Frame", nil, frame)
		content:SetPoint("TOPLEFT", 17, -27)
		content:SetPoint("BOTTOMRIGHT", -17, 40)

		local widget = {
			titletext    = titletext,
			titlebg      = titlebg,
			sizer_se     = sizer_se,
			sizer_s      = sizer_s,
			sizer_e      = sizer_e,
			content      = content,
			frame        = frame,
			type         = Type,
		}
		for method, func in pairs(methods) do
			widget[method] = func
		end
		closebutton.obj = widget

		return AceGUI:RegisterAsContainer(widget)
	end

	AceGUI:RegisterWidgetType("FDRaidingHelperFrame", Constructor, 1)
end

--------------------------------------------------------------------------------
-- Item roll frame
--------------------------------------------------------------------------------

do
	local function Button_OnClick(frame)
		PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
		frame.obj:Hide()
	end

	local function Frame_OnShow(frame)
		frame.obj:Fire("OnShow")
	end

	local function Frame_OnClose(frame)
		frame.obj:Fire("OnClose")
	end

	local function Frame_OnMouseDown(frame)
		AceGUI:ClearFocus()
	end

	local function Title_OnMouseDown(frame)
		frame:GetParent():StartMoving()
		AceGUI:ClearFocus()
	end

	local function MoverSizer_OnMouseUp(mover)
		local frame = mover:GetParent()
		frame:StopMovingOrSizing()
	end

	local function SizerSE_OnMouseDown(frame)
		frame:GetParent():StartSizing("BOTTOMRIGHT")
		AceGUI:ClearFocus()
	end

	local function SizerS_OnMouseDown(frame)
		frame:GetParent():StartSizing("BOTTOM")
		AceGUI:ClearFocus()
	end

	local function SizerE_OnMouseDown(frame)
		frame:GetParent():StartSizing("RIGHT")
		AceGUI:ClearFocus()
	end

	--[[-----------------------------------------------------------------------------
	Methods
	-------------------------------------------------------------------------------]]
	local methods = {
		["OnAcquire"] = function(self)
			self.frame:SetParent(UIParent)
			self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
			self:SetTitle()
			self:PrepareForRender()
			self:Show()
	        self:EnableResize(false)
		end,

		["OnRelease"] = function(self) end,

		["OnWidthSet"] = function(self, width)
			local content = self.content
			local contentwidth = width - 34
			if contentwidth < 0 then
				contentwidth = 0
			end
			content:SetWidth(contentwidth)
			content.width = contentwidth
		end,

		["OnHeightSet"] = function(self, height)
			local content = self.content
			local contentheight = height - 57
			if contentheight < 0 then
				contentheight = 0
			end
			content:SetHeight(contentheight)
			content.height = contentheight
		end,

		["SetTitle"] = function(self, title)
			self.titletext:SetText(title)
			self.titlebg:SetWidth((self.titletext:GetWidth() or 0) + 10)
		end,

		["Hide"] = function(self)
			self.frame:Hide()
		end,

		["Show"] = function(self)
			self.frame:Show()
		end,

		["SetTimerValue"] = function(self, timerValue)
			self.timerStr:SetText(timerValue)
		end,

		["SetLastBet"] = function(self, playerName, colorPrefix, amount)
			local value = ''
			if playerName then
				self.currentBet = amount
				self.lastBetter = playerName
				value = FDKP:format('%d DKP от %s%s', amount, colorPrefix, playerName)
				FDKP:logInfo('%s%s&e повысил ставку до &a%d %s DKP&e.', colorPrefix, playerName, amount, self.dkpType)
			else
				value = FDKP:colorize('&cнет')
				self.currentBet = 0
				self.lastBetter = ''
				self.rollEndedStr:SetText('')
				self.timerStr:SetText('')
				self.endButton:SetEnabled(true)
			end
			self.lastBetStr:SetText(FDKP:format('Последняя ставка: %s', value))
			self:CheckBetButtons(nil)
		end,

		["SetCanRoll"] = function(self, value)
			if value then
				value = FDKP:colorize('&aда')
				self.canRoll = true
				self:CheckBetButtons(true)
			else
				value = FDKP:colorize('&cнет')
				self.canRoll = false
				self:CheckBetButtons(false)
			end
			self.canRollStr:SetText(FDKP:format('Вы претендуете: %s', value))
			self.timerStr:SetText('')
		end,

		["EndTheRoll"] = function(self)
			self.rollEndedStr:SetText(FDKP:colorize('&aРозыгрыш предмета завершен!'))
			self.endButton:SetEnabled(false)
			self:CheckBetButtons(false)
			FDKP:logInfo('Розыгрыш предмета завершен!')
		end,

		["CheckBetButtons"] = function(self, active)
			if self.preparation or active == false then
				for _, button in pairs(self.plusButtons) do
					button:SetEnabled(false)
				end
				self.allIn:SetEnabled(false)
				return
			end
			local dkp = FDKP:getDKP(nil, self.dkpType)
			for bet, button in pairs(self.plusButtons) do
				local newBet = self.currentBet + bet
				button:SetEnabled(newBet >= FDKP_MIN_BET and dkp >= FDKP_MIN_BET)
			end
			self.allIn:SetEnabled(dkp > self.currentBet and dkp > FDKP_MIN_BET)
		end,

		["EnableResize"] = function(self, state)
			local func = state and "Show" or "Hide"
			self.sizer_se[func](self.sizer_se)
			self.sizer_s[func](self.sizer_s)
			self.sizer_e[func](self.sizer_e)
		end,

		["PrepareForRender"] = function(self)
			local frame = self.frame
			self:SetWidth(379)
			self:SetHeight(150)
			frame:ClearAllPoints()
			frame:SetPoint('TOP', 0, -10)
		end
	}

	--[[-----------------------------------------------------------------------------
	Constructor
	-------------------------------------------------------------------------------]]
	local FrameBackdrop = {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	}

	local PaneBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	}

	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:Hide()

		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:SetResizable(true)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetBackdrop(FrameBackdrop)
		frame:SetBackdropColor(0, 0, 0, 1)
		frame:SetMinResize(400, 200)
		frame:SetToplevel(true)
		frame:SetScript("OnShow", Frame_OnShow)
		frame:SetScript("OnHide", Frame_OnClose)
		frame:SetScript("OnMouseDown", Frame_OnMouseDown)

		local closebutton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		closebutton:SetScript("OnClick", Button_OnClick)
		closebutton:SetPoint("BOTTOMRIGHT", -17, 17)
		closebutton:SetHeight(20)
		closebutton:SetWidth(80)
		closebutton:SetText(CLOSE)

		local endButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		endButton:SetScript("OnClick", function(this, button)
			local frame = this.obj
			FDKP_ADDON:SendData(FDKP_CHANNEL_ITEM_ROLL_END, 'RAID', nil, frame.rollID)
			if frame.currentBet and frame.currentBet > 0 and frame.lastBetter then
				local _, itemLink = GetItemInfo(frame.rollLink)
				if itemLink then
					TEST = {{frame.lastBetter}, frame.dkpType, -frame.currentBet, itemLink}
					FDKP_BINLOG:compileDkpChangeRecord({frame.lastBetter}, frame.dkpType, -frame.currentBet, itemLink)
				end
			end
		end)
		endButton:SetPoint("BOTTOMRIGHT", -17, 17 + 20 + 2)
		endButton:SetHeight(18)
		endButton:SetWidth(80)
		endButton:SetText('Завершить')

		local startTimer = function(button, seconds)
			FDKP_ADDON:SendData(FDKP_CHANNEL_ITEM_ROLL_TIMER, 'RAID', nil, {button.obj.rollID, seconds})
		end

		local timerButton10 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		timerButton10:SetScript("OnClick", function(this, button) startTimer(this, 10) end)
		timerButton10:SetPoint("BOTTOMRIGHT", -17 - 39 - 2, 17 + 20 + 2 + 18 + 2)
		timerButton10:SetHeight(18)
		timerButton10:SetWidth(39)
		timerButton10:SetText('10s')

		local timerButton20 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		timerButton20:SetScript("OnClick", function(this, button) startTimer(this, 20) end)
		timerButton20:SetPoint("BOTTOMRIGHT", -17, 17 + 20 + 2 + 18 + 2)
		timerButton20:SetHeight(18)
		timerButton20:SetWidth(39)
		timerButton20:SetText('20s')

		local lastBetStr = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		lastBetStr:SetPoint('BOTTOMLEFT', 15, 65)
		lastBetStr:SetText('')

		local canRollStr = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		canRollStr:SetPoint('BOTTOMLEFT', 15, 65 - 13)
		canRollStr:SetText('')

		local rollEndedStr = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		rollEndedStr:SetPoint('BOTTOMLEFT', 15, 65 - 13 * 2)
		rollEndedStr:SetText('')

		local timerStr = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		timerStr:SetPoint('TOPRIGHT', -45, -35)
		timerStr:SetText('')

		local initialPlusX = 17
		local plusOffset = 46

		local bets = {10, 50, 100, 500}
		local plusButtons = {}
		for i, bet in pairs(bets) do
			local plusButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
			plusButton:SetScript('OnClick', function(this, button)
				FDKP_ROLL:makeBet(this.obj.rollID, this.obj.rollerName, FDKP_BET_MODE_DEFAULT, {bet})
			end)
			plusButton:SetPoint("BOTTOMLEFT", initialPlusX + plusOffset * (i - 1), 17)
			plusButton:SetHeight(20)
			plusButton:SetWidth(plusOffset - 1)
			plusButton:SetText('+' .. bet)
			plusButtons[bet] = plusButton
		end

		local allIn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		allIn:SetScript("OnClick", function(this, button)
			FDKP_ROLL:makeBet(this.obj.rollID, this.obj.rollerName, FDKP_BET_MODE_ALL_IN, {})
		end)
		allIn:SetPoint("BOTTOMLEFT", initialPlusX + plusOffset * 4, 17)
		allIn:SetHeight(20)
		allIn:SetWidth(80)
		allIn:SetText('Все, что есть')

		local titlebg = frame:CreateTexture(nil, "OVERLAY")
		titlebg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		titlebg:SetTexCoord(0.31, 0.67, 0, 0.63)
		titlebg:SetPoint("TOP", 0, 12)
		titlebg:SetWidth(100)
		titlebg:SetHeight(40)

		local title = CreateFrame("Frame", nil, frame)
		title:EnableMouse(true)
		title:SetScript("OnMouseDown", Title_OnMouseDown)
		title:SetScript("OnMouseUp", MoverSizer_OnMouseUp)
		title:SetAllPoints(titlebg)

		local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		titletext:SetPoint("TOP", titlebg, "TOP", 0, -14)

		local titlebg_l = frame:CreateTexture(nil, "OVERLAY")
		titlebg_l:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		titlebg_l:SetTexCoord(0.21, 0.31, 0, 0.63)
		titlebg_l:SetPoint("RIGHT", titlebg, "LEFT")
		titlebg_l:SetWidth(30)
		titlebg_l:SetHeight(40)

		local titlebg_r = frame:CreateTexture(nil, "OVERLAY")
		titlebg_r:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
		titlebg_r:SetTexCoord(0.67, 0.77, 0, 0.63)
		titlebg_r:SetPoint("LEFT", titlebg, "RIGHT")
		titlebg_r:SetWidth(30)
		titlebg_r:SetHeight(40)

		local sizer_se = CreateFrame("Frame", nil, frame)
		sizer_se:SetPoint("BOTTOMRIGHT")
		sizer_se:SetWidth(25)
		sizer_se:SetHeight(25)
		sizer_se:EnableMouse()
		sizer_se:SetScript("OnMouseDown",SizerSE_OnMouseDown)
		sizer_se:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

		local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
		line1:SetWidth(14)
		line1:SetHeight(14)
		line1:SetPoint("BOTTOMRIGHT", -8, 8)
		line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		local x = 0.1 * 14/17
		line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

		local line2 = sizer_se:CreateTexture(nil, "BACKGROUND")
		line2:SetWidth(8)
		line2:SetHeight(8)
		line2:SetPoint("BOTTOMRIGHT", -8, 8)
		line2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		local x = 0.1 * 8/17
		line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

		local sizer_s = CreateFrame("Frame", nil, frame)
		sizer_s:SetPoint("BOTTOMRIGHT", -25, 0)
		sizer_s:SetPoint("BOTTOMLEFT")
		sizer_s:SetHeight(25)
		sizer_s:EnableMouse(true)
		sizer_s:SetScript("OnMouseDown", SizerS_OnMouseDown)
		sizer_s:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

		local sizer_e = CreateFrame("Frame", nil, frame)
		sizer_e:SetPoint("BOTTOMRIGHT", 0, 25)
		sizer_e:SetPoint("TOPRIGHT")
		sizer_e:SetWidth(25)
		sizer_e:EnableMouse(true)
		sizer_e:SetScript("OnMouseDown", SizerE_OnMouseDown)
		sizer_e:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

		--Container Support
		local content = CreateFrame("Frame", nil, frame)
		content:SetPoint("TOPLEFT", 17, -27)
		content:SetPoint("BOTTOMRIGHT", -17, 40)

		local widget = {
			titletext    = titletext,
			titlebg      = titlebg,
			sizer_se     = sizer_se,
			sizer_s      = sizer_s,
			sizer_e      = sizer_e,
			content      = content,
			frame        = frame,
			type         = Type,
			lastBetStr   = lastBetStr,
			canRollStr   = canRollStr,
			rollEndedStr = rollEndedStr,
			timerStr     = timerStr,
			allIn        = allIn,
			currentBet   = 0,
			lastBetter   = '',
			lastBetTime  = 0,
			endButton    = endButton,
			timerButton10 = timerButton10,
			timerButton20 = timerButton20,
			preparation  = false,
			dkpType      = 'NA',
			rollID       = 0,
			rollLink     = ''
		}
		widget.plusButtons = plusButtons
		for _, button in pairs(plusButtons) do
			button.obj = widget
		end
		for method, func in pairs(methods) do
			widget[method] = func
		end
		closebutton.obj, allIn.obj, endButton.obj = widget, widget, widget
		timerButton10.obj, timerButton20.obj = widget, widget

		return AceGUI:RegisterAsContainer(widget)
	end

	AceGUI:RegisterWidgetType("FDRollFrame", Constructor, widgetVersion)
end