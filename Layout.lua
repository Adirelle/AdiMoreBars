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

local healthBarClass, healthBarProto, super = addon.BarClass:SubClass()

function healthBarProto:OnCreate(name, unit, order)
	super.OnCreate(self, name)

	self.gradient = { 1, 0, 0, 1, 1, 0, 0, 1, 0 }
	self.unit = unit
	self.showBelow = 0.9
	self.order = order
	self.LabelText = true
	self.CurrentText = true
end

function healthBarProto:IsAvailable()
	return super.IsAvailable(self) and (self.unit ~= "pet" or UnitExists("pet"))
end

function healthBarProto:GetLabel()
	return UnitName(self.unit)
end
healthBarProto.UNIT_NAME = healthBarProto.UpdateLabel

function healthBarProto:OnEnable()
	super.OnEnable(self)
	self:RegisterUnitEvent('UNIT_HEALTH', self.unit)
	self:RegisterUnitEvent('UNIT_HEALTH_MAX', self.unit)
	self:RegisterUnitEvent('UNIT_NAME', self.unit)
	if self.unit == "pet" then
		self:RegisterUnitEvent('UNIT_PET', "player")
	end
end
healthBarProto.UNIT_PET = healthBarProto.UpdateVisibility

function healthBarProto:OnShow()
	super.OnShow(self)
	self:UnregisterEvent('UNIT_HEALTH')
	self:RegisterUnitEvent('UNIT_HEALTH_FREQUENT', self.unit)
end

function healthBarProto:OnHide()
	super.OnHide(self)
	self:UnregisterEvent('UNIT_HEALTH_FREQUENT')
	self:RegisterUnitEvent('UNIT_HEALTH', self.unit)
end

function healthBarProto:GetCurrent()
	return UnitHealth(self.unit)
end

function healthBarProto:GetMinMax()
	return 0, UnitHealthMax(self.unit)
end

function healthBarProto:UNIT_HEALTH(event, unit)
	self:Debug('UNIT_HEALTH', event, unit, self.unit)
	return self:UpdateCurrent()
end
healthBarProto.UNIT_HEALTH_FREQUENT = healthBarProto.UNIT_HEALTH

function healthBarProto:UNIT_HEALTH_MAX(event, unit)
	self:Debug('UNIT_HEALTH_MAX', event, unit, self.unit)
	return self:UpdateMinMax()
end

healthBarClass:Create("PlayerHealth", "player", -10)
healthBarClass:Create("PetHealth", "pet", -20)

local powerBarClass, powerBarProto, super = addon.BarClass:SubClass()

function powerBarProto:OnCreate(name, unit, order, power, powerIndex)
	super.OnCreate(self, name)

	self.unit = unit
	self.power = power
	self.powerIndex = powerIndex or _G['SPELL_POWER_'..power]
	self.order = order
	self.CurrentText = true
	self.LabelText = true

	local pbc = PowerBarColor[power] or PowerBarColor[self.powerIndex]
	if pbc then
		self.color = { pbc.r, pbc.g, pbc.b }
	end

end

function powerBarProto:OnInitialize()
	super.OnInitialize(self)

	if self.segmented then
		self.Separators = {}
	end
end

function powerBarProto:OnEnable()
	super.OnEnable(self)
	if self.power == "COMBO" then
		self:RegisterUnitEvent('UNIT_COMBO_POINTS', self.unit)
	else
		self:RegisterUnitEvent('UNIT_POWER', self.unit)
		self:RegisterUnitEvent('UNIT_POWER_MAX', self.unit)
	end
	self:RegisterUnitEvent('UNIT_DISPLAYPOWER', self.unit)
	self:RegisterUnitEvent('UNIT_POWER_BAR_SHOW', self.unit)
	self:RegisterUnitEvent('UNIT_POWER_BAR_HIDE', self.unit)
	if self.onlyForSpecs then
		self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
	end
end
powerBarProto.PLAYER_SPECIALIZATION_CHANGED = powerBarProto.UpdateVisibility

function powerBarProto:OnShow()
	super.OnShow(self)
	if self.power ~= "COMBO" then
		self:RegisterUnitEvent('UNIT_POWER_FREQUENT', self.unit)
		self:UnregisterEvent('UNIT_POWER')
	end
end

function powerBarProto:OnHide()
	super.OnHide(self)
	if self.power ~= "COMBO" then
		self:RegisterUnitEvent('UNIT_POWER', self.unit)
		self:UnregisterEvent('UNIT_POWER_FREQUENT', self.unit)
	end
end

function powerBarProto:IsAvailable()
	if not super.IsAvailable(self) or UnitPowerMax(self.unit, self.powerIndex) == 0 then
		return false
	end
	if not self.onlyForSpecs then
		return true
	end
	local specIndex = GetSpecialization()
	local spec = specIndex and GetSpecializationInfo(specIndex)
	return spec and self.onlyForSpecs[spec] or false
end

function powerBarProto:GetCurrent()
	return UnitPower(self.unit, self.powerIndex, true)
end

function powerBarProto:GetMinMax()
	return 0, UnitPowerMax(self.unit, self.powerIndex, true)
end

function powerBarProto:GetLabel()
	return _G[self.power] or self.power
end

function powerBarProto:FullUpdate()
	super.FullUpdate(self)
	self:UpdateSeparators()
end

function powerBarProto:OnSizeChanged()
	self:UpdateSeparators()
end

function powerBarProto:OnMinMaxChanged(mini, maxi)
	super.OnMinMaxChanged(self, mini, maxi)
	self:UpdateSeparators()
end

function powerBarProto:UpdateSeparators()
	if not self.segmented then return end
	local separators, segmentSize = self.Separators, self.segmented
	local mini, maxi = self:GetMinMax()
	local numSeparators = ceil((maxi-mini) / segmentSize) - 1
	local width = self:GetWidth() / (numSeparators+1)
	for i = 1, numSeparators do
		local separator = separators[i]
		if not separator then
			separator = self:CreateTexture(nil, "OVERLAY", nil, -1)
			separator:SetTexture(0, 0, 0, 1)
			separator:SetWidth(1)
			separator:SetPoint("TOP")
			separator:SetPoint("BOTTOM")
			separators[i] = separator
		end
		separator:SetPoint("LEFT", i * width, 0)
		separator:Show()
	end
	for i = numSeparators+1, #separators do
		separators[i]:Hide()
	end
end

function powerBarProto:UNIT_DISPLAYPOWER()
	return self:UpdateVisibility()
end
powerBarProto.UNIT_POWER_BAR_SHOW = powerBarProto.UNIT_DISPLAYPOWER
powerBarProto.UNIT_POWER_BAR_HIDE = powerBarProto.UNIT_DISPLAYPOWER

function powerBarProto:UNIT_POWER(event, unit, power)
	if power and power ~= self.power then return end
	self:Debug('UNIT_POWER', event, unit, power, self.unit, self.power)
	return self:UpdateCurrent()
end
powerBarProto.UNIT_COMBO_POINTS = powerBarProto.UNIT_POWER
powerBarProto.UNIT_POWER_FREQUENT = powerBarProto.UNIT_POWER

function powerBarProto:UNIT_POWER_MAX(event, unit, power)
	if power and power ~= self.power then return end
	self:Debug('UNIT_POWER_MAX', event, unit, power, self.unit, self.power)
	return self:UpdateMinMax()
end

local playerClass = select(2, UnitClass("player"))
local function IsA(class, ...) return playerClass == class or (... and IsA(...)) end

if not IsA("WARRIOR", "DEATHKNIGHT", "HUNTER", "ROGUE") then
	local manaBar = powerBarClass:Create("Mana", "player", 10, "MANA")
	manaBar.showBelow = 0.98
	if IsA("MONK") then
		manaBar.onlyForSpecs = { [270] = true } -- Mistweaver
	end
end

if IsA("HUNTER") then
	local focusBar = powerBarClass:Create("Focus", "player", 20, "FOCUS")
	focusBar.showBelow = 0.95
	focusBar.showInCombat = true

elseif IsA("DEATHKNIGHT") then
	local runicPowerBar = powerBarClass:Create("RunicPower", "player", 20, "RUNIC_POWER")
	runicPowerBar.showInCombat = true
	runicPowerBar.showAbove = 0

elseif IsA("PALADIN") then
	local holyPowerBar = powerBarClass:Create("HolyPower", "player", 20, "HOLY_POWER")
	holyPowerBar.segmented = 1
	holyPowerBar.showInCombat = true
	holyPowerBar.showAbove = 0

elseif IsA("WARLOCK") then
	local souldShardBar = powerBarClass:Create("SoulShards", "player", 20, "SOUL_SHARDS")
	souldShardBar.segmented = 1
	souldShardBar.showInCombat = true
	souldShardBar.showAbove = 0
	souldShardBar.onlyForSpecs = { [265] = true } -- Affliction Warlock

	local burningEmberBar = powerBarClass:Create("BurningEmbers", "player", 20, "BURNING_EMBERS")
	burningEmberBar.segmented = 10
	burningEmberBar.showInCombat = true
	burningEmberBar.showAbove = 0
	burningEmberBar.onlyForSpecs = { [267] = true } -- Destruction Warlock

	local demonicFuryBar = powerBarClass:Create("DemonicFury", "player", 20, "DEMONIC_FURY")
	demonicFuryBar.showInCombat = true
	demonicFuryBar.showAbove = 200
	demonicFuryBar.onlyForSpecs = { [266] = true } -- Demonology Warlock

elseif IsA("DRUID", "ROGUE", "MONK") then
	local energyBar = powerBarClass:Create("Energy", "player", 20, "ENERGY")
	energyBar.showBelow = 1
	energyBar.showInCombat = not IsA("DRUID")
	if IsA("MONK") then
		energyBar.onlyForSpecs = {
			[268] = true, -- Brewmaster
			[269] = true, -- Windwalker
		}
	end

end

if IsA("DRUID", "WARRIOR") then
	local rageBar = powerBarClass:Create("Rage", "player", 30, "RAGE")
	rageBar.showAbove = 0
	rageBar.showInCombat = IsA("WARRIOR")

elseif IsA("MONK") then
	local chiBar = powerBarClass:Create("Chi", "player", 30, "CHI")
	chiBar.segmented = 1
	chiBar.showAbove = 0
	chiBar.showInCombat = true
end

if IsA("DRUID", "ROGUE") then
	local comboBar = powerBarClass:Create("Combo", "player", 50, "COMBO", 4)
	comboBar.segmented = 1
	comboBar.showAbove = 0
	comboBar.showInCombat = IsA("ROGUE")
end

if IsA("DRUID") then
	local eclipseBar = powerBarClass:Create("Eclipse", "player", 40, "ECLIPSE")
	eclipseBar.showInCombat = true
	eclipseBar.onlyForSpecs = { [102] = true } -- Balance

	function eclipseBar:GetMinMax()
		local maxi = UnitPowerMax(self.unit, self.powerIndex)
		return -maxi, maxi
	end
end

local alternateBar = powerBarClass:Create("Alternate", "player", 50, "ALTERNATE", ALTERNATE_POWER_INDEX)
alternateBar.color = { 1, 1, 1 }

function alternateBar:IsAvailable()
	if not powerBarProto.IsAvailable(self) then
		return false
	end
	return not not UnitAlternatePowerInfo(self.unit)
end

function alternateBar:GetMinMax()
	return select(2, UnitAlternatePowerInfo(self.unit)), UnitPowerMax(self.unit, self.powerIndex)
end

function alternateBar:UpdateColor()
	local c = self.color
	c[1], c[2], c[3] = select(2, UnitAlternatePowerTextureInfo(self.unit, 2))
	powerBarProto.UpdateColor(self)
end

function alternateBar:GetLabel()
	return (select(10, UnitAlternatePowerInfo(self.unit)))
end
