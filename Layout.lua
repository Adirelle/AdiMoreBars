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

local healthBarClass, healthBarProto = addon.BarClass:SubClass()

function healthBarProto:OnCreate(name, unit, order)
	self.super.OnCreate(self, name)

	self.gradient = { 1, 0, 0, 1, 1, 0, 0, 1, 0 }
	self.unit = unit
	self.showBelow = 0.9
	self.order = order
	self.UnitNameText = true
	self.CurrentText = true

	self:Hook('OnEnable', function(self)
		self:RegisterUnitEvent('UNIT_HEALTH', self.unit)
		self:RegisterUnitEvent('UNIT_HEALTH_MAX', self.unit)
	end)
	self:Hook('OnDisable', function(self)
		self:UnregisterEvent('UNIT_HEALTH', self.unit)
		self:UnregisterEvent('UNIT_HEALTH_MAX', self.unit)
	end)

	self:Hook('OnShow', function(self)
		self:RegisterUnitEvent('UNIT_HEALTH_FREQUENT', self.unit)
	end)
	self:Hook('OnHide', function(self)
		self:UnregisterEvent('UNIT_HEALTH_FREQUENT')
	end)
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

local powerBarClass, powerBarProto = addon.BarClass:SubClass()

function powerBarProto:OnCreate(name, unit, order, power, powerIndex)
	self.super.OnCreate(self, name)

	self.unit = unit
	self.power = power
	self.powerIndex = powerIndex or _G['SPELL_POWER_'..power]
	self.showInCombat = true
	self.showBelow = 0.9
	self.order = order
	self.CurrentText = true

	local pbc = PowerBarColor[power] or PowerBarColor[self.powerIndex]
	if pbc then
		self.color = { pbc.r, pbc.g, pbc.b }
	end
	self:Hook('OnEnable', function(self)
		self:RegisterUnitEvent('UNIT_POWER', self.unit)
		self:RegisterUnitEvent('UNIT_POWER_MAX', self.unit)
	end)
	self:Hook('OnDisable', function(self)
		self:UnregisterEvent('UNIT_POWER', self.unit)
		self:UnregisterEvent('UNIT_POWER_MAX', self.unit)
	end)

	self:Hook('OnShow', function(self)
		self:RegisterUnitEvent('UNIT_POWER_FREQUENT', self.unit)
	end)
	self:Hook('OnHide', function(self)
		self:UnregisterEvent('UNIT_POWER_FREQUENT')
	end)
end

function powerBarProto:IsAvailable()
	return self.super.IsAvailable(self) and UnitPower(self.unit, self.powerIndex) > 0
end

function powerBarProto:GetCurrent()
	return UnitPower(self.unit, self.powerIndex)
end

function powerBarProto:GetMinMax()
	return 0, UnitPowerMax(self.unit, self.powerIndex)
end

function powerBarProto:UNIT_POWER(event, unit, power)
	if power and power ~= self.power then return end
	self:Debug('UNIT_POWER', event, unit, power, self.unit, self.power)
	return self:UpdateCurrent()
end
powerBarProto.UNIT_POWER_FREQUENT = powerBarProto.UNIT_POWER

function powerBarProto:UNIT_POWER_MAX(event, unit, power)
	if power and power ~= self.power then return end
	self:Debug('UNIT_POWER_MAX', event, unit, power, self.unit, self.power)
	return self:UpdateMinMax()
end

powerBarClass:Create("Focus", "player", 10, "FOCUS")
