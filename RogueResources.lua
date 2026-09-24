-- RogueResources.lua
local addonName, RR = ...   -- private namespace shared across the addon's files

-- ---------------------------------------------------------------------------
-- Localization of the addon's own UI text (labels, buttons, tooltips). Spell and
-- poison names come localized from the game already; this table covers the strings
-- WE write. `L` starts as the English defaults; a matching locale table overrides
-- them, and any key with no translation just keeps the English text.
--
-- Note: the Improved Slice and Dice heading prefers the game's own localized talent
-- name (read live in DetectSndRank), so `improvedSnD` here is only a fallback.
-- ---------------------------------------------------------------------------
local L = {
    scale          = "Scale",
    improvedSnD    = "Improved Slice and Dice",
    auto           = "Auto",
    manual         = "Manual",
    autoNotFound   = "Auto (talent not found)",
    autoFromTalent = "Auto (from talent)",
    notFoundShort  = "not found",
    none           = "None",
    showPoison     = "Show poison icons",
    showMinimap    = "Show minimap button",
    lock           = "Lock",
    unlock         = "Unlock",
    resetPositions = "Reset positions",
    abilityIcons   = "Ability icons",
    reorderHint    = "drag to reorder  \226\128\162  checkbox to show/hide",
    notLearned     = "(not learned)",
    clickToOpen    = "Click to open options.",
    mhPoison       = "Main-hand poison",
    ohPoison       = "Off-hand poison",
    anyPoison      = "Any (first found)",
    panelDesc      = "Energy, combo points, Slice and Dice, cooldowns and weapon poisons. "
        .. "Use |cffffd100/rr unlock|r to drag the bars and poison icons into place, "
        .. "or |cffffd100/rr options|r for the standalone window.",
}

do
    local T = {
        ptBR = {
            scale = "Escala", improvedSnD = "Instantâneo e Letal aprimorado",
            manual = "Manual", autoNotFound = "Auto (talento não encontrado)",
            autoFromTalent = "Auto (do talento)", notFoundShort = "não encontrado", none = "Nenhum",
            showPoison = "Mostrar ícones de veneno", showMinimap = "Mostrar botão do minimapa",
            lock = "Travar", unlock = "Destravar", resetPositions = "Redefinir posições",
            abilityIcons = "Ícones de habilidades",
            reorderHint = "arraste para reordenar  \226\128\162  caixa para mostrar/ocultar",
            notLearned = "(não aprendida)", clickToOpen = "Clique para abrir as opções.",
            mhPoison = "Veneno da mão principal", ohPoison = "Veneno da mão secundária",
            anyPoison = "Qualquer (o primeiro)",
            panelDesc = "Energia, pontos de combo, recargas e venenos de arma para Ladinos. "
                .. "Use |cffffd100/rr unlock|r para posicionar as barras e os ícones de veneno, "
                .. "ou |cffffd100/rr options|r para a janela independente.",
        },
        esES = {
            scale = "Escala", improvedSnD = "Rebanar y trocear mejorado",
            manual = "Manual", autoNotFound = "Auto (talento no encontrado)",
            autoFromTalent = "Auto (del talento)", notFoundShort = "no encontrado", none = "Ninguno",
            showPoison = "Mostrar iconos de veneno", showMinimap = "Mostrar botón del minimapa",
            lock = "Bloquear", unlock = "Desbloquear", resetPositions = "Restablecer posiciones",
            abilityIcons = "Iconos de habilidades",
            reorderHint = "arrastra para reordenar  \226\128\162  casilla para mostrar/ocultar",
            notLearned = "(no aprendida)", clickToOpen = "Clic para abrir las opciones.",
            mhPoison = "Veneno de mano principal", ohPoison = "Veneno de mano secundaria",
            anyPoison = "Cualquiera (el primero)",
            panelDesc = "Energía, puntos de combo, reutilizaciones y venenos de arma para Pícaros. "
                .. "Usa |cffffd100/rr unlock|r para colocar las barras y los iconos de veneno, "
                .. "o |cffffd100/rr options|r para la ventana independiente.",
        },
        frFR = {
            scale = "Échelle", improvedSnD = "Trancher et lacérer amélioré",
            manual = "Manuel", autoNotFound = "Auto (talent introuvable)",
            autoFromTalent = "Auto (du talent)", notFoundShort = "introuvable", none = "Aucun",
            showPoison = "Afficher les icônes de poison", showMinimap = "Afficher le bouton de la mini-carte",
            lock = "Verrouiller", unlock = "Déverrouiller", resetPositions = "Réinitialiser les positions",
            abilityIcons = "Icônes de capacités",
            reorderHint = "glisser pour réorganiser  \226\128\162  case pour afficher/masquer",
            notLearned = "(non apprise)", clickToOpen = "Cliquez pour ouvrir les options.",
            mhPoison = "Poison de la main directrice", ohPoison = "Poison de la main secondaire",
            anyPoison = "N'importe lequel (le premier)",
            panelDesc = "Énergie, points de combo, temps de recharge et poisons d'arme pour les Voleurs. "
                .. "Utilisez |cffffd100/rr unlock|r pour placer les barres et les icônes de poison, "
                .. "ou |cffffd100/rr options|r pour la fenêtre indépendante.",
        },
        deDE = {
            scale = "Skalierung", improvedSnD = "Verbessertes Schlitzen",
            manual = "Manuell", autoNotFound = "Auto (Talent nicht gefunden)",
            autoFromTalent = "Auto (aus Talent)", notFoundShort = "nicht gefunden", none = "Keine",
            showPoison = "Giftsymbole anzeigen", showMinimap = "Minikarten-Knopf anzeigen",
            lock = "Sperren", unlock = "Entsperren", resetPositions = "Positionen zurücksetzen",
            abilityIcons = "Fähigkeitensymbole",
            reorderHint = "Ziehen zum Sortieren  \226\128\162  Kästchen zum Ein-/Ausblenden",
            notLearned = "(nicht erlernt)", clickToOpen = "Klicken, um die Optionen zu öffnen.",
            mhPoison = "Gift für die Waffenhand", ohPoison = "Gift für die Schildhand",
            anyPoison = "Beliebig (erstes gefundenes)",
            panelDesc = "Energie, Kombopunkte, Abklingzeiten und Waffengifte für Schurken. "
                .. "Mit |cffffd100/rr unlock|r die Leisten und Giftsymbole platzieren, "
                .. "oder |cffffd100/rr options|r für das eigenständige Fenster.",
        },
    }
    T.esMX = T.esES
    local loc = (GetLocale and GetLocale()) or "enUS"
    if T[loc] then for k, v in pairs(T[loc]) do L[k] = v end end
end

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

-- Poison types by internal key + rank-1 item id + English fallback (used only for the
-- menu when a type isn't carried and can't be resolved yet).
local POISON_DEFS = {
    { key = "instant",   id = 6947,  en = "Instant Poison" },
    { key = "deadly",    id = 2892,  en = "Deadly Poison" },
    { key = "wound",     id = 10918, en = "Wound Poison" },
    { key = "mindnumb",  id = 5237,  en = "Mind-numbing Poison" },
    { key = "crippling", id = 3775,  en = "Crippling Poison" },
}

-- Every poison rank's item id -> type key. We identify poisons in bags by ID (identical
-- in every language) rather than by name, which is what makes this locale-independent.
local POISON_ID_TO_KEY = {}
do
    local ranks = {
        instant   = { 6947, 6949, 6950, 8926, 8927, 8928 },
        deadly    = { 2892, 2893, 8984, 8985, 20844, 22053, 22054 },
        wound     = { 10918, 10920, 10921, 10922 },
        mindnumb  = { 5237, 6951, 9186 },
        crippling = { 3775, 3776 },
    }
    for key, ids in pairs(ranks) do for _, id in ipairs(ids) do POISON_ID_TO_KEY[id] = key end end
end

-- Strip a trailing rank numeral (" VI") so "Sofortgift VI" -> "Sofortgift" for matching.
local function PoisonBase(name) return (name:gsub("%s+[IVXLCDM]+$", "")) end

local poisonName = {}   -- key -> localized base name
local function RefreshPoisonNames()
    wipe(poisonName)
    -- Primary source: read localized names straight off the poison items you carry.
    for bag = 0, 4 do
        local slots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag))
            or (GetContainerNumSlots and GetContainerNumSlots(bag)) or 0
        for s = 1, slots do
            local id, nm
            if C_Container and C_Container.GetContainerItemInfo then
                local info = C_Container.GetContainerItemInfo(bag, s)
                if info then id = info.itemID; nm = info.itemName or (info.hyperlink and info.hyperlink:match("%[(.-)%]")) end
            end
            local key = id and POISON_ID_TO_KEY[id]
            if key and nm then poisonName[key] = PoisonBase(nm) end
        end
    end
    -- Fallback (menu display for types you aren't carrying): resolve rank 1 by id.
    for _, d in ipairs(POISON_DEFS) do
        if not poisonName[d.key] then
            local n = GetItemInfo and GetItemInfo(d.id)
            poisonName[d.key] = n and PoisonBase(n) or d.en
            if not n and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(d.id) end
        end
    end
end
RefreshPoisonNames()

-- Find a poison in the bags for the /use macro, identified by item id (locale-free). With
-- a type key it returns that type's highest-rank item name; with none, any poison.
local function FindBagPoison(typeKey)
    local bestName, bestID
    for bag = 0, 4 do
        local slots = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag))
            or (GetContainerNumSlots and GetContainerNumSlots(bag)) or 0
        for s = 1, slots do
            local id, name
            if C_Container and C_Container.GetContainerItemInfo then
                local info = C_Container.GetContainerItemInfo(bag, s)
                if info then id = info.itemID; name = info.itemName or (info.hyperlink and info.hyperlink:match("%[(.-)%]")) end
            end
            if not name and GetContainerItemLink then
                local link = GetContainerItemLink(bag, s)
                name = link and link:match("%[(.-)%]")
                id = link and tonumber(link:match("item:(%d+)"))
            end
            local key = id and POISON_ID_TO_KEY[id]
            if key and name and (not typeKey or key == typeKey) then
                if not bestName or id > (bestID or -1) then bestName, bestID = name, id end
            end
        end
    end
    return bestName
end

-- Scan a weapon's tooltip for the temporary-enchant (poison) line, matched against the
-- localized poison base names (the enchant API doesn't report poisons here). Returns text.
local function WeaponEnchantText(slot)
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local data = C_TooltipInfo.GetInventoryItem("player", slot)
        if data and data.lines then
            for _, line in ipairs(data.lines) do
                local t = line.leftText
                if t then
                    for _, d in ipairs(POISON_DEFS) do
                        local bn = poisonName[d.key]
                        if bn and t:find(bn, 1, true) then return t end
                    end
                end
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
    local choiceKey = RogueResourcesDB.poisonChoice[PoisonKey(b)]   -- stable key like "instant"
    local poison = RogueResourcesDB.locked and FindBagPoison(choiceKey) or nil
    if poison then
        b:SetAttribute("type1", "macro")
        b:SetAttribute("macrotext", "/use " .. poison .. "\n/use " .. b.slot)
    else
        b:SetAttribute("type1", nil)
    end
end

-- Right-click a weapon button to choose which poison it applies. Saved per weapon by a
-- stable key; the menu shows the client's localized poison names.
local function OpenPoisonMenu(b)
    RogueResourcesDB.poisonChoice = RogueResourcesDB.poisonChoice or {}
    local key = PoisonKey(b)
    local label = (key == "mh") and L.mhPoison or L.ohPoison
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(b, function(_, root)
            root:CreateTitle(label)
            for _, d in ipairs(POISON_DEFS) do
                local mark = (RogueResourcesDB.poisonChoice[key] == d.key) and "|cff40ff40> |r" or ""
                root:CreateButton(mark .. (poisonName[d.key] or d.en), function()
                    RogueResourcesDB.poisonChoice[key] = d.key
                    ArmPoisonButton(b)
                end)
            end
            root:CreateDivider()
            root:CreateButton(L.anyPoison, function()
                RogueResourcesDB.poisonChoice[key] = nil
                ArmPoisonButton(b)
            end)
        end)
    else   -- fallback: cycle through the types
        local cur, idx = RogueResourcesDB.poisonChoice[key], 0
        for i, d in ipairs(POISON_DEFS) do if d.key == cur then idx = i break end end
        local nextDef = POISON_DEFS[(idx % #POISON_DEFS) + 1]
        RogueResourcesDB.poisonChoice[key] = nextDef.key
        ArmPoisonButton(b)
        print("|cff00ff88RogueResources:|r " .. label .. ": " .. (poisonName[nextDef.key] or nextDef.en))
    end
end


-- ---------------------------------------------------------------------------
-- Saved settings
-- ---------------------------------------------------------------------------
RR.defaults = {
    locked      = true,
    position    = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -179 },
    poisonPos   = { point = "CENTER", relativePoint = "CENTER", x = 144, y = -179 },
    sndAuto     = true, -- auto-detect the Improved Slice and Dice talent rank (see below)
    sndMult     = 1.0,  -- manual Improved SnD multiplier, used only when sndAuto = false
    scale       = 1.0,  -- UI scale for the bars + poison frame (0.5 .. 2.0)
    minimapHidden = false, -- hide the minimap button
    minimapAngle  = 200,   -- minimap button position, degrees around the ring
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

-- Show the known+enabled icons (or ALL, if RR.showAll is on for previewing), in the
-- saved order, WRAPPED to the bar width: as many per row as fit under the energy bar,
-- overflow flows to the next row. Each row is centered. Re-run on spell/order changes.
local function LayoutIcons(f)
    for _, o in ipairs(f.icons) do o:Hide() end
    local visible = {}
    for _, key in ipairs(RogueResourcesDB.iconOrder) do
        local o = f.iconByKey[key]
        if o and (RR.showAll or (IconKnown(o) and IsEnabled(o))) then
            o:Show(); visible[#visible + 1] = o
        end
    end
    local perRow = math.max(1, math.floor((BAR_W + ICON_GAP) / (ICON_SIZE + ICON_GAP)))
    for i, o in ipairs(visible) do
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        local rowCount = math.min(perRow, #visible - row * perRow)   -- icons in this row
        local rowW = rowCount * ICON_SIZE + (rowCount - 1) * ICON_GAP
        local x0 = (BAR_W - rowW) / 2
        o:ClearAllPoints()
        o:SetPoint("TOPLEFT", f, "BOTTOMLEFT",
            x0 + col * (ICON_SIZE + ICON_GAP),
            -GAP - row * (ICON_SIZE + ICON_GAP))
    end
end

-- ---------------------------------------------------------------------------
-- Options: a canvas panel registered under Options -> AddOns (the built-in
-- Settings UI). Holds a UI-scale slider and the drag-to-reorder / show-hide
-- ability list. Built once at login so it always appears in the AddOns list.
-- ---------------------------------------------------------------------------
local OPT_W, ROW_H = 340, 30
local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.5, 2.0, 0.05

-- Improved Slice and Dice: each talent rank adds 15% duration (max 45% at rank 3). The
-- manual override list mirrors those ranks; auto-detect reads the rank straight off the
-- talent (see DetectSndRank) so most players never need to touch this.
local SND_MULT_PER_RANK = 0.15
local SND_MULTS = {
    { v = 1.00, r = "None" },
    { v = 1.15, r = "1/3" },
    { v = 1.30, r = "2/3" },
    { v = 1.45, r = "3/3" },
}
local function MultText(v) return string.format("x%.2f", v or 1) end
-- Menu label for a rank entry, e.g. "None (x1.00)" / "2/3 (x1.30)" ("None" localized).
local function MultLabel(o) return (o.r == "None" and L.none or o.r) .. string.format(" (x%.2f)", o.v) end

-- Read the Improved Slice and Dice talent rank without hardcoding tree coordinates or
-- per-rank spell IDs (this client may use a revised tree). We scan the talent tables and
-- identify the talent locale-independently: it shares the Slice and Dice ability icon, and
-- its name contains the ability name. Everything is pcall-guarded so an unexpected talent
-- API surface just yields nil (falling back to the manual multiplier). Returns rank or nil.
local function DetectSndRank()
    if type(GetNumTalentTabs) ~= "function" or type(GetTalentInfo) ~= "function" then return nil end
    local sndName = SpellName(5171)
    local sndTex  = SpellTex(5171)
    local numTabs = GetNumTalentTabs() or 0
    for tab = 1, numTabs do
        local numT = (type(GetNumTalents) == "function" and GetNumTalents(tab)) or 0
        for i = 1, numT do
            local ok, name, icon, _, _, rank = pcall(GetTalentInfo, tab, i)
            if ok and name then
                local iconStr = (type(icon) == "string") and icon:lower() or nil
                local match =
                    (sndName and name ~= sndName and name:find(sndName, 1, true) ~= nil) or
                    (iconStr and iconStr:find("slicedice", 1, true) ~= nil) or
                    (type(icon) == "number" and sndTex and icon == sndTex)
                if match then return rank or 0, name end
            end
        end
    end
    return nil
end

-- Cache the auto-detected multiplier + the game's own localized talent name on RR
-- (recomputed at login and on talent changes).
local function UpdateAutoSndMult()
    local rank, name = DetectSndRank()
    RR.autoSndMult = rank and (1 + SND_MULT_PER_RANK * rank) or nil
    RR.autoSndName = name
end

-- Heading for the Improved Slice and Dice control: prefer the game's own localized
-- talent name (when detected), else our translated fallback.
local function SndHeading()
    return RR.autoSndName or L.improvedSnD
end

-- The multiplier actually applied to a Slice and Dice cast: the auto-detected value when
-- auto mode is on and detection succeeded, otherwise the manual choice.
local function EffectiveSndMult()
    if RogueResourcesDB.sndAuto and RR.autoSndMult then return RR.autoSndMult end
    return RogueResourcesDB.sndMult or 1
end

-- Options button caption: reflects auto vs manual and what was detected.
local function SndButtonText()
    if RogueResourcesDB.sndAuto then
        return RR.autoSndMult and (L.auto .. ": " .. MultText(RR.autoSndMult)) or L.autoNotFound
    end
    return L.manual .. ": " .. MultText(RogueResourcesDB.sndMult)
end

-- Forward declarations: these are defined later in the file but referenced by the
-- options controls above them (the Lock/Reset buttons and the drag-reorder callbacks).
local RefreshOptions, SetLocked, ApplyPosition, ApplyPoisonPosition

-- Apply the saved UI scale to the bars and the (separate) poison frame together.
local function ApplyScale(f)
    local s = RogueResourcesDB.scale or 1.0
    f:SetScale(s)
    if f.poisonFrame then f.poisonFrame:SetScale(s) end
end

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

-- Reset the bars and poison frame to their default positions (fresh copies so the saved
-- tables never alias RR.defaults), then re-anchor both.
local function ResetPositions(f)
    local dp, dpp = RR.defaults.position, RR.defaults.poisonPos
    RogueResourcesDB.position  = { point = dp.point,  relativePoint = dp.relativePoint,  x = dp.x,  y = dp.y }
    RogueResourcesDB.poisonPos = { point = dpp.point, relativePoint = dpp.relativePoint, x = dpp.x, y = dpp.y }
    ApplyPosition(f)
    ApplyPoisonPosition(f)
    print("|cff00ff88RogueResources:|r positions reset to default.")
end

-- Choose the Improved Slice and Dice multiplier from the options button (context menu,
-- with a cycle fallback on API surfaces that lack MenuUtil).
local function OpenSndMenu(f, anchor)
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(anchor, function(_, root)
            root:CreateTitle(SndHeading())
            local autoLabel = L.autoFromTalent ..
                (RR.autoSndMult and (" — " .. MultText(RR.autoSndMult)) or (" — " .. L.notFoundShort))
            root:CreateButton((RogueResourcesDB.sndAuto and "|cff40ff40> |r" or "") .. autoLabel, function()
                RogueResourcesDB.sndAuto = true
                UpdateAutoSndMult()
                RefreshOptions(f)
            end)
            root:CreateDivider()
            for _, o in ipairs(SND_MULTS) do
                local on = (not RogueResourcesDB.sndAuto) and math.abs((RogueResourcesDB.sndMult or 1) - o.v) < 1e-3
                root:CreateButton((on and "|cff40ff40> |r" or "") .. MultLabel(o), function()
                    RogueResourcesDB.sndAuto = false
                    RogueResourcesDB.sndMult = o.v
                    RefreshOptions(f)
                end)
            end
        end)
    else
        -- No menu API: cycle Auto -> None -> 1/3 -> 2/3 -> 3/3 -> Auto.
        if RogueResourcesDB.sndAuto then
            RogueResourcesDB.sndAuto = false
            RogueResourcesDB.sndMult = SND_MULTS[1].v
        else
            local cur, idx = RogueResourcesDB.sndMult or 1, 1
            for i, o in ipairs(SND_MULTS) do if math.abs(o.v - cur) < 1e-3 then idx = i break end end
            if idx >= #SND_MULTS then
                RogueResourcesDB.sndAuto = true
            else
                RogueResourcesDB.sndMult = SND_MULTS[idx + 1].v
            end
        end
        RefreshOptions(f)
    end
end

-- Show/hide poison icons from the options checkbox. Toggling visibility of a frame that
-- parents secure buttons is blocked in combat, so guard and revert the check if locked.
local function TogglePoisonFromOptions(f, check)
    if InCombatLockdown and InCombatLockdown() then
        print("|cff00ff88RogueResources:|r can't toggle poison icons in combat.")
        check:SetChecked(not RogueResourcesDB.poisonHidden)   -- revert to the real state
        return
    end
    RogueResourcesDB.poisonHidden = not check:GetChecked()
    if f.poisonFrame then f.poisonFrame:SetShown(not RogueResourcesDB.poisonHidden) end
end

-- One reorder/show-hide row, parented to a view's list container. Dragging a row
-- reorders the icons; the checkbox toggles it on/off. Anchor math is relative to the
-- list so it works wherever the view lives (floating window OR the Settings page).
local function MakeOptionRow(f, view, i)
    local list = view.list
    local row = CreateFrame("Frame", nil, list)
    row:SetSize(OPT_W, ROW_H - 4)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    row.slotIndex = i
    row:EnableMouse(true)
    row:RegisterForDrag("LeftButton")

    local hl = row:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints(row); hl:SetColorTexture(1, 1, 1, 0.10); hl:Hide()

    local grip = row:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    grip:SetPoint("LEFT", 3, 0); grip:SetText("=")

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22); icon:SetPoint("LEFT", 22, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Show/hide toggle. Checked = show on the bar (when learned).
    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    check:SetScript("OnClick", function(self)
        if row.key then
            RogueResourcesDB.iconEnabled[row.key] = self:GetChecked() and true or false
            LayoutIcons(f)
            RefreshOptions(f)   -- keep the other view's checkbox in sync
        end
    end)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    label:SetPoint("RIGHT", check, "LEFT", -6, 0)
    label:SetJustifyH("LEFT")

    row:SetScript("OnEnter", function() hl:Show() end)
    row:SetScript("OnLeave", function() if not row.dragging then hl:Hide() end end)
    row:SetScript("OnDragStart", function(self)
        self.dragging = true
        hl:Show()
        self:SetFrameLevel(list:GetFrameLevel() + 20)
        self:SetScript("OnUpdate", function(self)
            local s = list:GetEffectiveScale()
            local _, cy = GetCursorPosition()
            self:ClearAllPoints()
            self:SetPoint("TOP", UIParent, "BOTTOMLEFT", list:GetLeft() + OPT_W / 2, cy / s + 10)
        end)
    end)
    row:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self.dragging = false
        hl:Hide()
        local s = list:GetEffectiveScale()
        local _, cy = GetCursorPosition()
        local offsetFromTop = list:GetTop() - (cy / s)
        local target = math.floor(offsetFromTop / ROW_H + 0.5) + 1
        MoveIconTo(f, self.slotIndex, target)
    end)

    row.hl, row.icon, row.label, row.check = hl, icon, label, check
    return row
end

-- Build the shared options body (scale slider + reorder/show-hide list) into `body`.
-- Registers a "view" so RefreshOptions can keep every open copy (the floating window
-- AND the Settings page) in sync. Returns the body height.
local function PopulateOptions(f, body)
    local view = {}
    local y = -4   -- vertical cursor (from body top); advanced as each control is placed

    -- Scale slider.
    local scaleLabel = body:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", 0, y); scaleLabel:SetText(L.scale)
    y = y - 20

    local slider = CreateFrame("Slider", nil, body, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 6, y)
    slider:SetWidth(240)
    slider:SetMinMaxValues(SCALE_MIN, SCALE_MAX)
    slider:SetValueStep(SCALE_STEP)
    slider:SetObeyStepOnDrag(true)
    if slider.Low  then slider.Low:SetText(math.floor(SCALE_MIN * 100) .. "%") end
    if slider.High then slider.High:SetText(math.floor(SCALE_MAX * 100) .. "%") end
    if slider.Text then slider.Text:SetText("") end
    local scaleVal = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    scaleVal:SetPoint("LEFT", slider, "RIGHT", 12, 0)
    slider:SetScript("OnValueChanged", function(_, value)
        if f._syncing then return end               -- ignore programmatic sync SetValue
        value = math.floor(value / SCALE_STEP + 0.5) * SCALE_STEP
        RogueResourcesDB.scale = value
        ApplyScale(f)
        RefreshOptions(f)                            -- update value text + the other view
    end)
    view.slider, view.scaleVal = slider, scaleVal
    y = y - 40

    -- Improved Slice and Dice multiplier (opens a menu of the four talent ranks). The
    -- heading uses the game's own localized talent name when detected (see RefreshOptions).
    local sndLabel = body:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sndLabel:SetPoint("TOPLEFT", 0, y); sndLabel:SetText(SndHeading())
    view.sndLabel = sndLabel
    y = y - 20
    local sndBtn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
    sndBtn:SetPoint("TOPLEFT", 0, y); sndBtn:SetSize(190, 22)
    sndBtn:SetScript("OnClick", function(self) OpenSndMenu(f, self) end)
    view.sndBtn = sndBtn
    y = y - 34

    -- Show poison icons.
    local poisonCheck = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
    poisonCheck:SetPoint("TOPLEFT", -2, y); poisonCheck:SetSize(26, 26)
    local pcl = poisonCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pcl:SetPoint("LEFT", poisonCheck, "RIGHT", 2, 0); pcl:SetText(L.showPoison)
    poisonCheck:SetScript("OnClick", function(self) TogglePoisonFromOptions(f, self) end)
    view.poisonCheck = poisonCheck
    y = y - 30

    -- Show minimap button.
    local mmCheck = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
    mmCheck:SetPoint("TOPLEFT", -2, y); mmCheck:SetSize(26, 26)
    local mml = mmCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mml:SetPoint("LEFT", mmCheck, "RIGHT", 2, 0); mml:SetText(L.showMinimap)
    mmCheck:SetScript("OnClick", function(self)
        RogueResourcesDB.minimapHidden = not self:GetChecked()
        if f.minimapButton then f.minimapButton:SetShown(not RogueResourcesDB.minimapHidden) end
    end)
    view.minimapCheck = mmCheck
    y = y - 30

    -- Lock / Reset positions.
    local lockBtn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
    lockBtn:SetPoint("TOPLEFT", 2, y); lockBtn:SetSize(110, 22)
    lockBtn:SetScript("OnClick", function()
        SetLocked(f, not RogueResourcesDB.locked)
        RefreshOptions(f)
    end)
    view.lockBtn = lockBtn
    local resetBtn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
    resetBtn:SetPoint("LEFT", lockBtn, "RIGHT", 8, 0); resetBtn:SetSize(130, 22)
    resetBtn:SetText(L.resetPositions)
    resetBtn:SetScript("OnClick", function() ResetPositions(f) end)
    y = y - 36

    -- Ability icon list (drag to reorder, checkbox to show/hide).
    local listHead = body:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    listHead:SetPoint("TOPLEFT", 0, y); listHead:SetText(L.abilityIcons)
    local listHint = body:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    listHint:SetPoint("LEFT", listHead, "RIGHT", 8, 0)
    listHint:SetText(L.reorderHint)
    y = y - 20

    local list = CreateFrame("Frame", nil, body)
    list:SetPoint("TOPLEFT", 0, y)
    list:SetSize(OPT_W, #f.icons * ROW_H)
    view.list = list
    view.rows = {}
    for i = 1, #f.icons do view.rows[i] = MakeOptionRow(f, view, i) end
    y = y - #f.icons * ROW_H

    f.optionViews = f.optionViews or {}
    f.optionViews[#f.optionViews + 1] = view

    local bodyH = -y + 8
    body:SetSize(OPT_W, bodyH)
    return bodyH, view
end

-- The embedded copy under Options -> AddOns (built at login so it always appears).
local function BuildSettingsPanel(f)
    if f.settingsPanel then return f.settingsPanel end
    local panel = CreateFrame("Frame", nil, UIParent)
    panel.name = "Rogue Resources"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Rogue Resources")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
    sub:SetJustifyH("LEFT")
    sub:SetText(L.panelDesc)

    local body = CreateFrame("Frame", nil, panel)
    body:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -22)
    PopulateOptions(f, body)

    -- Refresh the rows/slider each time the page is shown (Blizzard opens it, not us).
    panel:SetScript("OnShow", function() RefreshOptions(f) end)

    -- Register under Options -> AddOns. Prefer the modern Settings API; fall back to the
    -- legacy InterfaceOptions registration on older API surfaces.
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "Rogue Resources")
        Settings.RegisterAddOnCategory(category)
        RR.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    f.settingsPanel = panel
    RefreshOptions(f)   -- populate the just-built rows
    return panel
end

-- The standalone, draggable options window that /rr options opens. Shows the same
-- controls as the Settings -> AddOns page (both are kept in sync via RefreshOptions).
local function BuildOptions(f)
    if f.optWindow then return f.optWindow end
    local opt = CreateFrame("Frame", nil, UIParent)
    opt:SetFrameStrata("DIALOG")
    opt:SetMovable(true); opt:EnableMouse(true)
    opt:SetClampedToScreen(true)
    opt:RegisterForDrag("LeftButton")
    opt:SetScript("OnDragStart", function(self) self:StartMoving() end)
    opt:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    opt:SetPoint("CENTER")

    local edge = opt:CreateTexture(nil, "BACKGROUND", nil, -1)
    edge:SetPoint("TOPLEFT", -1, 1); edge:SetPoint("BOTTOMRIGHT", 1, -1)
    edge:SetColorTexture(0, 0, 0, 1)
    local bg = opt:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(opt); bg:SetColorTexture(0.06, 0.06, 0.07, 0.96)

    local title = opt:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("Rogue Resources")

    local close = CreateFrame("Button", nil, opt, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    local body = CreateFrame("Frame", nil, opt)
    body:SetPoint("TOPLEFT", 16, -40)
    local bodyH = PopulateOptions(f, body)
    opt:SetSize(OPT_W + 32, bodyH + 52)

    opt:SetScript("OnShow", function() RefreshOptions(f) end)
    opt:Hide()   -- new frames start shown; hide so the first /rr options opens it
    f.optWindow = opt
    return opt
end

-- Refresh EVERY built options view (floating window + Settings page) from saved state:
-- the scale slider/value and the reorder rows. `f._syncing` guards the slider so the
-- programmatic SetValue below doesn't re-fire OnValueChanged.
function RefreshOptions(f)
    if not f.optionViews then return end
    local s = RogueResourcesDB.scale or 1.0
    local order = RogueResourcesDB.iconOrder
    f._syncing = true
    for _, view in ipairs(f.optionViews) do
        -- Only push a value that actually differs, so we don't fight the thumb of the
        -- slider currently being dragged (its value already equals s after snapping).
        if view.slider and math.abs((view.slider:GetValue() or 0) - s) > 1e-4 then
            view.slider:SetValue(s)
        end
        if view.scaleVal then view.scaleVal:SetText(math.floor(s * 100 + 0.5) .. "%") end
        if view.sndLabel then view.sndLabel:SetText(SndHeading()) end
        if view.sndBtn then view.sndBtn:SetText(SndButtonText()) end
        if view.lockBtn then view.lockBtn:SetText(RogueResourcesDB.locked and L.unlock or L.lock) end
        if view.poisonCheck then view.poisonCheck:SetChecked(not RogueResourcesDB.poisonHidden) end
        if view.minimapCheck then view.minimapCheck:SetChecked(not RogueResourcesDB.minimapHidden) end
        for i, row in ipairs(view.rows) do
            row:ClearAllPoints()   -- reset from any drag; snap back to this slot
            row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
            local o = order[i] and f.iconByKey[order[i]]
            row.key = o and o.key or nil
            if o then
                row:Show()
                row.icon:SetTexture(o.icon:GetTexture())
                row.label:SetText(o.label .. (IconKnown(o) and "" or ("  |cff808080" .. L.notLearned .. "|r")))
                row.check:SetChecked(IsEnabled(o))
            else
                row:Hide()
            end
        end
    end
    f._syncing = false
end

-- /rr options: toggle the standalone floating window.
local function ToggleOptions(f)
    local opt = BuildOptions(f)
    if opt:IsShown() then opt:Hide() else RefreshOptions(f); opt:Show() end
end

-- A draggable minimap button (parented to the Minimap, positioned by angle on the ring)
-- that opens the options window. Uses the Slice and Dice icon. Position is saved.
local function BuildMinimapButton(f)
    if f.minimapButton or not Minimap then return f and f.minimapButton end
    local b = CreateFrame("Button", "RogueResourcesMinimapButton", Minimap)
    b:SetSize(31, 31); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
    b:RegisterForClicks("AnyUp")
    b:RegisterForDrag("LeftButton")

    -- Standard LibDBIcon-style layout: a small icon inset inside the tracking-border ring,
    -- so the button reads as a round minimap button rather than a bare square.
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20); bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17); icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture(SpellTex(5171) or SND_FALLBACK_ICON)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53); border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Sit on the minimap ring: radius from the minimap's own size (works whatever its
    -- scale/shape), not a hardcoded value that overlaps a larger minimap.
    local function place()
        local a = math.rad(RogueResourcesDB.minimapAngle or 200)
        local r = (Minimap:GetWidth() / 2) + 5
        b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
    end
    place()

    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local sc = Minimap:GetEffectiveScale()
            RogueResourcesDB.minimapAngle = math.deg(math.atan2(cy / sc - my, cx / sc - mx))
            place()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnClick", function() ToggleOptions(f) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Rogue Resources")
        GameTooltip:AddLine(L.clickToOpen, 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    b:SetShown(not RogueResourcesDB.minimapHidden)
    f.minimapButton = b
    return b
end

-- Register with the Addon Compartment (the button list on the minimap) if the client
-- supports it. Clicking the entry opens the options window. Registered once.
local function RegisterAddonCompartment(f)
    if RR.compartmentRegistered then return end
    if not (AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon) then return end
    AddonCompartmentFrame:RegisterAddon({
        text = "Rogue Resources",
        icon = SpellTex(5171) or SND_FALLBACK_ICON,
        notCheckable = true,
        registerForAnyClick = true,
        func = function() ToggleOptions(f) end,
    })
    RR.compartmentRegistered = true
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

function ApplyPoisonPosition(f)   -- forward-declared above (options reset button uses it)
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

function ApplyPosition(f)   -- forward-declared above (options reset button uses it)
    local pos = RogueResourcesDB.position or RR.defaults.position
    f:ClearAllPoints()
    f:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
end

function SetLocked(f, locked)   -- forward-declared above (options Lock button uses it)
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
-- Localized poison names resolve from item ids as those items get cached.
ev:RegisterEvent("GET_ITEM_INFO_RECEIVED")
-- Belt-and-suspenders: persist the frame position on logout/reload too, so it never
-- reverts even if an OnDragStop was somehow missed.
ev:RegisterEvent("PLAYER_LOGOUT")

ev:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "PLAYER_LOGIN" then
        -- Rogue-only: this addon tracks rogue resources, so on any other class we build
        -- nothing and drop all events (the folder can sit installed on an alt harmlessly).
        local _, class = UnitClass("player")
        if class ~= "ROGUE" then
            self:UnregisterAllEvents()
            return
        end
        -- Seed the DB HERE, not at ADDON_LOADED: on this client SavedVariables aren't
        -- loaded until after ADDON_LOADED, so touching the global that early would
        -- replace it with defaults and make the client skip loading the real saved
        -- data. By PLAYER_LOGIN the saved values are present.
        RogueResourcesDB = ApplyDefaults(RR.defaults, RogueResourcesDB)
        RefreshSpellSets()      -- re-resolve spell names now that the spellbook is loaded
        RefreshPoisonNames()    -- re-resolve localized poison names
        UpdateAutoSndMult()     -- detect the Improved Slice and Dice talent rank
        frame = BuildUI()
        BuildPoisonFrame(frame)
        BuildSettingsPanel(frame)   -- register the Options -> AddOns panel up front
        BuildMinimapButton(frame)
        RegisterAddonCompartment(frame)
        ApplyScale(frame)
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
        LayoutIcons(frame)      -- show/hide icons as abilities are learned
        PollCooldowns(frame)    -- catch any newly-known ability already on cooldown
        UpdateAutoSndMult()     -- talents change spells too; re-detect the SnD rank
        RefreshOptions(frame)   -- keep the options button caption current
    elseif event == "UNIT_INVENTORY_CHANGED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        UpdatePoisons(frame)   -- poison applied/removed, or weapon swapped (icon + OH show)
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        RefreshPoisonNames()   -- a poison item cached; localized names are now available
        UpdatePoisons(frame)
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
                StartSnD(frame, CP_DURATION[cp] * EffectiveSndMult())
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
        RefreshOptions(frame)
    elseif msg == "unlock" then
        SetLocked(frame, false)
        RefreshOptions(frame)
    elseif msg == "options" or msg == "config" or msg == "" then
        ToggleOptions(frame)
    elseif msg == "showall" then   -- temporary: preview every icon (resets on reload)
        RR.showAll = not RR.showAll
        LayoutIcons(frame)
        print("|cff00ff88RogueResources:|r show-all preview " .. (RR.showAll and "ON" or "OFF") .. ".")
    elseif msg == "poison" or msg == "poisons" then
        if InCombatLockdown and InCombatLockdown() then
            print("|cff00ff88RogueResources:|r can't toggle poison icons in combat.")
        else
            RogueResourcesDB.poisonHidden = not RogueResourcesDB.poisonHidden
            frame.poisonFrame:SetShown(not RogueResourcesDB.poisonHidden)
            RefreshOptions(frame)
            print("|cff00ff88RogueResources:|r poison icons " ..
                (RogueResourcesDB.poisonHidden and "hidden." or "shown."))
        end
    elseif msg == "minimap" then
        RogueResourcesDB.minimapHidden = not RogueResourcesDB.minimapHidden
        if frame.minimapButton then frame.minimapButton:SetShown(not RogueResourcesDB.minimapHidden) end
        RefreshOptions(frame)
        print("|cff00ff88RogueResources:|r minimap button " ..
            (RogueResourcesDB.minimapHidden and "hidden." or "shown."))
    elseif msg:match("^scale") then
        local n = tonumber(msg:match("scale(%d+%.?%d*)"))
        if n then
            n = math.max(SCALE_MIN, math.min(SCALE_MAX, n))
            RogueResourcesDB.scale = n
            ApplyScale(frame)
            RefreshOptions(frame)   -- reflect the new value in any open options view
            print(("|cff00ff88RogueResources:|r scale set to %d%%."):format(math.floor(n * 100 + 0.5)))
        else
            print(("|cff00ff88RogueResources:|r current scale %d%%. Usage: /rr scale 1.25 (%d-%d%%)."):format(
                math.floor((RogueResourcesDB.scale or 1) * 100 + 0.5),
                math.floor(SCALE_MIN * 100), math.floor(SCALE_MAX * 100)))
        end
    elseif msg:match("^sndmult") then
        if msg:match("auto") then
            RogueResourcesDB.sndAuto = true
            UpdateAutoSndMult()
            RefreshOptions(frame)
            print("|cff00ff88RogueResources:|r Improved SnD set to auto (" ..
                (RR.autoSndMult and MultText(RR.autoSndMult) or "talent not found") .. ").")
        else
            local n = tonumber(msg:match("sndmult(%d+%.?%d*)"))
            if n and n > 0 then
                RogueResourcesDB.sndAuto = false
                RogueResourcesDB.sndMult = n
                RefreshOptions(frame)
                print("|cff00ff88RogueResources:|r Improved SnD multiplier set to " .. n .. " (manual).")
            else
                print("|cff00ff88RogueResources:|r current SnD " ..
                    (RogueResourcesDB.sndAuto and ("auto " .. (RR.autoSndMult and MultText(RR.autoSndMult) or "(not found)"))
                        or ("manual " .. MultText(RogueResourcesDB.sndMult)))
                    .. ". Usage: /rr sndmult 1.45 | /rr sndmult auto")
            end
        end
    else
        print("|cff00ff88RogueResources:|r /rr options | unlock | lock | poison | minimap | scale <0.5-2.0> | sndmult <auto|1.0-1.45>")
    end
end
