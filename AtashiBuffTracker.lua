local ABT = { }

-- Listing all buffs, Ignore status should be modified to your liking or be exposed to some sort of
-- options UI if I ever get around making one. One way would be to ignore them per area or something
-- for stuff like Aspect of the Wild.
ABT.ImportantBuffs = {

}

function ABT.AddBuffsToTable(...)
	for k, v in pairs({...}) do
		ABT.ImportantBuffs[k] = v
	end
end

-- Druid Buffs
ABT.AddBuffsToTable({
	BuffName = "Mark of the Wild",
	GreaterName = "Gift of the Wild",
}, {
	BuffName = "Gift of the Wild",
})

-- Hunter Buffs
ABT.AddBuffsToTable({
	BuffName = "Trueshot Aura",
	Ignore = true
}, {
	BuffName = "Aspect of the Wild",
	Ignore = true
})

-- Mage Buffs
ABT.AddBuffsToTable({
	BuffName = "Arcane Intellect",
	GreaterName = "Arcane Brilliance",
	IgnoredClasses = { "Warrior", "Rogue" }
}, {
	BuffName = "Arcane Brilliance",
	IgnoredClasses = { "Warrior", "Rogue" }
})

-- Paladin Buffs
ABT.AddBuffsToTable({
	BuffName = "Blessing of Might",
	GreaterName = "Greater Blessing of Might",
	IgnoredClasses = { "Druid", "Warlock", "Mage", "Priest", "Paladin" }
}, {
	BuffName = "Greater Blessing of Might",
	IgnoredClasses = { "Druid", "Warlock", "Mage", "Priest", "Paladin" }
}, {
	BuffName = "Blessing of Light",
	GreaterName = "Greater Blessing of Light"
}, {
	BuffName = "Greater Blessing of Light"
}, {
	BuffName = "Blessing of Kings",
	GreaterName = "Greater Blessing of Kings"
}, {
	BuffName = "Greater Blessing of Kings"
}, {
	BuffName = "Blessing of Sanctuary",
	GreaterName = "Greater Blessing of Sanctuary",
	Ignore = true
}, {
	BuffName = "Greater Blessing of Sanctuary",
	Ignore = true
}, {
	BuffName = "Blessing of Wisdom",
	GreaterName = "Greater Blessing of Wisdom",
	IgnoredClasses = { "Warrior", "Rogue" }
}, {
	BuffName = "Greater Blessing of Wisdom",
	IgnoredClasses = { "Warrior", "Rogue" }
}, {
	BuffName = "Blessing of Salvation",
	GreaterName = "Greater Blessing of Salvation",
	IgnoredRoles = { "MAINTANK" }
}, {
	BuffName = "Greater Blessing of Salvation",
	IgnoredRoles = { "MAINTANK" }
});

-- Priest Buffs
ABT.AddBuffsToTable({
	BuffName = "Power Word: Fortitude",
	GreaterName = "Prayer of Fortitude"
}, {
	BuffName = "Prayer of Fortitude"
});
	-- Rogue Buffs
	-- Shaman Buffs
	-- Warlock Buffs

-- Consumables
ABT.AddBuffsToTable({
	BuffName = "Greater Shadow Protection Potion"
})

ABT.RaidMembers = {
	-- We store all the raid members here :)
}

ABT.MissingBuffs = {

}

ABT.raidIndex = 1
ABT.deadCount = 0
ABT.offlineCount = 0
ABT.doRun = false

_G.SLASH_ABT1 = '/abt'
SlashCmdList["ABT"] = function(a_slashMessage)
	ABT.doRun = true
end

function OnLoad(self)
	DEFAULT_CHAT_FRAME:AddMessage("Atashi buff tracker loaded!")
end

function PrintResults()
	if ABT.offlineCount > 0 then
		ABT.MissingBuffs["Offline"] = ABT.offlineCount
	end

	if ABT.deadCount > 0 then
		ABT.MissingBuffs["Dead"] = ABT.deadCount
	end

	for i = 1, table.getn(ABT.RaidMembers) do
		for buff, bool in pairs(ABT.RaidMembers[i].Missing) do
			if ABT.MissingBuffs[buff] then
				ABT.MissingBuffs[buff] = ABT.MissingBuffs[buff] + 1
			else
				ABT.MissingBuffs[buff] = 1
			end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("ABT >> The following buffs are missing:")
	for buff, number in pairs(ABT.MissingBuffs) do
		DEFAULT_CHAT_FRAME:AddMessage("    " .. buff .. ": " .. number)
	end
end

function OnUpdate(self, event)
	if not ABT.doRun or not (IsInRaid() or IsInGroup()) then
		return
	end

	if ABT.raidIndex > GetNumGroupMembers() then
		ABT.MissingBuffs = {
			-- Clear the previous parse
		}

		PrintResults()

		ABT.raidIndex = 1
		ABT.RaidMembers = { }
		ABT.deadCount = 0
		ABT.doRun = false
		return
	end

	ABT.RaidMembers[ABT.raidIndex] = { }
	local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(ABT.raidIndex)
	ABT.RaidMembers[ABT.raidIndex].Name = name
	ABT.RaidMembers[ABT.raidIndex].Class = class
	ABT.RaidMembers[ABT.raidIndex].Role = role
	ABT.RaidMembers[ABT.raidIndex].BuffedWith = { }
	ABT.RaidMembers[ABT.raidIndex].Missing = { }

	if isDead then
		ABT.deadCount = ABT.deadCount + 1
	end

	if not online then
		ABT.offlineCount = ABT.offlineCount + 1
	end

	local currentBuffIndex = 1
	local maxBuffs = 32

	-- Find out what buffs the unit have
	repeat
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff("raid" .. ABT.raidIndex, currentBuffIndex)
		
		if name ~= nil then
			table.insert(ABT.RaidMembers[ABT.raidIndex].BuffedWith, name)
		end

		currentBuffIndex = currentBuffIndex + 1
	until (name == nil or buff == maxBuffs)

	-- Compare the found buffs on a unit with what we expect to find
	for importantBuffIndex = 1, table.getn(ABT.ImportantBuffs) do
		local isMissing = true
		local unitBuffCount = table.getn(ABT.RaidMembers[ABT.raidIndex].BuffedWith)

		if not ABT.ImportantBuffs[importantBuffIndex].Ignore then
			for unitBuffIndex = 1, unitBuffCount do
				if ABT.ImportantBuffs[importantBuffIndex].GreaterName then
					local buffName = ABT.RaidMembers[ABT.raidIndex].BuffedWith[unitBuffIndex]

					if buffName == ABT.ImportantBuffs[importantBuffIndex].BuffName then
						isMissing = false
						break
					elseif buffName == ABT.ImportantBuffs[importantBuffIndex].GreaterName then
						isMissing = false
						break
					end
				else
					if ABT.RaidMembers[ABT.raidIndex].BuffedWith[unitBuffIndex] == ABT.ImportantBuffs[importantBuffIndex].BuffName then
						isMissing = false
						break
					end
				end
			end

			if isMissing then
				local ignoredBuffForClass = false
				local ignoredBuffForRole = false

				-- Is this buff ignored by this class?
				if ABT.ImportantBuffs[importantBuffIndex].IgnoredClasses then
					for classIndex = 1, table.getn(ABT.ImportantBuffs[importantBuffIndex].IgnoredClasses) do
						if ABT.ImportantBuffs[importantBuffIndex].IgnoredClasses[classIndex] == ABT.RaidMembers[ABT.raidIndex].Class then
							-- This Buff is not important for the class, ignoring it.
							ignoredBuffForClass = true
						end
					end
				end

				-- Is this buff ignored by this role? This only works if you set the Main Tank role in the UI.
				if ABT.ImportantBuffs[importantBuffIndex].IgnoredRoles then
					for classIndex = 1, table.getn(ABT.ImportantBuffs[importantBuffIndex].IgnoredRoles) do
						if ABT.ImportantBuffs[importantBuffIndex].IgnoredRoles[classIndex] == ABT.RaidMembers[ABT.raidIndex].Role then
							-- This Buff is not important for the class, ignoring it.
							ignoredBuffForRole = true
						end
					end
				end

				if not ignoredBuffForClass and not ignoredBuffForRole then
					if ABT.ImportantBuffs[importantBuffIndex].GreaterName then
						-- Placeholder true, using a hash map to avoid duplicates
						ABT.RaidMembers[ABT.raidIndex].Missing[ABT.ImportantBuffs[importantBuffIndex].GreaterName] = true
					else
						-- Placeholder true, using a hash map to avoid duplicates
						ABT.RaidMembers[ABT.raidIndex].Missing[ABT.ImportantBuffs[importantBuffIndex].BuffName] = true
					end
				end
			end
		end
	end

	ABT.raidIndex = ABT.raidIndex + 1
end