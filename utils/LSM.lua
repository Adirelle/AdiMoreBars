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

local function NOOP() end

function addon:RegisterLSMCallback(widget, mediatype, SetMedia, GetKey)
	if not GetKey then
		GetKey = NOOP
	end
	if type(SetMedia) == "string" then
		local methodName = SetMedia
		SetMedia = function(...) return widget[methodName](...) end
	end
	local handler = function(_, mt)
		if not mt or mt == mediatype then
			SetMedia(widget, LSM:Fetch(mediatype, GetKey()))
		end
	end
	LSM.RegisterCallback(widget, "LibSharedMedia_SetGlobal", handler)
	LSM.RegisterCallback(widget, "LibSharedMedia_Registered", handler)
	handler()
	return handler
end
