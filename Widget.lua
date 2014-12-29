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

	local width, height = 150, 20
	self:SetSize(width, height)
	self:SetBackdrop(BAR_BACKDROP)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0, 0, 0, 0)

	LSM.RegisterCallback(self, "LibSharedMedia_SetGlobal", "UpdateTexture")
	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "UpdateTexture")
	self:UpdateTexture()

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

function barProto:OnInitialize()
	self:Debug('OnInitialize')
	
	if self.UnitNameText and self.unit then
		local text = self:CreateFontString(self:GetName().."UnitName", "ARTWORK", "GameFontWhite")
		text:SetPoint("LEFT")
		self.UnitNameText = text
	else
		self.UnitNameText = nil
	end
	
	if self.PercentText then
		local text = self:CreateFontString(self:GetName().."Percent", "ARTWORK", "NumberFontNormal")
		text:SetPoint("CENTER")
		self.PercentText = text
	end

	if self.CurrentText or self.FractionText then
		local text = self:CreateFontString(self:GetName().."Current", "ARTWORK", "NumberFontNormal")
		text:SetPoint("RIGHT")
		self.CurrentText = self.CurrentText and text or nil
		self.FractionText = self.FractionText and text or nil
	end
	
	if self.showBelow then
		if self.showBelow >= 0.0 and self.showBelow <= 1.0 then
			self:Hook('CheckVisibility', function()
				if self:GetPercent() < self.showBelow then
					self.shouldShow = true 
				end
			end)
			self:Hook('UpdateMinMax', self.UpdateVisibility)
		else
			self:Hook('CheckVisibility', function()
				if self:GetCurrent() < self.showBelow then
					self.shouldShow = true 
				end
			end)
		end
		self:Hook('UpdateCurrent', self.UpdateVisibility)
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
	if self.unit == "pet" then
		self:RegisterUnitEvent('UNIT_PET', 'player')
	end
	if self.UnitNameText and self.unit then
		self:RegisterUnitEvent('UNIT_NAME', self.unit)
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

function barProto:OnValueChanged(value)
	self:Debug('OnValueChanged', value)
	if self.CurrentText then
		self.CurrentText:SetFormattedText("%d", value)
	end	
	self:UpdatePercent()
end

function barProto:OnMinMaxChanged(mini, maxi)
	self:Debug('OnMinMaxChanged', mini, maxi)
	self:UpdatePercent()
end

function barProto:IsAvailable()
	return self.unit ~= "pet" or UnitExists("pet")
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

function barProto:UpdateTexture(mediatype)
	if mediatype and mediatype ~= "statusbar" then
		return
	end
	self:SetStatusBarTexture(LSM:Fetch("statusbar"))
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

function barProto:UpdateName()
	if self.UnitNameText then
		self.UnitNameText:SetText(UnitName(self.unit)) 
	end
end
barProto.UNIT_NAME = barProto.UpdateName

function barProto:UpdateVisibility()
	self.shouldShow = false
	if self:IsAvailable() then
		self:CheckVisibility()
	end
	self:Debug('UpdateVisibility', self.shouldShow)
	if self.shouldShow and not self:IsShown() then
		self:Show()
		self:SetAlpha(0)
		self:SetScript('OnUpdate', self.OnUpdate)
	elseif not self.shouldShow and self:IsShown() then
		self:SetScript('OnUpdate', self.OnUpdate)
	end
end
barProto.UNIT_PET = barProto.UpdateVisibility

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
	-- Hide
	if self.showInCombat and self.inCombat then
		self.shouldShow = true
	end
end

function barProto:FullUpdate()
	self:Debug('FullUpdate')
	self:UpdateTexture()
	self:UpdateName()
	self:UpdateMinMax()
	self:UpdateCurrent()
end

function barProto:UpdateCurrent()
	self:SetValue(self:GetCurrent())
end

function barProto:UpdateMinMax()
	self:SetMinMaxValues(self:GetMinMax())
end

function barProto:UpdatePercent()
	local percent = self:GetPercent()
	if self.percent == percent then return end
	self.percent = percent
	if self.gradient then
		self:UpdateColor()
	end
	if self.PercentText then
		self.PercentText:SetFormattedText("%d%%", floor(percent*100+0.5))
	end
	if self.FractionText then
		local _, maxi = self:GetMinMax()
		self.FractionText:SetFormattedText("%d / %d", self:GetCurrent(), maxi)
	end
end
