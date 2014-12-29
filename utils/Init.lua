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

local function Init(event, name)
	if name ~= addonName then return end
	addon.UnregisterEvent(addonName.."Init", event)
	addon.db = LibStub('AceDB-3.0'):New(addonName.."DB", addon.DEFAULT_SETTINGS or {}, true)
	return addon:OnInitialize()
end

addon.RegisterEvent(addonName.."Init", 'ADDON_LOADED', Init)
