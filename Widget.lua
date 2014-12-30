--[[
AdiMoreBars - Movable health and power bars.
Copyright 2013-2014 Adirelle (adirelle@gmail.com)
All rights reserved.

This file is part of AdiMoreBars.

AdiMoreBars is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

AdiMoreBars is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with AdiMoreBars.  If not, see <http://www.gnu.org/licenses/>.
--]]

local addonName, addon = ...

local LSM = LibStub('LibSharedMedia-3.0')

local BORDER_SIZE = 2
local PADDING = 2

local BAR_BACKDROP = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	tile = true,
	tileSize = 16,
}
local BORDER_BACKDROP = {
	edgeFile = [[Interface\Addons\AdiCastBar\media\white16x16]],
	edgeSize = BORDER_SIZE,
}

local barClass, barProto = {}, {}
addon.BarClass = barClass

barProto.Debug = addon.Debug
barProto.Hook = hooksecurefunc
barProto.class = barClass

setmetatable(barProto, { __index = getmetatable(CreateFrame("StatusBar")).__index })

barClass.__index = barProto

function barClass:Create(name, ...)
	local frame = CreateFrame("StatusBar", addonName..name, addon.Anchor)
	setmetatable(frame, self)
	frame:OnCreate(name, ...)
	addon:RegisterBar(frame)
	return frame
end

function barClass:SubClass()
	local newClass, newProto = {}, {}

	newProto.super = self.__index
	newProto.class = newClass
	setmetatable(newProto, { __index = self.__index })

	newClass.parent = self
	newClass.__index = newProto
	setmetatable(newClass, { __index = self })

	return newClass, newProto
end

local handlers = {
	OnShow           = function(self) return self:OnShow() end,
	OnHide           = function(self) return self:OnHide() end,
	OnSizeChanged    = function(self, w, h) return self:OnSizeChanged(w, h) end,
    OnValueChanged   = function(self, value) return self:OnValueChanged(value) end,
	OnMinMaxChanged  = function(self, mini, maxi) return self:OnMinMaxChanged(mini, maxi) end,
	OnEvent          = function(self, event, ...) return self[event](self, event, ...) end,
}

local NOOP = function() end
barProto.OnSizeChanged = NOOP

function barProto:OnCreate(name)
	self:Hide()
	for name, handler in pairs(handlers) do
		self:SetScript(name, handler)
	end

	local width, height = 350, 24
	self:SetSize(width, height)
	self:SetBackdrop(BAR_BACKDROP)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0, 0, 0, 0)

	self.UpdateTexture = addon:RegisterLSMCallback(self, "statusbar", "SetTexture")

	local border = CreateFrame("Frame", nil, self)
	border:SetWidth(width+BORDER_SIZE*2)
	border:SetHeight(height+BORDER_SIZE*2)
	border:SetPoint("CENTER")
	border:SetBackdrop(BORDER_BACKDROP)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(0, 0, 0, 1)
	self.Border = border
end

function barProto:GetDB()
	return addon.db.profile.bars[self:GetName()]
end

local function SetFont(fontstring, fontFile)
	fontstring:SetFont(fontFile, 13, "")
	fontstring:SetShadowColor(0, 0, 0, 1)
	fontstring:SetShadowOffset(1, -1)
end

function barProto:OnInitialize()
	self:Debug('OnInitialize')

	if self.LabelText then
		local text = self:CreateFontString(self:GetName().."Label", "OVERLAY")
		text:SetPoint("LEFT", PADDING, 0)
		addon:RegisterLSMCallback(text, "font", SetFont)
		self.LabelText = text
	end

	if self.MaximumText then
		local text = self:CreateFontString(self:GetName().."Maximum", "OVERLAY")
		text:SetPoint("RIGHT", -PADDING, 0)
		addon:RegisterLSMCallback(text, "font", SetFont)
		self.MaximumText = text
	end

	if self.CurrentText or self.MaximumText then
		local text = self:CreateFontString(self:GetName().."Current", "OVERLAY")
		if self.MaximumText then
			text:SetPoint("RIGHT", self.MaximumText, "LEFT")
		else
			text:SetPoint("RIGHT", -PADDING, 0)
		end
		addon:RegisterLSMCallback(text, "font", SetFont)
		self.CurrentText = text
	end

	if self.PercentText then
		local text = self:CreateFontString(self:GetName().."Percent", "OVERLAY")
		if self.CurrentText then
			text:SetPoint("CENTER")
		else
			text:SetPoint("RIGHT", -PADDING, 0)
		end
		addon:RegisterLSMCallback(text, "font", SetFont)
		self.PercentText = text
	end

	if self:GetDB().enabled then
		self:Enable()
	else
		self:Disable()
	end
end

function barProto:Enable()
	if not self.enabled then
		self.enabled = true
		self:OnEnable()
	end
end

function barProto:Disable()
	if self.enabled then
		self.enabled = false
		self:OnDisable()
	end
end

function barProto:PLAYER_ENTERING_WORLD()
	return self:UpdateVisibility()
end

function barProto:OnEnable()
	self:Debug('OnEnable')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	if self.showInCombat then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
		self:RegisterEvent('PLAYER_REGEN_DISABLED')
		self:UpdateCombatStatus()
	end
	self:UpdateVisibility()
end

function barProto:OnDisable()
	self:Debug('OnDisable')
	self:Hide()
	self:UnregisterAllEvents()
end

function barProto:OnShow()
	self:Debug('OnShow')
	addon:UpdateLayout()
	self:FullUpdate()
end

function barProto:OnHide()
	self:Debug('OnHide')
	addon:UpdateLayout()
end

local function SmartValue(value)
	if value >= 10000000 then
		return format("%.1fm", value/1000000)
	elseif value >= 10000 then
		return format("%.1fk", value/1000)
	else
		return tostring(value)
	end
end

function barProto:OnValueChanged(value)
	self:Debug('OnValueChanged', value)
	if self.CurrentText then
		self.CurrentText:SetText(SmartValue(value))
	end
end

function barProto:OnMinMaxChanged(mini, maxi)
	self:Debug('OnMinMaxChanged', mini, maxi)
	if self.MaximumText then
		self.MaximumText:SetText(" / "..SmartValue(maxi))
	end
end

function barProto:IsAvailable()
	return true
end

function barProto:GetLabel()
	return self:GetName()
end

function barProto:GetCurrent()
	return 0
end

function barProto:GetMinMax()
	return 0, 0
end

function barProto:GetPercent()
	local current, mini, maxi = self:GetCurrent(), self:GetMinMax()
	if current and mini and maxi and maxi ~= mini then
		return (current - mini) / (maxi - mini)
	end
	return 0
end

function barProto:SetTexture(texture)
	self:SetStatusBarTexture(texture)
	self:UpdateColor()
end

function barProto:UpdateColor()
	if self.color then
		self:SetStatusBarColor(unpack(self.color, 1, 3))
	end
	if self.gradient then
		self:SetStatusBarColor(addon.HCYColorGradient(self:GetPercent(), 1.0, unpack(self.gradient)))
	end
end

function barProto:UpdateLabel()
	if self.LabelText then
		self.LabelText:SetText(self:GetLabel())
	end
end

function barProto:UpdateVisibility()
	self.shouldShow = self:IsAvailable() and self:CheckVisibility()
	self:Debug('UpdateVisibility', self.shouldShow)
	if self.shouldShow and not self:IsShown() then
		self:Show()
		self:SetAlpha(0)
		self:SetScript('OnUpdate', self.OnUpdate)
	elseif not self.shouldShow and self:IsShown() then
		self:SetScript('OnUpdate', self.OnUpdate)
	end
end

function barProto:UpdateCombatStatus(event)
	if not self.showInCombat then return end
	local inCombat = event == 'PLAYER_REGEN_DISABLED' or InCombatLockdown()
	if self.inCombat ~= inCombat then
		self.inCombat = inCombat
		return self:UpdateVisibility()
	end
end
barProto.PLAYER_REGEN_ENABLED = barProto.UpdateCombatStatus
barProto.PLAYER_REGEN_DISABLED = barProto.UpdateCombatStatus

local FADING_SPEED = 1 / 0.3
function barProto:OnUpdate(elapsed)
	local alpha = self:GetAlpha()
	if self.shouldShow then
		alpha = alpha + FADING_SPEED * elapsed
		if alpha >= 1.0 then
			self:SetAlpha(1.0)
			return self:SetScript('OnUpdate', nil)
		end
	else
		alpha = alpha - FADING_SPEED * elapsed
		if alpha <= 0.0 then
			self:SetAlpha(0)
			self:SetScript('OnUpdate', nil)
			return self:Hide()
		end
	end
	self:SetAlpha(alpha)
end

function barProto:CheckVisibility()
	if self.showInCombat and self.inCombat then
		self:Debug('CheckVisibility', inCombat)
		return true
	end
	if self.showBelow and self:GetPercent() < self.showBelow then
		self:Debug('CheckVisibility', self:GetPercent(), 'below', self.showBelow)
		return true
	end
	if self.showAbove and self:GetCurrent() > self.showAbove then
		self:Debug('CheckVisibility', self:GetCurrent(), 'above', self.showAbove)
		return true
	end
	self:Debug('CheckVisibility', 'nothing')
	return false
end

function barProto:FullUpdate()
	self:Debug('FullUpdate')
	self:UpdateTexture()
	self:UpdateLabel()
	self:UpdateMinMax()
	self:UpdateCurrent()
end

function barProto:UpdateCurrent()
	local current = self:GetCurrent()
	if self._current == current then return end
	self._current = current
	self:SetValue(current)
	if self.showAbove or self.showBelow then
		self:UpdateVisibility()
	end
	self:UpdatePercent()
end

function barProto:UpdateMinMax()
	local mini, maxi = self:GetMinMax()
	if self._mini == mini and self._maxi == maxi then return end
	self._mini, self._maxi = mini, maxi
	self:SetMinMaxValues(mini, maxi)
	self:UpdatePercent()
	if self.showBelow then
		self:UpdateVisibility()
	end
end

function barProto:UpdatePercent()
	local percent = self:GetPercent()
	if self._percent == percent then return end
	self._percent = percent
	if self.gradient then
		self:UpdateColor()
	end
	if self.PercentText then
		self.PercentText:SetFormattedText("%d%%", floor(percent*100+0.5))
	end
end
