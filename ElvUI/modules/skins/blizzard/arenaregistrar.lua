local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

local _G = _G
local select = select

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.arenaregistrar ~= true then return end

	ArenaRegistrarFrame:CreateBackdrop("Transparent")
	ArenaRegistrarFrame.backdrop:Point("TOPLEFT", 14, -18)
	ArenaRegistrarFrame.backdrop:Point("BOTTOMRIGHT", -30, 67)

	ArenaRegistrarFrame:StripTextures(true)

	S:HandleCloseButton(ArenaRegistrarFrameCloseButton)

	ArenaRegistrarGreetingFrame:StripTextures()

	select(1, ArenaRegistrarGreetingFrame:GetRegions()):SetTextColor(1, 0.80, 0.10)
	RegistrationText:SetTextColor(1, 0.80, 0.10)

	S:HandleButton(ArenaRegistrarFrameGoodbyeButton)

	for i = 1, MAX_TEAM_BORDERS do
		local button = _G["ArenaRegistrarButton"..i]
		local obj = select(3, button:GetRegions())

		S:HandleButtonHighlight(button)

		obj:SetTextColor(1, 1, 1)
	end

	ArenaRegistrarPurchaseText:SetTextColor(1, 1, 1)

	S:HandleButton(ArenaRegistrarFrameCancelButton)
	S:HandleButton(ArenaRegistrarFramePurchaseButton)

	select(6, ArenaRegistrarFrameEditBox:GetRegions()):Kill()
	select(7, ArenaRegistrarFrameEditBox:GetRegions()):Kill()
	S:HandleEditBox(ArenaRegistrarFrameEditBox)
	ArenaRegistrarFrameEditBox:Height(18)

	PVPBannerFrame:CreateBackdrop("Transparent")
	PVPBannerFrame.backdrop:Point("TOPLEFT", 10, -12)
	PVPBannerFrame.backdrop:Point("BOTTOMRIGHT", -33, 73)

	PVPBannerFrame:StripTextures()

	PVPBannerFramePortrait:Kill()

	PVPBannerFrameCustomizationFrame:StripTextures()

	local customization, customizationLeft, customizationRight
	for i = 1, 2 do
		customization = _G["PVPBannerFrameCustomization"..i]
		customizationLeft = _G["PVPBannerFrameCustomization"..i.."LeftButton"]
		customizationRight = _G["PVPBannerFrameCustomization"..i.."RightButton"]

		customization:StripTextures()
		S:HandleNextPrevButton(customizationLeft)
		S:HandleNextPrevButton(customizationRight)
	end

	local pickerButton
	for i = 1, 3 do
		pickerButton = _G["PVPColorPickerButton"..i]
		S:HandleButton(pickerButton)
		if i == 2 then
			pickerButton:Point("TOP", PVPBannerFrameCustomization2, "BOTTOM", 0, -33)
		elseif i == 3 then
			pickerButton:Point("TOP", PVPBannerFrameCustomization2, "BOTTOM", 0, -59)
		end
	end

	S:HandleButton(PVPBannerFrameAcceptButton)
	S:HandleButton(PVPBannerFrameCancelButton)
	S:HandleButton(select(4, PVPBannerFrame:GetChildren())) -- PVPBannerFrameCancelButton duplicated

	S:HandleCloseButton(PVPBannerFrameCloseButton)
end

S:AddCallback("ArenaRegistrar", LoadSkin)