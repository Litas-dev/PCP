

local version, build, date, tocversion = GetBuildInfo()
local isVanilla = string.find(version, "^1%.12") ~= nil

local function PCP_GetAddonVersion()
    local v = nil
    if GetAddOnMetadata then
        v = GetAddOnMetadata("PCP", "Version")
    end
    if type(v) ~= "string" or v == "" then
        v = "0.0.0"
    end
    return v
end

local function PCP_ParseSemver(v)
    if type(v) ~= "string" then return 0, 0, 0 end
    local maj, min, pat = string.match(v, "(%d+)%.(%d+)%.(%d+)")
    return tonumber(maj) or 0, tonumber(min) or 0, tonumber(pat) or 0
end

local function PCP_IsNewerVersion(remote, localV)
    local r1, r2, r3 = PCP_ParseSemver(remote)
    local l1, l2, l3 = PCP_ParseSemver(localV)
    if r1 ~= l1 then return r1 > l1 end
    if r2 ~= l2 then return r2 > l2 end
    return r3 > l3
end

local PCP_UPDATE_PREFIX = "PCP_VER"
local PCP_RELEASES_URL = "https://github.com/Litas-dev/PCP/releases"
local pcpLastVersionBroadcastAt = 0

local function PCP_RegisterAddonPrefix()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PCP_UPDATE_PREFIX)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(PCP_UPDATE_PREFIX)
    end
end

local function PCP_SendAddonMessage(prefix, message, channel, target)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(prefix, message, channel, target)
    elseif SendAddonMessage then
        SendAddonMessage(prefix, message, channel, target)
    end
end

local function PCP_BroadcastVersion()
    local now = (GetTime and GetTime()) or 0
    if now > 0 and (now - (pcpLastVersionBroadcastAt or 0)) < 30 then
        return
    end
    pcpLastVersionBroadcastAt = now

    local v = PCP_GetAddonVersion()

    if IsInGuild and IsInGuild() then
        PCP_SendAddonMessage(PCP_UPDATE_PREFIX, v, "GUILD")
    end
    if IsInRaid and IsInRaid() then
        PCP_SendAddonMessage(PCP_UPDATE_PREFIX, v, "RAID")
    elseif IsInGroup and IsInGroup() then
        PCP_SendAddonMessage(PCP_UPDATE_PREFIX, v, "PARTY")
    end
end

local function PCP_SetSolid(tex, r, g, b, a)
    if not tex then return end
    if tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, a)
    else
        tex:SetTexture(r, g, b, a)
    end
end

local pcpLastFlashButton = nil

local function PCP_FlashButton(btn)
    if not btn then return end

    if pcpLastFlashButton and pcpLastFlashButton ~= btn then
        local old = pcpLastFlashButton
        if old._pcpFlashTex then
            old._pcpFlashTex:Hide()
        end
    end
    pcpLastFlashButton = btn

    if not btn._pcpFlashTex then
        local t = btn:CreateTexture(nil, "OVERLAY")
        t:SetAllPoints()
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetVertexColor(0.20, 0.60, 1.00, 0.18)
        t:Hide()
        btn._pcpFlashTex = t
        btn._pcpFlashToken = 0
    end

    btn._pcpFlashToken = (btn._pcpFlashToken or 0) + 1
    local token = btn._pcpFlashToken

    btn._pcpFlashTex:Show()

    if C_Timer and C_Timer.After then
        C_Timer.After(1, function()
            if not btn or not btn._pcpFlashTex then return end
            if btn._pcpFlashToken ~= token then return end
            btn._pcpFlashTex:Hide()
        end)
    else
        local f = btn._pcpFlashFrame
        if not f then
            f = CreateFrame("Frame", nil, btn)
            btn._pcpFlashFrame = f
        end
        local elapsedAcc = 0
        f:SetScript("OnUpdate", function(_, elapsed)
            elapsedAcc = elapsedAcc + (elapsed or 0)
            if elapsedAcc >= 1 then
                f:SetScript("OnUpdate", nil)
                if btn._pcpFlashToken == token and btn._pcpFlashTex then
                    btn._pcpFlashTex:Hide()
                end
            end
        end)
    end
end

local function PCP_SkinButton(btn)
    if not btn or btn._pcpSkinned then return end
    if btn.GetObjectType and btn:GetObjectType() ~= "Button" then return end

    local hasText = false
    if btn.GetFontString and btn:GetFontString() then
        hasText = true
    elseif btn.GetText then
        local t = btn:GetText()
        if type(t) == "string" and t ~= "" then
            hasText = true
        end
    end
    if not hasText then return end

    btn._pcpSkinned = true

    if btn.SetNormalTexture then
        btn:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
        local t = btn:GetNormalTexture()
        if t then
            t:SetAllPoints()
            t:SetVertexColor(0.11, 0.12, 0.15, 0.95)
        end
    end

    if btn.SetPushedTexture then
        btn:SetPushedTexture("Interface\\Buttons\\WHITE8x8")
        local t = btn:GetPushedTexture()
        if t then
            t:SetAllPoints()
            t:SetVertexColor(0.09, 0.10, 0.12, 0.98)
        end
    end

    if btn.SetHighlightTexture then
        btn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
        local t = btn:GetHighlightTexture()
        if t then
            t:SetAllPoints()
            t:SetVertexColor(1, 1, 1, 0.06)
        end
    end

    if btn.SetDisabledTexture then
        btn:SetDisabledTexture("Interface\\Buttons\\WHITE8x8")
        local t = btn:GetDisabledTexture()
        if t then
            t:SetAllPoints()
            t:SetVertexColor(0.07, 0.08, 0.10, 0.70)
        end
    end

    local top = btn:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", 0, 0)
    top:SetHeight(1)
    PCP_SetSolid(top, 1, 1, 1, 0.08)

    local bottom = btn:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    PCP_SetSolid(bottom, 1, 1, 1, 0.08)

    local left = btn:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", 0, 0)
    left:SetWidth(1)
    PCP_SetSolid(left, 1, 1, 1, 0.08)

    local right = btn:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
    PCP_SetSolid(right, 1, 1, 1, 0.08)
end

local function PCP_SkinAllButtons(frame)
    if not frame or not frame.GetChildren then return end
    local function walk(parent)
        for _, child in ipairs({ parent:GetChildren() }) do
            if child and child.GetObjectType and child:GetObjectType() == "Button" then
                PCP_SkinButton(child)
                if child._pcpSkinned and not child._pcpFlashWrapped then
                    child._pcpFlashWrapped = true
                    local orig = child:GetScript("OnClick")
                    child:SetScript("OnClick", function(self, ...)
                        if type(orig) == "function" then
                            orig(self, ...)
                        end
                        PCP_FlashButton(self)
                    end)
                end
            end
            if child and child.GetChildren then
                walk(child)
            end
        end
    end
    walk(frame)
end

local function PCP_SkinFrame(frame)
    if not frame or frame._pcpFrameSkinned then return end
    frame._pcpFrameSkinned = true

    if frame.SetFrameStrata then
        frame:SetFrameStrata("HIGH")
    end
    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(true)
    end

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = true,
            tileSize = 16,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        if frame.SetBackdropColor then
            frame:SetBackdropColor(0.06, 0.07, 0.08, 0.94)
        end
        if frame.SetBackdropBorderColor then
            frame:SetBackdropBorderColor(0, 0, 0, 0.95)
        end
    end

    local bar = frame:CreateTexture(nil, "BACKGROUND")
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    bar:SetHeight(28)
    PCP_SetSolid(bar, 0.10, 0.12, 0.16, 0.95)
    frame._pcpHeaderBar = bar

    local divider = frame:CreateTexture(nil, "BORDER")
    divider:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    PCP_SetSolid(divider, 1, 1, 1, 0.06)
    frame._pcpHeaderDivider = divider
end

local function PCP_CreateMinimapButton()
    if PCPButtonFrame then return end
    if not Minimap then return end

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
    PCPButtonFrame:SetFrameStrata("MEDIUM")

    if not isVanilla and PCPButtonFrame.SetBackdrop then
        PCPButtonFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        PCPButtonFrame:SetBackdropColor(0.06, 0.07, 0.08, 0.92)
        PCPButtonFrame:SetBackdropBorderColor(1, 1, 1, 0.08)
    elseif isVanilla then
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
    local n = PCPButtonFrame.GetNormalTexture and PCPButtonFrame:GetNormalTexture()
    if n and n.SetTexCoord then
        n:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    local p = PCPButtonFrame.GetPushedTexture and PCPButtonFrame:GetPushedTexture()
    if p and p.SetTexCoord then
        p:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    local function dragStart(self)
        if PCPButtonFrame_BeingDragged then
            self:SetScript("OnUpdate", PCPButtonFrame_BeingDragged)
        end
    end

    local function dragStop(self)
        self:SetScript("OnUpdate", nil)
        if PCPButtonFrame_UpdatePosition then
            PCPButtonFrame_UpdatePosition()
        end
    end

    local function onClick(self)
        if PCPButtonFrame_OnClick then
            PCPButtonFrame_OnClick()
        elseif PCPButtonFrame_Toggle then
            PCPButtonFrame_Toggle()
        end
    end

    local function onEnter(self)
        if PCPButtonFrame_OnEnter then
            PCPButtonFrame_OnEnter(self)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("PartyBot Control Panel\nLeft Click: Toggle\nRight Click: Move", 1,1,1)
            GameTooltip:Show()
        end
    end

    local function onLeave()
        GameTooltip:Hide()
    end

    PCPButtonFrame:SetScript("OnDragStart", dragStart)
    PCPButtonFrame:SetScript("OnDragStop", dragStop)
    PCPButtonFrame:SetScript("OnClick", onClick)
    PCPButtonFrame:SetScript("OnEnter", onEnter)
    PCPButtonFrame:SetScript("OnLeave", onLeave)
    PCPButtonFrame:Show()
end

local function PCP_InitSettings()
    if type(PCPSettings) ~= "table" then
        PCPSettings = {}
    end
    if type(PCPSettings.sectionEnabled) ~= "table" then
        PCPSettings.sectionEnabled = {}
    end
    if type(PCPSettings.ui) ~= "table" then
        PCPSettings.ui = {}
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

    if type(PCPSettings.ui.activeTab) ~= "string" then
        PCPSettings.ui.activeTab = "Bots"
    end
    if type(PCPSettings.ui.scale) ~= "number" then
        PCPSettings.ui.scale = 1
    end
    if type(PCPSettings.ui.bigFont) ~= "boolean" then
        PCPSettings.ui.bigFont = false
    end
end

local function PCP_ClampScale(v)
    v = tonumber(v) or 1
    if v < 0.8 then v = 0.8 end
    if v > 1.3 then v = 1.3 end
    return v
end

local function PCP_ApplyScale(frame)
    if not frame or not frame.SetScale then return end
    if type(PCPSettings) ~= "table" or type(PCPSettings.ui) ~= "table" then return end
    frame:SetScale(PCP_ClampScale(PCPSettings.ui.scale))
end

local function PCP_EnsureOriginalFonts(frame)
    if not frame or frame._pcpOriginalFonts then return end
    frame._pcpOriginalFonts = {}

    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            local font, size, flags = region:GetFont()
            frame._pcpOriginalFonts[region] = { font = font, size = size, flags = flags }
        end
    end

    for _, child in ipairs({ frame:GetChildren() }) do
        if child and child.GetObjectType and child:GetObjectType() == "Button" and child.GetFontString then
            local fs = child:GetFontString()
            if fs and not frame._pcpOriginalFonts[fs] then
                local font, size, flags = fs:GetFont()
                frame._pcpOriginalFonts[fs] = { font = font, size = size, flags = flags }
            end
        end
    end
end

local function PCP_ApplyFontMode(frame)
    if not frame then return end
    if type(PCPSettings) ~= "table" or type(PCPSettings.ui) ~= "table" then return end
    PCP_EnsureOriginalFonts(frame)

    local big = PCPSettings.ui.bigFont and true or false
    local mul = big and 1.15 or 1

    for fs, orig in pairs(frame._pcpOriginalFonts or {}) do
        if fs and fs.SetFont and orig and type(orig.size) == "number" then
            fs:SetFont(orig.font, math.floor((orig.size * mul) + 0.5), orig.flags)
        end
    end
end

local PCP_AlignExternalButtons

local function PCP_TryHookFillRaidBots(frame)
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

    PCP_CreateMinimapButton()
    if PCPButtonFrame then
        PCPButtonFrame:Show()
        if PCPButtonFrame_UpdatePosition then
            PCPButtonFrame_UpdatePosition()
        end
    end

    PCP_RegisterAddonPrefix()
    PCP_BroadcastVersion()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        OnPlayerLogin(self, event, ...)
        return
    end

    if event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        PCP_BroadcastVersion()
        return
    end

    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix ~= PCP_UPDATE_PREFIX then return end

        local localV = PCP_GetAddonVersion()
        local remoteV = message
        if type(remoteV) ~= "string" or remoteV == "" then return end

        if PCP_IsNewerVersion(remoteV, localV) then
            PCP_InitSettings()
            PCPSettings.ui = PCPSettings.ui or {}
            if PCPSettings.ui.updateNotifiedVersion ~= remoteV then
                PCPSettings.ui.updateNotifiedVersion = remoteV
                print("|cffffd100PCP|r: Newer version detected from " .. (sender or "unknown") .. ": " .. remoteV .. " (you have " .. localV .. ")")
                print("|cffffd100PCP|r: Releases: " .. PCP_RELEASES_URL)
            end
        end
    end
end)

local function PCP_InitCollapsible(frame)
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

    local footer = CreateFrame("Frame", nil, frame)
    if closeButton then
        closeButton:SetParent(footer)
        closeButton:ClearAllPoints()
        closeButton:SetPoint("TOP", footer, "TOP", 0, -8)
    end
    if versionLabel then
        versionLabel:SetParent(footer)
        versionLabel:ClearAllPoints()
        versionLabel:SetPoint("BOTTOM", footer, "BOTTOM", 0, 6)
    end

    if not _G.PCPExternalLeftAnchor then
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
        local y = frame._pcpTopOffset or 6
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
            _G.PCPExternalLeftAnchor:ClearAllPoints()
            _G.PCPExternalLeftAnchor:SetPoint("LEFT", frame, "LEFT", 0, 0)
            _G.PCPExternalLeftAnchor:Show()
        end
        if _G.PCPExternalRightAnchor then
            _G.PCPExternalRightAnchor:ClearAllPoints()
            _G.PCPExternalRightAnchor:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
            _G.PCPExternalRightAnchor:Show()
        end

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

        local function EnsureUiPopup()
            if frame._pcpUiPopup then return end

            local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            popup:SetPoint("TOPRIGHT", optionsButton, "BOTTOMRIGHT", 0, -6)
            popup:SetSize(240, 120)
            popup:SetFrameStrata("DIALOG")
            popup:SetFrameLevel(200)
            if popup.SetClampedToScreen then
                popup:SetClampedToScreen(true)
            end
            popup:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                tile = true,
                tileSize = 16,
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            popup:SetBackdropColor(0.06, 0.07, 0.08, 0.96)
            popup:SetBackdropBorderColor(0, 0, 0, 0.95)
            popup:Hide()
            popup:EnableMouse(true)

            local function IsHovering()
                if popup.IsMouseOver and popup:IsMouseOver() then
                    return true
                end
                if optionsButton and optionsButton.IsMouseOver and optionsButton:IsMouseOver() then
                    return true
                end
                if MouseIsOver then
                    if MouseIsOver(popup) then return true end
                    if optionsButton and MouseIsOver(optionsButton) then return true end
                end
                return false
            end

            local function HoldOpen()
                popup._pcpAutoHideAcc = 0
                if GetTime then
                    popup._pcpHoldOpenUntil = GetTime() + 1.0
                else
                    popup._pcpHoldOpenUntil = nil
                end
            end

            popup._pcpAutoHideAcc = 0
            popup:SetScript("OnShow", function(self)
                self._pcpAutoHideAcc = 0
                self._pcpHoldOpenUntil = nil
            end)
            popup:SetScript("OnUpdate", function(self, elapsed)
                if not self:IsShown() then return end
                if IsHovering() then
                    self._pcpAutoHideAcc = 0
                    return
                end
                if self._pcpHoldOpenUntil and GetTime and GetTime() < self._pcpHoldOpenUntil then
                    self._pcpAutoHideAcc = 0
                    return
                end
                self._pcpAutoHideAcc = (self._pcpAutoHideAcc or 0) + (elapsed or 0)
                if self._pcpAutoHideAcc >= 1.5 then
                    self:Hide()
                end
            end)

            local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -10)
            title:SetText("UI Settings")

            local slider = CreateFrame("Slider", "PCPUIScaleSlider", popup, "OptionsSliderTemplate")
            slider:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -34)
            slider:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -10, -34)
            slider:SetMinMaxValues(0.8, 1.3)
            slider:SetValueStep(0.05)
            slider:SetObeyStepOnDrag(true)

            local label = _G[slider:GetName() .. "Text"]
            local low = _G[slider:GetName() .. "Low"]
            local high = _G[slider:GetName() .. "High"]
            if label then label:SetText("UI Scale") end
            if low then low:SetText("0.8") end
            if high then high:SetText("1.3") end

            slider:SetScript("OnValueChanged", function(_, value)
                HoldOpen()
                if type(PCPSettings) == "table" and type(PCPSettings.ui) == "table" then
                    PCPSettings.ui.scale = PCP_ClampScale(value)
                end
                PCP_ApplyScale(frame)
            end)

            local cb = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -76)
            cb:SetChecked(type(PCPSettings) == "table" and type(PCPSettings.ui) == "table" and PCPSettings.ui.bigFont and true or false)
            local txt = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            txt:SetPoint("LEFT", cb, "RIGHT", 4, 1)
            txt:SetText("Big Font")
            cb:SetScript("OnClick", function(self)
                HoldOpen()
                if type(PCPSettings) == "table" and type(PCPSettings.ui) == "table" then
                    PCPSettings.ui.bigFont = self:GetChecked() and true or false
                end
                PCP_ApplyFontMode(frame)
                if frame._pcpLayout then
                    frame._pcpLayout:Relayout()
                end
            end)

            frame._pcpUiPopup = popup
            frame._pcpUiScaleSlider = slider
            frame._pcpUiBigFont = cb
        end

        local function ToggleUiPopup()
            EnsureUiPopup()
            local p = frame._pcpUiPopup
            if not p then return end
            if p:IsShown() then
                p:Hide()
            else
                if frame._pcpUiScaleSlider then
                    frame._pcpUiScaleSlider:SetValue(PCP_ClampScale(type(PCPSettings) == "table" and type(PCPSettings.ui) == "table" and PCPSettings.ui.scale or 1))
                end
                if frame._pcpUiBigFont then
                    frame._pcpUiBigFont:SetChecked(type(PCPSettings) == "table" and type(PCPSettings.ui) == "table" and PCPSettings.ui.bigFont and true or false)
                end
                p:Show()
                p._pcpAutoHideAcc = 0
                if GetTime then
                    p._pcpHoldOpenUntil = GetTime() + 1.0
                else
                    p._pcpHoldOpenUntil = nil
                end
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
            menu[#menu + 1] = { text = "UI Settings...", notCheckable = true, func = ToggleUiPopup }
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
                    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
                    popup:SetPoint("TOPRIGHT", optionsButton, "BOTTOMRIGHT", 0, -6)
                    local popupHeight = (#frame._pcpLayout.sections * 24) + 24
                    popup:SetSize(200, popupHeight)
                    popup:SetFrameStrata("DIALOG")
                    popup:SetFrameLevel(180)
                    if popup.SetClampedToScreen then
                        popup:SetClampedToScreen(true)
                    end
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
    PCP_SkinFrame(frame)
    PCP_SkinAllButtons(frame)
    PCP_ApplyScale(frame)
    PCP_ApplyFontMode(frame)
    if frame._pcpLayout then
        if not frame._pcpTabs then
            frame._pcpTabs = {}

            local tabs = { "Bots", "Commands", "Marks", "All" }
            local tabLabels = {
                Bots = "Bots",
                Commands = "Cmds",
                Marks = "Marks",
                All = "All",
            }
            for i, key in ipairs(tabs) do
                local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
                b:SetSize(52, 20)
                if i == 1 then
                    b:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -32)
                else
                    b:SetPoint("LEFT", frame._pcpTabs[i - 1], "RIGHT", 6, 0)
                end
                b:SetText(tabLabels[key] or key)
                b._pcpTabKey = key
                PCP_SkinButton(b)
                frame._pcpTabs[i] = b
            end

            frame._pcpTopOffset = 58
        end

        local function ApplyTab(tabKey)
            if type(PCPSettings) == "table" and type(PCPSettings.ui) == "table" then
                PCPSettings.ui.activeTab = tabKey
            end

            local showAll = tabKey == "All"
            local showBots = tabKey == "Bots"
            local showCommands = tabKey == "Commands"
            local showMarks = tabKey == "Marks"

            for _, sec in ipairs(frame._pcpLayout.sections) do
                local enabled = false
                local savedEnabled = true
                if type(PCPSettings) == "table" and type(PCPSettings.sectionEnabled) == "table" then
                    savedEnabled = PCPSettings.sectionEnabled[sec.baseText] ~= false
                end

                if showAll then
                    enabled = savedEnabled
                elseif showBots then
                    enabled = (sec.baseText == "PartyBot Configurator" or sec.baseText == "Add PartyBot by role") and savedEnabled
                elseif showCommands then
                    enabled = (sec.baseText == "Commands" or sec.baseText == "Come" or sec.baseText == "Move" or sec.baseText == "Stay") and savedEnabled
                elseif showMarks then
                    enabled = (sec.baseText == "Mark Configurator") and savedEnabled
                end

                sec.enabled = enabled
            end

            for _, b in ipairs(frame._pcpTabs) do
                local n = b and b.GetNormalTexture and b:GetNormalTexture()
                if n and n.SetVertexColor then
                    if b._pcpTabKey == tabKey then
                        n:SetVertexColor(0.15, 0.17, 0.22, 0.98)
                    else
                        n:SetVertexColor(0.11, 0.12, 0.15, 0.95)
                    end
                end
            end

            frame._pcpLayout:Relayout()
            PCP_AlignExternalButtons(frame)
        end

        if not frame._pcpTabHandlers then
            frame._pcpTabHandlers = true
            for _, b in ipairs(frame._pcpTabs) do
                b:SetScript("OnClick", function() ApplyTab(b._pcpTabKey) end)
            end
        end

        local savedTab = (type(PCPSettings) == "table" and type(PCPSettings.ui) == "table" and PCPSettings.ui.activeTab) or "Bots"
        ApplyTab(savedTab)
    end
    if frame._pcpLayout then
        frame._pcpLayout:Relayout()
    end
end


function PCPFrame_OnLoad(frame)
    local f = isVanilla and this or frame

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    PCP_SkinFrame(f)
    PCP_SkinAllButtons(f)

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

AddCmd = ""
CmdItr = 1
function CmdStackHide()
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
		SendChatMessage(CMD_GENERAL .. arg);
end

function SetPause()
		SendChatMessage(CMD_GENERAL .. " pause ");
end

function SetUnpause()
		SendChatMessage(CMD_GENERAL .. " unpause ");
end

AddMark = "ccmark"
MarkItr = 1
function MarkStackHide()
	ccmark:Hide()
	focusmark:Hide()
end

function MarkADD()
	Marks = { "ccmark", "focusmark" }

	MarkItr = MarkItr + 1	
	if MarkItr >= table.getn(Marks) + 1 then MarkItr = 1 end
	AddMark = Marks[MarkItr]

	if Marks[MarkItr] == "ccmark" then MarkStackHide() ccmark:Show() end
	if Marks[MarkItr] == "focusmark" then MarkStackHide() focusmark:Show() end
end

function MarkSUB()
	Marks = { "ccmark", "focusmark" }

	MarkItr = MarkItr - 1	
	if MarkItr <= 0 then MarkItr = table.getn(Marks) end
	AddMark = Marks[MarkItr]

	if Marks[MarkItr] == "ccmark" then MarkStackHide() ccmark:Show() end
	if Marks[MarkItr] == "focusmark" then MarkStackHide() focusmark:Show() end
end

function SetMark(self, arg)
	SendChatMessage(CMD_GENERAL .. AddMark .. " " .. arg);
end

function ShowMark()
	SendChatMessage(CMD_GENERAL .. AddMark);
end

function ClearMark()
	SendChatMessage(CMD_GENERAL .. "clear " .. AddMark);
end

function ClearAllMark()
	SendChatMessage(CMD_GENERAL .. "clear");
end

AddToggle = "aoe"
ToggleItr = 1
function ToggleStackHide()
	ToggleAOE:Hide()
	ToggleHelmCloak:Hide()
	helm:Hide()
	cloak:Hide()
end

function ToggleADD()
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
	SendChatMessage(CMD_GENERAL .."toggle " .. AddToggle);
end

function SubPartyBotClone(self)
	SendChatMessage(CMD_PARTYBOT_CLONE);
end

function SubPartyBotRemove(self)
	SendChatMessage(CMD_PARTYBOT_REMOVE);
end

function SubPartyBotMoveAll()
	SendChatMessage(CMD_PARTYBOT_MAll);
end

function SubPartyBotStayAll()
	SendChatMessage(CMD_PARTYBOT_SAll);
end

AddClass = "warrior"
ClassItr = 1
function SetClassADD()
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
	tank:Hide()
	healer:Hide()
	meleedps:Hide()
	rangedps:Hide()
end

AddRole = "tank"
RoleItr = 1
function SetRoleADD()
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
	gender:Hide()
	male:Hide()
	female:Hide()
end

AddGender = "gender"
GenderItr = 1
function SetGenderADD()
		Genders = { "gender", "male", "female" }
		
		GenderItr = GenderItr + 1	
		if GenderItr >= table.getn(Genders) + 1 then GenderItr = 1 end
		AddGender = Genders[GenderItr]

		if Genders[GenderItr] == "gender" then GenderStackHide() gender:Show() end
		if Genders[GenderItr] == "male" then GenderStackHide() male:Show() end
		if Genders[GenderItr] == "female" then GenderStackHide() female:Show() end
end

function SetGenderSUB()
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
	warsong:Hide()
	arathi:Hide()
	alterac:Hide()
end

function SetBGADD()
	BGS = { "warsong", "arathi", "alterac" }
	
	BGItr = BGItr + 1	
	if BGItr == 4 then BGItr = 1 end
	AddBG = BGS[BGItr]
	
	if BGS[BGItr] == "warsong" then BGStackHide() warsong:Show() end
	if BGS[BGItr] == "arathi" then BGStackHide() arathi:Show() end
	if BGS[BGItr] == "alterac" then BGStackHide() alterac:Show() end
end

function SetBGSUB()
	BGS = { "warsong", "arathi", "alterac" }
	
	BGItr = BGItr - 1	
	if BGItr == 0 then BGItr = 3 end
	AddBG = BGS[BGItr]
	
	if BGS[BGItr] == "warsong" then BGStackHide() warsong:Show() end
	if BGS[BGItr] == "arathi" then BGStackHide() arathi:Show() end
	if BGS[BGItr] == "alterac" then BGStackHide() alterac:Show() end
end

function SubPartyBotAddAdvanced(self)
	SendChatMessage(CMD_PARTYBOT_ADD .. AddClass .. " " .. AddRole .. " " .. AddGender);
end

function SubPartyBotAdd(self, arg)
	SendChatMessage(CMD_PARTYBOT_ADD .. arg);
end

function Brackets()
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
	RanBotLevel = Brackets()
	SendChatMessage(CMD_BATTLEBOT_ADD .. arg1 .. " " .. arg2 .. " " .. RanBotLevel);
end

function SubBattleGo(self, arg1)
	SendChatMessage(CMD_BATTLEGROUND_GO .. arg1);
end

function CloseFrame()
	PCPFrame:Hide();
end

function OpenFrame()
	DEFAULT_CHAT_FRAME:AddMessage("Loading PartyBot Control Panel...");
	DEFAULT_CHAT_FRAME:RegisterEvent('CHAT_MSG_SYSTEM')
	PCPFrame:Show();
end

local PCPFrameShown = false
if type(PCPButtonPosition) ~= "number" then
	PCPButtonPosition = 268
end

function PCPButtonFrame_OnClick()
	PCPButtonFrame_Toggle();
end

function PCPButtonFrame_Init()
   
	if(PCPFrameShown) then
		PCPFrame:Show();
	else
		PCPFrame:Hide();
	end
end

function PCPButtonFrame_Toggle()
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
    GameTooltip:SetOwner(self, "ANCHOR_LEFT");
    GameTooltip:SetText("PartyBot Control Panel \n Press Left Click to Open/Close \n Hold Right Click to move the icon");
    GameTooltip:Show();
end

function PCPButtonFrame_UpdatePosition()
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
   
    local xpos,ypos = GetCursorPosition() 
    local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom() 

    xpos = xmin-xpos/UIParent:GetScale()+70 
    ypos = ypos/UIParent:GetScale()-ymin-70 

    PCPButtonFrame_SetPosition(math.deg(math.atan2(ypos,xpos)));
end

function PCPButtonFrame_SetPosition(v)
    if(v < 0) then
        v = v + 360;
    end

    PCPButtonPosition = v;
    PCPButtonFrame_UpdatePosition();
end

SLASH_PCP1 = '/PCP'
function SlashCmdList.PCP(msg, editbox)
    if (msg == "" or msg == "cp") then
        if (PCPFrame:IsVisible()) then
            PCPFrame:Hide()
        else
			PCPFrame:Show()
        end
    end
end

function ShowToggle()
	if (PCPFrame:IsVisible()) then
		PCPFrame:Hide()
	else
		PCPFrame:Show()
	end
end

function JoinWorld()
	id, name = GetChannelName(1)
	if (name ~= "World") then
		JoinChannelByName("World", nil, ChatFrame1:GetID(), 0)
	end
end
