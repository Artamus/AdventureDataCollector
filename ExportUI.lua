local _, addonTbl = ...
local ExportFrame = nil

-- Credit for this goes to seriallos from the simc addon
addonTbl.GetExportFrame = function(text, resetHandler, numMissions)
    if not ExportFrame then
        local f = CreateFrame("Frame", "ADCExportFrame", UIParent, "DialogBoxFrame")
        f:SetPoint("CENTER", nil, nil, 0, 0)
        f:SetSize(600, 400)
        f:SetBackdrop(
            {
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
                edgeSize = 16,
                insets = {left = 8, right = 8, top = 8, bottom = 8}
            }
        )
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetScript(
            "OnMouseDown",
            function(self, button)
                if button == "LeftButton" then
                    self:StartMoving()
                end
            end
        )
        f:SetScript(
            "OnMouseUp",
            function(self, button)
                self:StopMovingOrSizing()
            end
        )

        ADCExportFrameButton:SetText("Close")

        -- Button to clear data
        local clearButton = CreateFrame("Button", "ADCExportClearButton", f)
        clearButton:SetPoint("LEFT", ADCExportFrameButton, "RIGHT", 0, 0)
        clearButton:SetSize(128, 32)
        clearButton:SetNormalFontObject("GameFontNormalLarge")
        clearButton:SetText("Reset data")
        clearButton:HookScript(
            "OnClick",
            function(self)
                resetHandler()
                f:Hide()
            end
        )

        local ntex = clearButton:CreateTexture()
        ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
        ntex:SetTexCoord(0, 0.625, 0, 0.6875)
        ntex:SetAllPoints()
        clearButton:SetNormalTexture(ntex)

        local htex = clearButton:CreateTexture()
        htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
        htex:SetTexCoord(0, 0.625, 0, 0.6875)
        htex:SetAllPoints()
        clearButton:SetHighlightTexture(htex)

        local ptex = clearButton:CreateTexture()
        ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
        ptex:SetTexCoord(0, 0.625, 0, 0.6875)
        ptex:SetAllPoints()
        clearButton:SetPushedTexture(ptex)

        -- Frame to display number of missions in storage
        local missionCounter = CreateFrame("Frame", "ADCExportMissionCountFrame", f)
        missionCounter:SetPoint("RIGHT", ADCExportFrameButton, "LEFT", 0, 0)
        missionCounter:SetSize(128, 32)
        missionCounter.text = missionCounter:CreateFontString(nil, nil, "GameFontNormalLarge")
        missionCounter.text:SetPoint("CENTER", missionCounter, "CENTER", 0, 0)
        missionCounter.text:SetText("")

        -- scroll frame
        local sf = CreateFrame("ScrollFrame", "ADCExportScrollFrame", f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -32)
        sf:SetPoint("BOTTOM", ADCExportFrameButton, "TOP", 0, 0)

        -- edit box
        local eb = CreateFrame("EditBox", "ADCExportEditBox", ADCExportScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(true)
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript(
            "OnEscapePressed",
            function()
                f:Hide()
            end
        )
        sf:SetScrollChild(eb)

        -- resizable
        f:SetResizable(true)
        f:SetMinResize(150, 100)
        local rb = CreateFrame("Button", "ADCExportResizeButton", f)
        rb:SetPoint("BOTTOMRIGHT", -6, 7)
        rb:SetSize(16, 16)

        rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

        rb:SetScript(
            "OnMouseDown",
            function(self, button)
                if button == "LeftButton" then
                    f:StartSizing("BOTTOMRIGHT")
                    self:GetHighlightTexture():Hide()
                end
            end
        )
        rb:SetScript(
            "OnMouseUp",
            function(self, button)
                f:StopMovingOrSizing()
                self:GetHighlightTexture():Show()
                eb:SetWidth(sf:GetWidth())
            end
        )

        ExportFrame = f
    end

    ADCExportEditBox:SetText(text)
    ADCExportEditBox:HighlightText()

    local missionWord = numMissions == 1 and "mission" or "missions"
    ADCExportMissionCountFrame.text:SetText("[" .. numMissions .. " " .. missionWord .. "]")
    return ExportFrame
end
