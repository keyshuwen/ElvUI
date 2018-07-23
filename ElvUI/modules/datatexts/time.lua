local E, L, V, P, G = unpack(ElvUI);
local DT = E:GetModule("DataTexts");

local time = time;
local format, join = string.format, string.join;

local GetGameTime = GetGameTime;
local GetNumSavedInstances = GetNumSavedInstances;
local GetSavedInstanceInfo = GetSavedInstanceInfo;
local SecondsToTime = SecondsToTime;

local timeDisplayFormat = "";
local dateDisplayFormat = "";
local europeDisplayFormat_nocolor = join("", "%02d", ":|r%02d");
local lockoutInfoFormatNoEnc = "%s%s |cffaaaaaa(%s)";
local difficultyInfo = {"N", "N", "H", "H"};
local lockoutColorExtended, lockoutColorNormal = {r = 0.3, g = 1, b = 0.3}, {r = .8, g = .8, b = .8};

local function OnClick(_, btn)
	if(btn == "RightButton") then
		if(not IsAddOnLoaded("Blizzard_TimeManager")) then LoadAddOn("Blizzard_TimeManager"); end
		TimeManagerClockButton_OnClick(TimeManagerClockButton);
	else
		GameTimeFrame:Click();
	end
end

local function OnLeave()
	DT.tooltip:Hide();
end

local function OnEnter(self)
	DT:SetupTooltip(self)
	
	RequestRaidInfo()

	local name, id, reset;
	local oneraid, instanceid;
	for i = 1, GetNumSavedInstances() do
		name, id, reset = GetSavedInstanceInfo(i);
		if(name) then
			if(not oneraid) then
				DT.tooltip:AddLine(" ");
				DT.tooltip:AddLine(L["Saved Raid(s)/Heroic Instance(s)"]);
				oneraid = true;
			end
			instanceid = format("%s (%d)", name, id)
			DT.tooltip:AddDoubleLine(instanceid, SecondsToTime(reset, true), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b);
		end
		if i == 1 then
			DT.tooltip:AddLine(" ")
		end
	end

	DT.tooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, format(europeDisplayFormat_nocolor, GetGameTime()), 1, 1, 1, lockoutColorNormal.r, lockoutColorNormal.g, lockoutColorNormal.b);

	DT.tooltip:Show();
end

local lastPanel;
local int = 5;
local function OnUpdate(self, t)
	int = int - t;

	if(int > 0) then return; end

	self.text:SetText(BetterDate(E.db.datatexts.timeFormat .. " " .. E.db.datatexts.dateFormat, time()):gsub(":", timeDisplayFormat):gsub("%s", dateDisplayFormat));

	lastPanel = self;
	int = 1;
end

local function ValueColorUpdate(hex)
	timeDisplayFormat = join("", hex, ":|r");
	dateDisplayFormat = join("", hex, " ");

	if(lastPanel ~= nil) then
		OnUpdate(lastPanel, 20000);
	end
end
E["valueColorUpdateFuncs"][ValueColorUpdate] = true;

DT:RegisterDatatext("Time", nil, nil, OnUpdate, OnClick, OnEnter, OnLeave);
