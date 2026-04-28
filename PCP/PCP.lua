local version, build, date, tocversion = GetBuildInfo()
local isVanilla = string.find(version, "^1%.12") ~= nil

-- PCP supports both 1.12.x (“Vanilla” private server clients) and 1.13+/Classic clients.
-- The biggest difference in this file is the old global `this` usage in 1.12 vs `self` in newer clients.

if not PCPButtonFrame then
    -- Creates the minimap button that toggles the main PCP window.
    local parentFrame = Minimap
    local width, height = 32, 32

    if isVanilla then
        PCPButtonFrame = CreateFrame("Button", "PCPButtonFrame", parentFrame)
    else
        PCPButtonFrame = CreateFrame("Button", "PCPButtonFrame", parentFrame, "BackdropTemplate")
    end

    PCPButtonFrame:SetWidth(width, height)
    PCPButtonFrame:SetHeight(height)	
    PCPButtonFrame:SetPoint("TOP", parentFrame, "TOP", 0, 0)
    PCPButtonFrame:EnableMouse(true)
    PCPButtonFrame:SetMovable(true)
    PCPButtonFrame:SetUserPlaced(true)
    PCPButtonFrame:RegisterForDrag("RightButton")
    PCPButtonFrame:SetFrameStrata("LOW")

   
    if isVanilla then
        PCPButtonFrame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        PCPButtonFrame:SetBackdropColor(0, 0, 0, 0.5)
    end

   
    PCPButtonFrame:SetNormalTexture("Interface\\AddOns\\PCP\\img\\SoloCraft.tga")
    PCPButtonFrame:SetPushedTexture("Interface\\AddOns\\PCP\\img\\SoloCraft.tga")
    PCPButtonFrame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

   
   
   
    -- Saves the minimap button position while dragging it.
    local function SaveButtonPosition()
        local point, relativeTo, relativePoint, xOffset, yOffset = PCPButtonFrame:GetPoint()
        PCPButtonFrame.position = {point, relativeTo, relativePoint, xOffset, yOffset}
    end

    -- Restores the minimap button position (if it was saved earlier).
    local function RestoreButtonPosition()
        if PCPButtonFrame.position then
            local point, relativeTo, relativePoint, xOffset, yOffset = unpack(PCPButtonFrame.position)
            PCPButtonFrame:ClearAllPoints()
            PCPButtonFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
        end
    end

   
   
   
    local dragStart, dragStop, onClick, onEnter, onLeave

    if isVanilla then
        dragStart = function() this:StartMoving() end
        dragStop  = function() this:StopMovingOrSizing(); SaveButtonPosition() end
        onClick   = function() PCPButtonFrame_Toggle() end
        onEnter   = function()
                        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                        GameTooltip:SetText("PartyBot Control Panel\nLeft Click: Toggle\nRight Click: Move", 1,1,1)
                        GameTooltip:Show()
                    end
    else
        dragStart = function(self) self:StartMoving() end
        dragStop  = function(self) self:StopMovingOrSizing(); SaveButtonPosition() end
        onClick   = function(self) PCPButtonFrame_Toggle() end
        onEnter   = function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText("PartyBot Control Panel\nLeft Click: Toggle\nRight Click: Move", 1,1,1)
                        GameTooltip:Show()
                    end
    end

    onLeave = function() GameTooltip:Hide() end

    PCPButtonFrame:SetScript("OnDragStart", dragStart)
    PCPButtonFrame:SetScript("OnDragStop", dragStop)
    PCPButtonFrame:SetScript("OnClick", onClick)
    PCPButtonFrame:SetScript("OnEnter", onEnter)
    PCPButtonFrame:SetScript("OnLeave", onLeave)

    RestoreButtonPosition()
    PCPButtonFrame:Show()
end

local PCPFrameShown = false

function PCPButtonFrame_Toggle()
    -- Toggles the main PCP window.
    if PCPFrameShown then
        PCPFrame:Hide()
    else
        PCPFrame:Show()
    end
    PCPFrameShown = not PCPFrameShown
end

local function PCP_InitSettings()
    -- Initializes saved variables and default “section enabled” state for the collapsible layout.
    if type(PCPSettings) ~= "table" then
        PCPSettings = {}
    end
    if type(PCPSettings.sectionEnabled) ~= "table" then
        PCPSettings.sectionEnabled = {}
    end

    local defaults = {
        ["PartyBot Configurator"] = true,
        ["Add PartyBot by role"] = true,
        ["Commands"] = true,
        ["Come"] = true,
        ["Move"] = true,
        ["Stay"] = true,
        ["Mark Configurator"] = true,
    }

    for key, value in pairs(defaults) do
        if PCPSettings.sectionEnabled[key] == nil then
            PCPSettings.sectionEnabled[key] = value
        end
    end
end

local PCP_AlignExternalButtons

local function PCP_TryHookFillRaidBots(frame)
    -- FillRaidBots repositions its buttons (FILL RAID / KICK ALL / REFILL) continuously and can
    -- override any anchoring we do from PCP. To make PCP “win”, we hook FillRaidBots’
    -- RepositionButtonsFromOffset() and apply our alignment after it runs.
    if _G.PCP_FRBHooked then return end
    if type(_G.RepositionButtonsFromOffset) ~= "function" then return end

    local orig = _G.RepositionButtonsFromOffset
    local unpackFn = _G.unpack or (table and table.unpack)

    _G.RepositionButtonsFromOffset = function(...)
        local results = { orig(...) }
        if PCP_AlignExternalButtons then
            PCP_AlignExternalButtons(frame or _G.PCPFrame or _G.PCPFrameRemake)
        end
        if unpackFn then
            return unpackFn(results)
        end
    end

    _G.PCP_FRBHooked = true
end

PCP_AlignExternalButtons = function(frame)
    -- Keeps external addon buttons aligned to the PCP frame when PCP changes height
    -- (collapsing/expanding sections).
    --
    -- This targets FillRaidBots specifically by looking for the global button names it creates.
    -- If the user enables FillRaidBots “move buttons” modes, we don’t interfere.
    if not frame or not frame.IsShown or not frame:IsShown() then return end

    PCP_TryHookFillRaidBots(frame)

    local openBtn = _G.OpenFillRaidButton
    local kickBtn = _G.KickAllButton
    local refillBtn = _G.reFillButton
    if not openBtn and not kickBtn and not refillBtn then return end

    if openBtn and openBtn.isMoving then return end

    local frb = _G.FillRaidBotsSavedSettings
    if type(frb) == "table" and (frb.moveButtonsEnabled or frb.moveButtonsRelative) then
        return
    end

    local layout = "vertical"
    local spacing = 10
    if type(frb) == "table" then
        if frb.ButtonLayout == true then
            layout = "horizontal"
        elseif type(frb.ButtonLayout) == "string" then
            layout = frb.ButtonLayout
        end
        if type(frb.ButtonSpacing) == "number" then
            spacing = frb.ButtonSpacing
        end
    end

    -- Anchor frame used as a stable reference point on the left edge of PCP.
    -- Other addons can also use PCPExternalLeftAnchor/PCPExternalRightAnchor if they want.
    local anchor = _G.PCPExternalLeftAnchor or frame
    local gap = 8

    local buttons = {}
    if openBtn and openBtn.IsShown and openBtn:IsShown() then buttons[#buttons + 1] = openBtn end
    if kickBtn and kickBtn.IsShown and kickBtn:IsShown() then buttons[#buttons + 1] = kickBtn end
    if refillBtn and refillBtn.IsShown and refillBtn:IsShown() then buttons[#buttons + 1] = refillBtn end
    if #buttons == 0 then return end

    if layout == "horizontal" then
        local rightmost = buttons[#buttons]
        rightmost:ClearAllPoints()
        rightmost:SetPoint("RIGHT", anchor, "LEFT", -gap, 0)

        for i = #buttons - 1, 1, -1 do
            local btn = buttons[i]
            local nextBtn = buttons[i + 1]
            btn:ClearAllPoints()
            btn:SetPoint("RIGHT", nextBtn, "LEFT", -spacing, 0)
        end
        return
    end

    local totalH = 0
    for i, btn in ipairs(buttons) do
        local h = (btn.GetHeight and btn:GetHeight()) or 0
        totalH = totalH + h
        if i > 1 then
            totalH = totalH + spacing
        end
    end

    local firstBtn = buttons[1]
    local firstH = (firstBtn.GetHeight and firstBtn:GetHeight()) or 0
    local firstCenterY = (totalH / 2) - (firstH / 2)

    firstBtn:ClearAllPoints()
    firstBtn:SetPoint("RIGHT", anchor, "LEFT", -gap, firstCenterY)

    for i = 2, #buttons do
        local btn = buttons[i]
        local prev = buttons[i - 1]
        btn:ClearAllPoints()
        btn:SetPoint("TOP", prev, "BOTTOM", 0, -spacing)
    end
end

local function OnPlayerLogin(self, event)
    PCP_InitSettings()
    if isVanilla then
        print("Vanilla client loaded: " .. version)
    else
        print("Classic client loaded: " .. version)
    end

    PCPButtonFrame:Show()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", OnPlayerLogin)

local function PCP_InitCollapsible(frame)
    -- Builds a “collapsible sections” layout around the original XML UI.
    -- It works by:
    -- 1) Finding header FontStrings (section titles).
    -- 2) Grouping other UI objects under the nearest header based on their original TOP-anchored Y offsets.
    -- 3) Re-parenting those objects into per-section container frames.
    -- 4) Recomputing the PCPFrame height when sections are hidden/shown.
    if frame._pcpLayout then return end

    local headerTextSet = {
        ["PartyBot Configurator"] = true,
        ["Add PartyBot by role"] = true,
        ["Commands"] = true,
        ["Come"] = true,
        ["Move"] = true,
        ["Stay"] = true,
        ["Mark Configurator"] = true,
    }

    local headers = {}
    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and headerTextSet[text] then
                local point, relTo, relPoint, xOfs, yOfs = region:GetPoint(1)
                if point and relPoint and (relTo == frame or relTo == nil) and string.find(relPoint, "TOP") and type(yOfs) == "number" then
                    headers[#headers + 1] = {
                        baseText = text,
                        fontString = region,
                        point = point,
                        relPoint = relPoint,
                        xOfs = xOfs or 0,
                        yOfs = yOfs,
                    }
                end
            end
        end
    end

    if #headers == 0 then return end

    table.sort(headers, function(a, b) return a.yOfs > b.yOfs end)

    local sections = {}
    for i, header in ipairs(headers) do
        sections[#sections + 1] = {
            key = header.baseText .. ":" .. tostring(i),
            baseText = header.baseText,
            header = header,
            enabled = (type(PCPSettings) == "table"
                and type(PCPSettings.sectionEnabled) == "table"
                and PCPSettings.sectionEnabled[header.baseText] ~= false) or true,
            items = {},
            byObj = {},
        }
    end

    local function FindSectionForY(yOfs)
        local assigned = nil
        for _, sec in ipairs(sections) do
            if yOfs <= sec.header.yOfs then
                assigned = sec
            else
                break
            end
        end
        return assigned
    end

    local function AddTopAnchoredObject(obj)
        if not obj or obj == frame._pcpBackdropFrame then return end

        local point, relTo, relPoint, xOfs, yOfs = obj:GetPoint(1)
        if not point or not relPoint or type(yOfs) ~= "number" then return end
        if not ((relTo == frame) or (relTo == nil)) then return end
        if not string.find(relPoint, "TOP") then return end

        local sec = FindSectionForY(yOfs)
        if not sec then return end

        if sec.byObj[obj] then return end
        sec.byObj[obj] = true

        local item = {
            obj = obj,
            point = point,
            relPoint = relPoint,
            xOfs = xOfs or 0,
            yOfs = yOfs,
        }
        sec.items[#sec.items + 1] = item
    end

    for _, child in ipairs({ frame:GetChildren() }) do
        AddTopAnchoredObject(child)
    end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            AddTopAnchoredObject(region)
        end
    end

    local containers = {}
    for _, sec in ipairs(sections) do
        local container = CreateFrame("Frame", nil, frame)
        sec.container = container
        containers[#containers + 1] = container

        local headerHForPad = sec.header.fontString:GetHeight() or 18
        local topPad = -4
        if sec.header.point and not string.find(sec.header.point, "TOP") then
            topPad = -math.floor((headerHForPad / 2) + 2)
        end
        sec.topPad = topPad

        for _, item in ipairs(sec.items) do
            local obj = item.obj
            if obj and obj.SetParent then
                obj:SetParent(container)
                obj:ClearAllPoints()
                item.newY = (item.yOfs - sec.header.yOfs) + topPad
                obj:SetPoint(item.point, container, item.relPoint, item.xOfs, item.newY)
            end
        end

        sec.header.fontString:SetText(sec.baseText)
    end

    local closeButton = nil
    for _, child in ipairs({ frame:GetChildren() }) do
        if child and child.GetName and child:GetName() == "CloseButton" then
            closeButton = child
            break
        end
    end

    local versionLabel = nil
    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text and string.find(text, "^v%d") then
                versionLabel = region
                break
            end
        end
    end

    -- Footer container: keeps Close + version label grouped and positioned consistently.
    local footer = CreateFrame("Frame", nil, frame)
    if closeButton then
        closeButton:SetParent(footer)
        closeButton:ClearAllPoints()
        closeButton:SetPoint("TOP", footer, "TOP", 0, -8)
    end
    if versionLabel then
        -- Puts the version label centered under the Close button (instead of overlapping it).
        versionLabel:SetParent(footer)
        versionLabel:ClearAllPoints()
        versionLabel:SetPoint("BOTTOM", footer, "BOTTOM", 0, 6)
    end

    if not _G.PCPExternalLeftAnchor then
        -- Small helper anchors at the left/right edge of PCPFrame.
        -- External addons can anchor to these instead of doing GetLeft()/GetTop() math.
        local a = CreateFrame("Frame", "PCPExternalLeftAnchor", frame)
        a:SetSize(1, 1)
        a:Hide()
        _G.PCPExternalLeftAnchor = a
    end
    if not _G.PCPExternalRightAnchor then
        local a = CreateFrame("Frame", "PCPExternalRightAnchor", frame)
        a:SetSize(1, 1)
        a:Hide()
        _G.PCPExternalRightAnchor = a
    end

    local function MeasureSectionHeight(sec)
        local headerH = sec.header.fontString:GetHeight() or 18
        local topPadLocal = sec.topPad or -4
        local maxDepth = (-topPadLocal) + headerH + 8
        for _, item in ipairs(sec.items) do
            local obj = item.obj
            if obj and obj ~= sec.header.fontString and obj:IsShown() then
                local h = (obj.GetHeight and obj:GetHeight()) or (obj.GetStringHeight and obj:GetStringHeight()) or 0
                local depth = (- (item.newY or 0)) + h + 8
                if depth > maxDepth then
                    maxDepth = depth
                end
            end
        end
        return maxDepth
    end

    local layout = {}
    layout.sections = sections
    layout.footer = footer
    layout.MeasureSectionHeight = MeasureSectionHeight

    function layout:Relayout()
        -- Lays out all enabled sections from top to bottom, then places the footer.
        -- Finally, it updates PCPFrame height to fit the visible content.
        local y = 6
        for _, sec in ipairs(self.sections) do
            if sec.enabled then
                sec.container:Show()
            sec.container:ClearAllPoints()
            sec.container:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -y)
            sec.container:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -y)
            local h = self.MeasureSectionHeight(sec)
            sec.container:SetHeight(h)
            y = y + h
            else
                sec.container:Hide()
            end
        end

        self.footer:ClearAllPoints()
        self.footer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -y)
        self.footer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -y)
        self.footer:SetHeight(70)
        y = y + 70 + 6

        frame:SetHeight(math.max(200, y))

        if _G.PCPExternalLeftAnchor then
            -- Keep helper anchors glued to the current PCPFrame edges.
            _G.PCPExternalLeftAnchor:ClearAllPoints()
            _G.PCPExternalLeftAnchor:SetPoint("LEFT", frame, "LEFT", 0, 0)
            _G.PCPExternalLeftAnchor:Show()
        end
        if _G.PCPExternalRightAnchor then
            _G.PCPExternalRightAnchor:ClearAllPoints()
            _G.PCPExternalRightAnchor:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
            _G.PCPExternalRightAnchor:Show()
        end

        -- Re-align external addon buttons after any size/layout change.
        PCP_AlignExternalButtons(frame)
    end

    if not frame._pcpOptionsButton then
        local optionsButton = CreateFrame("Button", nil, frame)
        optionsButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
        optionsButton:SetSize(18, 18)
        optionsButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
        optionsButton:SetPushedTexture("Interface\\Buttons\\UI-OptionsButton")
        optionsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        optionsButton:SetFrameLevel(frame:GetFrameLevel() + 100)

        optionsButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Options", 1, 1, 1)
            GameTooltip:Show()
        end)
        optionsButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

        local function SetSectionEnabled(sec, enabled)
            sec.enabled = enabled and true or false
            if type(PCPSettings) == "table" and type(PCPSettings.sectionEnabled) == "table" then
                PCPSettings.sectionEnabled[sec.baseText] = sec.enabled
            end
        end

        local function ShowMenu()
            local menu = {
                { text = "Sections", isTitle = true, notCheckable = true },
            }

            for _, sec in ipairs(frame._pcpLayout.sections) do
                menu[#menu + 1] = {
                    text = sec.baseText,
                    keepShownOnClick = true,
                    isNotRadio = true,
                    checked = function() return sec.enabled end,
                    func = function()
                        SetSectionEnabled(sec, not sec.enabled)
                        frame._pcpLayout:Relayout()
                    end,
                }
            end

            menu[#menu + 1] = { text = "", notCheckable = true, disabled = true }
            menu[#menu + 1] = {
                text = "Show All",
                notCheckable = true,
                func = function()
                    for _, sec in ipairs(frame._pcpLayout.sections) do
                        SetSectionEnabled(sec, true)
                    end
                    frame._pcpLayout:Relayout()
                end,
            }
            menu[#menu + 1] = {
                text = "Hide All",
                notCheckable = true,
                func = function()
                    for _, sec in ipairs(frame._pcpLayout.sections) do
                        SetSectionEnabled(sec, false)
                    end
                    frame._pcpLayout:Relayout()
                end,
            }

            if EasyMenu then
                if not frame._pcpOptionsMenuFrame then
                    frame._pcpOptionsMenuFrame = CreateFrame("Frame", "PCPOptionsMenuFrame", UIParent, "UIDropDownMenuTemplate")
                end
                EasyMenu(menu, frame._pcpOptionsMenuFrame, "cursor", 0, 0, "MENU", 2)
            else
                if not frame._pcpOptionsPopup then
                    local popup = CreateFrame("Frame", nil, frame, "BackdropTemplate")
                    popup:SetPoint("TOPRIGHT", optionsButton, "BOTTOMRIGHT", 0, -6)
                    local popupHeight = (#frame._pcpLayout.sections * 24) + 24
                    popup:SetSize(200, popupHeight)
                    popup:SetFrameLevel(frame:GetFrameLevel() + 200)
                    popup:SetBackdrop({
                        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                        tile = true,
                        tileSize = 16,
                        edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 },
                    })
                    popup:SetBackdropColor(0, 0, 0, 0.9)

                    local y = -10
                    popup.checks = {}
                    for _, sec in ipairs(frame._pcpLayout.sections) do
                        local cb = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
                        cb:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, y)
                        cb:SetHitRectInsets(0, -140, 0, 0)
                        local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        label:SetPoint("LEFT", cb, "RIGHT", 4, 1)
                        label:SetText(sec.baseText)
                        cb._pcpLabel = label
                        cb:SetChecked(sec.enabled)
                        cb:SetScript("OnClick", function(self)
                            SetSectionEnabled(sec, self:GetChecked())
                            frame._pcpLayout:Relayout()
                        end)
                        popup.checks[#popup.checks + 1] = cb
                        y = y - 24
                    end
                    frame._pcpOptionsPopup = popup
                end

                local popup = frame._pcpOptionsPopup
                if popup:IsShown() then
                    popup:Hide()
                else
                    for i, sec in ipairs(frame._pcpLayout.sections) do
                        local cb = popup.checks[i]
                        if cb then
                            cb:SetChecked(sec.enabled)
                        end
                    end
                    popup:Show()
                end
            end
        end

        optionsButton:SetScript("OnClick", ShowMenu)
        frame._pcpOptionsButton = optionsButton
    end

    frame._pcpLayout = layout
    frame._pcpLayout:Relayout()

    if not frame._pcpExternalAligner then
        -- Safety net: some addons (like FillRaidBots) keep re-positioning their buttons.
        -- This periodically re-applies our alignment so the buttons stay centered.
        local aligner = CreateFrame("Frame", nil, frame)
        local elapsedAcc = 0
        aligner:SetScript("OnUpdate", function(_, elapsed)
            elapsedAcc = elapsedAcc + elapsed
            if elapsedAcc >= 0.05 then
                elapsedAcc = 0
                PCP_AlignExternalButtons(frame)
            end
        end)
        frame._pcpExternalAligner = aligner
    end
end

local function PCPFrame_OnShow(frame)
    PCP_InitCollapsible(frame)
    if frame._pcpLayout then
        frame._pcpLayout:Relayout()
    end
end


function PCPFrame_OnLoad(frame)
    local f = isVanilla and this or frame

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    if not isVanilla and not f._pcpBackdropApplied then
        local backdropConfig = {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        }

        local function ApplyBackdrop(target)
            if not target or type(target.SetBackdrop) ~= "function" then return false end
            target:SetBackdrop(backdropConfig)
            if type(target.SetBackdropColor) == "function" then
                target:SetBackdropColor(0, 0, 0, 0.4)
            end
            if type(target.SetBackdropBorderColor) == "function" then
                target:SetBackdropBorderColor(1, 1, 1, 1)
            end
            return true
        end

        if not ApplyBackdrop(f) then
            local backdropFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
            backdropFrame:SetAllPoints(f)
            backdropFrame:SetFrameStrata(f:GetFrameStrata())
            local level = f:GetFrameLevel()
            backdropFrame:SetFrameLevel(level > 0 and (level - 1) or 0)
            ApplyBackdrop(backdropFrame)
            f._pcpBackdropFrame = backdropFrame
        end

        f._pcpBackdropApplied = true
    end

    f:SetScript("OnDragStart", function()
        if isVanilla then
            this:StartMoving()
        else
            frame:StartMoving()
        end
    end)

    f:SetScript("OnDragStop", function()
        if isVanilla then
            this:StopMovingOrSizing()
        else
            frame:StopMovingOrSizing()
        end
    end)

    if f.HookScript then
        if not f._pcpOnShowHooked then
            f:HookScript("OnShow", PCPFrame_OnShow)
            f._pcpOnShowHooked = true
        end
    elseif not f:GetScript("OnShow") then
        f:SetScript("OnShow", PCPFrame_OnShow)
    end

    f:Hide()
end

SLASH_MOVEFRAME1 = "/movepcp"
SlashCmdList["MOVEFRAME"] = function()
    -- Slash command: move PCPFrame to your cursor position.
    -- Usage: /movepcp (then your mouse position becomes the new frame center)
    if not PCPFrame then return end 

   
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale() 

   
    x = x / scale
    y = y / scale

   
    PCPFrame:ClearAllPoints()
    PCPFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

BINDING_HEADER_CCP = "PartyBot Control Panel";
BINDING_NAME_CP = "Show/Hide PCP";

-- Chat command strings sent to the server (SoloCraft/PartyBot server commands).
CMD_PARTYBOT_CLONE = ".partybot clone";
CMD_PARTYBOT_REMOVE = ".partybot remove";
CMD_PARTYBOT_ADD = ".partybot add ";
CMD_PARTYBOT_MAll = ".partybot moveall";
CMD_PARTYBOT_SAll = ".partybot stayall";
CMD_BATTLEGROUND_GO = ".go ";
CMD_BATTLEBOT_ADD = ".battlebot add ";
CMD_TOGGLE_HELM = ".partybot togglehelm ";
CMD_TOGGLE_CLOAK = ".partybot togglecloak ";
CMD_GENERAL = ".partybot ";

-- UI state: current “selected” command/mark/toggle shown in the stacks.
AddCmd = ""
CmdItr = 1
function CmdStackHide()
	-- Hides all “command type” labels (All/Tank/Healer/...).
	CmdAll:Hide()
	CmdTank:Hide()
	CmdHealer:Hide()
	CmdDPS:Hide()
	CmdMDPS:Hide()
	CmdRDPS:Hide()
	CmdWarrior:Hide()
	CmdPaladin:Hide()
	CmdHunter:Hide()
	CmdRogue:Hide()
	CmdPriest:Hide()
	CmdShaman:Hide()
	CmdMage:Hide()
	CmdWarlock:Hide()
	CmdDruid:Hide()
end

function CmdADD()
	-- Cycles command type forward and updates the visible label.
	Cmds = { "", "tank", "healer", "dps", "mdps", "rdps", "warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }

	CmdItr = CmdItr + 1	
	if CmdItr >= table.getn(Cmds) + 1 then CmdItr = 1 end
	AddCmd = Cmds[CmdItr]

	if Cmds[CmdItr] == "" then CmdStackHide() CmdAll:Show() end
	if Cmds[CmdItr] == "tank" then CmdStackHide() CmdTank:Show() end
	if Cmds[CmdItr] == "healer" then CmdStackHide() CmdHealer:Show() end
	if Cmds[CmdItr] == "dps" then CmdStackHide() CmdDPS:Show() end
	if Cmds[CmdItr] == "mdps" then CmdStackHide() CmdMDPS:Show() end
	if Cmds[CmdItr] == "rdps" then CmdStackHide() CmdRDPS:Show() end
	if Cmds[CmdItr] == "warrior" then CmdStackHide() CmdWarrior:Show() end
	if Cmds[CmdItr] == "paladin" then CmdStackHide() CmdPaladin:Show() end
	if Cmds[CmdItr] == "hunter" then CmdStackHide() CmdHunter:Show() end
	if Cmds[CmdItr] == "rogue" then CmdStackHide() CmdRogue:Show() end
	if Cmds[CmdItr] == "priest" then CmdStackHide() CmdPriest:Show() end
	if Cmds[CmdItr] == "shaman" then CmdStackHide() CmdShaman:Show() end
	if Cmds[CmdItr] == "mage" then CmdStackHide() CmdMage:Show() end
	if Cmds[CmdItr] == "warlock" then CmdStackHide() CmdWarlock:Show() end
	if Cmds[CmdItr] == "druid" then CmdStackHide() CmdDruid:Show() end
end

function CmdSUB()
	-- Cycles command type backward and updates the visible label.
	Cmds = { "", "tank", "healer", "dps", "mdps", "rdps", "warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }

	CmdItr = CmdItr - 1	
	if CmdItr <= 0 then CmdItr = table.getn(Cmds) end
	AddCmd = Cmds[CmdItr]

	if Cmds[CmdItr] == "" then CmdStackHide() CmdAll:Show() end
	if Cmds[CmdItr] == "tank" then CmdStackHide() CmdTank:Show() end
	if Cmds[CmdItr] == "healer" then CmdStackHide() CmdHealer:Show() end
	if Cmds[CmdItr] == "dps" then CmdStackHide() CmdDPS:Show() end
	if Cmds[CmdItr] == "mdps" then CmdStackHide() CmdMDPS:Show() end
	if Cmds[CmdItr] == "rdps" then CmdStackHide() CmdRDPS:Show() end
	if Cmds[CmdItr] == "warrior" then CmdStackHide() CmdWarrior:Show() end
	if Cmds[CmdItr] == "paladin" then CmdStackHide() CmdPaladin:Show() end
	if Cmds[CmdItr] == "hunter" then CmdStackHide() CmdHunter:Show() end
	if Cmds[CmdItr] == "rogue" then CmdStackHide() CmdRogue:Show() end
	if Cmds[CmdItr] == "priest" then CmdStackHide() CmdPriest:Show() end
	if Cmds[CmdItr] == "shaman" then CmdStackHide() CmdShaman:Show() end
	if Cmds[CmdItr] == "mage" then CmdStackHide() CmdMage:Show() end
	if Cmds[CmdItr] == "warlock" then CmdStackHide() CmdWarlock:Show() end
	if Cmds[CmdItr] == "druid" then CmdStackHide() CmdDruid:Show() end
end

function SetCommand(arg)
	-- Sends: .partybot <role/class/etc>
		SendChatMessage(CMD_GENERAL .. arg);
end

function SetPause()
	-- Sends: .partybot pause
		SendChatMessage(CMD_GENERAL .. " pause ");
end

function SetUnpause()
	-- Sends: .partybot unpause
		SendChatMessage(CMD_GENERAL .. " unpause ");
end

AddMark = "ccmark"
MarkItr = 1
function MarkStackHide()
	-- Hides all mark mode labels (ccmark/focusmark).
	ccmark:Hide()
	focusmark:Hide()
end

function MarkADD()
	-- Cycles mark mode forward and updates the visible label.
	Marks = { "ccmark", "focusmark" }

	MarkItr = MarkItr + 1	
	if MarkItr >= table.getn(Marks) + 1 then MarkItr = 1 end
	AddMark = Marks[MarkItr]

	if Marks[MarkItr] == "ccmark" then MarkStackHide() ccmark:Show() end
	if Marks[MarkItr] == "focusmark" then MarkStackHide() focusmark:Show() end
end

function MarkSUB()
	-- Cycles mark mode backward and updates the visible label.
	Marks = { "ccmark", "focusmark" }

	MarkItr = MarkItr - 1	
	if MarkItr <= 0 then MarkItr = table.getn(Marks) end
	AddMark = Marks[MarkItr]

	if Marks[MarkItr] == "ccmark" then MarkStackHide() ccmark:Show() end
	if Marks[MarkItr] == "focusmark" then MarkStackHide() focusmark:Show() end
end

function SetMark(self, arg)
	-- Sends: .partybot <markType> <markArg>
	SendChatMessage(CMD_GENERAL .. AddMark .. " " .. arg);
end

function ShowMark()
	-- Sends: .partybot <markType>
	SendChatMessage(CMD_GENERAL .. AddMark);
end

function ClearMark()
	-- Sends: .partybot clear <markType>
	SendChatMessage(CMD_GENERAL .. "clear " .. AddMark);
end

function ClearAllMark()
	-- Sends: .partybot clear
	SendChatMessage(CMD_GENERAL .. "clear");
end

AddToggle = "aoe"
ToggleItr = 1
function ToggleStackHide()
	-- Hides all toggle labels.
	ToggleAOE:Hide()
	ToggleHelmCloak:Hide()
	helm:Hide()
	cloak:Hide()
end

function ToggleADD()
	-- Cycles toggle mode forward and updates the visible label.
	Toggles = { "aoe", "ToggleHelmCloak", "helm", "cloak" }

	ToggleItr = ToggleItr + 1	
	if ToggleItr >= table.getn(Toggles) + 1 then ToggleItr = 1 end
	AddToggle = Toggles[ToggleItr]

	if Toggles[ToggleItr] == "aoe" then ToggleStackHide() ToggleAOE:Show() end
	if Toggles[ToggleItr] == "ToggleHelmCloak" then ToggleStackHide() ToggleHelmCloak:Show() end
	if Toggles[ToggleItr] == "helm" then ToggleStackHide() helm:Show() end
	if Toggles[ToggleItr] == "cloak" then ToggleStackHide() cloak:Show() end
end

function ToggleSUB()
	-- Cycles toggle mode backward and updates the visible label.
	Toggles = { "aoe", "ToggleHelmCloak", "helm", "cloak" }

	ToggleItr = ToggleItr - 1	
	if ToggleItr <= 0 then ToggleItr = table.getn(Toggles) end
	AddToggle = Toggles[ToggleItr]

	if Toggles[ToggleItr] == "aoe" then ToggleStackHide() ToggleAOE:Show() end
	if Toggles[ToggleItr] == "ToggleHelmCloak" then ToggleStackHide() ToggleHelmCloak:Show() end
	if Toggles[ToggleItr] == "helm" then ToggleStackHide() helm:Show() end
	if Toggles[ToggleItr] == "cloak" then ToggleStackHide() cloak:Show() end
end

function SetToggle()
	-- Sends: .partybot toggle <toggleName>
	SendChatMessage(CMD_GENERAL .."toggle " .. AddToggle);
end

function SubPartyBotClone(self)
	-- Sends: .partybot clone
	SendChatMessage(CMD_PARTYBOT_CLONE);
end

function SubPartyBotRemove(self)
	-- Sends: .partybot remove
	SendChatMessage(CMD_PARTYBOT_REMOVE);
end

function SubPartyBotMoveAll()
	-- Sends: .partybot moveall
	SendChatMessage(CMD_PARTYBOT_MAll);
end

function SubPartyBotStayAll()
	-- Sends: .partybot stayall
	SendChatMessage(CMD_PARTYBOT_SAll);
end

AddClass = "warrior"
ClassItr = 1
function SetClassADD()
	-- Cycles class forward and updates the class icon/label.
	-- Also skips faction-only classes (Alliance paladin / Horde shaman).
	Classes = { "warrior" , "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }
		
	ClassItr = ClassItr + 1	
	if ClassItr == 10 then ClassItr = 1 end
	
	if UnitFactionGroup("player") == "Alliance" then
		if Classes[ClassItr] == "shaman" then 
			ClassItr = ClassItr + 1 
			AddClass = Classes[ClassItr]
		end
	else AddClass = Classes[ClassItr]
	end
	
	if UnitFactionGroup("player") == "Horde" then
		if Classes[ClassItr] == "paladin" then 
			ClassItr = ClassItr + 1 
			AddClass = Classes[ClassItr]
		end
	else AddClass = Classes[ClassItr]
	end	
	
	if Classes[ClassItr] == "warrior" then druid:Hide() warrior:Show() end
	if UnitFactionGroup("player") == "Alliance" then 
		if Classes[ClassItr] == "paladin" then warrior:Hide() paladin:Show() end
		if Classes[ClassItr] == "hunter" then paladin:Hide() hunter:Show() end	
	else
		if Classes[ClassItr] == "hunter" then warrior:Hide() hunter:Show() end
	end	
	if Classes[ClassItr] == "rogue" then hunter:Hide() rogue:Show() end
	if Classes[ClassItr] == "priest" then rogue:Hide() priest:Show() end
	if UnitFactionGroup("player") == "Horde" then 
		if Classes[ClassItr] == "shaman" then priest:Hide() shaman:Show() end
		if Classes[ClassItr] == "mage" then shaman:Hide() mage:Show() end	
	else
		if Classes[ClassItr] == "mage" then priest:Hide() mage:Show() end
	end	
	if Classes[ClassItr] == "warlock" then mage:Hide() warlock:Show() end
	if Classes[ClassItr] == "druid" then warlock:Hide() druid:Show() end
	
	RoleUpdate()
	RoleItr = 1
end

function SetClassSUB()
	-- Cycles class backward and updates the class icon/label.
	-- Also skips faction-only classes (Alliance paladin / Horde shaman).
	Classes = { "warrior" , "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid" }

	ClassItr = ClassItr - 1		
	if ClassItr == 0 then ClassItr = 9 end
	
	if UnitFactionGroup("player") == "Alliance" then
		if Classes[ClassItr] == "shaman" then 
			ClassItr = ClassItr - 1 
			AddClass = Classes[ClassItr]
		end
	else AddClass = Classes[ClassItr]
	end
	
	if UnitFactionGroup("player") == "Horde" then
		if Classes[ClassItr] == "paladin" then 
			ClassItr = ClassItr - 1 
			AddClass = Classes[ClassItr]
		end
	else AddClass = Classes[ClassItr]
	end		
		
	if UnitFactionGroup("player") == "Alliance" then
		if Classes[ClassItr] == "warrior" then paladin:Hide() warrior:Show() end
		if Classes[ClassItr] == "paladin" then hunter:Hide() paladin:Show() end
	else 
		if Classes[ClassItr] == "warrior" then hunter:Hide() warrior:Show() end
	end
	if Classes[ClassItr] == "hunter" then rogue:Hide() hunter:Show() end	
	if Classes[ClassItr] == "rogue" then priest:Hide() rogue:Show() end
	if UnitFactionGroup("player") == "Horde" then 
		if Classes[ClassItr] == "priest" then shaman:Hide() priest:Show() end
		if Classes[ClassItr] == "shaman" then mage:Hide() shaman:Show() end
	else 
		if Classes[ClassItr] == "priest" then mage:Hide() priest:Show() end
	end
	if Classes[ClassItr] == "mage" then warlock:Hide() mage:Show() end		
	if Classes[ClassItr] == "warlock" then druid:Hide() warlock:Show() end
	if Classes[ClassItr] == "druid" then warrior:Hide() druid:Show() end
	
	RoleUpdate()
	RoleItr = 1
end

function RaceUpdate()
	-- Updates the race selection defaults based on the currently selected class + player faction.
	if Classes[ClassItr] == "warrior" then 
		if UnitFactionGroup("player") == "Alliance" then 
			RaceStackHide()
			human:Show()
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			orc:Show()
			AddRace = "orc"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end
	end

	if Classes[ClassItr] == "paladin" then 
		RaceStackHide()
		human:Show()		
		AddRace = "human" 
	end

	if Classes[ClassItr] == "hunter" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			dwarf:Show()			
			AddRace = "dwarf" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			orc:Show()		
			AddRace = "orc"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end	
	end
	if Classes[ClassItr] == "rogue" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			human:Show()			
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			orc:Show()		
			AddRace = "orc"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end		
	end
	if Classes[ClassItr] == "priest" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			human:Show()			
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			undead:Show()		
			AddRace = "undead"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end		
	end
	if Classes[ClassItr] == "shaman" then 
		RaceStackHide()
		orc:Show()		
		AddRace = "orc"
	end
	if Classes[ClassItr] == "mage" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			human:Show()			
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			undead:Show()		
			AddRace = "undead"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end		 
	end
	if Classes[ClassItr] == "warlock" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			human:Show()			
			AddRace = "human" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			orc:Show()		
			AddRace = "orc"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end		
	end
	if Classes[ClassItr] == "druid" then 
		if UnitFactionGroup("player") == "Alliance" then
			RaceStackHide()	
			nightelf:Show()			
			AddRace = "nightelf" 
		elseif UnitFactionGroup("player") == "Horde" then 
			RaceStackHide()
			tauren:Show()		
			AddRace = "tauren"
		else
			RaceStackHide()
			race:Show()
			AddRace = "race"
		end	
	end
end

function RoleUpdate()
	-- Updates the role selection defaults based on the currently selected class.
	-- This controls what role string will be used for “Add PartyBot by role”.
	if Classes[ClassItr] == "warrior" then 
		RoleStackHide()
		tank:Show()
		AddRole = "tank"
	end
	if Classes[ClassItr] == "paladin" then 
		RoleStackHide()
		tank:Show()
		AddRole = "tank"
	end
	if Classes[ClassItr] == "hunter" then 
		RoleStackHide()
		rangedps:Show()
		AddRole = "rangedps"
	end
	if Classes[ClassItr] == "rogue" then 
		RoleStackHide()
		meleedps:Show()
		AddRole = "meleedps"
	end
	if Classes[ClassItr] == "priest" then 
		RoleStackHide()
		healer:Show()
		AddRole = "healer"
	end
	if Classes[ClassItr] == "shaman" then 
		RoleStackHide()
		tank:Show()
		AddRole = "tank"
	end
	if Classes[ClassItr] == "mage" then 
		RoleStackHide()
		rangedps:Show()
		AddRole = "rangedps" 
	end
	if Classes[ClassItr] == "warlock" then 
		RoleStackHide()
		rangedps:Show()
		AddRole = "rangedps"	
	end
	if Classes[ClassItr] == "druid" then 
		RoleStackHide()
		tank:Show()
		AddRole = "tank"
	end	
end

function RaceStackHide()
	-- Hides all race icons/labels in the race stack.
	race:Hide()
	human:Hide()
	dwarf:Hide()
	nightelf:Hide()
	gnome:Hide()
	orc:Hide()
	undead:Hide()
	tauren:Hide()
	troll:Hide()	
end

AddRace = "race"
RaceItr = 0
function SetRaceADD()
	-- Cycles race forward inside the current faction’s allowed race list for the chosen class.
	if AddClass == "warrior" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "tauren", "troll", "race" }		
		end		
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end		
		
	elseif AddClass == "paladin" then		
		Races = { "human", "dwarf", "race" }
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		
	elseif AddClass == "hunter" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "dwarf", "nightelf", "race" }			
		else 			
			Races = { "orc", "tauren", "troll", "race" }		
		end		
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "rogue" then		
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "troll", "race" }		
		end
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]	

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "priest" then
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "race" }			
		else 			
			Races = { "undead", "troll", "race" }		
		end	
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "shaman" then			
		Races = { "orc", "tauren", "troll", "race" }
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "mage" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "gnome", "race" }			
		else 			
			Races = { "undead", "troll", "race" }		
		end	
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end

		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end	

	elseif AddClass == "warlock" then			
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "race" }		
		end
		
		RaceItr = RaceItr + 1	
		if RaceItr >= table.getn(Races) + 1 then RaceItr = 1 end
		AddRace = Races[RaceItr]		

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end		

	elseif AddClass == "druid" then		
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "nightelf" }			
		else 			
			Races = { "tauren" }		
		end

		AddRace = Races[RaceItr]		
	
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
	end
end

function SetRaceSUB()
	-- Cycles race backward inside the current faction’s allowed race list for the chosen class.
	if RaceItr == 0 then RaceItr = 5 end

	if AddClass == "warrior" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "tauren", "troll", "race" }		
		end
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end	

	elseif AddClass == "paladin" then		
		Races = { "human", "dwarf", "race" }
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end

	elseif AddClass == "hunter" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "dwarf", "nightelf", "race" }			
		else 			
			Races = { "orc", "tauren", "troll", "race" }		
		end		
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "rogue" then		
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "troll", "race" }		
		end
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]	

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "priest" then
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "dwarf", "nightelf", "race" }			
		else 			
			Races = { "undead", "troll", "race" }		
		end	
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]
		
		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "dwarf" then RaceStackHide() dwarf:Show() end
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "shaman" then		
		Races = { "orc", "tauren", "troll", "race" }
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end

	elseif AddClass == "mage" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "gnome", "race" }			
		else 			
			Races = { "undead", "troll", "race" }		
		end	
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end

		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end
		if Races[RaceItr] == "troll" then RaceStackHide() troll:Show() end	

	elseif AddClass == "warlock" then		
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "human", "gnome", "race" }			
		else 			
			Races = { "orc", "undead", "race" }		
		end
		
		RaceItr = RaceItr - 1	
		if RaceItr <= 0 then RaceItr = table.getn(Races) end
		AddRace = Races[RaceItr]		

		if Races[RaceItr] == "race" then RaceStackHide() race:Show() end

		if Races[RaceItr] == "human" then RaceStackHide() human:Show() end
		if Races[RaceItr] == "gnome" then RaceStackHide() gnome:Show() end
		
		if Races[RaceItr] == "orc" then RaceStackHide() orc:Show() end
		if Races[RaceItr] == "undead" then RaceStackHide() undead:Show() end		

	elseif AddClass == "druid" then	
		if UnitFactionGroup("player") == "Alliance" then 
			Races = { "nightelf" }			
		else 			
			Races = { "tauren" }		
		end

		AddRace = Races[RaceItr]		
	
		if Races[RaceItr] == "nightelf" then RaceStackHide() nightelf:Show() end
		
		if Races[RaceItr] == "tauren" then RaceStackHide() tauren:Show() end			
	end
end

function RoleStackHide()
	-- Hides all role icons/labels in the role stack.
	tank:Hide()
	healer:Hide()
	meleedps:Hide()
	rangedps:Hide()
end

AddRole = "tank"
RoleItr = 1
function SetRoleADD()
	-- Cycles role forward for the selected class (some classes have only one role option here).
	if AddClass == "warrior" then
		Roles = { "tank", "meleedps" }
		
		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "tank" then RoleStackHide() tank:Show() end
		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end

	elseif AddClass == "paladin" then
		Roles = { "tank", "healer", "meleedps" }
		
		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "tank" then RoleStackHide() tank:Show() end
		if Roles[RoleItr] == "healer" then RoleStackHide() healer:Show() end
		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end		
	
	elseif AddClass == "hunter" then		
		Roles = { "rangedps" }
		
		AddRole = "rangedps"

		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end

	elseif AddClass == "rogue" then
		Roles = { "meleedps" }

		AddRole = "meleedps" 

		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end
		
	elseif AddClass == "priest" then
		Roles = { "healer", "rangedps" }

		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "healer" then RoleStackHide() healer:Show() end
		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end

	elseif AddClass == "shaman" then
		Roles = { "tank", "healer", "meleedps", "rangedps" }

		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "tank" then RoleStackHide() tank:Show() end
		if Roles[RoleItr] == "healer" then RoleStackHide() healer:Show() end
		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end
		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end
		
	elseif AddClass == "mage" then	
		Roles = { "rangedps" }
		
		AddRole = "rangedps"

		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end	
		
	elseif AddClass == "warlock" then
		Roles = { "rangedps" }
		
		AddRole = "rangedps"

		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end
	
	elseif AddClass == "druid" then	
		Roles = { "tank", "healer", "meleedps", "rangedps" }
		
		RoleItr = RoleItr + 1	
		if RoleItr >= table.getn(Roles) + 1 then RoleItr = 1 end
		AddRole = Roles[RoleItr]
	
		if Roles[RoleItr] == "tank" then RoleStackHide() tank:Show() end
		if Roles[RoleItr] == "healer" then RoleStackHide() healer:Show() end
		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end		
		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end
	end
end

function SetRoleSUB()
	-- Cycles role backward for the selected class.
	if AddClass == "warrior" then
		Roles = { "tank", "meleedps" }
		
		RoleItr = RoleItr - 1	
		if RoleItr <= 0 then RoleItr = table.getn(Roles) end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "tank" then RoleStackHide() tank:Show() end
		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end

	elseif AddClass == "paladin" then
		Roles = { "tank", "healer", "meleedps" }
		
		RoleItr = RoleItr - 1	
		if RoleItr <= 0 then RoleItr = table.getn(Roles) end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "tank" then RoleStackHide() tank:Show() end
		if Roles[RoleItr] == "healer" then RoleStackHide() healer:Show() end
		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end		
	
	elseif AddClass == "hunter" then		
		Roles = { "rangedps" }
		
		AddRole = "rangedps"

		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end

	elseif AddClass == "rogue" then
		Roles = { "meleedps" }

		AddRole = "meleedps" 

		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end
		
	elseif AddClass == "priest" then
		Roles = { "healer", "rangedps" }

		RoleItr = RoleItr - 1	
		if RoleItr <= 0 then RoleItr = table.getn(Roles) end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "healer" then RoleStackHide() healer:Show() end
		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end

	elseif AddClass == "shaman" then
		Roles = { "tank", "healer", "meleedps", "rangedps" }

		RoleItr = RoleItr - 1	
		if RoleItr <= 0 then RoleItr = table.getn(Roles) end
		AddRole = Roles[RoleItr]

		if Roles[RoleItr] == "tank" then RoleStackHide() tank:Show() end
		if Roles[RoleItr] == "healer" then RoleStackHide() healer:Show() end
		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end
		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end
		
	elseif AddClass == "mage" then	
		Roles = { "rangedps" }
		
		AddRole = "rangedps"

		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end	
		
	elseif AddClass == "warlock" then
		Roles = { "rangedps" }
		
		AddRole = "rangedps"

		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end
	
	elseif AddClass == "druid" then	
		Roles = { "tank", "healer", "meleedps", "rangedps" }
		
		RoleItr = RoleItr - 1	
		if RoleItr <= 0 then RoleItr = table.getn(Roles) end
		AddRole = Roles[RoleItr]
	
		if Roles[RoleItr] == "tank" then RoleStackHide() tank:Show() end
		if Roles[RoleItr] == "healer" then RoleStackHide() healer:Show() end
		if Roles[RoleItr] == "meleedps" then RoleStackHide() meleedps:Show() end		
		if Roles[RoleItr] == "rangedps" then RoleStackHide() rangedps:Show() end
	end
end

function GenderStackHide()
	-- Hides all gender icons/labels in the gender stack.
	gender:Hide()
	male:Hide()
	female:Hide()
end

AddGender = "gender"
GenderItr = 1
function SetGenderADD()
	-- Cycles gender forward and updates the visible icon/label.
		Genders = { "gender", "male", "female" }
		
		GenderItr = GenderItr + 1	
		if GenderItr >= table.getn(Genders) + 1 then GenderItr = 1 end
		AddGender = Genders[GenderItr]

		if Genders[GenderItr] == "gender" then GenderStackHide() gender:Show() end
		if Genders[GenderItr] == "male" then GenderStackHide() male:Show() end
		if Genders[GenderItr] == "female" then GenderStackHide() female:Show() end
end

function SetGenderSUB()
	-- Cycles gender backward and updates the visible icon/label.
		Genders = { "gender", "male", "female" }

		GenderItr = GenderItr - 1	
		if GenderItr <= 0 then GenderItr = table.getn(Genders) end
		AddGender = Genders[GenderItr]

		if Genders[GenderItr] == "gender" then GenderStackHide() gender:Show() end
		if Genders[GenderItr] == "male" then GenderStackHide() male:Show() end
		if Genders[GenderItr] == "female" then GenderStackHide() female:Show() end
end

AddBG = "warsong"
BGItr = 1
function BGStackHide()
	-- Hides all battleground icons/labels in the BG stack.
	warsong:Hide()
	arathi:Hide()
	alterac:Hide()
end

function SetBGADD()
	-- Cycles battleground forward (Warsong/Arathi/Alterac).
	BGS = { "warsong", "arathi", "alterac" }
	
	BGItr = BGItr + 1	
	if BGItr == 4 then BGItr = 1 end
	AddBG = BGS[BGItr]
	
	if BGS[BGItr] == "warsong" then BGStackHide() warsong:Show() end
	if BGS[BGItr] == "arathi" then BGStackHide() arathi:Show() end
	if BGS[BGItr] == "alterac" then BGStackHide() alterac:Show() end
end

function SetBGSUB()
	-- Cycles battleground backward (Warsong/Arathi/Alterac).
	BGS = { "warsong", "arathi", "alterac" }
	
	BGItr = BGItr - 1	
	if BGItr == 0 then BGItr = 3 end
	AddBG = BGS[BGItr]
	
	if BGS[BGItr] == "warsong" then BGStackHide() warsong:Show() end
	if BGS[BGItr] == "arathi" then BGStackHide() arathi:Show() end
	if BGS[BGItr] == "alterac" then BGStackHide() alterac:Show() end
end

function SubPartyBotAddAdvanced(self)
	-- Sends: .partybot add <class> <role> <gender>
	-- Uses the currently selected values from the UI stacks.
	SendChatMessage(CMD_PARTYBOT_ADD .. AddClass .. " " .. AddRole .. " " .. AddGender);
end

function SubPartyBotAdd(self, arg)
	-- Sends: .partybot add <rawArg>
	SendChatMessage(CMD_PARTYBOT_ADD .. arg);
end

function Brackets()
	-- Picks a random bot level in your current PvP bracket (or 60 if you are 60).
	if UnitLevel("player") >= 10 and UnitLevel("player") <= 19 then return math.random(10,19) 
	elseif UnitLevel("player") >= 20 and UnitLevel("player") <= 29 then return math.random(20,29)
	elseif UnitLevel("player") >= 30 and UnitLevel("player") <= 39 then return math.random(30,39)
	elseif UnitLevel("player") >= 40 and UnitLevel("player") <= 49 then return math.random(40,49)
	elseif UnitLevel("player") >= 50 and UnitLevel("player") <= 59 then return math.random(50,59)
	elseif UnitLevel("player") == 60 then return 60
	else return math.random(10,19)
	end
end

function SubBattleBotAdd(self, arg1, arg2)
	-- Sends: .battlebot add <arg1> <arg2> <randomLevelFromBracket>
	RanBotLevel = Brackets()
	SendChatMessage(CMD_BATTLEBOT_ADD .. arg1 .. " " .. arg2 .. " " .. RanBotLevel);
end

function SubBattleGo(self, arg1)
	-- Sends: .go <locationOrBG>
	SendChatMessage(CMD_BATTLEGROUND_GO .. arg1);
end

function CloseFrame()
	-- Closes the main PCP window (Close button).
	PCPFrame:Hide();
end

function OpenFrame()
	-- Opens the main PCP window and prints a loading message.
	DEFAULT_CHAT_FRAME:AddMessage("Loading PartyBot Control Panel...");
	DEFAULT_CHAT_FRAME:RegisterEvent('CHAT_MSG_SYSTEM')
	PCPFrame:Show();
end

local PCPFrameShown = true
local PCPButtonPosition = 268

-- Legacy minimap button code (circular minimap position math).
-- Note: This is separate from the newer minimap button code at the top of the file.
-- If you’re cleaning things up, you probably want to keep only one minimap-button system.

function PCPButtonFrame_OnClick()
	-- Legacy minimap button click handler: toggles PCPFrame.
	PCPButtonFrame_Toggle();
end

function PCPButtonFrame_Init()
	-- Legacy minimap button init: shows/hides PCPFrame based on PCPFrameShown flag.
   
	if(PCPFrameShown) then
		PCPFrame:Show();
	else
		PCPFrame:Hide();
	end
end

function PCPButtonFrame_Toggle()
	-- Legacy minimap button toggle: toggles PCPFrame visibility and refreshes state.
	if(PCPFrame:IsVisible()) then
		PCPFrame:Hide();
		PCPFrameShown = false;
	else
		PCPFrame:Show();
		PCPFrameShown = true;
	end
	PCPButtonFrame_Init();
end

function PCPButtonFrame_OnEnter(self)
	-- Legacy minimap button tooltip.
    GameTooltip:SetOwner(self, "ANCHOR_LEFT");
    GameTooltip:SetText("PartyBot Control Panel \n Press Left Click to Open/Close \n Hold Right Click to move the icon");
    GameTooltip:Show();
end

function PCPButtonFrame_UpdatePosition()
	-- Legacy minimap button positioning around the minimap edge using angle math.
	PCPButtonFrame:SetPoint(
		"TOPLEFT",
		"Minimap",
		"TOPLEFT",
		54 - (78 * cos(PCPButtonPosition)),
		(78 * sin(PCPButtonPosition)) - 55
	);
	PCPButtonFrame_Init();
end

function PCPButtonFrame_BeingDragged()
	-- Legacy minimap button drag handler: converts cursor position to an angle.
   
    local xpos,ypos = GetCursorPosition() 
    local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom() 

    xpos = xmin-xpos/UIParent:GetScale()+70 
    ypos = ypos/UIParent:GetScale()-ymin-70 

    PCPButtonFrame_SetPosition(math.deg(math.atan2(ypos,xpos)));
end

function PCPButtonFrame_SetPosition(v)
	-- Legacy minimap button setter: normalizes degrees then applies position.
    if(v < 0) then
        v = v + 360;
    end

    PCPButtonPosition = v;
    PCPButtonFrame_UpdatePosition();
end

SLASH_PCP1 = '/PCP'
function SlashCmdList.PCP(msg, editbox)
	-- Slash command: /PCP or /PCP cp toggles the PCP window.
    if (msg == "" or msg == "cp") then
        if (PCPFrame:IsVisible()) then
            PCPFrame:Hide()
        else
			PCPFrame:Show()
        end
    end
end

function ShowToggle()
	-- Convenience toggle used by keybind (Show/Hide PCP).
	if (PCPFrame:IsVisible()) then
		PCPFrame:Hide()
	else
		PCPFrame:Show()
	end
end

function JoinWorld()
	-- Joins the “World” chat channel if you’re not already in it.
	id, name = GetChannelName(1)
	if (name ~= "World") then
		JoinChannelByName("World", nil, ChatFrame1:GetID(), 0)
	end
end
