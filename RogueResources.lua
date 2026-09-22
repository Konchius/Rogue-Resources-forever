-- RogueResources.lua
local addonName, RR = ...   -- private namespace shared across the addon's files

-- ---------------------------------------------------------------------------
-- Resource reads, tolerant of the client's API surface.
--
-- This is an Anniversary client running on the modern ("retail") engine, so it
-- can expose BOTH the classic and the retail resource APIs at once, and they can
-- briefly disagree during a combo-point spend. Each getter below prefers the API
-- that actually returns data on this client, mirroring the dual-API style the
-- ShadowRotation addon uses for spell lookups.
-- ---------------------------------------------------------------------------

-- Enum.PowerType may not exist on older API surfaces; fall back to the numeric
-- constants (Energy = 3, ComboPoints = 4) that those clients expect.
local POWER_ENERGY = (Enum and Enum.PowerType and Enum.PowerType.Energy) or 3
local POWER_COMBO  = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4

local function GetEnergy()
    local cur = UnitPower("player", POWER_ENERGY)
    local max = UnitPowerMax("player", POWER_ENERGY)
    if not max or max == 0 then max = 100 end   -- guard against a 0 max during load
    return cur or 0, max
end

-- Combo points are a SECRET value on this client (WoW: Forever / patch 12 "Secret
-- Values"). Tainted addon code may STORE and PASS the value, but must never compare
-- it, do arithmetic on it, or boolean-test it -- any of those throw an immediate Lua
-- error. So GetCP reads the value and returns it completely untouched, for a
-- whitelisted widget "sink" (StatusBar:SetValue) to render without ever revealing it.
-- Note we can't even write `a or b` here: `or` boolean-tests the secret and errors.
-- GetComboPoints is the read (combo points are target-attached on this client); we
-- only nil-check the FUNCTION, never its returned value.
local function GetCP()
    if GetComboPoints then return GetComboPoints("player", "target") end
    return UnitPower("player", POWER_COMBO)
end

local MAX_CP = 5   -- base rogue; talents/anticipation handled later if needed

-- Slice and Dice tracking.
--
-- IMPORTANT: on WoW: Forever, addon (tainted) code CANNOT read auras at all. Both
-- C_UnitAuras.GetPlayerAuraBySpellID and GetAuraDataBySpellName return nil for us
-- even while SnD is clearly up (confirmed via /rr snd) -- the same secret-value
-- lockdown that hides combo points, extended to buffs. Only Blizzard's secure UI can
-- read them. So we can't know SnD's real remaining time.
--
-- Instead we time it LOCALLY from the (non-secret) cast spellID, and ESTIMATE the
-- duration from combo points. We can't READ combo points (secret), so we COUNT combo-
-- point builders since the last finisher and use that count. SnD length by CP is the
-- rank-1 tooltip: 1->9s, 2->12, 3->15, 4->18, 5->21 (i.e. 6 + 3*CP). The Cooldown
-- widget is driven by OUR OWN numbers (GetTime, duration) so the swipe + countdown
-- text work without touching any secret value.
local SND_CAST_IDS = { [5171] = true, [6774] = true }   -- SnD ranks 1/2 (cast spellIDs)
local SND_FALLBACK_ICON = 132306                        -- ability_rogue_slicedice
local CP_DURATION = { 9, 12, 15, 18, 21 }               -- SnD seconds by combo points 1..5
local cpEstimate = 0                                    -- ESTIMATED combo points (see below)
RR.debug = false

-- NOTE: the SnD duration can only be ESTIMATED, never exact. The real combo points are
-- a secret value: we can't read them, can't do arithmetic on them, and can't even feed
-- them to a Curve's Evaluate (it rejects secrets in addon/tainted code -- confirmed
-- live). The aura's real duration is likewise unreadable, and the combat log that would
-- reveal a parry/dodge is a forbidden API. So we count combo-point BUILDERS since the
-- last finisher (cast spellIDs are not secret) and map that to a duration. This is exact
-- for a clean rotation but drifts when an avoided attack grants no combo point.

local function SpellTex(id)
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
    return GetSpellTexture and GetSpellTexture(id)
end

local function SpellName(id)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(id)
        if info and info.name then return info.name end
    end
    return GetSpellInfo and GetSpellInfo(id) or nil
end

-- Combo-point builders / finishers, keyed by localized name so EVERY rank matches by
-- its shared name. Resolved from representative spell IDs at load and again at login.
local BUILDERS, FINISHERS = {}, {}
local function RefreshSpellSets()
    wipe(BUILDERS); wipe(FINISHERS)
    for _, id in ipairs({ 1752, 53, 1776, 14278, 16511 }) do   -- Sinister Strike, Backstab, Gouge, Ghostly Strike, Hemorrhage
        local n = SpellName(id); if n then BUILDERS[n] = true end
    end
    for _, id in ipairs({ 2098, 408, 1943, 8647 }) do          -- Eviscerate, Kidney Shot, Rupture, Expose Armor
        local n = SpellName(id); if n then FINISHERS[n] = true end
    end
end
RefreshSpellSets()

-- Cooldown-tracked abilities. Each lists candidate spell IDs (ranks); we track the one
-- the player actually knows. Evasion is single-rank; Vanish has two.
local EVASION_IDS = { 5277 }
local VANISH_IDS  = { 1856, 1857 }
local KICK_IDS    = { 1766, 1767, 1768, 1769 }   -- Kick ranks 1-4
local SPRINT_IDS  = { 2983 }                     -- Sprint
local BLADEFLURRY_IDS = { 13877 }                -- Blade Flurry
local ADRENALINE_IDS  = { 13750 }                -- Adrenaline Rush
local BLIND_IDS   = { 2094 }                     -- Blind
local KIDNEY_IDS  = { 408, 8643 }                -- Kidney Shot ranks 1-2
local GOUGE_IDS   = { 1776, 1777, 8629, 11285, 11286 }   -- Gouge ranks 1-5
local SND_LIST    = { 5171, 6774 }               -- Slice and Dice ranks (for the known-check)

-- Pick the known rank from a candidate list (its cooldown reflects the shared CD).
local function KnownID(ids)
    for _, id in ipairs(ids) do
        if IsSpellKnown and IsSpellKnown(id) then return id end
        if IsPlayerSpell and IsPlayerSpell(id) then return id end
    end
    return ids[1]
end

-- Read a spell's cooldown start/duration, tolerant of the API surface. Values may be
-- plain numbers OR secret (we find out live); the caller handles both.
local function GetCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then return info.startTime, info.duration end
    end
    if GetSpellCooldown then
        local start, dur = GetSpellCooldown(spellID)
        return start, dur
    end
end

local function IsSecret(v) return issecretvalue and issecretvalue(v) end

-- Poisons apply as temporary WEAPON ENCHANTS (read via GetWeaponEnchantInfo), not auras.
local MAINHAND_SLOT, OFFHAND_SLOT = 16, 17
local FALLBACK_WEAPON_TEX = "Interface\\Icons\\INV_Sword_04"

local function HasWeapon(slot) return GetInventoryItemID and GetInventoryItemID("player", slot) ~= nil end
local function WeaponTex(slot) return GetInventoryItemTexture and GetInventoryItemTexture("player", slot) end

-- Poison base names the player can choose per weapon (localized elsewhere; enUS here).
local POISON_TYPES = {
    "Instant Poison", "Deadly Poison", "Wound Poison", "Mind-numbing Poison", "Crippling Poison",
}
local POISON_WORD = "Poison"

-- Find a poison in the bags for the /use macro. With a type ("Deadly Poison") it returns
-- that type's exact item name (highest rank in bags, e.g. "Deadly Poison V"); with no
-- type it returns any poison. Plain-text match so hyphens (Mind-numbing) are literal.
local function FindBagPoison(typeBase)
    local needle = typeBase or POISON_WORD
    local best
    for bag = 0, 4 do
        local slots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag))
            or (GetContainerNumSlots and GetContainerNumSlots(bag)) or 0
        for s = 1, slots do
            local name
            if C_Container and C_Container.GetContainerItemInfo then
                local info = C_Container.GetContainerItemInfo(bag, s)
                name = info and (info.itemName or (info.hyperlink and info.hyperlink:match("%[(.-)%]")))
            end
            if not name and GetContainerItemLink then
                local link = GetContainerItemLink(bag, s)
                name = link and link:match("%[(.-)%]")
            end
            if name and name:find(needle, 1, true) then
                -- Prefer the longest name (higher ranks have a " II"/" V" suffix).
                if not best or #name > #best then best = name end
            end
        end
    end
    return best
end

-- Fallback poison detection: scan the weapon's tooltip for the temporary-enchant line
-- (used when GetWeaponEnchantInfo doesn't report poisons). Returns the line text or nil.
local function WeaponEnchantText(slot)
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local data = C_TooltipInfo.GetInventoryItem("player", slot)
        if data and data.lines then
            for _, line in ipairs(data.lines) do
                local t = line.leftText
                if t and t:find(POISON_WORD) then return t end
            end
        end
    end
    return nil
end

local function PoisonKey(b) return (b.slot == MAINHAND_SLOT) and "mh" or "oh" end

-- (Re)arm a weapon button's left-click apply macro. Only armed while LOCKED (so an
-- unlocked click just repositions, never applies) and out of combat (secure attrs are
-- locked in combat). Uses the per-weapon poison choice, or any poison if unset.
local function ArmPoisonButton(b)
    if InCombatLockdown and InCombatLockdown() then return end
    RogueResourcesDB.poisonChoice = RogueResourcesDB.poisonChoice or {}
    local choice = RogueResourcesDB.poisonChoice[PoisonKey(b)]
    local poison = RogueResourcesDB.locked and FindBagPoison(choice) or nil
    if poison then
        b:SetAttribute("type1", "macro")
        b:SetAttribute("macrotext", "/use " .. poison .. "\n/use " .. b.slot)
    else
        b:SetAttribute("type1", nil)
    end
end

-- Right-click a weapon button to choose which poison it applies. Saved per weapon.
local function OpenPoisonMenu(b)
    RogueResourcesDB.poisonChoice = RogueResourcesDB.poisonChoice or {}
    local key = PoisonKey(b)
    local label = (key == "mh") and "Main-hand poison" or "Off-hand poison"
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(b, function(_, root)
            root:CreateTitle(label)
            for _, ptype in ipairs(POISON_TYPES) do
                local mark = (RogueResourcesDB.poisonChoice[key] == ptype) and "|cff40ff40> |r" or ""
                root:CreateButton(mark .. ptype, function()
                    RogueResourcesDB.poisonChoice[key] = ptype
                    ArmPoisonButton(b)
                end)
            end
            root:CreateDivider()
            root:CreateButton("Any (first found)", function()
                RogueResourcesDB.poisonChoice[key] = nil
                ArmPoisonButton(b)
            end)
        end)
    else   -- fallback: cycle through the types
        local cur, idx = RogueResourcesDB.poisonChoice[key], 0
        for i, t in ipairs(POISON_TYPES) do if t == cur then idx = i break end end
        local nextType = POISON_TYPES[(idx % #POISON_TYPES) + 1]
        RogueResourcesDB.poisonChoice[key] = nextType
        ArmPoisonButton(b)
        print("|cff00ff88RogueResources:|r " .. label .. ": " .. nextType)
    end
end


-- ---------------------------------------------------------------------------
-- Saved settings
-- ---------------------------------------------------------------------------
RR.defaults = {
    locked      = true,
    position    = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -179 },
    poisonPos   = { point = "CENTER", relativePoint = "CENTER", x = 144, y = -179 },
    sndMult     = 1.0,  -- Improved Slice and Dice talent multiplier (1.0/1.15/1.30/1.45)
}

-- Fill only MISSING keys from defaults (recursively), so a saved position/duration is
-- never clobbered on load, and default sub-tables aren't shared by reference.
local function ApplyDefaults(src, dst)
    dst = dst or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = ApplyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

-- ---------------------------------------------------------------------------
-- Display: an energy StatusBar with a segmented combo-point bar above it.
-- CP can't drive discrete pips (that needs a comparison on a secret value), so it's
-- a 0..MAX_CP StatusBar split by dividers to still read as segments.
-- ---------------------------------------------------------------------------
local BAR_W, BAR_H = 200, 16
local CP_H, GAP = 14, 5
local BAR_TEX = "Interface\\TargetingFrame\\UI-StatusBar"

-- A crisp 1px dark outline just outside a region, drawn on `host` behind the bars.
local function Outline(region, host, thick)
    thick = thick or 1
    local t = host:CreateTexture(nil, "BACKGROUND", nil, -6)
    t:SetColorTexture(0, 0, 0, 1)
    t:SetPoint("TOPLEFT", region, "TOPLEFT", -thick, thick)
    t:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", thick, -thick)
    return t
end

-- Subtle sheen on a bar: a faint additive block over the top plus a 1px highlight
-- line, giving the fill some depth without needing any gradient API.
local function Gloss(bar)
    local g = bar:CreateTexture(nil, "ARTWORK", nil, 2)
    g:SetColorTexture(1, 1, 1, 0.06)
    g:SetBlendMode("ADD")
    g:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    g:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -1, -math.max(2, bar:GetHeight() * 0.5))
    local hl = bar:CreateTexture(nil, "ARTWORK", nil, 3)
    hl:SetColorTexture(1, 1, 1, 0.20)
    hl:SetHeight(1)
    hl:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    hl:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -1, -1)
end

local ICON_SIZE, ICON_GAP = 32, 5

-- A bordered spell icon with a Cooldown swipe overlay. Used for the SnD timer and the
-- Evasion/Vanish cooldown trackers.
local function MakeIcon(parent, tex)
    local o = CreateFrame("Frame", nil, parent)
    o:SetSize(ICON_SIZE, ICON_SIZE)

    local border = o:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", o, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", o, "BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0, 0, 0, 1)

    local icon = o:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(o)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)   -- trim the default icon border
    if tex then icon:SetTexture(tex) end

    local cd = CreateFrame("Cooldown", nil, o, "CooldownFrameTemplate")
    cd:SetAllPoints(o)
    cd:SetHideCountdownNumbers(false)
    cd:SetDrawEdge(true)

    -- One-shot "ready" flash: a white overlay that pulses up then fades. Played when a
    -- tracked cooldown finishes (wired per-icon in BuildUI).
    local flash = o:CreateTexture(nil, "OVERLAY")
    flash:SetAllPoints(o)
    flash:SetColorTexture(1, 1, 1, 1)
    flash:SetBlendMode("ADD")
    flash:SetAlpha(0)
    local ag = flash:CreateAnimationGroup()
    local up = ag:CreateAnimation("Alpha")
    up:SetFromAlpha(0); up:SetToAlpha(0.85); up:SetDuration(0.12); up:SetOrder(1)
    local down = ag:CreateAnimation("Alpha")
    down:SetFromAlpha(0.85); down:SetToAlpha(0); down:SetDuration(0.40); down:SetOrder(2)

    o.icon, o.cd, o.flash = icon, cd, ag
    return o
end

-- True if the player knows any rank of this icon's ability (so we only show learned
-- skills). IsSpellKnown/IsPlayerSpell are both tried since neither is fully reliable.
local function IconKnown(o)
    if o.available then return o.available() end   -- custom check (e.g. poisons)
    if not o.ids then return true end
    for _, id in ipairs(o.ids) do
        if (IsSpellKnown and IsSpellKnown(id)) or (IsPlayerSpell and IsPlayerSpell(id)) then
            return true
        end
    end
    return false
end

-- User's show/hide preference for an icon (default shown). Independent of "known".
local function IsEnabled(o)
    local e = RogueResourcesDB.iconEnabled
    return not (e and e[o.key] == false)
end

-- The default left-to-right icon order (by key). The user can reorder via /rr options;
-- the chosen order is saved and reconciled against the real icon set on load.
local DEFAULT_ORDER = {
    "snd", "evasion", "vanish", "kick", "sprint", "bladeflurry", "adrenaline", "blind", "kidney", "gouge",
}

-- Make RogueResourcesDB.iconOrder a clean list of every existing icon key: kept in the
-- saved order, dropping stale keys and appending any new abilities (in default order).
local function ReconcileOrder(f)
    if type(RogueResourcesDB.iconEnabled) ~= "table" then RogueResourcesDB.iconEnabled = {} end
    if type(RogueResourcesDB.poisonChoice) ~= "table" then RogueResourcesDB.poisonChoice = {} end
    local saved = type(RogueResourcesDB.iconOrder) == "table" and RogueResourcesDB.iconOrder or {}
    local seen, clean = {}, {}
    for _, key in ipairs(saved) do
        if f.iconByKey[key] and not seen[key] then clean[#clean + 1] = key; seen[key] = true end
    end
    for _, key in ipairs(DEFAULT_ORDER) do
        if f.iconByKey[key] and not seen[key] then clean[#clean + 1] = key; seen[key] = true end
    end
    RogueResourcesDB.iconOrder = clean
end

-- Show only the icons whose ability is known, in the saved order, as one centered row
-- with no gaps. Re-run on spell changes (leveling) and after reordering.
local function LayoutIcons(f)
    for _, o in ipairs(f.icons) do o:Hide() end
    local visible = {}
    for _, key in ipairs(RogueResourcesDB.iconOrder) do
        local o = f.iconByKey[key]
        if o and IconKnown(o) and IsEnabled(o) then o:Show(); visible[#visible + 1] = o end
    end
    local n = #visible
    local totalW = n * ICON_SIZE + math.max(0, n - 1) * ICON_GAP
    local x0 = (BAR_W - totalW) / 2
    for i, o in ipairs(visible) do
        o:ClearAllPoints()
        o:SetPoint("TOPLEFT", f, "BOTTOMLEFT", x0 + (i - 1) * (ICON_SIZE + ICON_GAP), -GAP)
    end
end

-- ---------------------------------------------------------------------------
-- Options panel: drag rows to reorder the icon row. Built lazily.
-- ---------------------------------------------------------------------------
local OPT_W, ROW_TOP, ROW_H = 320, 36, 30
local RefreshOptions   -- forward declaration (drag stop calls it)

-- Move the ability at slot `from` to slot `to` in the saved order, then re-lay-out.
local function MoveIconTo(f, from, to)
    local order = RogueResourcesDB.iconOrder
    to = math.max(1, math.min(#order, to))
    from = math.max(1, math.min(#order, from))
    if to ~= from then
        local key = table.remove(order, from)
        table.insert(order, to, key)
    end
    LayoutIcons(f)
    RefreshOptions(f)
end

local function BuildOptions(f)
    if f.options then return f.options end
    local opt = CreateFrame("Frame", nil, UIParent)
    opt:SetSize(OPT_W, ROW_TOP + #f.icons * ROW_H + 8)
    opt:SetPoint("CENTER")
    opt:SetFrameStrata("DIALOG")
    opt:SetMovable(true); opt:EnableMouse(true)
    opt:RegisterForDrag("LeftButton")
    opt:SetScript("OnDragStart", function(self) self:StartMoving() end)
    opt:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local edge = opt:CreateTexture(nil, "BACKGROUND", nil, -1)
    edge:SetPoint("TOPLEFT", -1, 1); edge:SetPoint("BOTTOMRIGHT", 1, -1)
    edge:SetColorTexture(0, 0, 0, 1)
    local bg = opt:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(opt); bg:SetColorTexture(0.06, 0.06, 0.07, 0.96)

    local title = opt:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    title:SetPoint("TOPLEFT", 12, -11)
    title:SetText("Rogue Resources — reorder & show/hide")

    local close = CreateFrame("Button", nil, opt, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    opt.rows = {}
    for i = 1, #f.icons do
        local row = CreateFrame("Frame", nil, opt)
        row:SetSize(OPT_W - 24, ROW_H - 4)
        row.slotIndex = i
        row:EnableMouse(true)
        row:RegisterForDrag("LeftButton")

        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints(row); hl:SetColorTexture(1, 1, 1, 0.10); hl:Hide()

        local grip = row:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
        grip:SetPoint("LEFT", 3, 0); grip:SetText("=")

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22); icon:SetPoint("LEFT", 20, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Show/hide toggle. Checked = show on the bar (when learned).
        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetSize(22, 22)
        check:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        check:SetScript("OnClick", function(self)
            if row.key then
                RogueResourcesDB.iconEnabled[row.key] = self:GetChecked() and true or false
                LayoutIcons(f)
            end
        end)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        label:SetPoint("RIGHT", check, "LEFT", -4, 0)
        label:SetJustifyH("LEFT")

        row:SetScript("OnEnter", function() hl:Show() end)
        row:SetScript("OnLeave", function() if not row.dragging then hl:Hide() end end)
        row:SetScript("OnDragStart", function(self)
            self.dragging = true
            hl:Show()
            self:SetFrameLevel(opt:GetFrameLevel() + 10)
            self:SetScript("OnUpdate", function(self)
                local s = opt:GetEffectiveScale()
                local _, cy = GetCursorPosition()
                self:ClearAllPoints()
                self:SetPoint("TOP", UIParent, "BOTTOMLEFT",
                    opt:GetLeft() + 12 + (OPT_W - 24) / 2, cy / s + 10)
            end)
        end)
        row:SetScript("OnDragStop", function(self)
            self:SetScript("OnUpdate", nil)
            self.dragging = false
            hl:Hide()
            local s = opt:GetEffectiveScale()
            local _, cy = GetCursorPosition()
            local offsetFromTop = opt:GetTop() - (cy / s)
            local target = math.floor((offsetFromTop - ROW_TOP) / ROW_H + 0.5) + 1
            MoveIconTo(f, self.slotIndex, target)
        end)

        row.hl, row.icon, row.label, row.check = hl, icon, label, check
        opt.rows[i] = row
    end

    f.options = opt
    return opt
end

function RefreshOptions(f)
    if not f.options then return end
    local order = RogueResourcesDB.iconOrder
    for i, row in ipairs(f.options.rows) do
        row:ClearAllPoints()   -- reset from any drag; snap back to this slot
        row:SetPoint("TOPLEFT", 12, -ROW_TOP - (i - 1) * ROW_H)
        row:SetFrameLevel(f.options:GetFrameLevel() + 1)
        local o = order[i] and f.iconByKey[order[i]]
        row.key = o and o.key or nil
        if o then
            row:Show()
            row.icon:SetTexture(o.icon:GetTexture())
            row.label:SetText(o.label .. (IconKnown(o) and "" or "  |cff808080(not learned)|r"))
            row.check:SetChecked(IsEnabled(o))
        else
            row:Hide()
        end
    end
end

local function ToggleOptions(f)
    local opt = BuildOptions(f)
    if opt:IsShown() then opt:Hide() else RefreshOptions(f); opt:Show() end
end

local function BuildUI()
    -- Anonymous (no global name) ON PURPOSE: a NAMED movable UIParent child gets
    -- captured by the client's frame-position/Edit-Mode manager (it appears in
    -- layout-local.txt) and forced back to its cached anchor on every login,
    -- overriding our own saved position. Staying nameless keeps position fully ours.
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(BAR_W, BAR_H + CP_H + GAP)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(false)   -- only interactive while unlocked
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        if p then
            RogueResourcesDB.position = { point = p, relativePoint = rp or p, x = x or 0, y = y or 0 }
            print(("|cff00ff88RogueResources:|r position saved (%d, %d)."):format(x or 0, y or 0))
        end
    end)

    -- Energy bar
    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetSize(BAR_W, BAR_H)
    bar:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
    bar:SetStatusBarTexture(BAR_TEX)
    bar:SetStatusBarColor(1.0, 0.82, 0.06)   -- energy yellow
    bar:SetMinMaxValues(0, 100)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetColorTexture(0.12, 0.10, 0.02, 0.55)   -- dark warm backing

    Gloss(bar)

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 1, 1)

    -- Combo-point bar. CP is a secret value, so we feed it straight into a StatusBar
    -- (a whitelisted sink that accepts secrets) instead of comparing it to light pips.
    -- Dividers split the fill into MAX_CP segments so it still reads as combo points.
    local cp = CreateFrame("StatusBar", nil, f)
    cp:SetSize(BAR_W, CP_H)
    cp:SetPoint("TOP", f, "TOP", 0, 0)
    cp:SetStatusBarTexture(BAR_TEX)
    cp:SetStatusBarColor(0.92, 0.20, 0.16)   -- combo red
    cp:SetMinMaxValues(0, MAX_CP)
    cp:SetValue(0)

    local cpbg = cp:CreateTexture(nil, "BACKGROUND")
    cpbg:SetAllPoints(cp)
    cpbg:SetColorTexture(0.16, 0.03, 0.03, 0.55)

    Gloss(cp)

    -- Gap-style dividers, colored like the panel so the fill reads as clean segments.
    for i = 1, MAX_CP - 1 do
        local div = cp:CreateTexture(nil, "OVERLAY")
        div:SetColorTexture(0.05, 0.05, 0.06, 1)
        div:SetSize(2, CP_H)
        div:SetPoint("CENTER", cp, "LEFT", (BAR_W / MAX_CP) * i, 0)
    end

    -- Framed backing behind both bars for a cohesive, "fits the UI" look.
    local panel = f:CreateTexture(nil, "BACKGROUND", nil, -7)
    panel:SetColorTexture(0.05, 0.05, 0.06, 0.9)
    panel:SetPoint("TOPLEFT", cp, "TOPLEFT", -1, 1)
    panel:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    Outline(panel, f)   -- outer frame
    Outline(bar, f)     -- crisp edge around each bar
    Outline(cp, f)

    -- Icon row below the bars, centered, showing only abilities you've learned:
    -- [Slice and Dice] [Evasion] [Vanish] [Kick] [Sprint] [Blade Flurry] [Adrenaline Rush].
    -- SnD shows an estimated buff timer; the rest show real cooldown swipes.
    local snd = MakeIcon(f, SpellTex(5171) or SND_FALLBACK_ICON)
    snd.key, snd.ids, snd.label = "snd", SND_LIST, SpellName(5171) or "Slice and Dice"
    -- Dim the SnD icon when its estimated duration runs out (expires is our own number).
    snd:SetScript("OnUpdate", function(self)
        if self.expires and GetTime() >= self.expires then
            self.expires = nil
            self:SetAlpha(0.35)
        end
    end)

    -- Helper: a cooldown-tracked ability icon with key/ids/label.
    local function AddCD(key, ids)
        local o = MakeIcon(f, SpellTex(ids[1]))
        o.key, o.ids, o.label = key, ids, (SpellName(ids[1]) or key)
        return o
    end
    local evasion    = AddCD("evasion", EVASION_IDS)
    local vanish     = AddCD("vanish", VANISH_IDS)
    local kick       = AddCD("kick", KICK_IDS)
    local sprint     = AddCD("sprint", SPRINT_IDS)
    local bladeflurry= AddCD("bladeflurry", BLADEFLURRY_IDS)
    local adrenaline = AddCD("adrenaline", ADRENALINE_IDS)
    local blind      = AddCD("blind", BLIND_IDS)
    local kidney     = AddCD("kidney", KIDNEY_IDS)
    local gouge      = AddCD("gouge", GOUGE_IDS)

    f.bar, f.text, f.cp, f.snd = bar, text, cp, snd
    f.icons = { snd, evasion, vanish, kick, sprint, bladeflurry, adrenaline, blind, kidney, gouge }
    f.cooldowns = { evasion, vanish, kick, sprint, bladeflurry, adrenaline, blind, kidney, gouge }
    f.iconByKey = {}
    for _, o in ipairs(f.icons) do f.iconByKey[o.key] = o end
    -- Map every rank of each tracked ability to its icon, so a cast of ANY rank triggers
    -- the right swipe (sidesteps the unreliable IsSpellKnown rank guessing).
    f.cdByCast = {}
    for _, o in ipairs(f.cooldowns) do
        for _, id in ipairs(o.ids) do f.cdByCast[id] = o end
        -- Flash once when the swipe completes (the ability is ready again).
        o.cd:SetScript("OnCooldownDone", function()
            o.running = false
            if o.flash then o.flash:Play() end
        end)
    end
    ReconcileOrder(f)
    LayoutIcons(f)   -- position only the learned abilities, in the saved order
    return f
end

-- A SEPARATE, independently movable pair of weapon buttons for poisons. Each shows the
-- equipped weapon's icon, red-pulses when that weapon is unpoisoned, and (via a secure
-- button) one-click applies a poison from your bags to that weapon.
local function BuildPoisonFrame(f)
    local pf = CreateFrame("Frame", nil, UIParent)
    pf:SetSize(ICON_SIZE * 2 + ICON_GAP, ICON_SIZE)
    pf:SetMovable(true)
    pf:SetClampedToScreen(true)

    local function MakeWeaponBtn(slot)
        local b = CreateFrame("Button", nil, pf, "SecureActionButtonTemplate")
        b:SetSize(ICON_SIZE, ICON_SIZE)
        b:RegisterForClicks("AnyDown")   -- fire once on press (both up+down = double-apply)
        b.slot = slot

        local border = b:CreateTexture(nil, "BACKGROUND")
        border:SetPoint("TOPLEFT", -1, 1); border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0, 0, 0, 1)
        local icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(b); icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local red = b:CreateTexture(nil, "OVERLAY", nil, 4)
        red:SetAllPoints(b); red:SetColorTexture(1, 0, 0, 1); red:SetBlendMode("ADD"); red:Hide()
        local pulse = red:CreateAnimationGroup(); pulse:SetLooping("BOUNCE")
        local a = pulse:CreateAnimation("Alpha")
        a:SetFromAlpha(0.15); a:SetToAlpha(0.55); a:SetDuration(0.5)
        local mins = b:CreateFontString(nil, "OVERLAY")
        mins:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE"); mins:SetPoint("BOTTOM", 0, 1)

        b.icon, b.red, b.redPulse, b.mins = icon, red, pulse, mins

        -- Right-click opens the poison-choice menu (down only, once).
        b:SetScript("PostClick", function(self, button, down)
            if button == "RightButton" and down then OpenPoisonMenu(self) end
        end)

        -- Left-drag the pair to move it while unlocked; left-click (armed only when
        -- locked) applies the poison.
        b:RegisterForDrag("LeftButton")
        b:SetScript("OnDragStart", function() if not RogueResourcesDB.locked then pf:StartMoving() end end)
        b:SetScript("OnDragStop", function()
            pf:StopMovingOrSizing()
            local p, _, rp, x, y = pf:GetPoint()
            if p then RogueResourcesDB.poisonPos = { point = p, relativePoint = rp or p, x = x or 0, y = y or 0 } end
        end)
        return b
    end

    local mh = MakeWeaponBtn(MAINHAND_SLOT)
    mh:SetPoint("LEFT", pf, "LEFT", 0, 0)
    local oh = MakeWeaponBtn(OFFHAND_SLOT)
    oh:SetPoint("LEFT", mh, "RIGHT", ICON_GAP, 0)

    f.poisonFrame, f.mhPoison, f.ohPoison = pf, mh, oh
    return pf
end

local function ApplyPoisonPosition(f)
    local pos = RogueResourcesDB.poisonPos or RR.defaults.poisonPos
    f.poisonFrame:ClearAllPoints()
    f.poisonFrame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
end

local function UpdateEnergy(f)
    local cur, max = GetEnergy()
    f.bar:SetMinMaxValues(0, max)
    f.bar:SetValue(cur)
    f.text:SetText(cur)
end

local function UpdateCP(f)
    -- SetValue is whitelisted to accept a secret value; we pass GetCP() through with
    -- no comparison, arithmetic, or boolean test, so this stays taint-safe.
    f.cp:SetValue(GetCP())
end

-- Update one weapon button: show the equipped weapon's texture, and reflect poison
-- state. `has` is the present-flag and `exp` the ms remaining (either may be secret,
-- so we guard). Poisoned -> normal icon + minutes; unpoisoned -> red tint + pulse.
local function UpdatePoisonIcon(o, on, exp, tip)
    if not o then return end
    o.icon:SetTexture(WeaponTex(o.slot) or FALLBACK_WEAPON_TEX)
    if on then
        if o.redPulse:IsPlaying() then o.redPulse:Stop() end
        o.red:Hide()
        o.icon:SetVertexColor(1, 1, 1)
        if exp and not IsSecret(exp) and exp > 0 then
            local m = math.ceil(exp / 60000)          -- ms -> whole minutes (API path)
            o.mins:SetText(m .. "m")
            o.mins:SetTextColor(m <= 2 and 1 or 1, m <= 2 and 0.5 or 1, m <= 2 and 0.2 or 1)
        elseif tip then
            local n = tonumber(tip:match("(%d+)"))    -- minutes (or charges) from the tooltip line
            if n and tip:find("[Mm]in") then
                o.mins:SetText(n .. "m")
                if n <= 2 then o.mins:SetTextColor(1, 0.5, 0.2) else o.mins:SetTextColor(1, 1, 1) end
            elseif n then
                o.mins:SetText(tostring(n))           -- charges or a bare count
                o.mins:SetTextColor(1, 1, 1)
            else
                o.mins:SetText("")
            end
        else
            o.mins:SetText("")
        end
    else
        o.icon:SetVertexColor(1, 0.35, 0.35)
        o.mins:SetText("")
        o.red:Show()
        if not o.redPulse:IsPlaying() then o.redPulse:Play() end
    end
end

local function UpdatePoisons(f)
    if not f.poisonFrame then return end
    local res = { pcall(GetWeaponEnchantInfo) }   -- ok, hasMH, mhExp, mhChg, mhID, hasOH, ohExp, ...
    -- Detect via the enchant API OR the weapon tooltip (the API doesn't report poisons
    -- on this client). Tooltip has no reliable timer, so exp comes only from the API.
    local mhTip, ohTip = WeaponEnchantText(MAINHAND_SLOT), WeaponEnchantText(OFFHAND_SLOT)
    local mhOn = (res[1] and res[2] and true) or (mhTip ~= nil)
    local ohOn = (res[1] and res[6] and true) or (ohTip ~= nil)
    UpdatePoisonIcon(f.mhPoison, mhOn, res[1] and res[3] or nil, mhTip)
    UpdatePoisonIcon(f.ohPoison, ohOn, res[1] and res[7] or nil, ohTip)
    -- Secure-frame changes (Show/Hide, attributes) are only allowed out of combat.
    if not (InCombatLockdown and InCombatLockdown()) then
        f.ohPoison:SetShown(HasWeapon(OFFHAND_SLOT))   -- hide OH when not dual-wielding
        ArmPoisonButton(f.mhPoison)
        ArmPoisonButton(f.ohPoison)
    end
end

-- Cooldowns are tracked by the ability's CAST, not by polling: polling GetSpellCooldown
-- picks up the 1.5s global cooldown too (which is SECRET in combat, so it can't be
-- filtered out), making on-GCD abilities like Kick misbehave. Instead, when a tracked
-- spell is cast we read ITS cooldown once and start the swipe. The value may be plain or
-- secret; SetCooldown accepts both. The swipe runs to completion so OnCooldownDone fires
-- the ready-flash (we never Clear() it mid-run, which would preempt the flash).
-- Display a spell's cooldown on the icon. In-combat cooldown values are SECRET and plain
-- SetCooldown rejects them, so we use the sanctioned secret-safe path:
-- C_Spell.GetSpellCooldownDuration -> a Duration object -> SetCooldownFromDurationObject.
-- Falls back to plain SetCooldown only when that API is missing (readable values).
local function SetCooldownSwipe(o, id)
    if C_Spell and C_Spell.GetSpellCooldownDuration and o.cd.SetCooldownFromDurationObject then
        local d = C_Spell.GetSpellCooldownDuration(id)
        if d then
            local ok = pcall(o.cd.SetCooldownFromDurationObject, o.cd, d)
            if ok then return true end
        end
    end
    local start, dur = GetCooldown(id)
    return pcall(o.cd.SetCooldown, o.cd, start, dur)
end

local function StartCooldownSwipe(o, castID)
    -- Defer a frame so the cooldown is registered after the cast succeeds.
    C_Timer.After(0.05, function()
        o.running = true
        SetCooldownSwipe(o, castID)
    end)
end

-- At login, catch any tracked ability ALREADY on cooldown. Uses the Duration object's
-- IsZero() to tell whether it's on cooldown (gated by HasSecretValues so a secret can't
-- throw); a secret value means we can't tell, so assume it's running and show it.
local function PollCooldown(o)
    if o.running or not o.ids then return end
    if not (C_Spell and C_Spell.GetSpellCooldownDuration) then return end
    for _, id in ipairs(o.ids) do
        local d = C_Spell.GetSpellCooldownDuration(id)
        if d then
            local ok, onCD = pcall(function()
                if d.HasSecretValues and d:HasSecretValues() then return true end
                if d.IsZero then return not d:IsZero() end
                return false
            end)
            if ok and onCD then
                o.running = true
                SetCooldownSwipe(o, id)
                return
            end
        end
    end
end

local function PollCooldowns(f)
    if not f.cooldowns then return end
    for _, o in ipairs(f.cooldowns) do PollCooldown(o) end
end

-- Start the SnD countdown from an estimated (non-secret) duration.
local function StartSnD(f, dur)
    f.snd:SetAlpha(1)
    f.snd.expires = GetTime() + dur   -- OnUpdate dims at this time
    f.snd.cd:SetCooldown(GetTime(), dur)
end

-- Reset to the inactive (dim) state; used at login before any cast.
local function StopSnD(f)
    f.snd:SetAlpha(0.35)
    f.snd.expires = nil
    if f.snd.cd.Clear then f.snd.cd:Clear() end
end

local function ApplyPosition(f)
    local pos = RogueResourcesDB.position or RR.defaults.position
    f:ClearAllPoints()
    f:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
end

local function SetLocked(f, locked)
    RogueResourcesDB.locked = locked
    f:EnableMouse(not locked)
    if locked then
        f.bar:SetStatusBarColor(1.0, 0.85, 0.10)
    else
        f.bar:SetStatusBarColor(0.10, 0.60, 1.00)   -- blue tint = "movable"
        print("|cff00ff88RogueResources:|r unlocked — drag the bars and the poison icons; /rr lock when done.")
    end
    UpdatePoisons(f)   -- (dis)arm the click-to-apply macros for the new lock state
end

-- ---------------------------------------------------------------------------
-- Wiring
-- ---------------------------------------------------------------------------
local frame
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")   -- DB is seeded here; SVs aren't ready at ADDON_LOADED
-- This client runs the retail engine: energy AND combo points are both player
-- powers delivered through UNIT_POWER_UPDATE (the classic UNIT_COMBO_POINTS event
-- doesn't exist here and errors on registration). UNIT_POWER_FREQUENT carries the
-- smooth energy-regen ticks. PLAYER_TARGET_CHANGED is kept only to redraw on
-- retarget, since CP now lives on the player, not the target.
ev:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
ev:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
-- UNIT_SPELLCAST_SUCCEEDED reports the non-secret cast spellID -- the trigger for BOTH
-- the SnD estimate and the cooldown swipes.
ev:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
-- Re-lay-out the icon row when spells are learned/leveled, so newly-learned abilities
-- (Vanish, Blade Flurry, Adrenaline Rush, ...) appear and unknown ones stay hidden.
ev:RegisterEvent("SPELLS_CHANGED")
-- Weapon poison changes: applying/removing a poison and swapping weapons.
ev:RegisterEvent("UNIT_INVENTORY_CHANGED")
ev:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
-- Belt-and-suspenders: persist the frame position on logout/reload too, so it never
-- reverts even if an OnDragStop was somehow missed.
ev:RegisterEvent("PLAYER_LOGOUT")

ev:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "PLAYER_LOGIN" then
        -- Seed the DB HERE, not at ADDON_LOADED: on this client SavedVariables aren't
        -- loaded until after ADDON_LOADED, so touching the global that early would
        -- replace it with defaults and make the client skip loading the real saved
        -- data. By PLAYER_LOGIN the saved values are present.
        RogueResourcesDB = ApplyDefaults(RR.defaults, RogueResourcesDB)
        RefreshSpellSets()   -- re-resolve names now that the spellbook is loaded
        frame = BuildUI()
        BuildPoisonFrame(frame)
        ApplyPosition(frame)
        ApplyPoisonPosition(frame)
        frame.poisonFrame:SetShown(not RogueResourcesDB.poisonHidden)
        SetLocked(frame, RogueResourcesDB.locked)
        UpdateEnergy(frame)
        UpdateCP(frame)
        StopSnD(frame)   -- start inactive until the first SnD cast
        PollCooldowns(frame)   -- catch anything already on cooldown at login
        UpdatePoisons(frame)
        -- Poll poisons periodically: expiry has no event, so keep the timer/state fresh.
        if C_Timer and C_Timer.NewTicker then
            C_Timer.NewTicker(2, function() if frame then UpdatePoisons(frame) end end)
        end
        return
    end

    if event == "PLAYER_LOGOUT" then
        if frame then
            local p, _, rp, x, y = frame:GetPoint()
            if p then RogueResourcesDB.position = { point = p, relativePoint = rp, x = x, y = y } end
        end
        return
    end

    if not frame then return end
    if event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" then
        UpdateEnergy(frame)
        UpdateCP(frame)   -- retail carries CP as a player power, so refresh both
    elseif event == "SPELLS_CHANGED" then
        LayoutIcons(frame)     -- show/hide icons as abilities are learned
        PollCooldowns(frame)   -- catch any newly-known ability already on cooldown
    elseif event == "UNIT_INVENTORY_CHANGED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        UpdatePoisons(frame)   -- poison applied/removed, or weapon swapped (icon + OH show)
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateCP(frame)
        cpEstimate = 0   -- combo points are per-target on this build; reset the count
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- arg3=spellID for SUCCEEDED (unit, castGUID, spellID); safe to index.
        if arg3 then
            -- Cooldown swipe and combo-point logic are independent -- Kidney Shot, for
            -- example, is both a tracked cooldown AND a finisher, so run both.
            local cdIcon = frame.cdByCast and frame.cdByCast[arg3]
            if cdIcon then StartCooldownSwipe(cdIcon, arg3) end
            if SND_CAST_IDS[arg3] then
                local cp = cpEstimate
                if cp < 1 then cp = 1 elseif cp > 5 then cp = 5 end
                StartSnD(frame, CP_DURATION[cp] * (RogueResourcesDB.sndMult or 1))
                cpEstimate = 0   -- finisher spent the combo points
            else
                local name = SpellName(arg3)
                if name then
                    if BUILDERS[name] then
                        cpEstimate = cpEstimate + 1
                        if cpEstimate > 5 then cpEstimate = 5 end
                    elseif FINISHERS[name] then
                        cpEstimate = 0
                    end
                end
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Slash command: /rr lock | unlock
-- ---------------------------------------------------------------------------
SLASH_ROGUERESOURCES1 = "/rr"
SlashCmdList.ROGUERESOURCES = function(msg)
    if not frame then return end
    msg = (msg or ""):lower():gsub("%s+", "")
    if msg == "lock" then
        SetLocked(frame, true)
    elseif msg == "unlock" then
        SetLocked(frame, false)
    elseif msg == "options" or msg == "config" or msg == "" then
        ToggleOptions(frame)
    elseif msg == "poison" or msg == "poisons" then
        if InCombatLockdown and InCombatLockdown() then
            print("|cff00ff88RogueResources:|r can't toggle poison icons in combat.")
        else
            RogueResourcesDB.poisonHidden = not RogueResourcesDB.poisonHidden
            frame.poisonFrame:SetShown(not RogueResourcesDB.poisonHidden)
            print("|cff00ff88RogueResources:|r poison icons " ..
                (RogueResourcesDB.poisonHidden and "hidden." or "shown."))
        end
    elseif msg:match("^sndmult") then
        local n = tonumber(msg:match("sndmult(%d+%.?%d*)"))
        if n and n > 0 then
            RogueResourcesDB.sndMult = n
            print("|cff00ff88RogueResources:|r Improved SnD multiplier set to " .. n .. " (x base duration).")
        else
            print("|cff00ff88RogueResources:|r current SnD multiplier " .. tostring(RogueResourcesDB.sndMult)
                .. ". Usage: /rr sndmult 1.45")
        end
    else
        print("|cff00ff88RogueResources:|r /rr options | unlock | lock | poison | sndmult <1.0-1.45>")
    end
end
