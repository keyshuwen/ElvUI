local E, L, V, P, G = unpack(ElvUI)
local CH = E:NewModule("Chat", "AceTimer-3.0", "AceHook-3.0", "AceEvent-3.0")
local CC = E:GetModule("ClassCache")
local LSM = LibStub("LibSharedMedia-3.0")

local _G = _G
local time, difftime = time, difftime
local pairs, unpack, select, tostring, next, tonumber, type, assert = pairs, unpack, select, tostring, next, tonumber, type, assert
local tinsert, tremove, twipe, tconcat = table.insert, table.remove, table.wipe, table.concat
local strmatch = strmatch
local gsub, find, gmatch, format, split = string.gsub, string.find, string.gmatch, string.format, string.split
local strlower, strsub, strlen, strupper = strlower, strsub, strlen, strupper

local BetterDate = BetterDate
local ChatEdit_ActivateChat = ChatEdit_ActivateChat
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local ChatEdit_ParseText = ChatEdit_ParseText
local ChatEdit_SetLastTellTarget = ChatEdit_SetLastTellTarget
local ChatFrame_ConfigEventHandler = ChatFrame_ConfigEventHandler
local ChatFrameEditBox = ChatFrameEditBox
local ChatFrame_SendTell = ChatFrame_SendTell
local ChatFrame_SystemEventHandler = ChatFrame_SystemEventHandler
local CreateFrame = CreateFrame
local FCF_GetCurrentChatFrame = FCF_GetCurrentChatFrame
local FCF_SetChatWindowFontSize = FCF_SetChatWindowFontSize
local FloatingChatFrame_OnEvent = FloatingChatFrame_OnEvent
local GetChannelName = GetChannelName
local GetDefaultLanguage = GetDefaultLanguage
local GetGuildRosterMOTD = GetGuildRosterMOTD
local GetMouseFocus = GetMouseFocus
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local GetTime = GetTime
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local IsAltKeyDown = IsAltKeyDown
local IsInInstance = IsInInstance
local IsMouseButtonDown = IsMouseButtonDown
local IsShiftKeyDown = IsShiftKeyDown
local PlaySound = PlaySound
local PlaySoundFile = PlaySoundFile
local ShowUIPanel, HideUIPanel = ShowUIPanel, HideUIPanel
local StaticPopup_Visible = StaticPopup_Visible
local ToggleFrame = ToggleFrame
local UnitName = UnitName
local wipe = wipe
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local GlobalStrings = {
	["AFK"] = AFK,
	["CHAT_FILTERED"] = CHAT_FILTERED,
	["CHAT_IGNORED"] = CHAT_IGNORED,
	["CHAT_RESTRICTED"] = CHAT_RESTRICTED,
	["CHAT_TELL_ALERT_TIME"] = CHAT_TELL_ALERT_TIME,
	["DND"] = DND,
	["RAID_WARNING"] = RAID_WARNING
}

local CreatedFrames = 0
local lines = {}
local msgList, msgCount, msgTime = {}, {}, {}
local chatFilters = {}

local PLAYER_REALM = gsub(E.myrealm,"[%s%-]","")
local PLAYER_NAME = E.myname.."-"..PLAYER_REALM

local DEFAULT_STRINGS = {
	BATTLEGROUND = L["BG"],
	GUILD = L["G"],
	PARTY = L["P"],
	RAID = L["R"],
	OFFICER = L["O"],
	BATTLEGROUND_LEADER = L["BGL"],
	RAID_LEADER = L["RL"],
}

local hyperlinkTypes = {
	["item"] = true,
	["spell"] = true,
	["unit"] = true,
	["quest"] = true,
	["enchant"] = true,
	["instancelock"] = true,
	["talent"] = true,
}

local smileyPack = {
	["Angry"] = [[Interface\AddOns\ElvUI\media\textures\smileys\angry.blp]],
	["Grin"] = [[Interface\AddOns\ElvUI\media\textures\smileys\grin.blp]],
	["Hmm"] = [[Interface\AddOns\ElvUI\media\textures\smileys\hmm.blp]],
	["MiddleFinger"] = [[Interface\AddOns\ElvUI\media\textures\smileys\middle_finger.blp]],
	["Sad"] = [[Interface\AddOns\ElvUI\media\textures\smileys\sad.blp]],
	["Surprise"] = [[Interface\AddOns\ElvUI\media\textures\smileys\surprise.blp]],
	["Tongue"] = [[Interface\AddOns\ElvUI\media\textures\smileys\tongue.blp]],
	["Cry"] = [[Interface\AddOns\ElvUI\media\textures\smileys\weepy.blp]],
	["Wink"] = [[Interface\AddOns\ElvUI\media\textures\smileys\winky.blp]],
	["Happy"] = [[Interface\AddOns\ElvUI\media\textures\smileys\happy.blp]],
	["Heart"] = [[Interface\AddOns\ElvUI\media\textures\smileys\heart.blp]],
	["BrokenHeart"] = [[Interface\AddOns\ElvUI\media\textures\smileys\broken_heart.blp]],
}

local smileyKeys = {
	["%:%-%@"] = "Angry",
	["%:%@"] = "Angry",
	["%:%-%)"]="Happy",
	["%:%)"]="Happy",
	["%:D"]="Grin",
	["%:%-D"]="Grin",
	["%;%-D"]="Grin",
	["%;D"]="Grin",
	["%=D"]="Grin",
	["xD"]="Grin",
	["XD"]="Grin",
	["%:%-%("]="Sad",
	["%:%("]="Sad",
	["%:o"]="Surprise",
	["%:%-o"]="Surprise",
	["%:%-O"]="Surprise",
	["%:O"]="Surprise",
	["%:%-0"]="Surprise",
	["%:P"]="Tongue",
	["%:%-P"]="Tongue",
	["%:p"]="Tongue",
	["%:%-p"]="Tongue",
	["%=P"]="Tongue",
	["%=p"]="Tongue",
	["%;%-p"]="Tongue",
	["%;p"]="Tongue",
	["%;P"]="Tongue",
	["%;%-P"]="Tongue",
	["%;%-%)"]="Wink",
	["%;%)"]="Wink",
	["%:S"]="Hmm",
	["%:%-S"]="Hmm",
	["%:%,%("]="Cry",
	["%:%,%-%("]="Cry",
	["%:%'%("]="Cry",
	["%:%'%-%("]="Cry",
	["%:%F"]="MiddleFinger",
	["<3"]="Heart",
	["</3"]="BrokenHeart",
}

local specialChatIcons
do --this can save some main file locals
	local IconPath	 = "|TInterface\\AddOns\\ElvUI\\media\\textures\\chatLogos\\"
	local ElvPurple	 = IconPath.."elvui_purple.tga:13:25|t"
	local ElvPink	 = IconPath.."elvui_pink.tga:13:25|t"
	local ElvBlue	 = IconPath.."elvui_blue.tga:13:25|t"
	local ElvGreen	 = IconPath.."elvui_green.tga:13:25|t"
	local ElvOrange	 = IconPath.."elvui_orange.tga:13:25|t"
	local ElvRed	 = IconPath.."elvui_red.tga:13:25|t"
	local ElvRainbow = IconPath.."elvui_rainbow.tga:13:25|t"
	local Bathrobe	 = IconPath.."bathrobe.blp:15:15|t"
	local MrHankey	 = IconPath.."mr_hankey.tga:16:18|t"
	specialChatIcons = {
--		["Smolderforge"] = {
--			["Loaal"] = ElvBlue,
--		}
	}
end

CH.Keywords = {}

local numScrollMessages
local function ChatFrame_OnMouseScroll(frame, delta)
	numScrollMessages = CH.db.numScrollMessages or 3
	if delta < 0 then
		if IsShiftKeyDown() then
			frame:ScrollToBottom()
		elseif IsAltKeyDown() then
			frame:ScrollDown()
		else
			for i = 1, numScrollMessages do
				frame:ScrollDown()
			end
		end
	elseif delta > 0 then
		if IsShiftKeyDown() then
			frame:ScrollToTop()
		elseif IsAltKeyDown() then
			frame:ScrollUp()
		else
			for i = 1, numScrollMessages do
				frame:ScrollUp()
			end
		end

		if CH.db.scrollDownInterval ~= 0 then
			if frame.ScrollTimer then
				CH:CancelTimer(frame.ScrollTimer, true)
			end

			frame.ScrollTimer = CH:ScheduleTimer("ScrollToBottom", CH.db.scrollDownInterval, frame)
		end
	end
end

function CH:GetGroupDistribution()
	local inInstance, kind = IsInInstance()
	if inInstance and kind == "pvp" then
		return "/bg "
	end
	if GetNumRaidMembers() > 0 then
		return "/ra "
	end
	if GetNumPartyMembers() > 0 then
		return "/p "
	end
	return "/s "
end

function CH:InsertEmotions(msg)
	for k,v in pairs(smileyKeys) do
		msg = gsub(msg,k,"|T"..smileyPack[v]..":16|t")
	end
	return msg
end

function CH:GetSmileyReplacementText(msg)
	if not msg or not self.db.emotionIcons or find(msg, "/run") or find(msg, "/dump") or find(msg, "/script") then return msg end
	local outstr = ""
	local origlen = strlen(msg)
	local startpos = 1
	local endpos, _

	while(startpos <= origlen) do
		endpos = origlen
		local pos = find(msg,"|H",startpos,true)
		if(pos ~= nil) then
			endpos = pos
		end
		outstr = outstr .. CH:InsertEmotions(strsub(msg,startpos,endpos)) --run replacement on this bit
		startpos = endpos + 1
		if(pos ~= nil) then
			_, endpos = find(msg,"|h.-|h",startpos)
			endpos = endpos or origlen
			if(startpos < endpos) then
				outstr = outstr .. strsub(msg,startpos,endpos) --don't run replacement on this bit
				startpos = endpos + 1
			end
		end
	end

	return outstr
end

function CH:StyleChat(frame)
	local name = frame:GetName()
	_G[name.."TabText"]:FontTemplate(LSM:Fetch("font", self.db.tabFont), self.db.tabFontSize, self.db.tabFontOutline)

	if frame.styled then return end

	frame:SetFrameLevel(4)

	local id = frame:GetID()

	local tab = _G[name.."Tab"]
	tab.isDocked = frame.isDocked

	for i = 1, #CHAT_FRAME_TEXTURES do
		_G[name..CHAT_FRAME_TEXTURES[i]]:Kill()
	end

	_G[name.."UpButton"]:Kill()
	_G[name.."DownButton"]:Kill()
	_G[name.."BottomButton"]:Kill()
	_G[name.."TabDockRegion"]:Kill()
	_G[name.."TabLeft"]:Kill()
	_G[name.."TabMiddle"]:Kill()
	_G[name.."TabRight"]:Kill()
	_G[name.."Tab"]:GetHighlightTexture():SetTexture(nil)

	if frame.isDocked or frame:IsVisible() then
		tab:Show()
	end

	hooksecurefunc(tab, "SetAlpha", function(t, alpha)
		if alpha ~= 1 and (not t.isDocked or SELECTED_CHAT_FRAME:GetID() == t:GetID()) then
			UIFrameFadeRemoveFrame(t)
			t:SetAlpha(1)
		elseif alpha < 0.6 then
			UIFrameFadeRemoveFrame(t)
			t:SetAlpha(0.6)
		end
	end)

	tab.text = _G[name.."TabText"]
	tab.text:SetTextColor(unpack(E["media"].rgbvaluecolor))
	hooksecurefunc(tab.text, "SetTextColor", function(self, r, g, b)
		local rR, gG, bB = unpack(E["media"].rgbvaluecolor)
		if r ~= rR or g ~= gG or b ~= bB then
			self:SetTextColor(rR, gG, bB)
		end
	end)

	if id ~= 2 then --Don't add timestamps to combat log, they don't work.
		tab.text:Point("LEFT", _G[name.."TabLeft"], "RIGHT", 0, -4)
		--This usually taints, but LibChatAnims should make sure it doesn't.
		frame.OldAddMessage = frame.AddMessage
		frame.AddMessage = CH.AddMessage
	end

	tab.flash = _G[name.."TabFlash"]
	tab.flash:ClearAllPoints()
	tab.flash:Point("TOPLEFT", _G[name.."TabLeft"], "TOPLEFT", -3, id == 2 and -3 or -2)
	tab.flash:Point("BOTTOMRIGHT", _G[name.."TabRight"], "BOTTOMRIGHT", 3, id == 2 and -7 or -6)

	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)

	--copy chat button
	frame.button = CreateFrame("Button", format("CopyChatButton%d", id), frame)
	frame.button:EnableMouse(true)
	frame.button:SetAlpha(0.35)
	frame.button:Size(20, 22)
	frame.button:SetPoint("TOPRIGHT")
	frame.button:SetFrameLevel(frame:GetFrameLevel() + 5)

	frame.button.tex = frame.button:CreateTexture(nil, "OVERLAY")
	frame.button.tex:SetInside()
	frame.button.tex:SetTexture([[Interface\AddOns\ElvUI\media\textures\copy.tga]])

	frame.button:SetScript("OnMouseUp", function(_, btn)
		if btn == "LeftButton" then
			CH:CopyChat(frame)
		elseif btn == "RightButton" and id ~= 2 then
			ToggleFrame(ChatMenu)
		end
	end)

	frame.button:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
	frame.button:SetScript("OnLeave", function(self)
		if _G[self:GetParent():GetName().."TabText"]:IsShown() then
			self:SetAlpha(0.35)
		else
			self:SetAlpha(0)
		end

	end)

	CreatedFrames = id
	frame.styled = true
end

function CH:AddMessage(msg, infoR, infoG, infoB, infoID, isHistory, historyTime)
	local historyTimestamp --we need to extend the arguments on AddMessage so we can properly handle times without overriding
	if isHistory == "ElvUI_ChatHistory" then historyTimestamp = historyTime end

	if (CH.db.timeStampFormat and CH.db.timeStampFormat ~= "NONE") then
		local timeStamp = BetterDate(CH.db.timeStampFormat, historyTimestamp or time())
		timeStamp = timeStamp:gsub(" ", "")
		timeStamp = timeStamp:gsub("AM", " AM")
		timeStamp = timeStamp:gsub("PM", " PM")
		if CH.db.useCustomTimeColor then
			local color = CH.db.customTimeColor
			local hexColor = E:RGBToHex(color.r, color.g, color.b)
			msg = format("%s[%s]|r %s", hexColor, timeStamp, msg)
		else
			msg = format("[%s] %s", timeStamp, msg)
		end
	end

	self.OldAddMessage(self, msg, infoR, infoG, infoB, infoID)
end

function CH:UpdateSettings()
	ChatFrameEditBox:SetAltArrowKeyMode(CH.db.useAltKey)
end

local removeIconFromLine
do
	local raidIconFunc = function(x) x = x~="" and _G["RAID_TARGET_"..x];return x and ("{"..strlower(x).."}") or "" end
	local stripTextureFunc = function(w, x, y) if x=="" then return (w~="" and w) or (y~="" and y) or "" end end
	local hyperLinkFunc = function(x, y) if x=="" then return y end end
	removeIconFromLine = function(text)
		text = gsub(text, "|TInterface\\TargetingFrame\\UI%-RaidTargetingIcon_(%d+):0|t", raidIconFunc) --converts raid icons into {star} etc, if possible.
		text = gsub(text, "(%s?)(|?)|T.-|t(%s?)", stripTextureFunc) --strip any other texture out but keep a single space from the side(s).
		text = gsub(text, "(|?)|H.-|h(.-)|h", hyperLinkFunc) --strip hyperlink data only keeping the actual text.
		return text
	end
end

local function colorizeLine(text, r, g, b)
	local hexCode = E:RGBToHex(r, g, b)
	local hexReplacement = format("|r%s", hexCode)

	text = gsub(text, "|r", hexReplacement)
	text = format("%s%s|r", hexCode, text)

	return text
end

function CH:GetLines(...)
	local index = 1
	wipe(lines)
	for i = select("#", ...), 1, -1 do
		local region = select(i, ...)
		if region:GetObjectType() == "FontString" then
			local line = tostring(region:GetText())
			local r, g, b = region:GetTextColor()

			line = removeIconFromLine(line)
			line = colorizeLine(line, r, g, b)

			lines[index] = line
			index = index + 1
		end
	end
	return index - 1
end

function CH:CopyChat(frame)
	if not CopyChatFrame:IsShown() then
		local _, fontSize = GetChatWindowInfo(frame:GetID())
		if fontSize < 10 then fontSize = 12 end
		FCF_SetChatWindowFontSize(frame, 0.01)
		CopyChatFrame:Show()
		local lineCt = self:GetLines(frame:GetRegions())
		local text = tconcat(lines, " \n", 1, lineCt)
		FCF_SetChatWindowFontSize(frame, fontSize)
		CopyChatFrameEditBox:SetText(text)
	else
		CopyChatFrame:Hide()
	end
end

function CH:OnEnter(frame)
	_G[frame:GetName().."Text"]:Show()
end

function CH:OnLeave(frame)
	_G[frame:GetName().."Text"]:Hide()
end

function CH:SetupChatTabs(frame, hook)
	if hook and (not self.hooks or not self.hooks[frame] or not self.hooks[frame].OnEnter) then
		self:HookScript(frame, "OnEnter")
		self:HookScript(frame, "OnLeave")
	elseif not hook and self.hooks and self.hooks[frame] and self.hooks[frame].OnEnter then
		self:Unhook(frame, "OnEnter")
		self:Unhook(frame, "OnLeave")
	end

	if not hook then
		_G[frame:GetName().."Text"]:Show()

		if frame.owner and frame.owner.button and GetMouseFocus() ~= frame.owner.button then
			frame.owner.button:SetAlpha(0.35)
		end
	elseif GetMouseFocus() ~= frame then
		_G[frame:GetName().."Text"]:Hide()

		if frame.owner and frame.owner.button and GetMouseFocus() ~= frame.owner.button then
			frame.owner.button:SetAlpha(1)
		end
	end
end

function CH:UpdateAnchors()
	local frame = _G["ChatFrameEditBox"]
	local noBackdrop = (self.db.panelBackdrop == "HIDEBOTH" or self.db.panelBackdrop == "RIGHT")
	frame:ClearAllPoints()
	if not E.db.datatexts.leftChatPanel and E.db.chat.editBoxPosition == "BELOW_CHAT" then
		frame:Point("TOPLEFT", ChatFrame1, "BOTTOMLEFT", noBackdrop and -1 or -4, noBackdrop and -1 or -4)
		frame:Point("BOTTOMRIGHT", ChatFrame1, "BOTTOMRIGHT", noBackdrop and 10 or 7, -LeftChatTab:GetHeight()-(noBackdrop and 1 or 4))
	elseif E.db.chat.editBoxPosition == "BELOW_CHAT" then
		frame:SetAllPoints(LeftChatDataPanel)
 	else
		frame:Point("BOTTOMLEFT", ChatFrame1, "TOPLEFT", noBackdrop and -1 or -1, noBackdrop and 1 or 4)
		frame:Point("TOPRIGHT", ChatFrame1, "TOPRIGHT", noBackdrop and 10 or 4, LeftChatTab:GetHeight()+(noBackdrop and 1 or 4))
	end

	-- CH:PositionChat(true)
end

local function FindRightChatID()
	local rightChatID

	for i = 1, NUM_CHAT_WINDOWS do
		local chat = _G["ChatFrame"..i]
		local id = chat:GetID()

		if(E:FramesOverlap(chat, RightChatPanel) and not E:FramesOverlap(chat, LeftChatPanel)) then
			rightChatID = id
			break
		end
	end

	return rightChatID
end

function CH:UpdateChatTabs()
	local fadeUndockedTabs = E.db["chat"].fadeUndockedTabs
	local fadeTabsNoBackdrop = E.db["chat"].fadeTabsNoBackdrop

	for i = 1, CreatedFrames do
		local chat = _G[format("ChatFrame%d", i)]
		local tab = _G[format("ChatFrame%sTab", i)]
		local id = chat:GetID()
		local isDocked = chat.isDocked

		if chat:IsShown() and (id == self.RightChatWindowID) then
			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "LEFT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		elseif not isDocked and chat:IsShown() then
			CH:SetupChatTabs(tab, fadeUndockedTabs and true or false)
		else
			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "RIGHT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		end
	end
end

function CH:PositionChat(override)
	if (InCombatLockdown() and not override and self.initialMove) then return end
	if not RightChatPanel or not LeftChatPanel then return end
	RightChatPanel:SetSize(E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth, E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight)
	LeftChatPanel:SetSize(E.db.chat.panelWidth, E.db.chat.panelHeight)

	self.RightChatWindowID = FindRightChatID()

	if not self.db.lockPositions or E.private.chat.enable ~= true then return end

	local chat, tab, id, isDocked
	local fadeUndockedTabs = E.db["chat"].fadeUndockedTabs
	local fadeTabsNoBackdrop = E.db["chat"].fadeTabsNoBackdrop

	for i = 1, CreatedFrames do
		local BASE_OFFSET = 57 + E.Spacing*3

		chat = _G[format("ChatFrame%d", i)]
		id = chat:GetID()
		tab = _G[format("ChatFrame%sTab", i)]
		isDocked = chat.isDocked
		tab.isDocked = chat.isDocked
		tab.owner = chat

		if chat:IsShown() and id == self.RightChatWindowID then
			chat:ClearAllPoints()

			if E.db.datatexts.rightChatPanel then
				chat:Point("BOTTOMLEFT", RightChatDataPanel, "TOPLEFT", 1, 3)
			else
				BASE_OFFSET = BASE_OFFSET - 24
				chat:Point("BOTTOMLEFT", RightChatDataPanel, "BOTTOMLEFT", 1, 1)
			end
			if id ~= 2 then
				chat:SetSize((E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth) - 11, (E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight) - BASE_OFFSET)
			else
				chat:SetSize(E.db.chat.panelWidth - 11, (E.db.chat.panelHeight - BASE_OFFSET) - CombatLogQuickButtonFrame_Custom:GetHeight())
			end

			tab:SetParent(RightChatPanel)
			chat:SetParent(RightChatPanel)

			if chat:IsMovable() then
				chat:SetUserPlaced(true)
			end
			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "LEFT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		elseif not isDocked and chat:IsShown() then
			tab:SetParent(UIParent)
			chat:SetParent(UIParent)
			CH:SetupChatTabs(tab, fadeUndockedTabs and true or false)
		else
			if id ~= 2 then
				chat:ClearAllPoints()
				if E.db.datatexts.leftChatPanel then
					chat:Point("BOTTOMLEFT", LeftChatToggleButton, "TOPLEFT", 1, 3)
				else
					BASE_OFFSET = BASE_OFFSET - 24
					chat:Point("BOTTOMLEFT", LeftChatToggleButton, "BOTTOMLEFT", 1, 1)
				end

				chat:SetSize(E.db.chat.panelWidth - 11, (E.db.chat.panelHeight - BASE_OFFSET))
			end
			chat:SetParent(LeftChatPanel)
			if i > 2 then
				tab:SetParent(LeftChatPanel)
			else
				tab:SetParent(LeftChatPanel)
			end
			if chat:IsMovable() then
				chat:SetUserPlaced(true)
			end

			if E.db.chat.panelBackdrop == "HIDEBOTH" or E.db.chat.panelBackdrop == "RIGHT" then
				CH:SetupChatTabs(tab, fadeTabsNoBackdrop and true or false)
			else
				CH:SetupChatTabs(tab, false)
			end
		end
	end

	self.initialMove = true
end

local function UpdateChatTabColor(_, r, g, b)
	for i = 1, CreatedFrames do
		_G["ChatFrame"..i.."TabText"]:SetTextColor(r, g, b)
	end
end
E["valueColorUpdateFuncs"][UpdateChatTabColor] = true

function CH:ScrollToBottom(frame)
	frame:ScrollToBottom()

	self:CancelTimer(frame.ScrollTimer, true)
end

function CH:PrintURL(url)
	return "|cFFFFFFFF[|Hurl:"..url.."|h"..url.."|h]|r "
end

function CH.FindURL(msg, ...)
	if not msg then return end

	local event = select(11, ...)
	if event and event == "CHAT_MSG_WHISPER" and CH.db.whisperSound ~= "None" and not CH.SoundPlayed then
		if (CH.db.noAlertInCombat and not InCombatLockdown()) or not CH.db.noAlertInCombat then
			PlaySoundFile(LSM:Fetch("sound", CH.db.whisperSound), "Master")
		end
		CH.SoundPlayed = true
		CH.SoundTimer = CH:ScheduleTimer("ThrottleSound", 1)
	end

	if not CH.db.url then
		msg = CH:CheckKeyword(msg)
		msg = CH:GetSmileyReplacementText(msg)
		return false, msg, ...
	end

	local text, tag = msg, strmatch(msg, "{(.-)}")
	if tag and ICON_TAG_LIST[strlower(tag)] then
		text = gsub(gsub(text, "(%S)({.-})", "%1 %2"), "({.-})(%S)", "%1 %2")
	end

	text = gsub(gsub(text, "(%S)(|c.-|H.-|h.-|h|r)", '%1 %2'), "(|c.-|H.-|h.-|h|r)(%S)", "%1 %2")
	-- http://example.com
	local newMsg, found = gsub(text, "(%a+)://(%S+)%s?", CH:PrintURL("%1://%2"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg)), ... end
	-- www.example.com
	newMsg, found = gsub(text, "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", CH:PrintURL("www.%1.%2"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg)), ... end
	-- example@example.com
	newMsg, found = gsub(text, "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", CH:PrintURL("%1@%2%3%4"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg)), ... end
	-- IP address with port 1.1.1.1:1
	newMsg, found = gsub(text, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)(:%d+)%s?", CH:PrintURL("%1.%2.%3.%4%5"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg)), ... end
	-- IP address 1.1.1.1
	newMsg, found = gsub(text, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?", CH:PrintURL("%1.%2.%3.%4"))
	if found > 0 then return false, CH:GetSmileyReplacementText(CH:CheckKeyword(newMsg)), ... end

	msg = CH:CheckKeyword(msg)
	msg = CH:GetSmileyReplacementText(msg)

	return false, msg, ...
end

local function SetChatEditBoxMessage(message)
	local ChatFrameEditBox = ChatEdit_ChooseBoxForSend()
	local editBoxShown = ChatFrameEditBox:IsShown()
	local editBoxText = ChatFrameEditBox:GetText()
	if not editBoxShown then
		ChatEdit_ActivateChat(ChatFrameEditBox)
	end
	if editBoxText and editBoxText ~= "" then
		ChatFrameEditBox:SetText("")
	end
	ChatFrameEditBox:Insert(message)
	ChatFrameEditBox:HighlightText()
end

local function HyperLinkedURL(data)
	if strsub(data, 1, 3) == "url" then
		local currentLink = strsub(data, 5)
		if currentLink and currentLink ~= "" then
			SetChatEditBoxMessage(currentLink)
		end
		return
	end
end

local SetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(data, ...)
	if strsub(data, 1, 3) == "url" then
		HyperLinkedURL(data)
	else
		SetHyperlink(self, data, ...)
	end
end

local hyperLinkEntered
function CH:OnHyperlinkEnter(frame, refString)
	if InCombatLockdown() then return end
	local linkToken = strmatch(refString, "^([^:]+)")
	if hyperlinkTypes[linkToken] then
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(refString)
		hyperLinkEntered = frame
		GameTooltip:Show()
	end
end

function CH:OnHyperlinkLeave(_, refString)
	-- local linkToken = refString:match("^([^:]+)")
	-- if hyperlinkTypes[linkToken] then
		-- HideUIPanel(GameTooltip)
		-- hyperLinkEntered = nil
	-- end

	if hyperLinkEntered then
		HideUIPanel(GameTooltip)
		hyperLinkEntered = nil
	end
end

function CH:OnMessageScrollChanged(frame)
	if hyperLinkEntered == frame then
		HideUIPanel(GameTooltip)
		hyperLinkEntered = false
	end
end

function CH:EnableHyperlink()
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if (not self.hooks or not self.hooks[frame] or not self.hooks[frame].OnHyperlinkEnter) then
			self:HookScript(frame, "OnHyperlinkEnter")
			self:HookScript(frame, "OnHyperlinkLeave")
			self:HookScript(frame, "OnMessageScrollChanged")
		end
	end
end

function CH:DisableHyperlink()
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if self.hooks and self.hooks[frame] and self.hooks[frame].OnHyperlinkEnter then
			self:Unhook(frame, "OnHyperlinkEnter")
			self:Unhook(frame, "OnHyperlinkLeave")
			self:Unhook(frame, "OnMessageScrollChanged")
		end
	end
end

function CH:DisableChatThrottle()
	twipe(msgList) twipe(msgCount) twipe(msgTime)
end

function CH:ShortChannel()
	return format("|Hchannel:%s|h[%s]|h", self, DEFAULT_STRINGS[strupper(self)] or gsub(self, "channel:", ""))
end

function CH:GetColoredName(event, _, arg2)
	if not E.private.general.classCache then return arg2 end

	if arg2 and arg2 ~= "" then
		local name, realm = strsplit("-", arg2)
		local englishClass = CC:GetClassByName(name, realm)

		if englishClass then
			local classColorTable = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[englishClass] or RAID_CLASS_COLORS[englishClass]
			if not classColorTable then
				return arg2
			end

			return format("\124cff%.2x%.2x%.2x", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255)..arg2.."\124r"
		end
	end

	return arg2
end

local function GetChatIcons(sender)
	for realm, _ in pairs(specialChatIcons) do
		for character, texture in pairs(specialChatIcons[realm]) do
			if (realm == PLAYER_REALM and sender == character) or sender == character.."-"..realm then
				return texture
			end
		end
	end
end

function CH:ChatFrame_MessageEventHandler(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, isHistory, historyTime, historyName)
	if strsub(event, 1, 8) == "CHAT_MSG" then
		local type = strsub(event, 10)
		local info = ChatTypeInfo[type]
		local historySavedName --we need to extend the arguments on CH.ChatFrame_MessageEventHandler so we can properly handle saved names without overriding
		if isHistory == "ElvUI_ChatHistory" then
			historySavedName = historyName
		end

		local filter, newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11 = false
		if chatFilters[event] then
			for _, filterFunc in next, chatFilters[event] do
				filter, newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11 = filterFunc(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, event)
				arg1 = newarg1 or arg1
				if filter then
					return true
				elseif newarg1 and newarg2 then
					arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11 = newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11
				end
			end
		end

		local coloredName = historySavedName or CH:GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11)

		local channelLength = arg4 and strlen(arg4)
		if (strsub(type, 1, 7) == "CHANNEL") and (type ~= "CHANNEL_LIST") and ((arg1 ~= "INVITE") or (type ~= "CHANNEL_NOTICE_USER")) then
			if arg1 == "WRONG_PASSWORD" then
				local staticPopup = _G[StaticPopup_Visible("CHAT_CHANNEL_PASSWORD") or ""]
				if staticPopup and staticPopup.data == arg9 then
					-- Don't display invalid password messages if we're going to prompt for a password (bug 102312)
					return
				end
			end

			local found = 0
			for index, value in pairs(self.channelList) do
				if channelLength > strlen(value) then
					-- arg9 is the channel name without the number in front...
					if ((arg7 > 0) and (self.zoneChannelList[index] == arg7)) or (strupper(value) == strupper(arg9)) then
						found = 1
						info = ChatTypeInfo["CHANNEL"..arg8]
						if (type == "CHANNEL_NOTICE") and (arg1 == "YOU_LEFT") then
							self.channelList[index] = nil
							self.zoneChannelList[index] = nil
						end
						break
					end
				end
			end
			if (found == 0) or not info then
				return true
			end
		end

		if type == "SYSTEM" or type == "TEXT_EMOTE" or type == "SKILL" or type == "LOOT" or type == "MONEY" or
			type == "OPENING" or type == "TRADESKILLS" or type == "PET_INFO" then
			self:AddMessage(arg1, info.r, info.g, info.b, info.id, isHistory, historyTime)
		elseif strsub(type,1,7) == "COMBAT_" then
			self:AddMessage(arg1, info.r, info.g, info.b, info.id, isHistory, historyTime)
		elseif strsub(type,1,6) == "SPELL_" then
			self:AddMessage(arg1, info.r, info.g, info.b, info.id, isHistory, historyTime)
		elseif strsub(type,1,10) == "BG_SYSTEM_" then
			self:AddMessage(arg1, info.r, info.g, info.b, info.id, isHistory, historyTime)
		elseif type == "IGNORED" then
			self:AddMessage(format(GlobalStrings.CHAT_IGNORED, arg2), info.r, info.g, info.b, info.id, isHistory, historyTime)
		elseif type == "FILTERED" then
			self:AddMessage(format(GlobalStrings.CHAT_FILTERED, arg2), info.r, info.g, info.b, info.id, isHistory, historyTime)
		elseif type == "RESTRICTED" then
			self:AddMessage(GlobalStrings.CHAT_RESTRICTED, info.r, info.g, info.b, info.id, isHistory, historyTime)
		elseif type == "CHANNEL_LIST" then
			if channelLength > 0 then
				self:AddMessage(format(_G["CHAT_"..type.."_GET"]..arg1, arg4), info.r, info.g, info.b, info.id, isHistory, historyTime)
			else
				self:AddMessage(arg1, info.r, info.g, info.b, info.id, isHistory, historyTime)
			end
		elseif type == "CHANNEL_NOTICE_USER" then
			local globalstring = _G["CHAT_"..arg1.."_NOTICE"]

			if strlen(arg5) > 0 then
				-- TWO users in this notice (E.G. x kicked y)
				self:AddMessage(format(globalstring, arg4, arg2, arg5), info.r, info.g, info.b, info.id, isHistory, historyTime)
			else
				self:AddMessage(format(globalstring, arg4, arg2), info.r, info.g, info.b, info.id, isHistory, historyTime)
			end
		elseif type == "CHANNEL_NOTICE" then
			local globalstring = _G["CHAT_"..arg1.."_NOTICE"]
			if arg10 > 0 then
				arg4 = arg4.." "..arg10
			end
			self:AddMessage(format(globalstring, arg4), info.r, info.g, info.b, info.id, isHistory, historyTime)
		else
			local body
			local _, fontHeight = GetChatWindowInfo(self:GetID())

			if fontHeight == 0 then
				--fontHeight will be 0 if it's still at the default (14)
				fontHeight = 14
			end

			-- Add AFK/DND flags
			local pflag = GetChatIcons(arg2)
			if arg6 ~= "" then
				if arg6 == "GM" then
					--Add Blizzard Icon, this was sent by a GM
					pflag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:0:2:0:-3|t "
				elseif arg6 == "DND" or arg6 == "AFK" then
					pflag = (pflag or "").._G["CHAT_FLAG_"..arg6]
				else
					pflag = _G["CHAT_FLAG_"..arg6]
				end
			else
				if pflag == true then
					pflag = ""
				end
			end

			pflag = pflag or ""

			local showLink = 1
			if strsub(type, 1, 7) == "MONSTER" or strsub(type, 1, 9) == "RAID_BOSS" then
				showLink = nil
			else
				arg1 = gsub(arg1, "%%", "%%%%")
			end

			-- Search for icon links and replace them with texture links.
			local term
			for tag in gmatch(arg1, "%b{}") do
				term = strlower(gsub(tag, "[{}]", ""))
				if ICON_TAG_LIST[term] and ICON_LIST[ICON_TAG_LIST[term]] then
					arg1 = gsub(arg1, tag, ICON_LIST[ICON_TAG_LIST[term]] .. "0|t")
				end
			end

			if (strlen(arg3) > 0) and (arg3 ~= "Universal") and (arg3 ~= GetDefaultLanguage()) then
				local languageHeader = "["..arg3.."] "
				if showLink and (strlen(arg2) > 0) then
					body = format(_G["CHAT_"..type.."_GET"]..languageHeader..arg1, pflag.."|Hplayer:"..arg2..":"..arg11.."|h".."["..coloredName.."]".."|h")
				else
					body = format(_G["CHAT_"..type.."_GET"]..languageHeader..arg1, pflag..arg2)
				end
			else
				if showLink and (strlen(arg2) > 0) and (type ~= "EMOTE") then
					body = format(_G["CHAT_"..type.."_GET"]..arg1, pflag.."|Hplayer:"..arg2..":"..arg11.."|h".."["..coloredName.."]".."|h")
				elseif showLink and (strlen(arg2) > 0) and (type == "EMOTE") then
					body = format(_G["CHAT_"..type.."_GET"]..arg1, pflag.."|Hplayer:"..arg2..":"..arg11.."|h".."["..coloredName.."]".."|h")
				else
					arg1 = arg1:gsub("%%s %%s", "%%s")
					body = format(_G["CHAT_"..type.."_GET"]..arg1, pflag..arg2)

					-- Add raid boss emote message
					if strsub(type, 1, 9) == "RAID_BOSS" then
						RaidNotice_AddMessage(RaidBossEmoteFrame, body, info)
						PlaySound("RaidBossEmoteWarning")
					end
				end
			end

			-- Add Channel
			arg4 = gsub(arg4, "%s%-%s.*", "")
			if(channelLength > 0) then
				body = "|Hchannel:channel:"..arg8.."|h["..arg4.."]|h "..body
			end

			if CH.db.shortChannels then
				body = body:gsub("|Hchannel:(.-)|h%[(.-)%]|h", CH.ShortChannel)
				body = body:gsub("CHANNEL:", "")
				body = body:gsub("^(.-|h) "..L["whispers"], "%1")
				body = body:gsub("^(.-|h) "..L["says"], "%1")
				body = body:gsub("^(.-|h) "..L["yells"], "%1")
				body = body:gsub("<"..GlobalStrings.AFK..">", "[|cffFF0000"..L["AFK"].."|r] ")
				body = body:gsub("<"..GlobalStrings.DND..">", "[|cffE7E716"..L["DND"].."|r] ")
				body = body:gsub("^%["..GlobalStrings.RAID_WARNING.."%]", "["..L["RW"].."]")
			end
			self:AddMessage(body, info.r, info.g, info.b, info.id, isHistory, historyTime)
		end

		if (isHistory ~= "ElvUI_ChatHistory") and type == "WHISPER" then
			ChatEdit_SetLastTellTarget(arg2)
			if self.tellTimer and (GetTime() > self.tellTimer) then
				PlaySound("TellMessage")
			end
			self.tellTimer = GetTime() + GlobalStrings.CHAT_TELL_ALERT_TIME
			FCF_FlashTab()
		end

		return true
	end
end

function CH:ChatFrame_ConfigEventHandler(...)
	return ChatFrame_ConfigEventHandler(...)
end

function CH:ChatFrame_SystemEventHandler(...)
	return ChatFrame_SystemEventHandler(...)
end

function CH:ChatFrame_OnEvent(...)
	if CH:ChatFrame_ConfigEventHandler(...) then return end
	if CH:ChatFrame_SystemEventHandler(...) then return end
	if CH:ChatFrame_MessageEventHandler(...) then return end
end

function CH:FloatingChatFrame_OnEvent(...)
	CH:ChatFrame_OnEvent(...)
	FloatingChatFrame_OnEvent(...)
end

local function FloatingChatFrameOnEvent(...)
	CH:FloatingChatFrame_OnEvent(...)
end

local function OnTextChanged(self)
	local text = self:GetText()

	if InCombatLockdown() then
		local MIN_REPEAT_CHARACTERS = E.db.chat.numAllowedCombatRepeat
		if strlen(text) > MIN_REPEAT_CHARACTERS then
		local repeatChar = true
		for i = 1, MIN_REPEAT_CHARACTERS, 1 do
			if strsub(text,(0-i), (0-i)) ~= strsub(text, (-1-i), (-1-i)) then
				repeatChar = false
				break
			end
		end
			if repeatChar then
				self:Hide()
				return
			end
		end
	end

	if strlen(text) < 5 then
		if strsub(text, 1, 4) == "/tt " then
			local unitname, realm = UnitName("target")
			if unitname and realm then
				unitname = unitname .. "-" .. realm:gsub(" ", "")
			end
			ChatFrame_SendTell((unitname or L["Invalid Target"]), ChatFrame1)
		end

		if strsub(text, 1, 4) == "/gr " then
			self:SetText(CH:GetGroupDistribution() .. strsub(text, 5))
			ChatEdit_ParseText(self, 0)
		end
	end

	local new, found = gsub(text, "|Kf(%S+)|k(%S+)%s(%S+)|k", "%2 %3")
	if found > 0 then
		new = new:gsub("|", "")
		self:SetText(new)
	end
end

function CH:SetupChat()
	if E.private.chat.enable ~= true then return end

	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		local id = frame:GetID()
		local _, fontSize = GetChatWindowInfo(id)
		self:StyleChat(frame)

		frame:SetFont(LSM:Fetch("font", self.db.font), fontSize, self.db.fontOutline)
		if self.db.fontOutline ~= "NONE" then
			frame:SetShadowColor(0, 0, 0, 0.2)
		else
			frame:SetShadowColor(0, 0, 0, 1)
		end
		frame:SetTimeVisible(100)
		frame:SetShadowOffset((E.mult or 1), -(E.mult or 1))
		frame:SetFading(self.db.fade)

		if not frame.scriptsSet then
			frame:SetScript("OnMouseWheel", ChatFrame_OnMouseScroll)
			frame:EnableMouseWheel(true)

			if id ~= 2 then
				frame:SetScript("OnEvent", FloatingChatFrameOnEvent)
			end

			hooksecurefunc(frame, "StopMovingOrSizing", function()
				CH:PositionChat(true)
			end)

			frame.scriptsSet = true
		end
	end

	local editbox = _G["ChatFrameEditBox"]
	if not editbox.isSkinned then
		local a, b, c = select(6, editbox:GetRegions()) a:Kill() b:Kill() c:Kill()
		editbox:SetTemplate("Default", true)
		editbox:SetAltArrowKeyMode(CH.db.useAltKey)
		editbox:SetAllPoints(LeftChatDataPanel)
		self:SecureHook(editbox, "AddHistoryLine", "ChatEdit_AddHistory")
		editbox:HookScript("OnTextChanged", OnTextChanged)

		editbox.historyLines = ElvCharacterDB.ChatEditHistory
		editbox.historyIndex = 0
		editbox:Hide()

		editbox:HookScript("OnEditFocusGained", function(self) self:Show() if not LeftChatPanel:IsShown() then LeftChatPanel.editboxforced = true LeftChatToggleButton:GetScript("OnEnter")(LeftChatToggleButton) end end)
		editbox:HookScript("OnEditFocusLost", function(self) if LeftChatPanel.editboxforced then LeftChatPanel.editboxforced = nil if LeftChatPanel:IsShown() then LeftChatToggleButton:GetScript("OnLeave")(LeftChatToggleButton) end end self.historyIndex = 0 self:Hide() end)

		for _, text in pairs(ElvCharacterDB.ChatEditHistory) do
			editbox:AddHistoryLine(text)
		end
		editbox.isSkinned = true
	end

	if self.db.hyperlinkHover then
		self:EnableHyperlink()
	end

	DEFAULT_CHAT_FRAME:SetParent(LeftChatPanel)

--	self:PositionChat(true)
	self:ScheduleTimer("PositionChat", 1)
end

local function PrepareMessage(author, message)
	if not author then return message end
	return format("%s%s", strupper(author), message)
end

function CH:ChatThrottleHandler(_, ...)
	local arg1, arg2 = ...

	if arg2 and arg2 ~= "" then
		local message = PrepareMessage(arg2, arg1)
		if msgList[message] == nil then
			msgList[message] = true
			msgCount[message] = 1
			msgTime[message] = time()
		else
			msgCount[message] = msgCount[message] + 1
		end
	end
end

function CH.CHAT_MSG_CHANNEL(message, author, ...)
	if not (message and author) then return end

	local blockFlag = false
	local msg = PrepareMessage(author, message)

	if msg == nil then return CH.FindURL(message, author, ...) end

	-- ignore player messages
	if author and author == UnitName("player") then return CH.FindURL(message, author, ...) end
	if msgList[msg] and CH.db.throttleInterval ~= 0 then
		if difftime(time(), msgTime[msg]) <= CH.db.throttleInterval then
			blockFlag = true
		end
	end

	if blockFlag then
		return true
	else
		if CH.db.throttleInterval ~= 0 then
			msgTime[msg] = time()
		end

		return CH.FindURL(message, author, ...)
	end
end

function CH.CHAT_MSG_YELL(message, author, ...)
	if not (message and author) then return end

	local blockFlag = false
	local msg = PrepareMessage(author, message)

	if msg == nil then return CH.FindURL(message, author, ...) end

	-- ignore player messages
	if author and author == UnitName("player") then return CH.FindURL(message, author, ...) end
	if msgList[msg] and msgCount[msg] > 1 and CH.db.throttleInterval ~= 0 then
		if difftime(time(), msgTime[msg]) <= CH.db.throttleInterval then
			blockFlag = true
		end
	end

	if blockFlag then
		return true
	else
		if CH.db.throttleInterval ~= 0 then
			msgTime[msg] = time()
		end

		return CH.FindURL(message, author, ...)
	end
end

function CH.CHAT_MSG_SAY(message, author, ...)
	if not (message and author) then return end

	return CH.FindURL(message, author, ...)
end

function CH:ThrottleSound()
	self.SoundPlayed = nil
end

local protectLinks = {}
function CH:CheckKeyword(message)
	for hyperLink in message:gmatch("|%x+|H.-|h.-|h|r") do
		protectLinks[hyperLink]=hyperLink:gsub("%s","|s")
		for keyword, _ in pairs(CH.Keywords) do
			if hyperLink == keyword then
				if(self.db.keywordSound ~= "None" and not self.SoundPlayed) then
					if (self.db.noAlertInCombat and not InCombatLockdown()) or not self.db.noAlertInCombat then
						PlaySoundFile(LSM:Fetch("sound", self.db.keywordSound), "Master")
					end
					self.SoundPlayed = true
					self.SoundTimer = CH:ScheduleTimer("ThrottleSound", 1)
				end
			end
		end
	end

	for hyperLink, tempLink in pairs(protectLinks) do
		message = message:gsub(hyperLink:gsub("([%(%)%.%%%+%-%*%?%[%^%$])","%%%1"), tempLink)
	end

	local classColorTable, tempWord, rebuiltString, lowerCaseWord, wordMatch, classMatch
	local isFirstWord = true
	for word in message:gmatch("%s-[^%s]+%s*") do
		if not next(protectLinks) or not protectLinks[word:gsub("%s",""):gsub("|s"," ")] then
			tempWord = word:gsub("[%s%p]", "")
			lowerCaseWord = tempWord:lower()
			for keyword, _ in pairs(CH.Keywords) do
				if lowerCaseWord == keyword:lower() then
					word = word:gsub(tempWord, format("%s%s|r", E.media.hexvaluecolor, tempWord))
					if self.db.keywordSound ~= "None" and not self.SoundPlayed  then
						if (self.db.noAlertInCombat and not InCombatLockdown()) or not self.db.noAlertInCombat then
							PlaySoundFile(LSM:Fetch("sound", self.db.keywordSound), "Master")
						end
						self.SoundPlayed = true
						self.SoundTimer = CH:ScheduleTimer("ThrottleSound", 1)
					end
				end
			end

			if self.db.classColorMentionsChat and E.private.general.classCache then
				tempWord = word:gsub("^[%s%p]-([^%s%p]+)([%-]?[^%s%p]-)[%s%p]*$","%1%2")

				classMatch = CC:GetCacheTable()[E.myrealm][tempWord]
				wordMatch = classMatch and lowerCaseWord

				if wordMatch and not E.global.chat.classColorMentionExcludedNames[wordMatch] then
					classColorTable = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classMatch] or RAID_CLASS_COLORS[classMatch]
					word = word:gsub(tempWord:gsub("%-","%%-"), format("\124cff%.2x%.2x%.2x%s\124r", classColorTable.r*255, classColorTable.g*255, classColorTable.b*255, tempWord))
				end
			end
		end

		if isFirstWord then
			rebuiltString = word
			isFirstWord = false
		else
			rebuiltString = format("%s%s", rebuiltString, word)
		end
	end

	for hyperLink, tempLink in pairs(protectLinks) do
		rebuiltString = rebuiltString:gsub(tempLink:gsub("([%(%)%.%%%+%-%*%?%[%^%$])","%%%1"), hyperLink)
		protectLinks[hyperLink] = nil
	end

	return rebuiltString
end

function CH:AddLines(lines, ...)
	for i = select("#", ...), 1, -1 do
		local x = select(i, ...)
		if	x:GetObjectType() == "FontString" and not x:GetName() then
			tinsert(lines, x:GetText())
		end
	end
end

function CH:ChatEdit_UpdateHeader(editbox)
	local type = editbox:GetAttribute("chatType")
	if type == "CHANNEL" then
		local id = GetChannelName(editbox:GetAttribute("channelTarget"))
		if id == 0 then
			editbox:SetBackdropBorderColor(unpack(E.media.bordercolor))
		else
			editbox:SetBackdropBorderColor(ChatTypeInfo[type..id].r, ChatTypeInfo[type..id].g, ChatTypeInfo[type..id].b)
		end
	elseif type then
		editbox:SetBackdropBorderColor(ChatTypeInfo[type].r, ChatTypeInfo[type].g, ChatTypeInfo[type].b)
	end
end

function CH:ChatEdit_OnEnterPressed()
	local type = this:GetAttribute("chatType")
	if ChatTypeInfo[type].sticky == 1 then
		if not self.db.sticky then type = "SAY" end
		this:SetAttribute("chatType", type)
	end
end

function CH:SetItemRef(link, text, button)
	if strsub(link, 1, 7) == "channel" then
		if IsModifiedClick("CHATLINK") then
			ToggleFriendsFrame(4)
		elseif button == "LeftButton" then
			local chanLink = strsub(link, 9)
			local chatType, chatTarget = strsplit(":", chanLink)

			if strupper(chatType) == "CHANNEL" then
				if GetChannelName(tonumber(chatTarget)) ~= 0 then
					ChatFrame_OpenChat("/"..chatTarget, this)
				end
			else
				ChatFrame_OpenChat("/"..chatType, this)
			end
--[[	-- TODO
		elseif button == "RightButton" then
			local chanLink = sub(link, 9)
			local chatType, chatTarget = strsplit(":", chanLink)
			if not strupper(chatType) == "CHANNEL" and GetChannelName(tonumber(chatTarget)) == 0 then
				ChatChannelDropDown_Show(this, strupper(chatType), chatTarget, Chat_GetColoredChatName(strupper(chatType), chatTarget))
			end
]]
		end

		return
	end

	return self.hooks.SetItemRef(link, text, button)
end

function CH:SetChatFont(chatFrame, fontSize)
	if not chatFrame then
		chatFrame = FCF_GetCurrentChatFrame()
	end
	if not fontSize then
		fontSize = this.value
	end
	chatFrame:SetFont(LSM:Fetch("font", self.db.font), fontSize, self.db.fontOutline)

	if self.db.fontOutline ~= "NONE" then
		chatFrame:SetShadowColor(0, 0, 0, 0.2)
	else
		chatFrame:SetShadowColor(0, 0, 0, 1)
	end
	chatFrame:SetShadowOffset((E.mult or 1), -(E.mult or 1))
end

function CH:ChatEdit_AddHistory(_, line)
	if find(line, "/rl") then return end

	if strlen(line) > 0 then
		for _, text in pairs(ElvCharacterDB.ChatEditHistory) do
			if text == line then
				return
			end
		end

		tinsert(ElvCharacterDB.ChatEditHistory, #ElvCharacterDB.ChatEditHistory + 1, line)
		if #ElvCharacterDB.ChatEditHistory > 20 then
			tremove(ElvCharacterDB.ChatEditHistory, 1)
		end
	end
end

function CH:UpdateChatKeywords()
	twipe(CH.Keywords)
	local keywords = self.db.keywords
	keywords = gsub(keywords,",%s",",")

	for i = 1, #{split(",", keywords)} do
		local stringValue = select(i, split(",", keywords))
		if stringValue ~= "" then
			CH.Keywords[stringValue] = true
		end
	end
end

function CH:UpdateFading()
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame"..i]
		if frame then
			frame:SetFading(self.db.fade)
		end
	end
end

function CH:DisplayChatHistory()
	local data, chat, d = ElvCharacterDB.ChatHistoryLog
	if not (data and next(data)) then return end

	CH.SoundPlayed = true
	for i = 1, NUM_CHAT_WINDOWS do
		chat = _G["ChatFrame"..i]
		for i = 1, #data do
			d = data[i]
			if type(d) == "table" then
				for _, messageType in pairs(chat.messageTypeList) do
					if gsub(strsub(d[50],10),"_INFORM","") == messageType then
						CH:ChatFrame_MessageEventHandler(chat,d[50],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],"ElvUI_ChatHistory",d[51],d[52])
					end
				end
			end
		end
	end
	CH.SoundPlayed = nil
end

tremove(ChatTypeGroup["GUILD"], 2)
function CH:DelayGuildMOTD()
	local delay, checks, delayFrame, chat = 0, 0, CreateFrame("Frame")
	tinsert(ChatTypeGroup["GUILD"], 2, "GUILD_MOTD")
	delayFrame:SetScript("OnUpdate", function(df, elapsed)
        delay = delay + elapsed
		if delay < 5 then return end
        local msg = GetGuildRosterMOTD()
		if msg and strlen(msg) > 0 then
			for i = 1, NUM_CHAT_WINDOWS do
				chat = _G["ChatFrame"..i]
				if chat and chat:IsEventRegistered("CHAT_MSG_GUILD") then
                    local info = ChatTypeInfo["GUILD"]
                    local string = format(GUILD_MOTD_TEMPLATE, msg)
                    chat:AddMessage(string, info.r, info.g, info.b, info.id)
					chat:RegisterEvent("GUILD_MOTD")
				end
			end
			df:SetScript("OnUpdate", nil)
		else -- 5 seconds can be too fast for the API response. let's try once every 5 seconds (max 5 checks).
			delay, checks = 0, checks + 1
			if checks >= 5 then
				df:SetScript("OnUpdate", nil)
			end
		end
	end)
end

function CH:SaveChatHistory(event, ...)
	if not self.db.chatHistory then return end
	local data = ElvCharacterDB.ChatHistoryLog

	local temp = {}
	for i = 1, select("#", ...) do
		temp[i] = select(i, ...) or false
	end

	if #temp > 0 then
		temp[50] = event
		temp[51] = time()
		temp[52] = CH:GetColoredName(event, ...)

		tinsert(data, temp)
		while #data >= 128 do
			tremove(data, 1)
		end
	end
	temp = nil -- Destory!

	if self.db.throttleInterval ~= 0 and (event == "CHAT_MESSAGE_SAY" or event == "CHAT_MESSAGE_YELL" or event == "CHAT_MSG_CHANNEL") then
		self:ChatThrottleHandler(event, ...)

		local message, author = ...
		local msg = PrepareMessage(author, message)
		if author and author ~= E.myname and msgList[msg] then
			if difftime(time(), msgTime[msg]) <= CH.db.throttleInterval then
				return
			end
		end
	end
end

function CH:ChatFrame_AddMessageEventFilter(event, filter)
	assert(event and filter)

	if chatFilters[event] then
		-- Only allow a filter to be added once
		for _, filterFunc in next, chatFilters[event] do
			if filterFunc == filter then
				return
			end
		end
	else
		chatFilters[event] = {}
	end

	tinsert(chatFilters[event], filter)
end

function CH:ChatFrame_RemoveMessageEventFilter(event, filter)
	assert(event and filter)

	if chatFilters[event] then
		for index, filterFunc in next, chatFilters[event] do
			if filterFunc == filter then
				tremove(chatFilters[event], index)
			end
		end

		if #chatFilters[event] == 0 then
			chatFilters[event] = nil
		end
	end
end

function CH:FCF_SetWindowAlpha(frame, alpha)
	frame.oldAlpha = alpha or 1
end

local FindURL_Events = {
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_AFK",
	"CHAT_MSG_DND",
}


function CH:Initialize()
	if ElvCharacterDB.ChatHistory then
  		ElvCharacterDB.ChatHistory = nil --Depreciated
  	end
	if ElvCharacterDB.ChatLog then
		ElvCharacterDB.ChatLog = nil --Depreciated
	end

	self.db = E.db.chat

	self:DelayGuildMOTD() --Keep this before `is Chat Enabled` check
	if E.private.chat.enable ~= true then return end

	if not ElvCharacterDB.ChatEditHistory then
		ElvCharacterDB.ChatEditHistory = {}
	end

	if not ElvCharacterDB.ChatHistoryLog or not self.db.chatHistory then
		ElvCharacterDB.ChatHistoryLog = {}
	end

	self:UpdateChatKeywords()

	self:UpdateFading()
	E.Chat = self
	self:SecureHook("ChatEdit_UpdateHeader")
	self:SecureHook("ChatEdit_OnEnterPressed")
	self:RawHook("SetItemRef", true)

	ChatFrameMenuButton:Kill()

	if(WIM) then
		WIM.RegisterWidgetTrigger("chat_display", "whisper,chat,w2w,demo", "OnHyperlinkClick", function(self) CH.clickedframe = self end)
		WIM.RegisterItemRefHandler("url", HyperLinkedURL)
	end

	self:SecureHook("FCF_SetChatWindowFontSize", "SetChatFont")
	self:RegisterEvent("UPDATE_CHAT_WINDOWS", "SetupChat")
	self:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "SetupChat")

	self:SetupChat()
	self:UpdateAnchors()
	if not E.db.chat.lockPositions then
		CH:UpdateChatTabs() --It was not done in PositionChat, so do it now
	end

	--First get all pre-existing filters and copy them to our version of chatFilters using ChatFrame_GetMessageEventFilters
	for name, _ in pairs(ChatTypeGroup) do
		for i = 1, #ChatTypeGroup[name] do
			local filterFuncTable = ChatFrame_GetMessageEventFilters(ChatTypeGroup[name][i])
			if filterFuncTable then
				chatFilters[ChatTypeGroup[name][i]] = {}

				for j = 1, #filterFuncTable do
					local filterFunc = filterFuncTable[j]
					tinsert(chatFilters[ChatTypeGroup[name][i]], filterFunc)
				end
			end
		end
	end

	--CHAT_MSG_CHANNEL isn't located inside ChatTypeGroup
	local filterFuncTable = ChatFrame_GetMessageEventFilters("CHAT_MSG_CHANNEL")
	if filterFuncTable then
		chatFilters["CHAT_MSG_CHANNEL"] = {}

		for j = 1, #filterFuncTable do
			local filterFunc = filterFuncTable[j]
			tinsert(chatFilters["CHAT_MSG_CHANNEL"], filterFunc)
		end
	end

	--Now hook onto Blizzards functions for other addons
	self:SecureHook("ChatFrame_AddMessageEventFilter")
	self:SecureHook("ChatFrame_RemoveMessageEventFilter")

	self:SecureHook("FCF_SetWindowAlpha")

	ChatTypeInfo["SAY"].sticky = 1
	ChatTypeInfo["EMOTE"].sticky = 1
	ChatTypeInfo["YELL"].sticky = 1
	ChatTypeInfo["WHISPER"].sticky = 1
	ChatTypeInfo["PARTY"].sticky = 1
	ChatTypeInfo["RAID"].sticky = 1
	ChatTypeInfo["RAID_WARNING"].sticky = 1
	ChatTypeInfo["BATTLEGROUND"].sticky = 1
	ChatTypeInfo["GUILD"].sticky = 1
	ChatTypeInfo["OFFICER"].sticky = 1
	ChatTypeInfo["CHANNEL"].sticky = 1

	for _, event in pairs(FindURL_Events) do
		ChatFrame_AddMessageEventFilter(event, CH[event] or CH.FindURL)
		local nType = strsub(event, 10)
		if nType ~= "AFK" and nType ~= "DND" then
			self:RegisterEvent(event, "SaveChatHistory")
		end
	end

	if self.db.chatHistory then
		self:DisplayChatHistory()
	end

	local S = E:GetModule("Skins")
	S:HandleNextPrevButton(CombatLogQuickButtonFrame_CustomAdditionalFilterButton, true)
	local frame = CreateFrame("Frame", "CopyChatFrame", E.UIParent)
	tinsert(UISpecialFrames, "CopyChatFrame")
	frame:SetTemplate("Transparent")
	frame:Size(700, 200)
	frame:Point("BOTTOM", E.UIParent, "BOTTOM", 0, 3)
	frame:Hide()
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetResizable(true)
	frame:SetMinResize(350, 100)
	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not self.isMoving then
			self:StartMoving()
			self.isMoving = true
		elseif(button == "RightButton" and not self.isSizing) then
			self:StartSizing()
			self.isSizing = true
		end
	end)
	frame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and self.isMoving then
			self:StopMovingOrSizing()
			self.isMoving = false
		elseif button == "RightButton" and self.isSizing then
			self:StopMovingOrSizing()
			self.isSizing = false
		end
	end)
	frame:SetScript("OnHide", function(self)
		if self.isMoving or self.isSizing then
			self:StopMovingOrSizing()
			self.isMoving = false
			self.isSizing = false
		end
	end)
	frame:SetFrameStrata("DIALOG")

	local scrollArea = CreateFrame("ScrollFrame", "CopyChatScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollArea:Point("TOPLEFT", frame, "TOPLEFT", 8, -30)
	scrollArea:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 8)
	S:HandleScrollBar(CopyChatScrollFrameScrollBar)
	scrollArea:SetScript("OnSizeChanged", function(self)
		CopyChatFrameEditBox:Width(self:GetWidth())
		CopyChatFrameEditBox:Height(self:GetHeight())
	end)
	scrollArea:HookScript("OnVerticalScroll", function(self, offset)
		CopyChatFrameEditBox:SetHitRectInsets(0, 0, offset, (CopyChatFrameEditBox:GetHeight() - offset - self:GetHeight()))
	end)

	local editBox = CreateFrame("EditBox", "CopyChatFrameEditBox", frame)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(99999)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(GameFontNormal)
	editBox:Width(scrollArea:GetWidth())
	editBox:Height(200)
	editBox:SetScript("OnEscapePressed", function() CopyChatFrame:Hide() end)
	scrollArea:SetScrollChild(editBox)
	CopyChatFrameEditBox:SetScript("OnTextChanged", function()
		local scrollBar = CopyChatScrollFrameScrollBar
		local _, max = scrollBar:GetMinMaxValues()
		for i = 1, max do
			scrollBar:SetValue(scrollBar:GetValue() + (scrollBar:GetHeight() / 2))
		end
	end)

	local close = CreateFrame("Button", "CopyChatFrameCloseButton", frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT")
	close:SetFrameLevel(close:GetFrameLevel() + 1)
	close:EnableMouse(true)
	S:HandleCloseButton(close)

	CombatLogQuickButtonFrame_Custom:StripTextures()
	CombatLogQuickButtonFrame_Custom:CreateBackdrop("Default", true)
	CombatLogQuickButtonFrame_Custom.backdrop:Point("TOPLEFT", 0, -1)
	CombatLogQuickButtonFrame_Custom.backdrop:Point("BOTTOMRIGHT", -22, 1)

	CombatLogQuickButtonFrame_CustomProgressBar:StripTextures()
	CombatLogQuickButtonFrame_CustomProgressBar:SetStatusBarTexture(E["media"].normTex)
	CombatLogQuickButtonFrame_CustomProgressBar:Point("TOPLEFT", 0, 3)

	CombatLogQuickButtonFrame_CustomAdditionalFilterButton:Size(20, 22)
	CombatLogQuickButtonFrame_CustomAdditionalFilterButton:Point("TOPRIGHT", CombatLogQuickButtonFrame_Custom, "TOPRIGHT", 0, -1)
	CombatLogQuickButtonFrame_CustomAdditionalFilterButton:SetHitRectInsets(0, 0, 0, 0)
end

local function InitializeCallback()
	CH:Initialize()
end

E:RegisterModule(CH:GetName(), InitializeCallback)