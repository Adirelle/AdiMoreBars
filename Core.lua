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

local bars = {}
addon.DEFAULT_SETTINGS = {
	profile = {
		anchor = {},
		bars = {
			['**'] = { enabled = true },
		}
	},
}

local SPACING = 4

local anchor = CreateFrame("Frame", addonName.."Anchor", UIParent)
anchor:SetPoint("CENTER", 0, -100)
anchor:SetSize(150, 20)
anchor:Hide()
addon.Anchor = anchor

function addon:OnInitialize()
	LibStub('LibMovable-1.0').RegisterMovable(addonName, anchor, function() return self.db.profile.anchor end)

	for _, bar in pairs(bars) do
		self:Debug('Initializing', bar:GetName())
		bar:OnInitialize()
	end

	anchor:Show()
end

local function SortBars(a, b)
	return a.order < b.order
end

local visibleBars = {}
local function DoUpdateLayout()
	anchor:SetScript('OnUpdate', nil)

	wipe(visibleBars)
	for _, bar in pairs(bars) do
		if bar:IsVisible() then
			tinsert(visibleBars, bar)
		end
	end
	table.sort(visibleBars, SortBars)

	for i, bar in ipairs(visibleBars) do
		if bar.order < 0 then
			local nextBar = visibleBars[i+1]
			if not nextBar or nextBar.order >= 0 then
				bar:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -SPACING)
			else
				bar:SetPoint("TOPLEFT", nextBar, "BOTTOMLEFT", 0, -SPACING)
			end
		else
			local prevBar = visibleBars[i-1]
			if not prevBar or prevBar.order < 0 then
				bar:SetPoint("BOTTOMLEFT", anchor, 0, 0)
			else
				bar:SetPoint("BOTTOMLEFT", prevBar, "TOPLEFT", 0, SPACING)
			end
		end
	end
end

function addon:UpdateLayout()
	anchor:SetScript('OnUpdate', DoUpdateLayout)
end

function addon:RegisterBar(bar)
	tinsert(bars, bar)
end
