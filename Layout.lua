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
	self.showInCombat = true
	self.showBelow = 0.9
	self.order = order
	self.UnitNameText = true
	self.PercentText = true
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

local playerHealth = healthBarClass:Create("PlayerHealth", "player", -10)
addon:RegisterBar(playerHealth)

local petHealth = healthBarClass:Create("PetHealth", "pet", -20)
addon:RegisterBar(petHealth)
