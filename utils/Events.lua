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

local mixins = {}

-- Event dispatching using CallbackHandler-1.0
local events = LibStub('CallbackHandler-1.0'):New(mixins, 'RegisterEvent', 'UnregisterEvent', 'UnregisterAllEvents')

local frame = CreateFrame("Frame")

frame:SetScript('OnEvent', function(_, ...) return events:Fire(...) end)

function events:OnUsed(_, event) return frame:RegisterEvent(event) end
function events:OnUnused(_, event) return frame:UnregisterEvent(event) end

function addon:EmbedEvents(target)
	for name, method in pairs(mixins) do
		target[name] = method
	end
end

addon:EmbedEvents(addon)
