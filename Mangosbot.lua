local Mangosbot_EventFrame = CreateFrame("Frame")
Mangosbot_EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_WHISPER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_ADDON")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
Mangosbot_EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

Mangosbot_EventFrame:Hide()

local ToolBars = {}
local GroupToolBars = {}
local CommandSeparator = "\\\\"
function SendBotCommand(text, chat, lang, channel)
    if (chat == "PARTY" and partySize() == 0) then return end
	if (chat == "SAY") then
		SendChatMessage(text, chat, lang, channel) 	
    else
        C_ChatInfo.SendAddonMessage("BOT", text, chat, channel)
    end
end
function SendBotAddonCommand(text, chat, lang, channel)
    SendBotCommand("#a "..text, chat, lang, channel)
end

function CreateToolBar(frame, y, name, buttons, x, spacing, register)
	local ok = C_ChatInfo.RegisterAddonMessagePrefix("BOT")
    if (x == nil) then x = 5 end
    if (spacing == nil) then spacing = 5 end
    if (register == nil) then register = true end

    if (frame.toolbar == nil) then
        frame.toolbar = {}
    end

    local tb = CreateFrame("Frame", "Toolbar" .. name, frame, BackdropTemplateMixin and "BackdropTemplate")
    tb:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    tb:SetWidth(frame:GetWidth() - x - 5)
    tb:SetHeight(22)
    tb:SetBackdropColor(0,0,0,1.0)
    tb:SetBackdrop({
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = false, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    tb:SetBackdropBorderColor(0,0,0,1.0)

    tb.buttons = {}
    for key, button in pairs(buttons) do
        local btn = CreateFrame("Button", "Toolbar" .. name .. key, tb, BackdropTemplateMixin and "BackdropTemplate")
        btn:SetPoint("TOPLEFT", tb, "TOPLEFT", button["index"] * (22 + spacing), 0)
        btn:SetWidth(20)
        btn:SetHeight(20)
        btn:SetBackdrop({
            edgeFile="Interface/ChatFrame/ChatFrameBackground",
            tile = false, tileSize = 16, edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropBorderColor(0, 0, 0, 0.0)
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonDown")
        btn["tooltip"] = button["tooltip"]
        btn:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT", 0, -frame:GetHeight() - 40)
          GameTooltip:SetText(btn["tooltip"])
          GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)
        btn["command"] = button["command"]
        btn["emote"] = button["emote"]
        btn["group"] = button["group"]
        btn["handler"] = button["handler"]
        btn["ToolBarButtonOnClick"] = ToolBarButtonOnClick;
        btn:SetScript("OnClick", function()
            btn["ToolBarButtonOnClick"](btn, true)
        end)

        local image = CreateFrame("Frame", "Toolbar" .. name .. key .. "Image", btn, BackdropTemplateMixin and "BackdropTemplate")
        image:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        image:SetWidth(16)
        image:SetHeight(16)
        image.texture = image:CreateTexture(nil, "BACKGROUND")
        local filename = "Interface\\Addons\\Mangosbot\\Images\\" .. button["icon"] .. ".tga"
        image.texture:SetTexture(filename)
        image.texture:SetAllPoints()
        btn.image = image

        tb.buttons[key] = btn
    end

    frame.toolbar[name] = tb
    if (register) then
        ToolBars[name] = buttons
    end
    return buttons
end

function ClickToolBarButton(toolbar, button)
    local btn = ToolBars[toolbar][button];
    ToolBarButtonOnClick(btn, false)
end

function ClickGroupToolBarButton(toolbar, button)
    local btn = GroupToolBars[toolbar][button];
    ToolBarButtonOnClick(btn, false)
end

function OnKeyBindingDown(button)
    local name = GetUnitName("target")
    local self = GetUnitName("player")
    if (CurrentBot == nil and (name == nil or not UnitExists("target") or UnitIsEnemy("target", "player") or not UnitIsPlayer("target") or name == self)) then
        ClickGroupToolBarButton("group_movement", button)
    else
        ClickToolBarButton("movement", button)
    end
end

function ToolBarButtonOnClick(btn, visual)
    if (btn["handler"] ~= nil) then
        btn["handler"]()
        return
    end

    if (visual) then
      btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1.0)
    end

    if (btn["emote"] ~= nil) then
        DoEmote(btn["emote"])
    end

    if (btn["group"]) then
        local delay = 0
        local first = true
        local combined = ""
        for key, command in pairs(btn["command"]) do
            combined = combined..command..CommandSeparator
        end
        combined = string.sub(combined, 1, string.len(combined) - 2)
        wait(0, function(combined) SendBotCommand(combined, "PARTY") end, combined)
        if (btn["tooltip"] ~= nil) then
            wait(delay + 1, function(command) SendBotCommand("#a " .. command, "PARTY") end, btn["tooltip"])
        end
    else
        local bot = GetUnitName("target")
        if (bot == nil) then bot = CurrentBot end
        local combined = ""
        for key, command in pairs(btn["command"]) do
            combined = combined..command..CommandSeparator
        end
        combined = string.sub(combined, 1, string.len(combined) - 2)
        wait(0, function(combined, bot) SendBotCommand(combined, "WHISPER", nil, bot) end, combined, bot)
    end
end

function ToggleButton(frame, toolbar, button, toggle, mixed)
    local btn = frame.toolbar[toolbar].buttons[button]
    if (toggle and mixed) then
        btn:SetBackdropBorderColor(0.2, 0.4, 0.2, 1.0)
    elseif (toggle) then
        btn:SetBackdropBorderColor(0.2, 1.0, 0.2, 1.0)
    else
        btn:SetBackdropBorderColor(0, 0, 0, 0.0)
    end
end

function EnablePositionSaving(frame, frameName, arg1)
    frame:SetScript("OnMouseDown", function() frame:StartMoving() end)
	frame:SetScript("OnMouseUp", function()
            local button = arg1
            local self = frame
            self:StopMovingOrSizing()

            if (frameopts == nil) then
                frameopts = {}
            end
            if (frameopts[frameName] == nil) then
                frameopts[frameName] = {}
            end

            local opts = frameopts[frameName]
            local from, _, to, x, y = self:GetPoint()

            opts.anchorFrom = from
            opts.anchorTo = to

            if self.is_expanded then
                if opts.anchorFrom == "TOPLEFT" or opts.anchorFrom == "LEFT" or opts.anchorFrom == "BOTTOMLEFT" then
                    opts.offsetx = x
                elseif opts.anchorFrom == "TOP" or opts.anchorFrom == "CENTER" or opts.anchorFrom == "BOTTOM" then
                    opts.offsetx = x - 151/2
                elseif opts.anchorFrom == "TOPRIGHT" or opts.anchorFrom == "RIGHT" or opts.anchorFrom == "BOTTOMRIGHT" then
                    opts.offsetx = x - 151
                end
            else
                opts.offsetx = x
            end
            opts.offsety = y
        end)

	do
		-------------------------------------------------------------------------------
		-- Restore the panel's position on the screen.
		-------------------------------------------------------------------------------
		local function Reset_Position()
            local self = frame
            if (frameopts == nil) then
                frameopts = {}
            end
            if (frameopts[frameName] == nil) then
                frameopts[frameName] = {}
            end
			local opts = frameopts[frameName]
			local FixedOffsetX = opts.offsetx

			self:ClearAllPoints()

			if opts.anchorTo == nil then
                self:SetPoint("CENTER", UIParent, "CENTER")
			else
				self:SetPoint(opts.anchorFrom, UIParent, opts.anchorTo, opts.offsetx, opts.offsety)
			end
		end

		frame:SetScript("OnShow", Reset_Position)
	end	-- do-block
end

function ResizeBotPanel(frame, width, height)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame.header:SetWidth(frame:GetWidth())
    frame.header.text:SetWidth(frame.header:GetWidth())
    for toolbarName,toolbar in pairs(ToolBars) do
        frame.toolbar[toolbarName]:SetWidth(frame:GetWidth() - 10)
    end
end

function CreateBotRoster()
    local frame = CreateFrame("Frame", "BotRoster", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:Hide()
    frame:SetWidth(170)
    frame:SetHeight(175)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:RegisterForDrag("LeftButton")

    EnablePositionSaving(frame, "BotRoster")

    frame.items = {}
    for i = 1,10 do
        local item = CreateFrame("Frame", "BotRoster_Item" .. i, frame, BackdropTemplateMixin and "BackdropTemplate")
        item:SetPoint("TOPLEFT", frame, "TOPLEFT", i * 100, 0)
        item:SetWidth(96)
        item:SetHeight(40)
        item:SetBackdropColor(0,0,0,1)
        item:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile="Interface/ChatFrame/ChatFrameBackground",
            tile = true, tileSize = 16, edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 0 }
        })
        item:SetBackdropBorderColor(0.8,0.8,0.8,1)

        item.text = item:CreateFontString("BotRoster_ItemHeader" .. i)
        item.text:SetPoint("TOPLEFT", item, "TOPLEFT", 20, 1)
        item.text:SetWidth(item:GetWidth())
        item.text:SetHeight(22)
        item.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
        item.text:SetJustifyH("LEFT")
        item.text:SetText("Click!")

        local cls = CreateFrame("Button", "BotRoster_ItemHeader" .. i .. "Image", item, BackdropTemplateMixin and "BackdropTemplate")
        cls:SetPoint("TOPLEFT", item, "TOPLEFT", 3, -3)
        cls:SetWidth(16)
        cls:SetHeight(16)
        cls:EnableMouse(true)
        cls:RegisterForClicks("LeftButtonDown")
        cls.texture = cls:CreateTexture(nil, "BACKGROUND")
        cls.texture:SetTexture("Interface\\Addons\\Mangosbot\\Images\\role_dps.tga")
        cls.texture:SetAllPoints()
        cls:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(item, "ANCHOR_TOPLEFT", 0, -item:GetHeight() - 40)
          GameTooltip:SetText("Bot Control Panel")
          GameTooltip:Show()
        end)
        cls:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)
        item.cls = cls

        CreateToolBar(item, -18, "quickbar"..i, {
            ["login"] = {
                icon = "login",
                command = {[0] = ""},
                strategy = "",
                tooltip = "Bring bot online",
                index = 0
            },
            ["logout"] = {
                icon = "logout",
                command = {[0] = ""},
                tooltip = "Logout bot",
                strategy = "",
                index = 0
            },
            ["invite"] = {
                icon = "invite",
                command = {[0] = ""},
                tooltip = "Invite to your group",
                strategy = "",
                index = 1
            },
            ["leave"] = {
                icon = "leave",
                command = {[0] = ""},
                tooltip = "Remove from group",
                strategy = "",
                index = 1
            },
            ["whisper"] = {
                icon = "whisper",
                command = {[0] = ""},
                tooltip = "Start whisper chat",
                strategy = "",
                index = 2
            },
            ["summon"] = {
                icon = "summon",
                command = {[0] = ""},
                tooltip = "Summon at meeting stone",
                strategy = "",
                index = 3
            }
        }, 20, 0, false)
        local tb = item.toolbar["quickbar"..i]
        tb:SetBackdropBorderColor(0,0,0,0.0)
        tb.buttons["login"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["logout"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["invite"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
        tb.buttons["leave"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
        tb.buttons["whisper"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 48, 0)
        tb.buttons["summon"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 32, 0)

        item:Hide()
        frame.items[i] = item
        frame.ShowRequest = false
    end

    CreateToolBar(frame, 0, "quickbar", {
        ["login_all"] = {
            icon = "login",
            command = {[0] = ""},
            strategy = "",
            tooltip = "Bring all bots online",
            index = 0
        },
        ["logout_all"] = {
            icon = "logout",
            command = {[0] = ""},
            tooltip = "Logout all bots",
            strategy = "",
            index = 1
        },
        ["invite_all"] = {
            icon = "invite",
            command = {[0] = ""},
            tooltip = "Invite all bots to your group",
            strategy = "",
            index = 2
        },
        ["leave_all"] = {
            icon = "leave",
            command = {[0] = ""},
            tooltip = "Remove all bots from group",
            strategy = "",
            index = 3
        },
        ["summon_all"] = {
            icon = "summon",
            command = {[0] = ""},
            tooltip = "Summon all bots at meeting stone",
            strategy = "",
            index = 4
        }
    }, 5, 0, false)
    frame.toolbar["quickbar"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_movement"] = CreateMovementToolBar(frame, 0, "group_movement", true, 5, 0, false)
    frame.toolbar["group_movement"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_formation"] = CreateFormationToolBar(frame, 0, "group_formation", true, 5, 0, false)
    frame.toolbar["group_formation"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_savemana"] = CreateSaveManaToolBar(frame, 0, "group_savemana", true, 5, 0, false)
    frame.toolbar["group_savemana"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_generic"] = CreateGenericNonCombatToolBar(frame, 0, "group_generic", true, 5, 0, false)
    frame.toolbar["group_generic"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_generic_combat"] = CreateGenericCombatToolBar(frame, 0, "group_generic_combat", true, 5, 0, false)
    frame.toolbar["group_generic_combat"]:SetBackdropBorderColor(0,0,0,0.0)

    return frame
end

function CreateRtiToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["rti_skull"] = {
            icon = "rti_skull",
            command = {[0] = "rti skull"},
            rti = "skull",
            tooltip = "Attack skull mark",
            index = 0,
            group = group
        },
        ["rti_cross"] = {
            icon = "rti_cross",
            command = {[0] = "rti cross"},
            rti = "cross",
            tooltip = "Attack cross mark",
            index = 1,
            group = group
        },
        ["rti_circle"] = {
            icon = "rti_circle",
            command = {[0] = "rti circle"},
            rti = "circle",
            tooltip = "Attack circle mark",
            index = 2,
            group = group
        },
        ["rti_star"] = {
            icon = "rti_star",
            command = {[0] = "rti star"},
            rti = "star",
            tooltip = "Attack star mark",
            index = 3,
            group = group
        },
        ["rti_square"] = {
            icon = "rti_square",
            command = {[0] = "rti square"},
            rti = "square",
            tooltip = "Attack square mark",
            index = 4,
            group = group
        },
        ["rti_triangle"] = {
            icon = "rti_triangle",
            command = {[0] = "rti triangle"},
            rti = "triangle",
            tooltip = "Attack triangle mark",
            index = 5,
            group = group
        },
        ["rti_diamond"] = {
            icon = "rti_diamond",
            command = {[0] = "rti diamond"},
            rti = "diamond",
            tooltip = "Attack diamond mark",
            index = 6,
            group = group
        },
        ["rti_moon"] = {
            icon = "rti_moon",
            command = {[0] = "rti moon"},
            rti = "moon",
            tooltip = "Attack moon mark",
            index = 7,
            group = group
        }
    }, x, spacing, register)
end

function CreateRtiCcToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["rti_skull"] = {
            icon = "cc_skull",
            command = {[0] = "rti cc skull"},
            rti_cc = "skull",
            tooltip = "CC skull mark",
            index = 0,
            group = group
        },
        ["rti_cross"] = {
            icon = "cc_cross",
            command = {[0] = "rti cc cross"},
            rti_cc = "cross",
            tooltip = "CC cross mark",
            index = 1,
            group = group
        },
        ["rti_circle"] = {
            icon = "cc_circle",
            command = {[0] = "rti cc circle"},
            rti_cc = "circle",
            tooltip = "CC circle mark",
            index = 2,
            group = group
        },
        ["rti_star"] = {
            icon = "cc_star",
            command = {[0] = "rti cc star"},
            rti_cc = "star",
            tooltip = "CC star mark",
            index = 3,
            group = group
        },
        ["rti_square"] = {
            icon = "cc_square",
            command = {[0] = "rti cc square"},
            rti_cc = "square",
            tooltip = "CC square mark",
            index = 4,
            group = group
        },
        ["rti_triangle"] = {
            icon = "cc_triangle",
            command = {[0] = "rti cc triangle"},
            rti_cc = "triangle",
            tooltip = "CC triangle mark",
            index = 5,
            group = group
        },
        ["rti_diamond"] = {
            icon = "cc_diamond",
            command = {[0] = "rti cc diamond"},
            rti_cc = "diamond",
            tooltip = "CC diamond mark",
            index = 6,
            group = group
        },
        ["rti_moon"] = {
            icon = "cc_moon",
            command = {[0] = "rti cc moon"},
            rti_cc = "moon",
            tooltip = "CC moon mark",
            index = 7,
            group = group
        }
    }, x, spacing, register)
end

function CreateMovementToolBar(frame, y, name, group, x, spacing, register)
    local tb = {
        ["follow_master"] = {
            icon = "follow_master",
            command = {[0] = "#a follow ?"},
            strategy = "follow",
            tooltip = "Follow me",
            index = 0,
            group = group,
            emote = "follow"
        },
        ["stay"] = {
            icon = "stay",
            command = {[0] = "#a stay ?"},
            strategy = "stay",
            tooltip = "Stay in place",
            index = 1,
            group = group,
            emote = "wait"
        },
        ["free"] = {
            icon = "free",
            command = {[0] = "#a free ?"},
            strategy = "free",
            tooltip = "Move around freely",
            index = 2,
            group = group
        }
    }
    local index = 3
    if (not group) then
        tb["runaway"] = {
            icon = "flee",
            command = {[0] = "#a runaway ?"},
            strategy = "runaway",
            tooltip = "Run away from mobs",
            index = index,
            group = group
        }
        index = index + 1
    end

        tb["guard"] = {
            icon = "guard",
        command = {[0] = "#a guard ?"},
            strategy = "guard",
            tooltip = "Guard pre-set place",
            index = index,
            group = group
        }
        index = index + 1
		
    if (not group) then		
        tb["grind"] = {
            icon = "grind",
            command = {[0] = "#a nc ~grind, ?"},
            strategy = "grind",
            tooltip = "Aggresive mode (grinding)",
            index = index,
            group = group
        }
        index = index + 1
    end

    tb["passive"] = {
        icon = "passive",
        command = {[0] = "#a nc ~passive,?", [1] = "#a co ~passive,?", [2] = "#a reset", [3] = "#a co ?"},
        strategy = "passive",
        tooltip = "Passive mode",
        index = index,
        group = group
    }
    index = index + 1

    tb["flee_passive"] = {
        icon = "flee_passive",
        command = {[0] = "#a flee ?"},
        strategy = "",
        tooltip = "Flee",
        index = index,
        group = group,
        emote = "flee"
    }
    index = index + 1

    if (group) then
        tb["loot"] = {
            icon = "loot",
            command = {[0] = "d add all loot", [1] = "d loot"},
            strategy = "",
            tooltip = "Loot everything",
            index = index,
            group = group
        }
        index = index + 1
        tb["attack"] = {
            icon = "dps",
            command = {[0] = "#a co -passive,+dps assist", [1] = "#a nc -passive,+dps assist", [2] = "#a @tank co -dps assist,+tank assist", [3] = "#a @tank nc -dps assist,+tank assist", [4] = "#a queue attack"},
            strategy = "",
            tooltip = "Attack my target",
            index = index,
            group = group
        }
        index = index + 1
        tb["tank attack"] = {
            icon = "tank_assist",
            command = {[0] = "#a @dps co -dps assist", [1] = "#a @dps nc -dps assist", [2] = "#a @tank attack"},
            strategy = "",
            tooltip = "tank attack",
            index = index,
            group = group
        }
        index = index + 1
    end

    return CreateToolBar(frame, -y, name, tb, x, spacing, register)
end

function CreateFormationToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["near"] = {
            icon = "formation_near",
            command = {[0] = "formation near"},
            formation = "near",
            tooltip = "Follow me",
            index = 0,
            group = group
        },
        ["melee"] = {
            icon = "formation_melee",
            command = {[0] = "formation melee"},
            formation = "melee",
            tooltip = "Melee formation",
            index = 1,
            group = group
        },
        ["arrow"] = {
            icon = "formation_arrow",
            command = {[0] = "formation arrow"},
            formation = "arrow",
            tooltip = "Tank first, dps last",
            index = 2,
            group = group
        },
        ["far"] = {
            icon = "formation_far",
            command = {[0] = "formation far"},
            formation = "far",
            tooltip = "Maintain a distance",
            index = 3,
            group = group
        },
        ["chaos"] = {
            icon = "formation_chaos",
            command = {[0] = "formation chaos"},
            formation = "chaos",
            tooltip = "Move freely",
            index = 4,
            group = group
        }
    }, x, spacing, register)
end

function CreateStanceToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["near"] = {
            icon = "stance_near",
            command = {[0] = "stance near"},
            stance = "near",
            tooltip = "Default stance",
            index = 0,
            group = group
        },
        ["tank"] = {
            icon = "stance_tank",
            command = {[0] = "stance tank"},
            stance = "tank",
            tooltip = "Off-tank stance",
            index = 1,
            group = group
        },
        ["turnback"] = {
            icon = "stance_turnback",
            command = {[0] = "stance turnback"},
            stance = "turnback",
            tooltip = "Tank the enemy away from party",
            index = 2,
            group = group
        },
        ["behind"] = {
            icon = "stance_behind",
            command = {[0] = "stance behind"},
            stance = "behind",
            tooltip = "Attack from behind (melee)",
            index = 3,
            group = group
        }
    }, x, spacing, register)
end

function CreateGenericNonCombatToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["food"] = {
            icon = "food",
            command = {[0] = "#a nc ~food,?"},
            strategy = "food",
            tooltip = "Use food and drinks",
            index = 0,
            group = group
        },
        ["loot"] = {
            icon = "loot",
            command = {[0] = "#a nc ~loot,?"},
            strategy = "loot",
            tooltip = "Enable looting",
            index = 1,
            group = group
        },
        ["gather"] = {
            icon = "gather",
            command = {[0] = "#a nc ~gather,?"},
            strategy = "gather",
            tooltip = "Gather herbs, ore, etc.",
            index = 2,
            group = group
        },
        ["reveal"] = {
            icon = "stats",
            command = {[0] = "#a nc ~reveal,?"},
            strategy = "reveal",
            tooltip = "Reveal gathering nodes",
            index = 3
        },
        ["mount"] = {
            icon = "mount",
            command = {[0] = "#a nc ~mount,?"},
            strategy = "mount",
            tooltip = "Mount up when possible",
            index = 4
        },		
        ["travel"] = {
            icon = "travel",
            command = {[0] = "#a nc ~travel,?"},
            strategy = "travel",
            tooltip = "Move to distant locations",
            index = 5
        }
    }, x, spacing, register)
end

function CreateGenericCombatToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["potions"] = {
            icon = "potions",
            command = {[0] = "#a react ~potions,?"},
            strategy = "potions",
            tooltip = "Use health and mana potions",
            index = 0,
            group = group
        },
        ["cast_time"] = {
            icon = "cast_time",
            command = {[0] = "#a co ~cast time,?"},
            strategy = "cast time",
            tooltip = "Do not cast long spells on almost dead targets",
            index = 1,
            group = group
        },
        ["mark_rti"] = {
            icon = "mark_rti",
            command = {[0] = "#a co ~mark rti,?"},
            strategy = "mark rti",
            tooltip = "Mark current target with raid icon",
            index = 2,
            group = group
        },
        ["ads"] = {
            icon = "ads",
            command = {[0] = "#a co ~ads,?", [1] = "#a nc ~ads,?"},
            strategy = "ads",
            tooltip = "Flee if ads might be pulled",
            index = 3,
            group = group
        },
        ["conserve_mana"] = {
            icon = "conserve_mana",
            command = {[0] = "#a co ~conserve mana,?"},
            strategy = "conserve mana",
            tooltip = "Reduce mana usage at cost of DPS",
            index = 4,
            group = group
        },
        ["cc"] = {
            icon = "cc",
            command = {[0] = "#a co ~cc,?"},
            strategy = "cc",
            tooltip = "Use crowd control abilities",
            index = 5,
            group = group
        }
    }, x, spacing, register)
end

function CreateSaveManaToolBar(frame, y, name, group, x, spacing, register)
    local buttons = {};
    for i = 1, 5 do
        buttons["savemana"..i] = {
            icon = "savemana"..i,
            command = {[0] = "save mana "..i},
            tooltip = "Save mana level: "..(i>1 and "#"..i or "disabled"),
            index = i - 1,
            group = group,
            savemana = i
        }
    end
    return CreateToolBar(frame, -y, name, buttons, x, spacing, register)
end

function StartChat()
    local editBox = _G["ChatFrameEditBox"]
    editBox:Show()
    editBox:SetFocus()
    local name = GetUnitName("target")
    if (name == nil) then name = CurrentBot end
    editBox:SetText("/w " .. name .. " ")
end

function CreateSelectedBotPanel()	
    local frame = CreateFrame("Frame", "SelectedBotPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:Hide()
    frame:SetWidth(170)
    frame:SetHeight(155)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0.5,0.1,0.7,1)
    frame:RegisterForDrag("LeftButton")

    frame.header = CreateFrame("Frame", "SelectedBotPanelHeader", frame, BackdropTemplateMixin and "BackdropTemplate")
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -16)
    frame.header:SetWidth(frame:GetWidth())
    frame.header:SetHeight(22)
    frame.header:SetBackdropColor(0.5,0.1,0.7,1)
    frame.header:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 2, right = 2, top = 2, bottom = 0 }
    })
    frame.header:SetBackdropBorderColor(0.5,0.1,0.7,1)

    frame.header.text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
    frame.header.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, 0)
    frame.header.text:SetWidth(frame.header:GetWidth())
    frame.header.text:SetHeight(22)
    frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
    frame.header.text:SetJustifyH("LEFT")
    frame.header.text:SetText("Click!")

    frame.header.role = CreateFrame("Frame", "SelectedBotPanelHeaderRole", frame.header, BackdropTemplateMixin and "BackdropTemplate")
    frame.header.role:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    frame.header.role:SetWidth(16)
    frame.header.role:SetHeight(16)
    frame.header.role.texture = frame.header.role:CreateTexture(nil, "BACKGROUND")
    frame.header.role.texture:SetTexture("Interface/Addons/Mangosbot/Images/role_dps.tga")
    frame.header.role.texture:SetAllPoints()

    EnablePositionSaving(frame, "SelectedBotPanel")

    local y = 25
    CreateMovementToolBar(frame, y, "movement", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "actions", {
        ["stats"] = {
            icon = "stats",
            command = {[0] = "stats"},
            strategy = "",
            tooltip = "Tell stats (XP, money, etc.)",
            index = 0
        },
        ["whisper"] = {
            icon = "whisper",
            command = {[0] = ""},
            tooltip = "Start whisper chat",
            strategy = "",
            handler = StartChat,
            index = 1
        },
        ["loot"] = {
            icon = "loot",
            command = {[0] = "d add all loot", [1] = "d loot"},
            strategy = "",
            tooltip = "Loot everything",
            index = 2
        },
        ["set_guard"] = {
            icon = "set_guard",
            command = {[0] = "position guard set"},
            strategy = "",
            tooltip = "Set guard position",
            index = 3
        },
        ["release"] = {
            icon = "release",
            command = {[0] = "release"},
            strategy = "",
            tooltip = "Release spirit",
            index = 4
        },
        ["revive"] = {
            icon = "revive",
            command = {[0] = "revive", [1] = "d revive from corpse"},
            strategy = "",
            tooltip = "Revive at Spirit Healer",
            index = 5
        },
        ["talk"] = {
            icon = "talk",
            command = {[0] = "talk", [1] = "accept *"},
            strategy = "",
            tooltip = "Talk",
            index = 6
        }
    })

    y = y + 25
    CreateToolBar(frame, -y, "inventory", {
        ["los"] = {
            icon = "los",
            command = {[0] = "los gos"},
            strategy = "",
            tooltip = "Show nearby game objects",
            index = 0
        },
        ["count"] = {
            icon = "count",
            command = {[0] = "c"},
            strategy = "",
            tooltip = "Show inventory",
            index = 1
        },
        ["bank"] = {
            icon = "bank",
            command = {[0] = "bank"},
            strategy = "",
            tooltip = "Show bank",
            index = 2
        },
        ["spells"] = {
            icon = "spells",
            command = {[0] = "spells +"},
            strategy = "",
            tooltip = "Show tradeskill",
            index = 3
        },
        ["equip"] = {
            icon = "equip",
            command = {[0] = "e ?"},
            strategy = "",
            tooltip = "Show equipment",
            index = 4
        },		
        ["mail"] = {
            icon = "mail",
            command = {[0] = "mail ?"},
            strategy = "",
            tooltip = "Show mail",
            index = 4
        },
        ["help"] = {
            icon = "help",
            command = {[0] = "help"},
            strategy = "",
            tooltip = "Help",
            index = 5
        }
    })

    y = y + 25
    CreateToolBar(frame, -y, "rpg", {
        ["rpg"] = {
            icon = "rpg",
            command = {[0] = "#a nc ~rpg,?"},
            strategy = "rpg",
            tooltip = "Rpg with nearby npcs",
            index = 0
        },
        ["rpg quest"] = {
            icon = "rpg_quest",
            command = {[0] = "#a nc ~rpg quest,?"},
            strategy = "rpg quest",
            tooltip = "Talk to quest npc's",
            index = 1
        },
        ["rpg vendor"] = {
            icon = "rpg_vendor",
            command = {[0] = "#a nc ~rpg vendor,?"},
            strategy = "rpg vendor",
            tooltip = "Talk to vendors",
            index = 2
        },
        ["rpg explore"] = {
            icon = "rpg_explore",
            command = {[0] = "#a nc ~rpg explore,?"},
            strategy = "rpg explore",
            tooltip = "Talk to inns, flightmasters",
            index = 3
        },
        ["rpg maintenance"] = {
            icon = "rpg_maintenance",
            command = {[0] = "#a nc ~rpg maintenance,?"},
            strategy = "rpg maintenance",
            tooltip = "Talk to armorers, trainers",
            index = 4
        },
        ["rpg player"] = {
            icon = "rpg_player",
            command = {[0] = "#a nc ~rpg player,?"},
            strategy = "rpg player",
            tooltip = "Duel/trade players",
            index = 5
        },
        ["rpg craft"] = {
            icon = "rpg_craft",
            command = {[0] = "#a nc ~rpg craft,?"},
            strategy = "rpg craft",
            tooltip = "Craft items, casts spells",
            index = 6
        },
        ["rpg bg"] = {
            icon = "rpg_bg",
            command = {[0] = "#a nc ~rpg bg,?"},
            strategy = "rpg bg",
            tooltip = "Queue for bg at battlemasters",
            index = 7
        }			
    })	

    y = y + 25
    CreateFormationToolBar(frame, y, "formation", false, 5, 5, true)

    y = y + 25
    CreateStanceToolBar(frame, y, "stance", false, 5, 5, true)

    y = y + 25
    CreateSaveManaToolBar(frame, y, "savemana", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "loot", {
        ["ll_equip"] = {
            icon = "ll_equip",
            command = {[0] = "ll ~equip"},
            loot = "equip",
            tooltip = "Loot equipment upgrades",
            index = 0
        },
        ["ll_qyest"] = {
            icon = "ll_quest",
            command = {[0] = "ll ~quest"},
            loot = "quest",
            tooltip = "Loot quest items",
            index = 1
        },
        ["ll_skill"] = {
            icon = "ll_skill",
            command = {[0] = "ll ~skill"},
            loot = "skill",
            tooltip = "Loot tradeskill items",
            index = 2
        },		
        ["ll_disenchant"] = {
            icon = "ll_disenchant",
            command = {[0] = "ll ~disenchant"},
            loot = "disenchant",
            tooltip = "Loot items for disenchanting",
            index = 3
        },
        ["ll_use"] = {
            icon = "ll_use",
            command = {[0] = "ll ~use"},
            loot = "use",
            tooltip = "Loot consumables/reagents",
            index = 4
        },
        ["ll_vendor"] = {
            icon = "ll_vendor",
            command = {[0] = "ll ~vendor"},
            loot = "vendor",
            tooltip = "Loot items for money",
            index = 5
        },		
        ["ll_trash"] = {
            icon = "ll_trash",
            command = {[0] = "ll ~trash"},
            loot = "trash",
            tooltip = "Loot useless items",
            index = 6
        }
    })

    y = y + 25
    CreateToolBar(frame, -y, "attack_type", {
        ["tank_aoe"] = {
            icon = "tank_assist",
            command = {[0] = "#a nc -dps assist,+tank assist,?", [1] = "#a co -dps assist,+tank assist,?"},
            strategy = "tank assist",
            tooltip = "Grab all aggro",
            index = 0
        },
        ["dps_assist"] = {
            icon = "dps_assist",
            command = {[0] = "#a nc -tank assist,+dps assist,?", [1] = "#a co -tank assist,+dps assist,?"},
            strategy = "dps assist",
            tooltip = "Assist others",
            index = 1
        },
        ["close"] = {
            icon = "close",
            command = {[0] = "#a co ~close,?"},
            strategy = "close",
            tooltip = "Melee combat",
            index = 2
        },
        ["ranged"] = {
            icon = "ranged",
            command = {[0] = "#a co ~ranged,?"},
            strategy = "ranged",
            tooltip = "Ranged combat",
            index = 3
        },
        ["threat"] = {
            icon = "threat",
            command = {[0] = "#a co ~threat,?"},
            strategy = "threat",
            tooltip = "Keep threat level low",
            index = 4
        },
		["wait_for_attack"] = {
            icon = "wait_for_attack",
            command = {[0] = "#a co ~wait for attack,?"},
            strategy = "wait for attack",
            tooltip = "Wait X seconds before attacking. To change the amount of seconds use 'wait for attack time X'",
            index = 5
        },
		["pull"] = {
            icon = "pull",
            command = {[0] = "#a co ~pull,?"},
            strategy = "pull",
            tooltip = "Set this bot to pull using the 'pull command'. Recommended to only have one bot with pull enabled.",
            index = 6
        },
		["pull back"] = {
            icon = "pull_back",
            command = {[0] = "#a co ~pull back,?"},
            strategy = "pull back",
            tooltip = "Pull back monsters back to the location where the 'pull command' was given.",
            index = 7
        }
    })

    y = y + 25
    CreateRtiToolBar(frame, y, "rti", false, 5, 5, true)

    y = y + 25
    CreateRtiCcToolBar(frame, y, "rti cc", false, 5, 5, true)

    y = y + 25
    CreateGenericNonCombatToolBar(frame, y, "generic", false, 5, 5, true)

    y = y + 25
    CreateGenericCombatToolBar(frame, y, "generic_combat", false, 5, 5, true)

    y = y + 25
 CreateToolBar(frame, -y, "CLASS_DRUID", {
        ["bear"] = {
            icon = "bear",
            command = {[0] = "#a co +tank feral,+close,+pull,+tank assist,-ranged,-stealth,-behind,?", [1] = "#a nc +tank feral,+tank assist,-stealth,?", [2] = "#a de +tank feral,?", [3] = "#a react +tank feral,?"},
            strategy = "tank feral",
            tooltip = "Bear mode (tank)",
            index = 0
        },
        ["cat"] = {
            icon = "cat",
            command = {[0] = "#a co +dps feral,+dps assist,+close,+stealth,+behind,-ranged,-pull,?", [1] = "#a nc +dps feral,+dps assist,+stealth,?", [2] = "#a de +dps feral,?", [3] = "#a react +dps feral,?"},
            strategy = "dps feral",
            tooltip = "Cat mode (melee)",
            index = 1
        },
        ["caster"] = {
            icon = "caster",
            command = {[0] = "#a co +balance,+dps assist,+ranged,-close,-pull,-stealth,?", [1] = "#a nc +balance,+dps assist,-stealth,?", [2] = "#a de +balance,?", [3] = "#a react +balance,?"},
            strategy = "balance",
            tooltip = "Balance mode (caster)",
            index = 2
        },
        ["heal"] = {
            icon = "heal",
            command = {[0] = "#a co +restoration,+dps assist,+ranged,-close,-pull,-stealth,?", [1] = "#a nc +restoration,+dps assist,-stealth,?", [2] = "#a de +restoration,?", [3] = "#a react +restoration,?"},
            strategy = "restoration",
            tooltip = "Restoration mode (healer)",
            index = 3
        },
		["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 4
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities",
            index = 5
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 6
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (poisons and curses)",
            index = 7
        },
		["offheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~offheal,?", [1] = "#a nc ~offheal,?"},
            strategy = "offheal",
            tooltip = "Use healing abilities to heal other party members while being in dps mode",
            index = 8
        },
		["stealth"] = {
            icon = "caster",
            command = {[0] = "#a co ~stealth,?", [1] = "#a nc ~stealth,?"},
            strategy = "stealth",
            tooltip = "Use stealth abilities",
            index = 9
        },
		["preheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~preheal,?"},
            strategy = "preheal",
            tooltip = "Heal the party before receiving melee damage",
            index = 10
        }
    })
    CreateToolBar(frame, -y, "CLASS_HUNTER", {
	    ["bm"] = {
            icon = "bear",
            command = {[0] = "#a co +beast mastery,?", [1] = "#a nc +beast mastery,?", [2] = "#a de +beast mastery,?", [3] = "#a react +beast mastery,?"},
            strategy = "beast mastery",
            tooltip = "Beast mastery mode (dps)",
            index = 0
        },
        ["ms"] = {
            icon = "dps",
            command = {[0] = "#a co +marksmanship,?", [1] = "#a nc +marksmanship,?", [2] = "#a de +marksmanship,?", [3] = "#a react +marksmanship,?"},
            strategy = "marksmanship",
            tooltip = "Marksmanship mode (dps)",
            index = 1
        },
        ["caster"] = {
            icon = "caster",
            command = {[0] = "#a co +survival,?", [1] = "#a nc +survival,?", [2] = "#a de +survival,?", [3] = "#a react +survival,?"},
            strategy = "survival",
            tooltip = "Survival mode (dps)",
            index = 2
        },
        ["aoe"] = {
            icon = "aoe",
            command = {[0] = "#a co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
		["stings"] = {
            icon = "dps_debuff",
            command = {[0] = "#a co ~sting,?"},
            strategy = "sting",
            tooltip = "Auto pick stings",
            index = 6
        },
		["aspects"] = {
            icon = "arcane",
            command = {[0] = "#a co ~aspect,?", [1] = "#a nc ~aspect,?"},
            strategy = "aspect",
            tooltip = "Auto pick aspects",
            index = 7
        },
        ["pet"] = {
            icon = "pet",
            command = {[0] = "#a co ~pet,?", [1] = "#a nc ~pet,?"},
            strategy = "pet",
            tooltip = "Use pet",
            index = 8
        }
    })
    CreateToolBar(frame, -y, "CLASS_MAGE", {
        ["arcane"] = {
            icon = "arcane",
            command = {[0] = "#a co +arcane,?", [1] = "#a nc +arcane,?", [2] = "#a de +arcane,?", [3] = "#a react +arcane,?"},
            strategy = "arcane",
            tooltip = "Arcane mode (caster)",
            index = 0
        },
        ["fire"] = {
            icon = "fire",
            command = {[0] = "#a co +fire,?", [1] = "#a nc +fire,?", [2] = "#a de +fire,?", [3] = "#a react +fire,?"},
            strategy = "fire",
            tooltip = "Fire mode (caster)",
            index = 1
        },
        ["frost"] = {
            icon = "frost",
            command = {[0] = "#a co +frost,?", [1] = "#a nc +frost,?", [2] = "#a de +frost,?", [3] = "#a react +frost,?"},
            strategy = "frost",
            tooltip = "Frost mode (caster)",
            index = 2
        },
		["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (curses)",
            index = 5
        }
    })
    CreateToolBar(frame, -y, "CLASS_PALADIN", {
        ["retribution"] = {
            icon = "dps",
            command = {[0] = "#a co +retribution,+dps assist,+close,-ranged,-pull,?", [1] = "#a nc +retribution,+dps assist,?", [2] = "#a de +retribution,?", [3] = "#a react +retribution,?"},
            strategy = "retribution",
            tooltip = "Retribution mode (melee)",
            index = 0
        },
        ["protection"] = {
            icon = "tank",
            command = {[0] = "#a co +protection,+close,+pull,+tank assist,-ranged,?", [1] = "#a nc +protection,+tank assist,?", [2] = "#a de +protection,?", [3] = "#a react +protection,?"},
            strategy = "protection",
            tooltip = "Protection mode (tank)",
            index = 1
        },
        ["holy"] = {
            icon = "heal",
            command = {[0] = "#a co +holy,+ranged,+dps assist,-close,-pull,?", [1] = "#a nc +holy,+dps assist,?", [2] = "#a de +holy,?", [3] = "#a react +holy,?"},
            strategy = "holy",
            tooltip = "Holy mode (healer)",
            index = 2
        },
		["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (curses)",
            index = 6
        },
		["offheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~offheal,?", [1] = "#a nc ~offheal,?"},
            strategy = "offheal",
            tooltip = "Use healing abilities to heal other party members while being in dps mode",
            index = 7
        },
		["aura"] = {
            icon = "bmana",
            command = {[0] = "#a co ~aura,?", [1] = "#a nc ~aura,?"},
            strategy = "aura",
            tooltip = "Auto pick aura",
            index = 8
        },
		["blessing"] = {
            icon = "bspeed",
            command = {[0] = "#a co ~blessing,?", [1] = "#a nc ~blessing,?"},
            strategy = "blessing",
            tooltip = "Auto pick blessings",
            index = 9
        },
		["preheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~preheal,?"},
            strategy = "preheal",
            tooltip = "Heal the party before receiving melee damage",
            index = 10
        }
    })
    CreateToolBar(frame, -y, "CLASS_PRIEST", {
        ["discipline"] = {
            icon = "heal",
            command = {[0] = "#a co +discipline,?", [1] = "#a nc +discipline,?", [2] = "#a de +discipline,?", [3] = "#a react +discipline,?"},
            strategy = "discipline",
            tooltip = "Discipline mode (healer)",
            index = 0
        },
        ["holy"] = {
            icon = "holy",
            command = {[0] = "#a co +holy,?", [1] = "#a nc +holy,?", [2] = "#a de +holy,?", [3] = "#a react +holy,?"},
            strategy = "holy",
            tooltip = "Holy mode (healer)",
            index = 1
        },
        ["shadow"] = {
            icon = "shadow",
            command = {[0] = "#a co +shadow,?", [1] = "#a nc +shadow,?", [2] = "#a de +shadow,?", [3] = "#a react +shadow,?"},
            strategy = "shadow",
            tooltip = "Shadow mode (dps)",
            index = 2
        },
		["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (curses)",
            index = 6
        },
		["offheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~offheal,?", [1] = "#a nc ~offheal,?"},
            strategy = "offheal",
            tooltip = "Use healing abilities to heal other party members while being in dps mode",
            index = 7
        },
		["offdps"] = {
            icon = "dps",
            command = {[0] = "#a co ~offdps,?", [1] = "#a nc ~offdps,?"},
            strategy = "offdps",
            tooltip = "Use dps abilities to attack enemies while being on healer mode",
            index = 8
        },
		["preheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~preheal,?"},
            strategy = "preheal",
            tooltip = "Heal the party before receiving melee damage",
            index = 9
        }
    })
    CreateToolBar(frame, -y, "CLASS_ROGUE", {
        ["combat"] = {
            icon = "dps",
            command = {[0] = "#a co +combat,?", [1] = "#a nc +combat,?", [2] = "#a de +combat,?", [3] = "#a react +combat,?"},
            strategy = "combat",
            tooltip = "Combat mode (melee)",
            index = 0
        },
		["assassination"] = {
            icon = "dps",
            command = {[0] = "#a co +assassination,?", [1] = "#a nc +assassination,?", [2] = "#a de +assassination,?", [3] = "#a react +assassination,?"},
            strategy = "assassination",
            tooltip = "Assassination mode (melee)",
            index = 1
        },
		["subtlety"] = {
            icon = "dps",
            command = {[0] = "#a co +subtlety,?", [1] = "#a nc +subtlety,?", [2] = "#a de +subtlety,?", [3] = "#a react +subtlety,?"},
            strategy = "subtlety",
            tooltip = "Subtlety mode (melee)",
            index = 2
        },
        ["aoe"] = {
            icon = "aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["poisons"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~poisons,?", [1] = "#a nc ~poisons,?"},
            strategy = "poisons",
            tooltip = "Auto pick poisons",
            index = 5
        },
		["stealth"] = {
            icon = "caster",
            command = {[0] = "#a co ~stealth,?", [1] = "#a nc ~stealth,?"},
            strategy = "stealth",
            tooltip = "Use stealth abilities",
            index = 6
        }
    })
    CreateToolBar(frame, -y, "CLASS_SHAMAN", {
        ["caster"] = {
            icon = "caster",
            command = {[0] = "#a co +elemental,+ranged,-close,?", [1] = "#a nc +elemental,?", [2] = "#a de +elemental,?", [3] = "#a react +elemental,?"},
            strategy = "elemental",
            tooltip = "Elemental mode (caster)",
            index = 0
        },
        ["heal"] = {
            icon = "heal",
            command = {[0] = "#a co +restoration,+threat,+ranged,-close,?", [1] = "#a nc +restoration,?", [2] = "#a de +restoration,?", [3] = "#a react +restoration,?"},
            strategy = "restoration",
            tooltip = "Restoration mode (healer)",
            index = 1
        },
        ["melee"] = {
            icon = "dps",
            command = {[0] = "#a co +enhancement,-ranged,+close,?", [1] = "#a nc +enhancement,?", [2] = "#a de +enhancement,?", [3] = "#a react +enhancement,?"},
            strategy = "enhancement",
            tooltip = "Enhancement mode (melee)",
            index = 2
        },
        ["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (poison and disease)",
            index = 6
        },
		["offheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~offheal,?", [1] = "#a nc ~offheal,?"},
            strategy = "offheal",
            tooltip = "Use healing abilities to heal other party members while being in dps mode",
            index = 7
        },
		["totems"] = {
            icon = "totems",
            command = {[0] = "#a co ~totems,?", [1] = "#a nc ~totems,?"},
            strategy = "totems",
            tooltip = "Auto pick totems",
            index = 8
        },
		["preheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~preheal,?"},
            strategy = "preheal",
            tooltip = "Heal the party before receiving melee damage",
            index = 9
        }
    })
    CreateToolBar(frame, -y, "CLASS_WARLOCK", {
        ["affliction"] = {
            icon = "dps",
            command = {[0] = "#a co +affliction,?", [1] = "#a nc +affliction,?", [2] = "#a de +affliction,?", [3] = "#a react +affliction,?"},
            strategy = "affliction",
            tooltip = "Affliction mode (caster)",
            index = 0
        },
        ["demonology"] = {
            icon = "dps",
            command = {[0] = "#a co +demonology,?", [1] = "#a nc +demonology,?", [2] = "#a de +demonology,?", [3] = "#a react +demonology,?"},
            strategy = "demonology",
            tooltip = "Demonology mode (caster)",
            index = 1
        },
        ["destruction"] = {
            icon = "dps",
            command = {[0] = "#a co +destruction,?", [1] = "#a nc +destruction,?", [2] = "#a de +destruction,?", [3] = "#a react +destruction,?"},
            strategy = "destruction",
            tooltip = "Destruction mode (caster)",
            index = 2
        },
        ["aoe"] = {
            icon = "aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
        ["dps_debuff"] = {
            icon = "dps_debuff",
            command = {[0] = "#a co ~curse,?"},
            strategy = "curse",
            tooltip = "Auto pick curses",
            index = 5
        },
        ["pet"] = {
            icon = "pet",
            command = {[0] = "#a co ~pet,?", [1] = "#a nc ~pet,?"},
            strategy = "pet",
            tooltip = "Auto pick pets",
            index = 6
        }
    })
    CreateToolBar(frame, -y, "CLASS_WARRIOR", {
        ["arms"] = {
            icon = "dps",
            command = {[0] = "#a co +arms,+dps assist,-pull,?", [1] = "#a nc +arms,+dps assist,?", [2] = "#a de +arms,?", [3] = "#a react +arms,?"},
            strategy = "arms",
            tooltip = "Arms mode (melee)",
            index = 0
        },
        ["fury"] = {
            icon = "grind",
            command = {[0] = "#a co +fury,+dps assist,-pull,?", [1] = "#a nc +fury,+dps assist,?", [2] = "#a de +fury,?", [3] = "#a react +fury,?"},
            strategy = "fury",
            tooltip = "Fury mode (melee)",
            index = 1
        },
        ["protection"] = {
            icon = "tank",
            command = {[0] = "#a co +protection,+tank assist,+pull,?", [1] = "#a nc +protection,+tank assist,?", [2] = "#a de +protection,?", [3] = "#a react +protection,?"},
            strategy = "protection",
            tooltip = "Protection mode (tank)",
            index = 2
        },
        ["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
        ["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
    })

    
    y = y + 25
    CreateToolBar(frame, -y, "CLASS_PALADIN_BLESSING", {
        ["bmana"] = {
            icon = "bmana",
            command = {[0] = "#a co +blessing might,?", [1] = "#a nc +blessing might,?"},
            strategy = "blessing might",
            tooltip = "Blessing of Might",
            index = 0
        },
        ["bhealth"] = {
            icon = "bhealth",
            command = {[0] = "#a co +blessing wisdom,?", [1] = "#a nc +blessing wisdom,?"},
            strategy = "blessing wisdom",
            tooltip = "Blessing of Wisdom",
            index = 1
        },
        ["bdps"] = {
            icon = "bdps",
            command = {[0] = "#a co +blessing kings,?", [1] = "#a nc +blessing kings,?"},
            strategy = "blessing kings",
            tooltip = "Blessing of Kings",
            index = 2
        },
        ["barmor"] = {
            icon = "barmor",
            command = {[0] = "#a co +blessing sanctuary,?", [1] = "#a nc +blessing sanctuary,?"},
            strategy = "blessing sanctuary",
            tooltip = "Blessing of Sanctuary",
            index = 3
        },
        ["blight"] = {
            icon = "bmana",
            command = {[0] = "#a co +blessing light,?", [1] = "#a nc +blessing light,?"},
            strategy = "blessing light",
            tooltip = "Blessing of Light",
            index = 4
        },
        ["bstats"] = {
            icon = "bhealth",
            command = {[0] = "#a co +blessing salvation,?", [1] = "#a nc +blessing salvation,?"},
            strategy = "blessing salvation",
            tooltip = "Blessing of salvation",
            index = 5
        }
    })
	CreateToolBar(frame, -y, "CLASS_SHAMAN_TOTEM_EARTH", {
		["stoneclaw"] = {
            icon = "totems",
            command = {[0] = "#a co +totem earth stoneclaw,?", [1] = "#a nc +totem earth stoneclaw,?"},
            strategy = "totem earth stoneclaw",
            tooltip = "Stoneclaw totem (earth)",
            index = 0
        },
		["stoneskin"] = {
            icon = "totems",
            command = {[0] = "#a co +totem earth stoneskin,?", [1] = "#a nc +totem earth stoneskin,?"},
            strategy = "totem earth stoneskin",
            tooltip = "Stoneskin totem (earth)",
            index = 1
        },
		["earthbind"] = {
            icon = "totems",
            command = {[0] = "#a co +totem earth earthbind,?", [1] = "#a nc +totem earth earthbind,?"},
            strategy = "totem earth earthbind",
            tooltip = "Earthbind totem (earth)",
            index = 2
        },
		["strength"] = {
            icon = "totems",
            command = {[0] = "#a co +totem earth strength,?", [1] = "#a nc +totem earth strength,?"},
            strategy = "totem earth strength",
            tooltip = "Strength of Earth totem (earth)",
            index = 3
        },
		["tremor"] = {
            icon = "totems",
            command = {[0] = "#a co +totem earth tremor,?", [1] = "#a nc +totem earth tremor,?"},
            strategy = "totem earth tremor",
            tooltip = "Tremor totem (earth)",
            index = 4
        }
	})
	CreateToolBar(frame, -y, "CLASS_ROGUE_POISON_MAIN", {
		["deadly"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison main deadly,?", [1] = "#a nc +poison main deadly,?"},
            strategy = "poison main deadly",
            tooltip = "Deadly Poison (main hand)",
            index = 0
        },
		["crippling"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison main crippling,?", [1] = "#a nc +poison main crippling,?"},
            strategy = "poison main crippling",
            tooltip = "Crippling Poison (main hand)",
            index = 1
        },
		["mind"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison main mind,?", [1] = "#a nc +poison main mind,?"},
            strategy = "poison main mind",
            tooltip = "Mind-Numbing Poison (main hand)",
            index = 2
        },
		["instant"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison main instant,?", [1] = "#a nc +poison main instant,?"},
            strategy = "poison main instant",
            tooltip = "Instant Poison (main hand)",
            index = 3
        },
		["wound"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison main wound,?", [1] = "#a nc +poison main wound,?"},
            strategy = "poison main wound",
            tooltip = "Wound Poison (main hand)",
            index = 4
        },
		["anesthetic"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison main anesthetic,?", [1] = "#a nc +poison main anesthetic,?"},
            strategy = "poison main anesthetic",
            tooltip = "Anesthetic Poison (main hand)",
            index = 5
        }
	})
	CreateToolBar(frame, -y, "CLASS_WARLOCK_CURSES", {
		["agony"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +curse agony,?"},
            strategy = "curse agony",
            tooltip = "Curse of Agony",
            index = 0
        },
		["doom"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +curse doom,?"},
            strategy = "curse doom",
            tooltip = "Curse of Doom",
            index = 1
        },
		["elements"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +curse elements,?"},
            strategy = "curse elements",
            tooltip = "Curse of the Elements",
            index = 2
        },
		["recklessness"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +curse recklessness,?"},
            strategy = "curse recklessness",
            tooltip = "Curse of Recklessness",
            index = 3
        },
		["weakness"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +curse weakness,?"},
            strategy = "curse weakness",
            tooltip = "Curse of Weakness",
            index = 4
        },
		["tongues"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +curse tongues,?"},
            strategy = "curse tongues",
            tooltip = "Curse of Tongues",
            index = 5
        },
		["shadow"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +curse shadow,?"},
            strategy = "curse shadow",
            tooltip = "Curse of Shadow",
            index = 6
        }
    })
    
	CreateToolBar(frame, -y, "CLASS_HUNTER_STINGS", {
		["serpent"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +sting serpent,?"},
            strategy = "sting serpent",
            tooltip = "Serpent Sting",
            index = 0
        },
		["viper"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +sting viper,?"},
            strategy = "sting viper",
            tooltip = "Viper Sting",
            index = 1
        },
		["scorpid"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +sting scorpid,?"},
            strategy = "sting scorpid",
            tooltip = "Scorpid Sting",
            index = 2
        }
	})
    y = y + 25
    CreateToolBar(frame, -y, "CLASS_PALADIN_AURA", {
	    ["barmor"] = {
            icon = "barmor",
            command = {[0] = "#a co +aura devotion,?", [1] = "#a nc +aura devotion,?"},
            strategy = "aura devotion",
            tooltip = "Devotion aura",
            index = 0
        },
        ["baoe"] = {
            icon = "aoe",
            command = {[0] = "#a co +aura retribution,?", [1] = "#a nc +aura retribution,?"},
            strategy = "aura retribution",
            tooltip = "Retribution aura",
            index = 1
        },
		["concentration"] = {
            icon = "bmana",
            command = {[0] = "#a co +aura concentration,?", [1] = "#a nc +aura concentration,?"},
            strategy = "aura concentration",
            tooltip = "Concentration aura",
            index = 2
        },
        ["rshadow"] = {
            icon = "rshadow",
            command = {[0] = "#a co +aura shadow,?", [1] = "#a nc +aura shadow,?"},
            strategy = "aura shadow",
            tooltip = "Shadow resistance aura",
            index = 3
        },
        ["rfrost"] = {
            icon = "frost",
            command = {[0] = "#a co +aura frost,?", [1] = "#a nc +aura frost,?"},
            strategy = "aura frost",
            tooltip = "Frost resistance aura",
            index = 4
        },
        ["rfire"] = {
            icon = "fire",
            command = {[0] = "#a co +aura fire,?", [1] = "#a nc +aura fire,?"},
            strategy = "aura fire",
            tooltip = "Fire resistance aura",
            index = 5
        },
        ["crusader"] = {
            icon = "bspeed",
            command = {[0] = "#a co +aura crusader,?", [1] = "#a nc +aura crusader,?"},
            strategy = "aura crusader",
            tooltip = "Crusader aura",
            index = 6
        },
        ["sanctity"] = {
            icon = "bdps",
            command = {[0] = "#a co +aura sanctity,?", [1] = "#a nc +aura sanctity,?"},
            strategy = "aura sanctity",
            tooltip = "Sanctity aura",
            index = 7
        }
    })
	CreateToolBar(frame, -y, "CLASS_SHAMAN_TOTEM_FIRE", {
		["nova"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire nova,?", [1] = "#a nc +totem fire nova,?"},
            strategy = "totem fire nova",
            tooltip = "Fire Nova totem (fire)",
            index = 0
        },
		["flametongue"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire flametongue,?", [1] = "#a nc +totem fire flametongue,?"},
            strategy = "totem fire flametongue",
            tooltip = "Flametongue totem (fire)",
            index = 1
        },
		["resistance"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire resistance,?", [1] = "#a nc +totem fire resistance,?"},
            strategy = "totem fire resistance",
            tooltip = "Frost Resistance totem (fire)",
            index = 2
        },
		["magma"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire magma,?", [1] = "#a nc +totem fire magma,?"},
            strategy = "totem fire magma",
            tooltip = "Magma totem (fire)",
            index = 3
        },
		["searing"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire searing,?", [1] = "#a nc +totem fire searing,?"},
            strategy = "totem fire searing",
            tooltip = "Searing totem (fire)",
            index = 4
        }
    })
	CreateToolBar(frame, -y, "CLASS_ROGUE_POISON_OFF", {
		["deadly"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison off deadly,?", [1] = "#a nc +poison off deadly,?"},
            strategy = "poison off deadly",
            tooltip = "Deadly Poison (off hand)",
            index = 0
        },
		["crippling"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison off crippling,?", [1] = "#a nc +poison off crippling,?"},
            strategy = "poison off crippling",
            tooltip = "Crippling Poison (off hand)",
            index = 1
        },
		["mind"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison off mind,?", [1] = "#a nc +poison off mind,?"},
            strategy = "poison off mind",
            tooltip = "Mind-Numbing Poison (off hand)",
            index = 2
        },
		["instant"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison off instant,?", [1] = "#a nc +poison off instant,?"},
            strategy = "poison off instant",
            tooltip = "Instant Poison (off hand)",
            index = 3
        },
		["wound"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison off wound,?", [1] = "#a nc +poison off wound,?"},
            strategy = "poison off wound",
            tooltip = "Wound Poison (off hand)",
            index = 4
        },
		["anesthetic"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison off anesthetic,?", [1] = "#a nc +poison off anesthetic,?"},
            strategy = "poison off anesthetic",
            tooltip = "Anesthetic Poison (off hand)",
            index = 5
        }
	})
	CreateToolBar(frame, -y, "CLASS_WARLOCK_PETS", {
		["imp"] = {
            icon = "pet",
            command = {[0] = "#a co +pet imp,?", [1] = "#a nc +pet imp,?"},
            strategy = "pet imp",
            tooltip = "Use Imp",
            index = 0
        },
		["voidwalker"] = {
            icon = "pet",
            command = {[0] = "#a co +pet voidwalker,?", [1] = "#a nc +pet voidwalker,?"},
            strategy = "pet voidwalker",
            tooltip = "Use Voidwalker",
            index = 1
        },
		["succubus"] = {
            icon = "pet",
            command = {[0] = "#a co +pet succubus,?", [1] = "#a nc +pet succubus,?"},
            strategy = "pet succubus",
            tooltip = "Use Succubus",
            index = 2
        },
		["felhunter"] = {
            icon = "pet",
            command = {[0] = "#a co +pet felhunter,?", [1] = "#a nc +pet felhunter,?"},
            strategy = "pet felhunter",
            tooltip = "Use Felhunter",
            index = 3
        },
		["felguard"] = {
            icon = "pet",
            command = {[0] = "#a co +pet felguard,?", [1] = "#a nc +pet felguard,?"},
            strategy = "pet felguard",
            tooltip = "Use Felguard",
            index = 4
        }
	})
    CreateToolBar(frame, -y, "CLASS_HUNTER_ASPECTS", {
		["hawk"] = {
            icon = "totems",
            command = {[0] = "#a co +aspect hawk,?", [1] = "#a nc +aspect hawk,?"},
            strategy = "aspect hawk",
            tooltip = "Aspect of the Hawk",
            index = 0
        },
		["monkey"] = {
            icon = "totems",
            command = {[0] = "#a co +aspect monkey,?", [1] = "#a nc +aspect monkey,?"},
            strategy = "aspect monkey",
            tooltip = "Aspect of the Monkey",
            index = 1
        },
		["cheetah"] = {
            icon = "totems",
            command = {[0] = "#a co +aspect cheetah,?", [1] = "#a nc +aspect cheetah,?"},
            strategy = "aspect cheetah",
            tooltip = "Aspect of the Cheetah",
            index = 2
        },
		["pack"] = {
            icon = "totems",
            command = {[0] = "#a co +aspect pack,?", [1] = "#a nc +aspect pack,?"},
            strategy = "aspect pack",
            tooltip = "Aspect of the Pack",
            index = 3
        },
		["beast"] = {
            icon = "totems",
            command = {[0] = "#a co +aspect beast,?", [1] = "#a nc +aspect beast,?"},
            strategy = "aspect beast",
            tooltip = "Aspect of the Beast",
            index = 4
        },
		["wild"] = {
            icon = "totems",
            command = {[0] = "#a co +aspect wild,?", [1] = "#a nc +aspect wild,?"},
            strategy = "aspect wild",
            tooltip = "Aspect of the Wild",
            index = 5
        },
		["viper"] = {
            icon = "totems",
            command = {[0] = "#a co +aspect viper,?", [1] = "#a nc +aspect viper,?"},
            strategy = "aspect viper",
            tooltip = "Aspect of the Viper",
            index = 6
        },
		["dragonhawk"] = {
            icon = "totems",
            command = {[0] = "#a co +aspect dragonhawk,?", [1] = "#a nc +aspect dragonhawk,?"},
            strategy = "aspect dragonhawk",
            tooltip = "Aspect of the Dragonhawk",
            index = 7
        }
	})

	y = y + 25
	CreateToolBar(frame, -y, "CLASS_SHAMAN_TOTEM_WATER", {
		["cleansing"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water cleansing,?", [1] = "#a nc +totem water cleansing,?"},
            strategy = "totem water cleansing",
            tooltip = "Cleansing totem (water)",
            index = 0
        },
		["resistance"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water resistance,?", [1] = "#a nc +totem water resistance,?"},
            strategy = "totem water resistance",
            tooltip = "Fire Resistance totem (water)",
            index = 1
        },
		["healing"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water healing,?", [1] = "#a nc +totem water healing,?"},
            strategy = "totem water healing",
            tooltip = "Healing Stream totem (water)",
            index = 2
        },
		["mana"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water mana,?", [1] = "#a nc +totem water mana,?"},
            strategy = "totem water mana",
            tooltip = "Mana Spring totem (water)",
            index = 3
        },
		["poison"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water poison,?", [1] = "#a nc +totem water poison,?"},
            strategy = "totem water poison",
            tooltip = "Poison Cleansing totem (water)",
            index = 4
        }
	})

	y = y + 25
	CreateToolBar(frame, -y, "CLASS_SHAMAN_TOTEM_AIR", {
		["grace"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air grace,?", [1] = "#a nc +totem air grace,?"},
            strategy = "totem air grace",
            tooltip = "Grace of Air totem (air)",
            index = 0
        },
		["grounding"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air grounding,?", [1] = "#a nc +totem air grounding,?"},
            strategy = "totem air grounding",
            tooltip = "Grounding totem (air)",
            index = 1
        },
		["resistance"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air resistance,?", [1] = "#a nc +totem air resistance,?"},
            strategy = "totem air resistance",
            tooltip = "Nature Resistance totem (air)",
            index = 2
        },
		["tranquil"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air tranquil,?", [1] = "#a nc +totem air tranquil,?"},
            strategy = "totem air tranquil",
            tooltip = "Tranquil Air totem (air)",
            index = 3
        },
		["windfury"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air windfury,?", [1] = "#a nc +totem air windfury,?"},
            strategy = "totem air windfury",
            tooltip = "Windfury totem (air)",
            index = 4
        },
		["windwall"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air windwall,?", [1] = "#a nc +totem air windwall,?"},
            strategy = "totem air windwall",
            tooltip = "Windwall totem (air)",
            index = 5
        },
		["wrath"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air wrath,?", [1] = "#a nc +totem air wrath,?"},
            strategy = "totem air wrath",
            tooltip = "Wrath of Air totem (air)",
            index = 6
        }
	})
    frame:SetHeight(y + 25)
    return frame
end

function SetFrameColor(frame, class)
    local color = RAID_CLASS_COLORS[class]
    if (color == nil) then
        color = {r = 0.5, g = 0.1, b = 0.7};
    end
    frame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
    frame.header:SetBackdropColor(color.r, color.g, color.b, 1.0)
    frame.header:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
end

local total = 0
function BotDebugTimer(self, elapsed)
    local elapsed = arg1
    if (elapsed) then
        total = total + elapsed
        if total >= 1 then
            local name = GetUnitName("target")
            if (name) then
                SendBotAddonCommand("debug action", "WHISPER", nil, name)
            end
            total = 0
        end
    end
end

local actionHistory = {}
local MaxDebugLines = 60
function CreateBotDebugPanel()
    local frame = CreateFrame("Frame", "BotDebugPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:Hide()
    frame:SetWidth(300)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0.5,0.1,0.7,1)
    frame:RegisterForDrag("LeftButton")

    frame.header = CreateFrame("Frame", "SelectedBotPanelHeader", frame, BackdropTemplateMixin and "BackdropTemplate")
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.header:SetWidth(frame:GetWidth())
    frame.header:SetHeight(22)
    frame.header:SetBackdropColor(0.5,0.1,0.7,1)
    frame.header:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 2, right = 2, top = 2, bottom = 0 }
    })
    frame.header:SetBackdropBorderColor(0.5,0.1,0.7,1)

    frame.header.text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
    frame.header.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, 0)
    frame.header.text:SetWidth(frame.header:GetWidth())
    frame.header.text:SetHeight(22)
    frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
    frame.header.text:SetJustifyH("LEFT")
    frame.header.text:SetText("Debug Info")

    local lineSize = 12
    for i = 1,MaxDebugLines do
        local text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
        text:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5 -i * lineSize)
        text:SetWidth(frame:GetWidth())
        text:SetHeight(18)
        text:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
        text:SetJustifyH("LEFT")
        text:SetText("Line"..i)
        frame["text"..i] = text

        actionHistory[i] = ""
    end
    frame:SetHeight(MaxDebugLines * lineSize + 30)

    EnablePositionSaving(frame, "BotDebugPanel")

    frame:SetScript("OnUpdate", BotDebugTimer)

    return frame
end

function UpdateBotDebugPanel(message, sender)
    local splitted = splitString2(message, "|")
    local length = tablelength(splitted)
    local filtered = {}
    for i = 1, length do
        local row = splitted[i];
        if (string.find(row, BotDebugFilter)) then
            table.insert(filtered, row)
        end
    end
    
    length = tablelength(filtered)
    BotDebugPanel.header.text:SetText("Debug Info "..length..", Filter: "..BotDebugFilter)
    
    if (length > MaxDebugLines) then length = MaxDebugLines end

    local first = MaxDebugLines - length + 1

    for i = 1, first-1 do
        local line = BotDebugPanel["text"..i]
        local source = BotDebugPanel["text"..(length + i)]
        line:SetText(source:GetText())
    end

    for i = first, MaxDebugLines do
        local idx = i - first + 1
        local name = trim2(filtered[idx])
        local line = BotDebugPanel["text"..i]
        line:SetText(name)
    end
end

botTable = {}
SelectedBotPanel = CreateSelectedBotPanel();
BotRoster = CreateBotRoster();
BotDebugPanel = CreateBotDebugPanel();
CurrentBot = nil
LastBot = nil
BotDebugFilter = ""

local function fmod(a,b)
    return a - math.floor(a/b)*b
end

function QueryBotParty()
    wait(0.1, function() SendBotCommand("#a ll ?"..CommandSeparator.."#a formation ?"..CommandSeparator.."#a stance ?"..CommandSeparator.."#a co ?"..CommandSeparator.."#a nc ?"..CommandSeparator.."#a save mana ?"..CommandSeparator.."#a react ?", "PARTY") end)
end

function QuerySelectedBot(name)
    wait(0.1, function() SendBotCommand("#a formation ?"..CommandSeparator.."#a stance ?"..CommandSeparator.."#a ll ?"..CommandSeparator.."#a co ?"..CommandSeparator.."#a nc ?"..CommandSeparator.."#a save mana ?"..CommandSeparator.."#a rti ?"..CommandSeparator.."#a react ?", "WHISPER", nil, name) end)
end

function UpdateBotList(delay)
    wait(delay, function() SendChatMessage(".bot list", "GUILD") end)
end

Mangosbot_EventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)		
    if (event == "PLAYER_TARGET_CHANGED") then
        local name = GetUnitName("target")
        local self = GetUnitName("player")
        if (CurrentBot == nil and (name == nil or not UnitExists("target") or UnitIsEnemy("target", "player") or not UnitIsPlayer("target"))) then
            SelectedBotPanel:Hide()
        else
            if (CurrentBot ~= name) then CurrentBot = nil end
            if (LastBot ~= name and (UnitPlayerOrPetInParty("target") or UnitPlayerOrPetInRaid("target"))) then
                QuerySelectedBot(name) 
				end
        end
		
		LastBot = name
    end

    if (event == "CHAT_MSG_SYSTEM" or event == "GROUP_ROSTER_UPDATE") then
        local message = arg1
        if (OnSystemMessage(message) or (event == "GROUP_ROSTER_UPDATE" and BotRoster:IsVisible())) then
            if (BotRoster.ShowRequest==true) then
                BotRoster:Show()
                BotRoster.ShowRequest = false
            end
            for i = 1,10 do
                BotRoster.items[i]:Hide()
            end
            local index = 1
            local x = 5
            local width = 0
            local height = 0
            local y = 5
            local colCount = 2
            local allBots = ""
            local first = true
            local allBotsLoggedIn = true
            local allBotsLoggedOut = true
            local allBotsInParty = true
            local atLeastOneBotInParty = false
            for key,bot in pairs(botTable) do
                if (index > 10) then 
                    index = 1 
                    y = 5
                end
                local item = BotRoster.items[index]
                if (first) then first = false
                else allBots = allBots .. "," end
                allBots = allBots .. key

                item.text:SetText(key)
                item.cls["key"] = key
                item.cls:SetScript("OnClick", function()
                    if (CurrentBot == item.cls["key"]) then
                        CurrentBot = nil
                        SelectedBotPanel:Hide()
                    else
                        CurrentBot = item.cls["key"]
                        QuerySelectedBot(CurrentBot)
                    end
                end)

				if (bot["class"] ~= nil) then
                local filename = "Interface\\Addons\\Mangosbot\\Images\\cls_" .. string.lower(bot["class"]) ..".tga"
                item.cls.texture:SetTexture(filename)

                local color = RAID_CLASS_COLORS[string.upper(bot["class"])]
                item.text:SetTextColor(color.r, color.g, color.b, 1.0)
				end	

                item:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", x, -y)

                local loginBtn = item.toolbar["quickbar"..index].buttons["login"]
                loginBtn:Hide()
                local logoutBtn = item.toolbar["quickbar"..index].buttons["logout"]
                logoutBtn:Hide()
                local inviteBtn = item.toolbar["quickbar"..index].buttons["invite"]
                inviteBtn:Show()
                local leaveBtn = item.toolbar["quickbar"..index].buttons["leave"]
                leaveBtn:Hide()
                local whisperBtn = item.toolbar["quickbar"..index].buttons["whisper"]
                whisperBtn:Hide()
                local summonBtn = item.toolbar["quickbar"..index].buttons["summon"]
                summonBtn:Hide()
                if (bot["online"]) then
                    item:SetBackdropBorderColor(0.6, 0.6, 0.2, 1.0)
                    logoutBtn:Show()
                    whisperBtn:Show()
                    summonBtn:Show()
                    local inParty = false
                    for i = 1,5 do
                        if (partyName(i) == key) then
                            inviteBtn:Hide()
                            leaveBtn:Show()
                            atLeastOneBotInParty = true
                            inParty = true
                            item:SetBackdropBorderColor(0.2, 0.8, 0.8, 1.0)
                        end
                    end
                    if (not inParty) then allBotsInParty = false end
                    allBotsLoggedOut = false
                else
                    item:SetBackdropBorderColor(0.2,0.2,0.2,1)
                    loginBtn:Show()
                    inviteBtn:Hide()
                    allBotsLoggedIn = false
                end
                loginBtn["key"] = key
                loginBtn:SetScript("OnClick", function()
                    SendBotCommand(".bot add " .. loginBtn["key"], "SAY")
                end)
                logoutBtn["key"] = key
                logoutBtn:SetScript("OnClick", function()
                    SendBotCommand(".bot rm " .. logoutBtn["key"], "SAY")
                end)
                inviteBtn["key"] = key
                inviteBtn:SetScript("OnClick", function()
                    InviteUnit(inviteBtn["key"])
                    UpdateBotList(1)
                    --InviteByName(inviteBtn["key"])
                end)
                leaveBtn["key"] = key
                leaveBtn:SetScript("OnClick", function()
                    SendBotCommand("leave", "WHISPER", nil, leaveBtn["key"])
                    UpdateBotList(1)
                end)
                whisperBtn["key"] = key
                whisperBtn:SetScript("OnClick", function()
                    local editBox = _G["ChatFrameEditBox"]
                    editBox:Show()
                    editBox:SetFocus()
                    editBox:SetText("/w " .. whisperBtn["key"] .. " ")
                end)
                summonBtn["key"] = key
                summonBtn:SetScript("OnClick", function()
                    SendBotCommand("summon", "WHISPER", nil, summonBtn["key"])
                end)


                item:Show()

                index = index + 1
                x = x + (5 + item:GetWidth())
                height = item:GetHeight()
                if (width < x) then width = x end
                if (fmod((index - 1), colCount) == 0) then
                    y = y + (5 + height)
                    x = 5
                end
            end
            if (fmod((index - 1), colCount) ~= 0) then
                y = y + (5 + height)
            end
            
            if (GetNumGroupMembers() > 10) then 
                y = 230
            end
                        
            local tb = BotRoster.toolbar["quickbar"]
            tb:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            local loginAllBtn = tb.buttons["login_all"]
            x = 0
            loginAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedIn) then
                loginAllBtn:Show()
                x = x + 16
            else
                loginAllBtn:Hide()
            end
            loginAllBtn["allBots"] = allBots
            loginAllBtn:SetScript("OnClick", function()
                SendBotCommand(".bot add " .. loginAllBtn["allBots"], "SAY")
            end)

            local logoutAllBtn = tb.buttons["logout_all"]
            logoutAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedOut) then
                logoutAllBtn:Show()
                x = x + 16
            else
                logoutAllBtn:Hide()
            end
            logoutAllBtn["allBots"] = allBots
            logoutAllBtn:SetScript("OnClick", function()
                SendBotCommand(".bot rm " .. logoutAllBtn["allBots"], "SAY")
            end)

            local inviteAllBtn = tb.buttons["invite_all"]
            inviteAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsInParty) then
                inviteAllBtn:Show()
                x = x + 16
            else
                inviteAllBtn:Hide()
            end
            inviteAllBtn["key"] = key
            inviteAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key)
                        --InviteByName(key)
						InviteUnit(key)
                    end, key)
                    timeout = timeout + 0.1
                end
                UpdateBotList(10)
            end)

            local leaveAllBtn = tb.buttons["leave_all"]
            leaveAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (atLeastOneBotInParty) then
                leaveAllBtn:Show()
                x = x + 16
            else
                leaveAllBtn:Hide()
            end
            leaveAllBtn["key"] = key
            leaveAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key) SendBotCommand("leave", "WHISPER", nil, key) end, key)
                    timeout = timeout + 0.1
                end
                UpdateBotList(10)
            end)
            
			local summonAllBtn = tb.buttons["summon_all"]
            summonAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedOut) then
                summonAllBtn:Show()
                x = x + 16
            else
                summonAllBtn:Hide()
            end
					
            summonAllBtn["key"] = key
            summonAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key) SendBotCommand("summon", "WHISPER", nil, key) end, key)
                    timeout = timeout + 0.1
                end
            end)				
            
            local formationToolBar = BotRoster.toolbar["group_formation"]
            if (atLeastOneBotInParty) then
                formationToolBar:Show()
                y = y + 22
                formationToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                formationToolBar:Hide()
            end

            local movementToolBar = BotRoster.toolbar["group_movement"]
            if (atLeastOneBotInParty) then
                movementToolBar:Show()
                y = y + 22
                movementToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                movementToolBar:Hide()
            end

            local savemanaToolBar = BotRoster.toolbar["group_savemana"]
            if (atLeastOneBotInParty) then
                savemanaToolBar:Show()
                y = y + 22
                savemanaToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                savemanaToolBar:Hide()
            end

            local genericToolBar = BotRoster.toolbar["group_generic"]
            if (atLeastOneBotInParty) then
                genericToolBar:Show()
                y = y + 22
                genericToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                genericToolBar:Hide()
            end

            local genericCombatToolBar = BotRoster.toolbar["group_generic_combat"]
            if (atLeastOneBotInParty) then
                genericCombatToolBar:Show()
                y = y + 22
                genericCombatToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                genericCombatToolBar:Hide()
            end

            UpdateGroupToolBar()
            BotRoster:SetWidth(width)
            BotRoster:SetHeight(y + 22)
        end
    end

    if (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_ADDON") then
        --print(event.." 1 "..arg1.." 2 "..arg2.." 3 "..arg3.." 4 "..arg4)
        local message = arg1
        local sender = arg2
        if (event == "CHAT_MSG_ADDON") then 
			message = arg2 
			sender = arg4 
		end

        OnWhisper(message, sender)
        
        if (BotDebugPanel:IsVisible()) then
            UpdateBotDebugPanel(message, sender)
        end

        if (BotRoster:IsVisible() or SelectedBotPanel:IsVisible()) then
            -- if (string.find(message, "Hello") == 1 or string.find(message, "Goodbye") == 1) then
            --     SendBotCommand(".bot list", "SAY")
            --     QueryBotParty()
            -- end
            if (string.find(message, "Following") == 1 or string.find(message, "Staying") == 1 or string.find(message, "Fleeing") == 1) then
                wait(0.1, function() SendBotAddonCommand("nc ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "Formation set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("formation ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "Stance set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("stance ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "Loot strategy set to ") == 1) then
                wait(0.1, function() SendBotAddonCommand("ll ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "rti set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("rti ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "rti cc set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("rti cc ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "save mana") == 1) then
                wait(0.1, function() SendBotAddonCommand("save mana ?", "WHISPER", nil, sender) end)
            end
            UpdateGroupToolBar()
        end

        local bot = botTable[sender]
        if (bot == nil or bot["strategy"] == nil or bot["role"] == nil) then
            SelectedBotPanel:Hide()
            return
        end
        local selected = GetUnitName("target")
        if (CurrentBot ~= nil) then selected = CurrentBot end
        if (sender == selected) then
            SelectedBotPanel:Show()

            local tmp, class = "Unknown";
            if (GetUnitName("target") ~= nil) then
                tmp,class = UnitClass("target")
            end
            SetFrameColor(SelectedBotPanel, class)

            local filename = "Interface\\Addons\\Mangosbot\\Images\\role_" .. bot["role"] .. ".tga"
            SelectedBotPanel.header.role.texture:SetTexture(filename)
            SelectedBotPanel.header.text:SetText(sender)

            local width = 0
            local height = 0
            for toolbarName,toolbar in pairs(ToolBars) do
                local panelVisible = true
                if (string.find(toolbarName, "CLASS_") == 1) then
                    if (string.find(string.sub(toolbarName, 7), class) == 1) then
                        SelectedBotPanel.toolbar[toolbarName]:Show()
                    else
                        SelectedBotPanel.toolbar[toolbarName]:Hide()
                        panelVisible = false
                    end
                end
                local numButtons = 0
                for buttonName,button in pairs(toolbar) do
                    local toggle = false
                    if (button["strategy"] ~= nil) then
                        for key,strategy in pairs(bot["strategy"]["nc"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
                        for key,strategy in pairs(bot["strategy"]["co"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
						for key,strategy in pairs(bot["strategy"]["react"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
                    end
                    if (button["formation"] ~= nil and bot["formation"] ~= nil and string.find(bot["formation"], button["formation"]) ~= nil) then
                        toggle = true
                    end
                    if (button["stance"] ~= nil and bot["stance"] ~= nil and string.find(bot["stance"], button["stance"]) ~= nil) then
                        toggle = true
                    end
                    if (button["rti"] ~= nil and bot["rti"] ~= nil and string.find(bot["rti"], button["rti"]) ~= nil) then
                        toggle = true
                    end
                    if (button["rti_cc"] ~= nil and bot["rti_cc"] ~= nil and string.find(bot["rti_cc"], button["rti_cc"]) ~= nil) then
                        toggle = true
                    end
                    if (button["loot"] ~= nil and bot["loot"] ~= nil and string.find(bot["loot"], button["loot"]) ~= nil) then
                        toggle = true
                    end
                    if (button["savemana"] ~= nil and bot["savemana"] ~= nil and string.find(bot["savemana"], button["savemana"]) ~= nil) then
                        toggle = true
                    end
                    ToggleButton(SelectedBotPanel, toolbarName, buttonName, toggle)
                    numButtons = numButtons + 1
                end
                if (panelVisible) then
                    height = height + 1
                    if (width < numButtons) then width = numButtons end
                end
            end
            ResizeBotPanel(SelectedBotPanel, width * 25 + 20, height * 25 + 25)
        end
    end
end)

function UpdateGroupToolBar()
    for toolbarName,toolbar in pairs(GroupToolBars) do
        for buttonName,button in pairs(toolbar) do
            local toggleCount = 0
            for botName,bot in pairs(botTable) do
                local toggle = false
                if (button["strategy"] ~= nil and bot["strategy"] ~= nil) then
                    for key,strategy in pairs(bot["strategy"]["nc"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
                    for key,strategy in pairs(bot["strategy"]["co"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
					for key,strategy in pairs(bot["strategy"]["react"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
                end
                if (button["formation"] ~= nil and bot["formation"] ~= nil and string.find(bot["formation"], button["formation"]) ~= nil) then
                    toggle = true
                end
                if (button["stance"] ~= nil and bot["stance"] ~= nil and string.find(bot["stance"], button["stance"]) ~= nil) then
                    toggle = true
                end
                if (button["rti"] ~= nil and bot["rti"] ~= nil and string.find(bot["rti"], button["rti"]) ~= nil) then
                    toggle = true
                end
                if (button["rti_cc"] ~= nil and bot["rti_cc"] ~= nil and string.find(bot["rti_cc"], button["rti_cc"]) ~= nil) then
                    toggle = true
                end
                if (button["loot"] ~= nil and bot["loot"] ~= nil and string.find(bot["loot"], button["loot"]) ~= nil) then
                    toggle = true
                end
                if (button["savemana"] ~= nil and bot["savemana"] ~= nil and string.find(bot["savemana"], button["savemana"]) ~= nil) then
                    toggle = true
                end
                
                if (toggle) then 
                    for i = 1,5 do
                        if (partyName(i) == botName) then
                            toggleCount = toggleCount + 1
                        end
                    end
                end
            end
            ToggleButton(BotRoster, toolbarName, buttonName, toggleCount > 0, toggleCount < partySize())
        end
    end
end

function trim2(s)

    local find = string.find
    local sub = string.sub
    function trim8(s)
      local i1,i2 = find(s,'^%s*')
      if i2 >= i1 then s = sub(s,i2+1) end
      local i1,i2 = find(s,'%s*$')
      if i2 >= i1 then s = sub(s,1,i1-1) end
      return s
    end
    return trim8(s)
end

function splitString2( self, inSplitPattern, outResults )
  if not inSplitPattern then
    return
  end
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function OnWhisper(message, sender)
    if (botTable[sender] == nil) then
        botTable[sender] = {}
    end

    local type = "co"
	local validStrategy = false
	local bot = botTable[sender]
	local trm = 19
	if(string.find(message, 'Combat Strategies: ') == 1) then
		type = "co"
		validStrategy = true
		trm = 19
	elseif(string.find(message, 'Non Combat Strategies: ') == 1) then
		type = "nc"
		validStrategy = true
		trm = 23
	elseif(string.find(message, 'Reaction Strategies: ') == 1) then
		type = "react"
		validStrategy = true
		trm = 21
	end
	
    if (validStrategy) then
		local list = {}
		local role = "dps"
        local text = string.sub(message, trm)
        local splitted = splitString2(text, ", ")
        for i = 1, tablelength(splitted) do
            local name = trim2(splitted[i])
            table.insert(list, name)
            if (name == "heal") then role = "heal" end
            if (name == "tank" or name == "bear") then role = "tank" end
        end
        if (bot['strategy'] == nil) then
            bot['strategy'] = {nc = {}, co = {}, react = {}}
        end
        if (type == "co") then
            bot["role"] = role
        end
        bot['strategy'][type] = list
    end
    if (string.find(message, 'Formation: ') == 1) then
        bot['formation'] = string.sub(message, 11)
    end
    if (string.find(message, 'Stance: ') == 1) then
        bot['stance'] = string.sub(message, 11)
    end
    if (string.find(message, 'Mana save level set: ') == 1) then
        bot['savemana'] = string.sub(message, 21)
    end
    if (string.find(message, 'Mana save level: ') == 1) then
        bot['savemana'] = string.sub(message, 17)
    end
    if (string.find(message, 'Loot strategy: ') == 1) then
        bot['loot'] = string.sub(message, 15)
    end
    if (string.find(message, 'rti: ') == 1) then
        bot['rti'] = string.sub(message, 5)
    end
    if (string.find(message, 'rti cc: ') == 1) then
        bot['rti_cc'] = string.sub(message, 5)
    end
end

local msgCount = 0

function OnSystemMessage(message)
	if (message == nil) then return false end
    if (string.find(message, 'add: ') == 1) and msgCount == 0 or (string.find(message, 'rm: ') == 1 and msgCount == 0) then
        UpdateBotList(1) 
        msgCount = msgCount + 1
        wait(5, function() msgCount = 0 end)
        return false
        end
    if (string.find(message, 'Bot roster: ') == 1) then
        botTable = {}
        local text = string.sub(message, 13)
        local splitted = splitString2(text, ", ")
        for i = 1, tablelength(splitted) do
            local line = trim2(splitted[i])
            local on = string.sub(line, 1, 1)
            local pos = string.find(line, " ")
            local name = string.sub(line, 2, pos - 1)
            local cls = string.sub(line, pos + 1)

            if (botTable[name] == nil) then
                botTable[name] = {}
            end
            botTable[name]["class"] = cls
            botTable[name]["online"] = (on == "+")
        end
        return true
    end
    return false
end

SLASH_MANGOSBOT1 = '/bot';
function SlashCmdList.MANGOSBOT(msg, editbox) -- 4.
    if (msg == "" or msg == "roster") then
        if (BotRoster:IsVisible()) then
            BotRoster:Hide()
        else
            BotRoster.ShowRequest = true
            SendBotCommand(".bot list", "SAY")
            QueryBotParty()
        end
    end
    if (string.find(msg, "debug")) then
        local cmd = string.sub(msg, 7)
        if (string.len(cmd) == 0 and BotDebugPanel:IsVisible()) then
            BotDebugPanel:Hide()
        else
            BotDebugPanel:Show()
            BotDebugFilter = cmd;
        end
    end
end

local waitTable = {};
local waitFrame = nil;

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function wait(delay, func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate");
    waitFrame:SetScript("OnUpdate",function ()
      local elapse = 0.1
      local count = tablelength(waitTable);
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9}});
  return true;
end

function print(s)
    if (s ~= nil) then DEFAULT_CHAT_FRAME:AddMessage(s); else DEFAULT_CHAT_FRAME:AddMessage("nil"); end
end

function partyName(i)
    local p = UnitName("party"..i)
    local r = UnitName("raid"..i)
    if (r == nil) then return p end
    return r
end

function partySize()
    local p = GetNumGroupMembers()
    local r = GetNumGroupMembers()
    if (r == 0) then return p end
    return r
end

print("MangosBOT Addon is loaded");
